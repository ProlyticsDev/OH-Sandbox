/**
* @author J.HESKETH
* @date 09/03/2016
* @description Batch class for cleaning up queued for delete media items - required due to 
* constraint that workflow cannot be triggered on delete. Instead media items have a 
* status of Queued For Delete are queried (via schedule) and removed. 
* 
*/ 
public with sharing class MediaItemBatch implements Database.Batchable<sObject>{
    public final String query;

    public MediaItemBatch(String q) {
    	query = q; 
    }

    public Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext BC, Media_Item__c[] scope){ 
        if(scope != null && !scope.isEmpty()) {
       	    MediaItemHandler.deleteMediaItems(scope);
       } 
    }

    public void finish(Database.BatchableContext BC){
       
   }
}