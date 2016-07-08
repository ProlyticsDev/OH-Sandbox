public with sharing class budgetCalculateVendorSchedule implements Schedulable{
	
	public void execute(SchedulableContext sc) {
      budgetCalculateVendorBatch b = new budgetCalculateVendorBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Actual_Dollar_Vendor__c, Actual_Qty_Vendor__c, Project__c from Budget__c where Type__c = \'Actual\''); 
      database.executebatch(b);
   }
   
   /* Run Adhoc:  database.executebatch(new budgetCalculateVendorBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Actual_Dollar_Vendor__c, Actual_Qty_Vendor__c, Project__c from Budget__c where Type__c = \'Actual\''));*/

}