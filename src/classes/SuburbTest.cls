@isTest
public class SuburbTest {

	static testMethod void PostcodeIsNumericTest() {
		List<Suburb__c> sub = TestData.createSuburbs(1); 
		sub[0].Postcode__c = 'tt'; 
		Test.startTest(); 
		try {
			update sub; 
			system.assert(false, 'Postcode must be a positive numeric value.'); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Postcode must be a positive numeric value.')); 
		}
		Test.stopTest(); 
	}

	static testMethod void PostcodeCannotBeNegativeTest() {
		List<Suburb__c> sub = TestData.createSuburbs(1); 
		sub[0].Postcode__c = '-56'; 
		Test.startTest(); 
		try {
			update sub; 
			system.assert(false, 'Verifies that a post code is not negative.'); 
		}
		catch(DmlException dmlEx) {
			system.assert(dmlEx.getMessage().contains('Postcode must be a positive numeric value.')); 
		}
		Test.stopTest(); 
	}
}