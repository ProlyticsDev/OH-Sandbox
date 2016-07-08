trigger commissionTrigger on Commission__c (after delete, after insert, after update) 
{

    //OppotunityUpdates for Revenue
    Map<Id,string> oppUpdates = new Map<Id,string>();
                //check if Amount has changed and it is Oliver Hume or Channel
    if (Trigger.isInsert)
        for (Commission__c c : Trigger.New)
            if (c.Category__c == 'Channel' || c.Category__c == 'Oliver Hume') 
                oppUpdates.put(c.Opportunity__c, c.Opportunity__c);

    if (Trigger.isUpdate && Trigger.isAfter) {   
        // Look up Oliver Hume record type id
        Id OHRecTypeId = [SELECT Id FROM RecordType WHERE sObjectType = 'Commission__c' AND DeveloperName ='Oliver_Hume'].Id;

        // Create maps specifying whether OH Commissions have been paid for a linked Opportunity
        // i.e. MAP<OpportunityID, HasBeenPaid?>
        MAP<Id, Boolean> oppsP1Paid = new MAP<Id, Boolean>();
        MAP<Id, Boolean> oppsP2Paid = new MAP<Id, Boolean>();
        SET<Id> oppIds = new SET<Id>();
        for (Commission__c c : Trigger.New) {
            if ((c.Category__c == 'Channel' || c.Category__c == 'Oliver Hume') && trigger.oldMap.get(c.Id).Amount__c != c.Amount__c)
                oppUpdates.put(c.Opportunity__c, c.Opportunity__c);

            if (c.RecordTypeId == OHRecTypeId &&
                c.Status__c == 'Paid' &&
                trigger.oldMap.get(c.Id).Status__c != c.Status__c) {
                oppIds.add(c.Opportunity__c);
                if (c.Payment_Type__c == 'P1') {
                    oppsP1Paid.put(c.Opportunity__c, true);
                } else if (c.Payment_Type__c == 'P2') {
                    oppsP2Paid.put(c.Opportunity__c, true);
                }
            }
        }
        
        // Find all OH Commissions that look up to same opportunities with Status != Paid
        LIST<Commission__c> comms = [SELECT Id, Opportunity__c, Payment_Type__c
                                    FROM Commission__c 
                                    WHERE Status__c != 'Paid'
                                    AND RecordTypeId =: OHRecTypeId
                                    AND Opportunity__c IN :oppIds];

        // If any OH Commissions have status not equal to Paid, then update paid flag to false
        for (Commission__c c: comms) {
            if (c.Payment_Type__c=='P1') {
                oppsP1Paid.put(c.Opportunity__c, false);
            } else if (c.Payment_Type__c=='P2') {
                oppsP2Paid.put(c.Opportunity__c, false);
            }
        }

        // Update 'Commissions_Paid_to_OH' checkbox field on Opportunities where both P1 & P2 OH Commissions have been paid
        LIST<Opportunity> oppsForUpdate = new LIST<Opportunity>();
        for (Id oppId : oppIds) {
            if ((!oppsP1Paid.containskey(oppId) || oppsP1Paid.get(oppId)) && 
                (!oppsP2Paid.containsKey(oppId) || oppsP2Paid.get(oppId))) {
                oppsForUpdate.add(new Opportunity(id = oppId, Commissions_Paid_to_OH__c = true));
            }
        }       
        Database.update(oppsForUpdate, false);

        // Get Opportunity Ids for OH Commissions which are paid for P1 & P2
        LIST<ID> oppsP1PaidIds = new LIST<ID>();
        LIST<ID> oppsP2PaidIds = new LIST<ID>();
        for (Id oppId : oppIds) {
            if (oppsP1Paid.containsKey(oppId) && oppsP1Paid.get(oppId)) {
                oppsP1PaidIds.add(oppId);
            }
            if (oppsP2Paid.containsKey(oppId) && oppsP2Paid.get(oppId)) {
                oppsP2PaidIds.add(oppId);
            }
        }

        // Find P1 Commission records which should be updated to Status = Payable
        LIST<Commission__c> com_P1_updates = [SELECT Id FROM Commission__c 
                                              WHERE Status__c != 'Paid'
                                              AND RecordTypeId !=: OHRecTypeId
                                              AND Payment_Type__c = 'P1'
                                              AND Opportunity__c IN :oppsP1PaidIds];

        // Find P2 Commission records which should be updated to Status = Payable
        LIST<Commission__c> com_P2_updates = [SELECT Id FROM Commission__c 
                                              WHERE Status__c != 'Paid'
                                              AND RecordTypeId !=: OHRecTypeId
                                              AND Payment_Type__c = 'P2'
                                              AND Opportunity__c IN :oppsP2PaidIds];

        // Update Commission status field to Payable
        LIST<Commission__c> commsForUpdate = new LIST<Commission__c>();
        for (Commission__c c : com_P1_updates) {
            c.Status__c = 'Payable';
            commsForUpdate.add(c);
        }
        for (Commission__c c : com_P2_updates) {
            c.Status__c = 'Payable';
            commsForUpdate.add(c);
        }

        Database.update(commsForUpdate, false);

    }
    
    if (!oppUpdates.isEmpty()) CommissionMaintain.GenerateRevenue( oppUpdates.values());
}