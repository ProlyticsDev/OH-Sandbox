@isTest
private class TranslationHandlerTest {
	
	@isTest static void checkTranslationIsUniqueSuburbTest() {
		Suburb__c sub = TestData.createSuburbs(1)[0]; 
		Suburb_Translation__c translation = new Suburb_Translation__c(Name='test', Field__c = 'Description', Language__c='Mandarin', 
			Suburb_Description__c='Testing this function', Suburb__c=sub.Id); 
		insert translation; 

		Test.startTest(); 
        List<Suburb_Translation__c> translations = new List<Suburb_Translation__c>(); 
        translations.add(translation); 
        
        TranslationHandler.checkTranslationIsUnique(true, translations); 
        //jh - assert a message has been thrown back to the page 
        ApexPages.Message[] pageMessages = ApexPages.getMessages(); 
        system.assertNotEquals(0, pageMessages.size()); 

		Test.stopTest(); 
	}
	
	@isTest static void checkTranslationIsUniqueProjectTest() {
		Project__c proj = TestData.createProject();
		insert proj; 

		Project_Translation__c translation = new Project_Translation__c(Name='test', Field__c = 'Description', Language__c='Mandarin', 
			Project_Description__c='Testing this function', Project__c=proj.Id); 
		insert translation; 

		Test.startTest(); 
        List<Project_Translation__c> translations = new List<Project_Translation__c>(); 
        translations.add(translation); 
        
        TranslationHandler.checkTranslationIsUnique(false, translations); 
        //jh - assert a message has been thrown back to the page 
        ApexPages.Message[] pageMessages = ApexPages.getMessages(); 
        system.assertNotEquals(0, pageMessages.size()); 

		Test.stopTest(); 
	}

	@isTest static void checkTranslationIsUniqueUpdateProjectTest() {
		Project__c proj = TestData.createProject();
		insert proj; 

		Project_Translation__c translation = new Project_Translation__c(Name='test', Field__c = 'Description', Language__c='Mandarin', 
			Project_Description__c='Testing this function', Project__c=proj.Id); 
		insert translation; 

		Test.startTest(); 
       	Project_Translation__c newTranslation =	translation.clone(); 
       	newTranslation.Field__c = ''; 
       	newTranslation.Project_Description__c = ''; 
       	insert newTranslation; 

       	newTranslation.Field__c = 'Description'; 
       	newTranslation.Language__c = 'Mandarin'; 
       	try {
       		update newTranslation; 
       		system.assert(false, 'Shouldnt update the translation!'); 
       	}
       	catch(Exception ex) {
       		system.assert(true); 
       	}

		Test.stopTest(); 
	}
	
}