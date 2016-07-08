trigger taskTrigger on Task (After Insert, After Update) {

/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 5 March 2013
Trigger Purpose: Update the 'Last Activity Date' custom field on the Opportunity record if this Task relates to an Opportunity
*/

    //Declare Variables
    String[] oIds = new String[]{};
    Opportunity[] oUpdates = new Opportunity[]{}; //List of Opportunities to be updated
    String opportunityPrefix = Opportunity.SobjectType.getDescribe().getKeyPrefix();

    For(Task t: trigger.new){
        
        //If the Task is related to an Opportunity, add the Opportunity to a list for updating
        
        If(t.WhatId != null && ((String)t.WhatId).startsWith(opportunityPrefix)){
        
            oIds.add(t.WhatId);
            
        }
    }
    if(!oIds.isEmpty()){
        //there are some opportunities to process, so finish the process
        //Loop through the list and update the Last Activity Date
        For(Opportunity o: [SELECT Id, Last_Activity_Date__c, Appointment_Start_Time__c, Appointment_End_Time__c FROM Opportunity WHERE Id in: oIds]){
            o.Last_Activity_Date__c = date.today();
            oUpdates.add(o); //Add to the list that will be updated
        }
        try{
            update oUpdates; //Update the Opportunities
        }
        catch(exception e){
            system.debug('Could not update the opportunity: '+e);
        }
    }    
    
}