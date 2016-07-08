/** 
* @author J.HESKETH  
* @date 09/03/2016
* @description Unit tests the functionality of the media item handler 
* HISTORY
* 06/04/2016 jh - updated unit tests to test suburb relationship 
*/ 
@isTest
public class MediaItemHandlerTest {

	//setup the data to be used in the tests 
	@testSetup static void setupTestData() {
		TestData.createSuburbs(1); 
		TestData.createProjects(1); 

		List<Suburb__c> theSuburbs = [SELECT Id, Name, Postcode__c FROM Suburb__c]; 
		theSuburbs[0].Postcode__c = '10'; 
		theSuburbs[0].Name = 'test0';
		update theSuburbs; 
	}

	// JH CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';


	//jh test that media items can save correctly when there is only one relationship 
	static testMethod void validateMediaItemRelationshipsPostive() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, false)[0]; 
		system.assert(String.isNotBlank(mItem.Id)); 

		Media_Item__c mItem2 = mItem.clone(); 
		Product__c prod = TestData.createApartmentProducts(1, proj.Id)[0]; 
		mItem2.Project__c = null; 
		mItem2.Product__c = prod.Id; 
		insert mItem2; 
		system.assert(String.isNotBlank(mItem.Id));

		Competitor_Project__c compProj = TestData.createCompetitorProjects(1)[0]; 
		Media_Item__c mItem3 = mItem.clone(); 
		mItem3.Project__c = null; 
		mItem3.Competitor_Project__c = compProj.Id; 
		insert mItem3; 
		system.assert(String.isNotBlank(mItem3.Id));  

		//validate the suburb saves correctly 
		Suburb__c suburb = [SELECT Id FROM Suburb__c limit 1]; 
		Media_Item__c mItem4 = mItem.clone(); 
		mItem4.Project__c = null; 
		mItem4.Suburb__c = suburb.Id; 
		insert mItem4; 
		system.assert(String.isNotBlank(mItem4.Id)); 
	}

	//jh test all the possible media item relationship combinations and ensure they all cause an error 
	static testMethod void validateMediaItemRelationshipsNegative() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, false)[0]; 
		system.assert(String.isNotBlank(mItem.Id)); 

		Test.startTest(); 
		Media_Item__c mItem2 = mItem.clone(); 
		Product__c prod = TestData.createApartmentProducts(1, proj.Id)[0]; 
		mItem2.Product__c = prod.Id; 
		mItem2.Competitor_Project__c = TestData.createCompetitorProjects(1)[0].Id; 
		try {
			insert mItem2; 
			system.assert(false); 
		}
		catch(Exception ex) {
			system.assert(true); 
		}

		Media_Item__c mItem3 = mItem.clone(); 
		Suburb__c suburb = [SELECT Id FROM Suburb__c limit 1]; 
		mItem3.Suburb__c = suburb.Id;  
		mItem3.Competitor_Project__c = TestData.createCompetitorProjects(1)[0].Id; 
		try {
			insert mItem3; 
			system.assert(false); 
		}
		catch(Exception ex) {
			system.assert(true); 
		}
		Test.stopTest(); 
	}

	//jh test that media items can save correctly when there is only one relationship 
	static testMethod void validateMediaItemHeroImageProjectPostive() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, true)[0]; 
		system.assert(String.isNotBlank(mItem.Id));
		system.assertEquals(mItem.Hero__c, true);  

		Media_Item__c mItem2 = mItem.clone();  
		try {
			insert mItem2; 
			system.assert(false, 'Cannot have two media items. This should fail.'); 
		}
		catch(Exception ex) {
			system.assert(true); 
		}
		
	}

	static testMethod void validateMediaItemHeroImageProjectNegative() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, false)[0]; 
		system.assert(String.isNotBlank(mItem.Id));
		system.assertEquals(mItem.Hero__c, false);  

		Media_Item__c mItem2 = mItem.clone();  
		mItem2.Hero__c = true; 
		try {
			insert mItem2; 
			system.assert(mItem2.Hero__c); 
		}
		catch(Exception ex) {
			system.assert(false, 'If theres no hero image already the media itme should get inserted!'); 
		}
		
	}
	
	static testMethod void validateMediaItemHeroImageProductPostive() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, true)[0];
		mItem.Project__c = null; 
		mItem.Product__c = TestData.createApartmentProducts(1, proj.Id)[0].Id; 
		update mItem; 

		system.assert(String.isNotBlank(mItem.Id));
		system.assertEquals(mItem.Hero__c, true);  

		Media_Item__c mItem2 = mItem.clone(); 
		try {
			insert mItem2; 
			system.assert(false, 'Cannot have two media items. This should fail.'); 
		}
		catch(Exception ex) {
			system.assert(true); 
		}
		
	}

	static testMethod void validateMediaItemHeroImageCompProjectPostive() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, true)[0];
		mItem.Project__c = null; 
		mItem.Competitor_Project__c = TestData.createCompetitorProjects(1)[0].Id; 
		update mItem; 

		system.assert(String.isNotBlank(mItem.Id));
		system.assertEquals(mItem.Hero__c, true);  

		Media_Item__c mItem2 = mItem.clone(); 
		try {
			insert mItem2; 
			system.assert(false, 'Cannot have two media items. This should fail.'); 
		}
		catch(Exception ex) {
			system.assert(true); 
		}
	} 

	static testMethod void validateMediaItemHeroImageSuburbPostive() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(1, true, proj.Id, true)[0];
		mItem.Project__c = null; 
		mItem.Suburb__c = [SELECT Id FROM Suburb__c limit 1].Id; 
		update mItem; 

		system.assert(String.isNotBlank(mItem.Id));
		system.assertEquals(mItem.Hero__c, true);  

		Media_Item__c mItem2 = mItem.clone(); 
		try {
			insert mItem2; 
			system.assert(false, 'Cannot have two media items. This should fail.'); 
		}
		catch(Exception ex) {
			system.assert(true); 
		}
	} 

	/**
	* @author JH 
	* @date 09/03/2016
	* @description JH - unit tests the schedulable batch class 
	*/ 
	static testMethod void mediaItemScheduledBatchTest() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(2, true, proj.Id, false)[0]; 
		mItem.Status__c = 'Queued For Delete'; 
		update mItem; 

		List<Media_Item__c> mediaItems = [SELECT Id FROM Media_Item__c WHERE IsDeleted = false]; 
		system.assertEquals(mediaItems.size(), 2); 

		List<Media_Item__c> terminatedMediaItems = [SELECT Id FROM Media_Item__c WHERE Status__c = 'Queued For Delete']; 
		system.assertEquals(terminatedMediaItems.size(), 1); 

		//JH - starts the job - batch runs on stopTest() 
		Test.startTest();
	    // Schedule the test job
	    String jobId = System.schedule('Test Job', CRON_EXP, new MediaItemSchedule());
	    // Get the information from the CronTrigger API object
	    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
	    // Verify the expressions are the same
	    System.assertEquals(CRON_EXP, ct.CronExpression); 
	    // Verify the job has not run
	    System.assertEquals(0, ct.TimesTriggered); 
	    // Verify the next time the job will run
	    System.assertEquals('2022-03-15 00:00:00',
	    	String.valueOf(ct.NextFireTime));
	    // Verify the scheduled job hasn't run yet.
	    Test.stopTest();
	}

	//jh - test job when there are terminated records
	static testMethod void mediaItemTerminatedBatchProcessPositiveTest() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(2, true, proj.Id, false)[0]; 
		mItem.Status__c = 'Queued For Delete'; 
		update mItem; 

		List<Media_Item__c> mediaItems = [SELECT Id FROM Media_Item__c WHERE IsDeleted = false]; 
		system.assertEquals(mediaItems.size(), 2); 

		List<Media_Item__c> terminatedMediaItems = [SELECT Id FROM Media_Item__c WHERE Status__c = 'Queued For Delete']; 
		system.assertEquals(terminatedMediaItems.size(), 1); 

		//JH - starts the job - batch runs on stopTest() - this really tests that the delete operation works - it will 
		//delete any results from the query passed into it. 
		Test.startTest();
		String query = 'Select Id From Media_Item__c WHERE Status__c = \'Queued For Delete\''; 
    	MediaItemBatch mediaBatch = new MediaItemBatch(query); 
    	Database.executeBatch(mediaBatch); 
		Test.stopTest(); 

		List<Media_Item__c> mediaItemsRemaining = [SELECT Id FROM Media_Item__c];
		system.assertEquals(mediaItemsRemaining.size(), 1); 
	}

	// jh test job when there aren't any terminated records
	static testMethod void mediaItemTerminatedBatchProcessNegativeTest() {
		Project__c proj = [SELECT Id FROM Project__c limit 1]; 
		Media_Item__c mItem = TestData.createMediaItems(2, true, proj.Id, false)[0]; 

		List<Media_Item__c> mediaItems = [SELECT Id FROM Media_Item__c WHERE IsDeleted = false]; 
		system.assertEquals(mediaItems.size(), 2); 

		List<Media_Item__c> terminatedMediaItems = [SELECT Id FROM Media_Item__c WHERE Status__c = 'Queued For Delete']; 
		system.assertEquals(terminatedMediaItems.size(), 0); 

		//JH - starts the job - batch runs on stopTest() 
		Test.startTest();
		String query = 'Select Id From Media_Item__c WHERE Status__c = \'Queued For Delete\''; 
    	MediaItemBatch mediaBatch = new MediaItemBatch(query); 
    	Database.executeBatch(mediaBatch); 
		Test.stopTest(); 
		//jh - nothing should have been deleted 
		List<Media_Item__c> mediaItemsRemaining = [SELECT Id FROM Media_Item__c];
		system.assertEquals(mediaItemsRemaining.size(), 2); 
	}
}