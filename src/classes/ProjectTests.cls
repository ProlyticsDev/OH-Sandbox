@isTest
public class ProjectTests {

	@testSetup static void setupRelatedData() {
		TestData.createAccounts(1); 
		TestData.createSuburbs(1); 
	}

	//test that a new project with a negative proximity 
	static testMethod void ProximityCannotBeNegativeTest() { 
		List<Project__c> proj = TestData.createProjects(1); 
		proj[0].Proximity_to_Airport__c = -1; 
		Test.startTest(); 
		try {
			update proj; 
			system.assert(false, 'Proximity fields should not be negative. '); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Proximity fields cannot')); 
		}
		Test.stopTest(); 
	}

	//test a new project with a negative walk score 
	static testMethod void WalkscoreCannotBeNegativeTest() { 
		List<Project__c> proj = TestData.createProjects(1); 
		proj[0].Walk_score__c = -1; 
		Test.startTest(); 
		try {
			update proj; 
			system.assert(false, 'Walk score cannot be negative.'); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Walk score must be greater than zero and less than 100')); 
		}
		Test.stopTest(); 
	}

	//test a new project with a walk score over a hundred  
	static testMethod void WalkscoreCannotBeOverHundredTest() { 
		List<Project__c> proj = TestData.createProjects(1); 
		proj[0].Walk_score__c = 101; 
		Test.startTest(); 
		try {
			update proj; 
			system.assert(false, 'Walk score cannot be over a hundred.'); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Walk score must be greater than zero and less than 100')); 
		}
		Test.stopTest(); 
	}

	//test a new project with a negative star rating 
	static testMethod void StarRatingCannotBeNegativeTest() { 
		List<Project__c> proj = TestData.createProjects(1); 
		proj[0].Star_Rating__c = -1; 
		Test.startTest(); 
		try {
			update proj; 
			system.assert(false, 'Star rating cannot be negative.'); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Star ratings cannot be negative.')); 
		}
		Test.stopTest(); 
	}

	//test a new project with a negative level 
	static testMethod void LevelsCannotBeNegativeTest() { 
		List<Project__c> proj = TestData.createProjects(1); 
		proj[0].Levels__c = -1; 
		Test.startTest(); 
		try {
			update proj; 
			system.assert(false, 'Level cannot be negative.'); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Levels cannot be negative.')); 
		}
		Test.stopTest(); 
	}
}