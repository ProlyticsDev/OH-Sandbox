@isTest
public class MediaItemCreateControllerTest {

	@testSetup static void setupRelatedData() {
		TestData.createAccounts(1); 
		TestData.createSuburbs(1); 
	}

	//Test initialisation with valid values 
	static testMethod void initialisationPositiveProductTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(1, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(prods); 

		//jh hit the standard controller class methods 
		StandardController stdContClass = new StandardController(setCont); 
		system.assertNotEquals(stdContClass.stdSetController, null); 

		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(prods); 
		mCont.stdSetCont = setCont; 
		Test.stopTest(); 

		system.assert(mCont.recordNames != null);
		system.assert(!mCont.recordNames.isEmpty());  
		system.assertEquals(mCont.recordNames.size(), 1); 
	}

	//Test initialisation with valid values 
	static testMethod void initialisationPositiveProjectTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		//List<Product__c> prods = TestData.createApartmentProducts(1, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(projects); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = false; 
		mCont.isAProject = true; 
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(projects); 
		mCont.stdSetCont = setCont; 
		Test.stopTest(); 

		system.assert(mCont.recordNames != null);
		system.assert(!mCont.recordNames.isEmpty()); 
		system.assertEquals(mCont.recordNames.size(), 1);  
	}

	//test with a blank controller
	static testMethod void initialisationNegativeTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(1, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(prods); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		mCont.stdSetCont = setCont; 

		//check page messages are thrown
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Media Items must be attached')) b = true;
		}
		system.assert(b);
		Test.stopTest(); 
	}

	static testMethod void initialisationTooManyRecordsTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(97, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(prods); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(prods); 
		mCont.stdSetCont = setCont; 

		//check page messages are thrown
		List<Apexpages.Message> msgs = ApexPages.getMessages();
		boolean b = false;
		for(Apexpages.Message msg:msgs){
		    if (msg.getDetail().contains('Cannot take more than 95 records')) {
		    	b = true;
		    } 
		}
		system.assert(b);
		Test.stopTest(); 
	}

	//test the next button successfully creates the new media item  
	static testMethod void nextSingleRecordPositiveTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(1, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(projects); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = false; 
		mCont.isAProject = true;
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(projects); 
		mCont.stdSetCont = setCont; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		mCont.next(); 

		List<Media_Item__c> item = [SELECT Id 
							  FROM Media_Item__c 
							  WHERE Project__c = :projects[0].Id]; 
		system.assertNotEquals(item, null); 
		system.assertEquals(item.size(), 1); 
		Test.stopTest(); 
	}

	static testMethod void stdSetContProjectTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(1, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(prods); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(prods); 
		mCont.stdSetCont = setCont; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		mCont.next(); 

		List<Media_Item__c> item = [SELECT Id 
							  FROM Media_Item__c 
							  WHERE Product__c = :prods[0].Id]; 
		system.assertNotEquals(item, null); 
		system.assertEquals(item.size(), 1); 
		Test.stopTest(); 
	}

	static testMethod void stdSetContCompProjectTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		Competitor_Project__c compProj = new Competitor_Project__c(Name='Comp Project'); 

		//setup the components standard controller 
		ApexPages.StandardController stdController = new ApexPages.StandardController(compProj); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isACompProject = true; 
		mCont.isAProduct = false; 
		mCont.isAProject = false; 

		//jh hit the standard controller class methods 
		StandardController stdContClass = new StandardController(stdController); 
		system.assertNotEquals(stdContClass.stdController, null); 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		mCont.stdCont = stdController; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		mCont.next(); 

		List<Media_Item__c> item = [SELECT Id 
							  FROM Media_Item__c 
							  WHERE Competitor_Project__c = :compProj.Id]; 
		system.assertNotEquals(item, null); 
		system.assertEquals(item.size(), 1); 
		Test.stopTest(); 
	}

	static testMethod void stdContSuburbTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		Suburb__c sub = new Suburb__c(Name='Test Suburb'); 

		//setup the components standard controller 
		ApexPages.StandardController stdController = new ApexPages.StandardController(sub); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isACompProject = false; 
		mCont.isAProduct = false; 
		mCont.isAProject = false; 
		mCont.isASuburb = true; 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		mCont.stdCont = stdController; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		mCont.next(); 

		List<Media_Item__c> item = [SELECT Id 
							  FROM Media_Item__c 
							  WHERE Suburb__c = :sub.Id]; 
		system.assertNotEquals(item, null); 
		system.assertEquals(item.size(), 1); 
		Test.stopTest(); 
	}

	//test that the next button with multiple records 
	static testMethod void nextMultiRecordPositiveTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(3, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(prods); 

		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(prods); 
		mCont.stdSetCont = setCont; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		mCont.next(); 

		system.assertEquals(mCont.recordNames.size(), 3); 
		List<Media_Item__c> item = [SELECT Id 
							  FROM Media_Item__c]; 
		system.assertNotEquals(item, null); 
		system.assertEquals(item.size(), 3); 
		Test.stopTest(); 
	}

	//test that the next button with multiple records 
	static testMethod void nextSingleRecordStandardContPositiveTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(3, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardController standardCont = new ApexPages.StandardController(prods[0]); 

		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		//standardCont.setSelected(prods); 
		mCont.stdCont = standardCont; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		mCont.next(); 

		system.assertEquals(mCont.recordNames.size(), 1); 
		List<Media_Item__c> item = [SELECT Id 
							  FROM Media_Item__c]; 
		system.assertNotEquals(item, null); 
		system.assertEquals(item.size(), 1); 
		Test.stopTest(); 
	}

	//test cancel button redirects to previous url 
	static testMethod void cancelWithStandardControllerTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(3, projects[0].Id); 

		//setup the  standard controller 
		ApexPages.StandardController standardCont = new ApexPages.StandardController(prods[0]); 
		system.assertEquals(mCont.recordNames, null);
		//setCont.setSelected(prods); 
		mCont.stdCont = standardCont; 
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		mCont.mediaItemDetails.Name = 'test'; 
		mCont.mediaItemDetails.Description__c = 'another test'; 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		Test.setCurrentPage(new PageReference('/' + prods[0].Id)); 
		
		String componentUrl = mCont.cancel().getUrl(); 
		system.assertNotEquals(componentUrl, '/' +prods[0].Id); 
		Test.stopTest(); 
	}

	//test cancel button redirects to previous url 
	static testMethod void cancelTest() {
		MediaItemCreateComponentController mCont = new MediaItemCreateComponentController(); 
		List<Project__c> projects = TestData.createProjects(1); 
		List<Product__c> prods = TestData.createApartmentProducts(3, projects[0].Id); 

		//setup the components standard controller 
		ApexPages.StandardSetController setCont = new ApexPages.StandardSetController(prods); 
		system.assertEquals(mCont.recordNames, null);
		mCont.isAProduct = true; 
		mCont.isAProject = false; 
		
		//this would fire the setter in turn firing the initialisation method 
		Test.startTest(); 
		setCont.setSelected(prods); 
		mCont.stdSetCont = setCont; 

		String componentUrl = mCont.cancel().getUrl(); 
		String standardContUrl = setCont.cancel().getUrl(); 

		//a direct comparasion of the pagereferences fails 
		system.assertEquals(componentUrl, standardContUrl); 
	}

	static testMethod void addGalleryItemsPositiveTest(){
		MediaAddGalleryItems galleryItems = new MediaAddGalleryItems(); 
		List<Suburb__c> sub = TestData.createSuburbs(1); 
		ApexPages.currentPage().getParameters().put('id', sub[0].Id); 
		
		PageReference ref = galleryItems.done(); 
		system.assert(ref.getUrl().contains(sub[0].Id)); 
	}
}