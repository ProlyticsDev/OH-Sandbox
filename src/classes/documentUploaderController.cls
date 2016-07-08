public with sharing class documentUploaderController
{
	public class applicationException extends Exception {}
	
	public transient blob documentValue {get;set;}
	public string documentName {get;set;}
	public string documentContentType {get;set;}
	public Document__c objDocument {get;set;}
	public Id documentStaffMemberId {get;set;}
	public boolean isSaveSuccessful {get;set;}
	
	public documentUploaderController()
	{
		//Initialize the document object
		objDocument = new Document__c();
		
		//Set the value for after save variable
		isSaveSuccessful = false;
	}
	
	public PageReference UploadDocument()
	{
		try
		{
			//Add an error if no File was selected
			if(string.isBlank(documentName))
			{
				apexPages.addMessage(new apexPages.message(apexPages.Severity.ERROR, 'File: You must enter a value'));
				return null;
			}
			
			//Insert the new Document__c
			objDocument.Staff_Member__c = documentStaffMemberId;
			insert objDocument;
			
			//Add the File as an attachment to the new Document__c
			Attachment objAttachment = new Attachment();
			objAttachment.Body = documentValue;
			objAttachment.Name = documentName;
			objAttachment.ContentType = documentContentType;
			objAttachment.ParentID = objDocument.Id;
			insert objAttachment;
			isSaveSuccessful = true;
		}
		catch(System.DMLException excep)
		{
			isSaveSuccessful = false;
			apexPages.addMessages(excep);
		}
		catch(Exception excep)
		{
			isSaveSuccessful = false;
			apexPages.addMessages(excep);
		}
		return null;
	}
}