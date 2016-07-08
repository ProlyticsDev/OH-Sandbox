@isTest
public class MediaItemThumbnailControllerTest {

	//load with valid media items 
	static testMethod void loadMediaItemThumbnailsPositiveTest() {
		TestData.createSuburbs(1); 
		List<Project__c> projs = TestData.createProjects(1); 
		List<Media_Item__c> mediaItems = TestData.createMediaItems(1, true, projs[0].Id, false); 

		MediaItemThumbnailController mc = new MediaItemThumbnailController(); 
		ApexPages.StandardController stdCont = new ApexPages.StandardController(projs[0]); 

		//logic fired with setter of standard controller 
		Test.startTest(); 
		mc.stdCont = stdCont; 
		system.assert(mc.hasMediaItems); 
		system.assert(!mc.thumbnailUrls.isEmpty());
		Test.stopTest(); 
	}

	//same test but with product 
	static testMethod void loadMediaItemThumbnailsProductPositiveTest() {
		TestData.createSuburbs(1); 
		List<Project__c> projs = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(1, projs[0].Id); 
		List<Media_Item__c> mediaItems = TestData.createMediaItems(1, false, prods[0].Id, false); 

		MediaItemThumbnailController mc = new MediaItemThumbnailController(); 
		ApexPages.StandardController stdCont = new ApexPages.StandardController(prods[0]); 

		//logic fired with setter of standard controller 
		Test.startTest(); 
		mc.stdCont = stdCont; 
		system.assert(mc.hasMediaItems); 
		system.assert(!mc.thumbnailUrls.isEmpty());
		//simply will return the std controller - code coverage
		mc.stdCont = stdCont; 
		Test.stopTest(); 
	}

	//load with no media items 
	static testMethod void loadMediaItemThumbnailsNegativeNoMediaItemsTest() {
		TestData.createSuburbs(1); 
		List<Project__c> projs = TestData.createProjects(1); 

		MediaItemThumbnailController mc = new MediaItemThumbnailController(); 
		ApexPages.StandardController stdCont = new ApexPages.StandardController(projs[0]); 

		//logic fired with setter of standard controller 
		Test.startTest(); 
		mc.stdCont = stdCont; 
		system.assert(!mc.hasMediaItems); 
		system.assert(mc.thumbnailUrls.isEmpty()); 
		Test.stopTest(); 
	}
}