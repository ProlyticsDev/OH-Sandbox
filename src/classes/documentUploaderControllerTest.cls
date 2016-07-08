@isTest
private class documentUploaderControllerTest {

    static testMethod void TestConstructor() 
    {
        documentUploaderController objDocumentUploaderController = new documentUploaderController();
        system.assertEquals(false, objDocumentUploaderController.isSaveSuccessful);
    }
    
    static testMethod void TestUploadDocument() 
    {
    	PageReference objPageReference = page.accountMashupVfp;
        test.setCurrentPage(objPageReference);
        
        documentUploaderController objDocumentUploaderController = new documentUploaderController();
        objDocumentUploaderController.objDocument = new Document__c();
        
        boolean isException = false;
        try
        {
        	objDocumentUploaderController.UploadDocument();
        	list<apexpages.Message> listMessages = apexPages.getMessages();
        	for(apexpages.Message objMessage : listMessages)
        	{
        		if(objMessage.getDetail().contains('File: You must enter a value') || 
        			objMessage.getSummary().contains('File: You must enter a value'))
        		{
        			isException = true;
        		}
        	}
        }
        catch(Exception excep) 
        {
        	throw excep;
    	}
        system.assertEquals(true, isException);
        isException = false;
        
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs (objCurrentUser) 
        {
	        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
	        if(objRecordTypeAccount != null)
            {
            	Project__c objProject = new Project__c();
                objProject.Name = 'Test Project';
                objProject.Sales_Manager__c = objCurrentUser.Id;
                objProject.City__c = 'Test'; 
                objProject.Description__c = 'Sample Description'; 
                objProject.Region__c = 'Melbourne'; 
                objProject.Street_Address__c = '12 Test'; 
                objProject.Zip_Postal_Code__c = 'Victoria';    
                objProject.Status__c = 'Planned';
                insert objProject;
                
            	Account objAccount = new Account();
                objAccount.FirstName = 'First Name';
                objAccount.LastName = 'Last Name';
                objAccount.RecordTypeId = objRecordTypeAccount.Id;
                insert objAccount;
                
                objDocumentUploaderController.objDocument.Expiry_Date__c = date.today();
                objDocumentUploaderController.objDocument.Name = 'Test Document';
                objDocumentUploaderController.objDocument.Project__c = objProject.Id;
                objDocumentUploaderController.documentStaffMemberId = objAccount.Id;
                objDocumentUploaderController.objDocument.Type__c = 'Police Check';
                objDocumentUploaderController.documentName = 'TestTest';
                objDocumentUploaderController.documentValue = blob.valueOf('TestBlob');
                objDocumentUploaderController.UploadDocument();
                
                system.assertEquals(true, objDocumentUploaderController.isSaveSuccessful);
                
                Document__c objDocument = [Select Id From Document__c Where Name = 'Test Document'];
                system.assertNotEquals(null, objDocument);
                
                Attachment objAttachment = [Select Id, ParentId From Attachment Where Name = 'TestTest'];
                system.assertEquals(objDocument.Id, objAttachment.ParentId);
            }
        }
    }
}