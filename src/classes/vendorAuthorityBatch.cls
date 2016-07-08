public with sharing class vendorAuthorityBatch implements Database.Batchable<sObject>{
	public final String query;
   	
	public vendorAuthorityBatch(String q){
         query=q;
	}

	public Database.QueryLocator start(Database.BatchableContext BC){
    	return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, Account[] scope){
		//budgetUtility.processBudgets(scope);
		vendorAuthorityUtility.checkProjectDocuments(scope);
	}

	public void finish(Database.BatchableContext BC){
		//Nothing to do.
   }
}