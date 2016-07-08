/**
* @author J.HESKETH
* @date 24/03/2016
* @description 
* 
*/ 
public with sharing class OpportunityBatch implements Database.Batchable<sObject>{
    public final String query;

    public OpportunityBatch (String q) {
        query = q; 
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, Opportunity[] scope){ 
        if(scope != null && !scope.isEmpty()) {
            List<Opportunity> opps = OpportunityUtility.expectedTitleDateGreaterThanThreeMonths(scope); 
            if(opps != null && !opps.isEmpty()) {
                database.update(opps,false); 
            }
       } 
    }

    public void finish(Database.BatchableContext BC){
       
   }
}