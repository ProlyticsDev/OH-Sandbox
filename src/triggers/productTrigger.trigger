trigger productTrigger on Product__c (before insert, before update, after update, after insert) {
/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 5 March 2013
Trigger Purpose: When the Internal Status of a Product is set to Unavailable, check to see if there are any other 
Opportunities that have an ‘interest’ (Stage values of New Enquiry; Contacted; Qualified; Appointment) in the same Product. 
If there are any, send a Task notification to the Opportunity Owner advising that the Product is no longer available.

Modified by: Mubbashir Ali, Aprika (mubbashir.ali@aprika.com.au)
Modified date: 27 March 2014
Modificiation Purpose: Oliver Hume needs to invoice the Vendor at the most opportune time to avoid issues with GST. 
    The Settlement Invoice Date needs to be updated based on the Titled Date and Settlement Terms agreed with the purchaser.
    The Opportunity Trigger will update the Product ‘Settlement Terms’ field to ensure it matches the same field on the Opportunity record. 

Modified by: Matt Lacey
Modified date: 24th June 2014
Modificiation Purpose: Commission records are being created from the Opportunity Trigger, that relate to the ‘IsWon’ Opportunity related to a Product record.
    These records need to have their ‘Status’ changed from Pending to Payable based on date values that will be entered on the Product. The dates trigger
    changes to checkboxes which are used to drive the status updates.

*/
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            ohHelper.createOrAssignCreditorLedger(Trigger.new);    
        }
        else if (Trigger.isUpdate) {
            // Recalculate Commission Due Dates if certain fields are updated
            set<string> dateOpps = new Set<string>();
            set<string> prs = new Set<string>();
            LIST<Opportunity> oppsForUpdate;
    
            for(Product__c pr : Trigger.New) {
                if ((pr.Expected_Titled_Date__c != Trigger.oldMap.get(pr.Id).Expected_Titled_Date__c) ||
                    (pr.Titled_Date__c != Trigger.oldMap.get(pr.Id).Titled_Date__c) ||
                    (pr.Title_Release__c != Trigger.oldMap.get(pr.Id).Title_Release__c)) {
                    prs.add(pr.Id);
                }
            }
    
            if (prs.size() > 0) {
                oppsForUpdate = [SELECT Id FROM Opportunity
                                 WHERE Primary_Product__c IN :prs
                                 AND StageName != 'Reservation Cancelled'
                                 AND StageName != 'Contract Cancelled'];
                for (Opportunity o : oppsForUpdate) {
                    dateOpps.add(o.Id);
                }
                if (dateOpps.size() > 0) {
                    CommissionDetail_Helper.RecalcCommission(new Set<string>(), dateOpps);
                }
            }            
        }
    }
    
    if(trigger.isBefore)
    {
        if(trigger.isInsert)
        {
            for(Product__c p: trigger.new)
            {
                //if the internal status item is empty, set it as the commencement status.
                if(p.Internal_Status_Item__c == null && p.Internal_Status_Override__c == null)
                {
                    p.Internal_Status_Item__c = p.Commencement_Status__c;
                }
            }   
        }
        else if(trigger.isUpdate)
        {
            Set<Id> allUpdated = new set<Id>();
            Set<Id> settlementChecked = new Set<Id>();
            Set<Id> unconditionalChecked = new Set<Id>();
            Set<Id> constructionChecked = new Set<Id>();
            Set<Id> buildLockUpChecked = new Set<Id>();
            Map<Id, Date> settlementDateChanged = new Map<Id, Date>();
            Map<Id, Date> unconditionalDateChanged = new Map<Id, Date>();
            Map<Id, Date> constructionDateChanged = new Map<Id, Date>();
            Map<Id, Date> buildLockUpDateChanged = new Map<Id, Date>();
            List<Commission__c> commissionPayable = new List<Commission__c>();
            List<Product__c> products = new List<Product__c>();
            
            for(Product__c objProduct : trigger.new)
            {
                if(objProduct.Solicitor__c != Trigger.oldMap.get(objProduct.Id).Solicitor__c) {
                    products.add(objProduct);
                }
                
                if(objProduct.Titled_Date__c != null && 
                    (ohHelper.NormalizeDecimal(objProduct.Settlement_Terms_Days__c) > 0 || (objProduct.Settlement_Terms_Days__c != trigger.oldMap.get(objProduct.Id).Settlement_Terms_Days__c)))
                {
                    if(objProduct.Titled_Date__c + integer.valueOf(ohHelper.NormalizeDecimal(objProduct.Settlement_Terms_Days__c)) < date.today())
                    {
                        objProduct.Settlement_Invoice_Date__c = date.today();
                    }
                    else
                    {
                        objProduct.Settlement_Invoice_Date__c = objProduct.Titled_Date__c + integer.valueOf(ohHelper.NormalizeDecimal(objProduct.Settlement_Terms_Days__c));
                    }
                }

                if(objProduct.Settled_Check__c && !trigger.oldmap.get(objProduct.Id).Settled_Check__c)
                {
                    settlementChecked.add(objProduct.Id);
                    allUpdated.add(objProduct.Id);
                }

                if(objProduct.Unconditional_Check__c && !trigger.oldMap.get(objProduct.Id).Unconditional_Check__c)
                {
                    unconditionalChecked.add(objProduct.Id);
                    allUpdated.add(objProduct.Id);
                }

                if(objProduct.Construction_Commenced_Check__c && !trigger.oldMap.get(objProduct.Id).Construction_Commenced_Check__c)
                {
                    constructionChecked.add(objProduct.Id);
                    allUpdated.add(objProduct.Id);
                }

                if(objProduct.Build_Lockup_Check__c && !trigger.oldMap.get(objProduct.Id).Build_Lockup_Check__c)
                {
                    buildLockUpChecked.add(objProduct.Id);
                    allUpdated.add(objProduct.Id);
                }
                //also check for date milestones
                if(objProduct.Settlement_Invoice_Date__c != null && objProduct.Settlement_Invoice_Date__c != trigger.oldmap.get(objProduct.Id).Settlement_Invoice_Date__c)
                {
                    settlementDateChanged.put(objProduct.Id, objProduct.Settlement_Invoice_Date__c);
                    allUpdated.add(objProduct.Id);
                }

                if(objProduct.Unconditional_Date__c != null && objProduct.Unconditional_Date__c != trigger.oldmap.get(objProduct.Id).Unconditional_Date__c)
                {
                    unconditionalDateChanged.put(objProduct.Id, objProduct.Unconditional_Date__c);
                    allUpdated.add(objProduct.Id);
                }

                if(objProduct.Construction_Commenced_Date__c != null && objProduct.Construction_Commenced_Date__c != trigger.oldmap.get(objProduct.Id).Construction_Commenced_Date__c)
                {
                    constructionDateChanged.put(objProduct.Id, objProduct.Construction_Commenced_Date__c);
                    allUpdated.add(objProduct.Id);
                }

                if(objProduct.Build_Lockup_Date__c != null && objProduct.Build_Lockup_Date__c != trigger.oldmap.get(objProduct.Id).Build_Lockup_Date__c)
                {
                    buildLockUpDateChanged.put(objProduct.Id, objProduct.Build_Lockup_Date__c);
                    allUpdated.add(objProduct.Id);
                }
            }
            ohHelper.createOrAssignCreditorLedger(products);
        }
    }
}