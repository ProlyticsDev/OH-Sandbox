public with sharing class budgetRecalcBatch implements Database.Batchable<sObject>{
	public final String query;
   	
	public budgetRecalcBatch(String q){
         query=q;
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, Budget__c[] scope){
		budgetUtility.processBudgets(scope);
	}

	public void finish(Database.BatchableContext BC){
		//execute the batch script that calculates any missing budget records.
		budgetCreateMissingBatch b = new budgetCreateMissingBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Project__c, Project__r.Name, Split_A_Id__c, Split_B_Id__c, Lead_Start_Date__c, Lead_End_Date__c, Vendor_Budget_Qty__c, OH_Budget_Qty__c from Budget__c where Type__c = \'Actual\''); 
      	database.executebatch(b);
   }
}