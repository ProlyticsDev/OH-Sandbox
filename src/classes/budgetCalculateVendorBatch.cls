public with sharing class budgetCalculateVendorBatch implements Database.Batchable<sObject>{
	public final String query;
   	
	public budgetCalculateVendorBatch(String q){
         query=q;
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, Budget__c[] scope){
		budgetUtility.updateVendorBudgets(scope);
	}

	public void finish(Database.BatchableContext BC){
		//END	
   }
}