@isTest
public class CompetitorProjectTriggerHandlerTest {

	@testSetup static void setupRelatedData() {
		TestData.createAccounts(1); 
		TestData.createSuburbs(1); 
	}

	//test method with postcode & name matching the test suburb 
	static testMethod void updateCompetitorProjectSuburbValidTest() {
		Competitor_Project__c compProj = new Competitor_Project__c();
		compProj.name	=	'CompetitorProject';
		compProj.Suburb_Name__c = 'Test0';

		Test.startTest(); 
		insert compProj; 
		Competitor_Project__c theCompProj = [SELECT Suburb_Name__c, Suburb__c 
											 FROM Competitor_Project__c 
											 WHERE Id = :compProj.Id limit 1]; 
		system.debug('The competitor project: ' + theCompProj);
		system.assert(theCompProj.Suburb__c != null); 
		Test.stopTest(); 
	}

	//test with postcode & name not matching any suburbs 
	static testMethod void updateCompetitorProjectSuburbInvalidTest() {
		Competitor_Project__c compProj = new Competitor_Project__c();
		compProj.name	=	'CompetitorProject';
		compProj.Suburb_Name__c = 'Test1';
		Test.startTest(); 
		try { 
			insert compProj; 
			system.assert(false, 'Should throw an error when suburb name & postcode dont match SF'); 
		}
		catch (DmlException ex) {
			system.assert(ex.getMessage().contains('The suburb name does not match a suburb in Salesforce.')); 
		}
		Test.stopTest(); 
	}

	//test without any suburb data 
	static testMethod void updateCompetitorProjectNoSuburbDataTest() {
		Competitor_Project__c compProj = new Competitor_Project__c();
		compProj.name	=	'CompetitorProject';
		compProj.Suburb_Name__c = '';
		Test.startTest(); 
		try { 
			insert compProj; 
			system.assert(false, 'Should throw an error when suburb name & postcode havent been populated'); 
		}
		catch (DmlException ex) {
			system.assert(ex.getMessage().contains('The suburb name has not been populated.')); 
		}
		Test.stopTest(); 
	}
}