/**
* @author JH 
* @date 09/03/2016
* @description Schedule class for the media item batch. 
* Passes in all the media item records with a status of terminated. 
* the batch will then delete these records. 
*/ 
public with sharing class MediaItemSchedule implements Schedulable{
    
    public void execute(SchedulableContext sc) {
    	String query = 'Select Id From Media_Item__c WHERE Status__c = \'New\' AND CreatedDate < LAST_N_DAYS:7 AND CDN_URL__c = \'\''; 
 
    	MediaItemBatch mediaBatch = new MediaItemBatch(query); 
    	Database.executeBatch(mediaBatch); 
	}
}