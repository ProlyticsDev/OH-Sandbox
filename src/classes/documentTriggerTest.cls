@isTest
private class documentTriggerTest 
{
    static testMethod void TestDocumentTaskGeneration() 
    {
    	list<Receipt__c> listReceipts = new list<Receipt__c>();
    	User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
		System.runAs (objCurrentUser)
 		{
        	RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        	Profile objProfile = [Select Id from Profile where name = 'System Administrator' limit 1];
        	if(objRecordTypeAccount != null && objProfile != null)
        	{
        		Account objAccount1 = new Account();
		    	objAccount1.FirstName = 'First Name';
		    	objAccount1.LastName = 'Last Name';
		    	objAccount1.RecordTypeId = objRecordTypeAccount.Id;
		    	insert objAccount1;
		    	
		    	User objUser1 = new User();
	            objUser1.Username= 'test@oliverhume.com.au';
	            objUser1.Email = 'test@oliverhume.com.au';
	            objUser1.Lastname = 'Hume';
	            objUser1.Firstname = 'Oliver';
	            objUser1.Alias = 'oHume';
	            objUser1.CommunityNickname = 'oHume01';
	            objUser1.TimeZoneSidKey = 'GMT';
	            objUser1.LocaleSidKey = 'en_US';
	            objUser1.EmailEncodingKey = 'ISO-8859-1';
	            objUser1.LanguageLocaleKey = 'en_US';
	            objUser1.ProfileId = objProfile.Id;
	            insert objUser1;
		    	
		    	Project__c objProject = new Project__c();
		    	objProject.Name = 'Test Project';
		    	objProject.Sales_Manager__c = objUser1.Id;
		    	objProject.City__c = 'Test'; 
                objProject.Description__c = 'Sample Description'; 
                objProject.Region__c = 'Melbourne'; 
                objProject.Street_Address__c = '12 Test'; 
                objProject.Zip_Postal_Code__c = 'Victoria';    
                objProject.Status__c = 'Planned';
		    	insert objProject;
		    	
		    	Document__c objDocument = new Document__c();
		    	objDocument.Staff_Member__c = objAccount1.Id;
		    	objDocument.Type__c = 'Police Check';
		    	objDocument.Project__c = objProject.Id;
		    	insert objDocument;
		    	
		    	Task objTask = [Select Id From Task Where Subject = 'HR Document Validation'];
		    	system.assertNotEquals(null, objTask);
        	}
 		}
    }
}