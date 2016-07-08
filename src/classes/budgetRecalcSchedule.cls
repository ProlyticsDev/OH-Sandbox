public with sharing class budgetRecalcSchedule implements Schedulable{
	
	public void execute(SchedulableContext sc) {
      budgetRecalcBatch b = new budgetRecalcBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Project__c from Budget__c where Type__c = \'Actual\''); 
      database.executebatch(b);
   }
   
   /* Run Adhoc:  database.executebatch(new budgetRecalcBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Project__c from Budget__c where Type__c = \'Actual\''));*/

}