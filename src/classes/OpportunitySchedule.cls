/**
* @author JH 
* @date 24/03/2016
* @description Schedule for all opportunities. Passes in a query of all opps. 
*/ 
public with sharing class OpportunitySchedule implements Schedulable{
    
    public void execute(SchedulableContext sc) {

		String query = 'Select Id, Project__r.Name,Expected_Titled_Date__c From Opportunity'; 
		OpportunityBatch oppBatch = new OpportunityBatch(query);
		Database.executeBatch(oppBatch);  
    }
}