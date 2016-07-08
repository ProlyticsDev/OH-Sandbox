/*
    Type:        Trigger
    Purpose:     Auto convert personal account, contact, opp if lead record type is
                 appartment

    Used By:     Lead Object
    ---------------------------------------------------------------
    History:
      v1.0 created -- Ji Zhang 27/09/2012
      v1.01 removed record type check -- Ji Zhang 20/11/2012
      v1.02 11/02/2016 HR - fix failing test where lead project is null or does not match the project list and not convert them. 
                            Add notes to Leads and assign them to Bad Lead queue to unconverted leads  
      v4.00 01/04/2016 HR - Add feature to update the primary product status for the property reservation leads in after insert and after update
                            Call the lead conversion method in the LeadFramework
            13/04/2016 HR - Change product status to available for deleted leads
            13/04/2016 JH - Refactored code changes 
            10/05/2016 JH - Added setLeadProject lookup to before update 
            12/05/2016 JH - Added method to set the subscription based on the record type before an insert 
*/

trigger LeadTrigger on Lead (before update, before insert, after insert, after update, after delete) {
    if(trigger.isBefore) {
        if(trigger.isInsert) {
           try{
                LeadFramework.filterReservationLeadsAndUpdateContractPrice(trigger.new); 
                LeadFramework.setLeadProjectLookup(trigger.new); 
            }catch(Exception ex){                
                ApexError.AddException(ex);                
                if(Test.isRunningTest()){
                    throw new NotImplementedException('Failed to insert lead(s). '+UtilClass.getApexErrors());
                }else{
                    throw new NotImplementedException('Failed to insert lead(s). '+ex.getMessage());
                }
            }
        }

        if(trigger.isUpdate) {
          try{
                LeadFramework.filterReservationLeadsAndUpdateContractPrice(trigger.new); 
                LeadFramework.setLeadProjectLookup(trigger.new); 
            }catch(Exception ex){
                ApexError.AddException(ex);
                if(Test.isRunningTest()){
                    throw new NotImplementedException('Failed to insert lead(s). '+UtilClass.getApexErrors());
                }else{
                    throw new NotImplementedException('Failed to insert lead(s). '+ex.getMessage());
                }
            }
        }
    }

    if(trigger.isAfter) {
        if(trigger.isInsert) {
           try{
                system.debug('Conversion is starting');
                LeadFramework.leadTriggerHandler(trigger.new); 
                //SalesFix : When a lead has opted out of email, add them to the global email usubscribe campaign
                LeadFramework.emailOptOutLeads(trigger.new);
                LeadFramework.shareLeadsWithCreators(trigger.new); 
            }catch(Exception ex){
                ApexError.AddException(ex);
                if(Test.isRunningTest()){
                    throw new NotImplementedException('Failed to insert lead(s). '+UtilClass.getApexErrors());
                }else{
                    throw new NotImplementedException('Failed to insert lead(s). '+ex.getMessage());
                }
            }
        }

        if(trigger.isUpdate) {
           try{
                LeadFramework.leadTriggerHandler(trigger.new); 
                //jh salesfix logic moved into separate method 
                LeadFramework.globalOptInOutUnsubscribeCampaign(trigger.newMap, trigger.oldMap);
                LeadFramework.shareLeadsWithCreators(trigger.new);  
                //jh - previously this was in the lead trigger & opp trigger
                //was causing multiple contact roles to be generated have removed this & left the logic for the opp trigger. 
                //LeadFramework.maintainPrimaryContact(trigger.newMap, trigger.oldMap); 
            }catch(Exception ex){
                ApexError.AddException(ex);
                if(Test.isRunningTest()){
                    throw new NotImplementedException('Failed to insert lead(s). '+UtilClass.getApexErrors());
                }else{
                    throw new NotImplementedException('Failed to insert lead(s). '+ex.getMessage());
                }
            }
        }
        
        if(trigger.isDelete){
            try{
                LeadFramework.performeAfterDeleteActions(trigger.old);
            }catch(Exception ex){
                ApexError.AddException(ex);
                if(Test.isRunningTest()){
                    throw new NotImplementedException('Failed to insert lead(s). '+UtilClass.getApexErrors());
                }else{
                    throw new NotImplementedException('Failed to insert lead(s). '+ex.getMessage());
                }
            }
        }
    }
}