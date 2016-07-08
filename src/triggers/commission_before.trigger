trigger commission_before on Commission__c (before insert, before update) {
    Map<Id,RecordType> rtMap = new Map<Id,RecordType>([select id, DeveloperName from RecordType where SobjectType = 'Commission__c']);
    List<string> ids = new List<string>();
    for( Commission__c comRec : trigger.new )
            ids.add(comRec.Opportunity__c);
            
    Map<Id,Opportunity> opportunities = new Map<id,Opportunity>();
    //Map<Id,integer> opportunityCount = new Map<id,integer>();
    for(Opportunity opp : [select Customer_Reference__c, Commission_Count__c, Primary_Product__c, Project__c, Project__r.Solicitor__c from Opportunity where Id in :ids]){
        opportunities.put(opp.Id, opp);
        //opportunityCount.put(opp.Id, integer.valueOf(opp.Commission_Count__c));
    }
        
    for( Commission__c comRec : trigger.new ){
        if (trigger.isUpdate && comRec.Amount_Excl__c != null && trigger.oldMap.get(comRec.Id).Amount_Excl__c != null && math.abs(comRec.Amount_Excl__c - trigger.oldMap.get(comRec.Id).Amount_Excl__c) > 0.01 && string.IsBlank(comRec.Amount_Change_Reason__c))
            comRec.addError('You must specify a change amount reason.');

        /* Disabled since File As field is being replaced by a formula
        if (string.IsBlank(comRec.File_As__c) && opportunities.containsKey(comRec.Opportunity__c) && opportunityCount.containsKey(comRec.Opportunity__c)){
            integer recCount = opportunityCount.get(comRec.Opportunity__c) + 1;
            comRec.File_As__c =  opportunities.get(comRec.Opportunity__c).Customer_Reference__c + '-' +  string.valueOf(recCount);
            if(comRec.File_As__c.Length()>20) comRec.File_As__c = comRec.File_As__c.substring(0,20);
            opportunityCount.put(comRec.Opportunity__c, recCount);
        }
        */
        
        if (string.IsBlank(comRec.Product__c) && opportunities.containsKey(comRec.Opportunity__c)){
            comRec.Product__c = opportunities.get(comRec.Opportunity__c).Primary_Product__c;
        }
        if (string.IsBlank(comRec.Project__c) && opportunities.containsKey(comRec.Opportunity__c)){
            comRec.Project__c = opportunities.get(comRec.Opportunity__c).Project__c;
        }
        if (opportunities.containsKey(comRec.Opportunity__c)){
            comRec.Vendor_Solicitor__c = opportunities.get(comRec.Opportunity__c).Project__r.Solicitor__c;
        }
        
        // Set checkboxes used for Roll-Up Summary field's filter criteria
        if (comRec.Category__c == 'House') {
            comRec.Include_In_OHCommissionRollups__c = true;
        } else if (comRec.Category__c == 'Oliver Hume') {
            comRec.Include_In_OHCommissionRollups__c = comRec.AccountMatchesVAOHAccount__c;
        } else {
            comRec.Include_In_OHCommissionRollups__c = false;
        }
        If (comRec.Commission_Claim_Type__c == 'Irrevocable - Retain') {
            comRec.Irrevocable_Retain__c = true;
        } else {
            comRec.Irrevocable_Retain__c = false;
        }
        
  /****
        10 Mar 16 mark.townsend@coroma.com.au 
        Related to: Commissions Project - Sprint 6, Item 6.22, 6.23, 6.24, 6.03
        Changed to remove finance flags, added additional automation, recalculate based on GST 
    ***/
    /**
       GST if not specified is the differenct between Amount (inc) and Amount_Excl__c as these are set on the VF Page, otherwise these values have been
       entered manually andf therefore the calculation will be Amount_Excl__c + GST__c, therefore calulate this as a fall back in all cases  **/


        
        boolean UpdateGST=false;
        if(trigger.IsUpdate){
            //Both Amount__c and Amount_Excl__c udpated in UI
            if(trigger.oldMap.get(comRec.Id).Amount__c != comRec.Amount__c && trigger.oldMap.get(comRec.Id).Amount_Excl__c != comRec.Amount_Excl__c){
                 updateGST=true;   
            }
            else if(trigger.oldMap.get(comRec.Id).Amount__c != comRec.Amount__c)//user just update amount manually
            {
                comRec.Amount_Excl__c = (comRec.Amount__c == null ? 0 : comRec.Amount__c)/1.1;
                updateGST=true;
            }
            else if(trigger.oldMap.get(comRec.Id).Amount_Excl__c != comRec.Amount_Excl__c)//user just update amount excl manually
            {
                comRec.Amount__c = (comRec.Amount_Excl__c == null ? 0 : comRec.Amount_Excl__c)*1.1;
                updateGST=true;
            }
            else if(trigger.oldMap.get(comRec.Id).GST__c != comRec.GST__c) // GST is updated manually
                comRec.Amount__c =  (comRec.Amount_Excl__c == null) ? 0 : comRec.Amount_Excl__c + comRec.GST__c;
        }
        
        if ( comRec.GST__c == null || UpdateGST) comRec.GST__c = ((comRec.Amount__c == null) ? 0 : comRec.Amount__c) - ((comRec.Amount_Excl__c == null) ? 0 : comRec.Amount_Excl__c);
        
         
        //set finance flags
        if(trigger.isUpdate){
            Commission__c oldRec = trigger.oldMap.get(comRec.id);
/*            
            if ( oldRec.Actual_Paid_Amount__c > 0 && comRec.Actual_Paid_Amount__c != oldRec.Actual_Paid_Amount__c){
                if ( comRec.Finance_Dept_Approved__c && string.IsBlank(comRec.Finance_Comment__c) ) {
                    comRec.AddError('The commission record has already been finance approved, you cannot update the Actual Paid amount.');
                    return;
                }
            }
            
            
            if ( comRec.Finance_Dept_Approved__c && string.IsBlank(comRec.Finance_Comment__c) &&
                 ((oldRec.Amount__c != null && comRec.Amount__c != oldRec.Amount__c) || 
                  (oldRec.Amount_Excl__c != null && comRec.Amount_Excl__c != oldRec.Amount_Excl__c)
                  )
                ) {
                comRec.AddError('The commission record has already been finance approved, you cannot update the Amount.');
                return;
            }            

            if ( oldRec.Finance_Dept_Approved__c != true && comRec.Finance_Dept_Approved__c && comRec.Amount__c != comRec.Actual_Paid_Amount__c){
                if (string.IsBlank(comRec.Finance_Comment__c)){
                    comRec.AddError('You must include a finance comment to approve this record.');
                    return;
                }
            }

            if( comRec.Actual_Paid_Amount__c != null && 
                (comRec.Actual_Paid_Amount__c != oldRec.Actual_Paid_Amount__c || comRec.Amount__c != oldRec.Amount__c)){
                if ( comRec.Actual_Date_Paid__c == null ) comRec.Actual_Date_Paid__c = Date.Today();
                if ( comRec.Actual_Paid_Amount__c == comRec.Amount__c ) {
                    comRec.Finance_Dept_Approved__c = true;
                    comRec.Status__c = 'Paid';
                }
            }
            */
            /*
                Add this Automation - FOR RECORD TYPE OLIVER HUME ONLY When User Marks the Status as 'Paid' and saves the Record, The Finance Dept Approved Tick box is Ticked, 
                The Actual Amount Recevied is entered to equal the Total Amount (inc GST), and the Actual Date Paid updates to TODAY 
                
                
                E.       Payment Date / Paid Automation for Commission Record
 
                When Record Status changed to PAID, Actual Amount Paid updates to match Total Amount and Finance Tick Box Ticked, 
                UNLESS either field IS NOT BLANK, in that case, do not update the fields.

*/
            if( rtMap.containsKey(comRec.RecordTypeId) && rtMap.get(comRec.RecordTypeId).DeveloperName == 'Oliver_Hume' && oldRec.Status__c != 'Paid' && comRec.Status__c == 'Paid' && comRec.Actual_Paid_Amount__c == null && !comRec.Finance_Dept_Approved__c ){
                    comRec.Actual_Paid_Amount__c = comRec.Amount__c;
                    comRec.Actual_Date_Paid__c = comRec.Actual_Date_Paid__c == null ? Date.Today() : comRec.Actual_Date_Paid__c;
                    comRec.Finance_Dept_Approved__c = true;
            }
            /*
                Add this Automation - FOR RECORD TYPE OLIVER HUME ONLY When the User Ticks the Finance Apt Tick Box, the Finance Comment and the Actual Date Paid, and clicks save, 
                the Commission Record status updates to 'Paid' */
            if( rtMap.containsKey(comRec.RecordTypeId) && rtMap.get(comRec.RecordTypeId).DeveloperName == 'Oliver_Hume' && oldRec.Finance_Dept_Approved__c != comRec.Finance_Dept_Approved__c && comRec.Finance_Dept_Approved__c && comRec.Actual_Date_Paid__c != null && !string.IsBlank(comRec.Finance_Comment__c)){
                comRec.Status__c = 'Paid';
            }
        }

    }
}