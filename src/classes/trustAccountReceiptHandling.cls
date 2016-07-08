public with sharing class trustAccountReceiptHandling
{
	public trustAccountReceiptHandling(ApexPages.StandardSetController ssc)
	{
	}

    @RemoteAction
    public static String sendAndStoreReceipt(String receiptId)
    {
    	Receipt__c r;

		try
		{
			r = [select Id, Name, Opportunity__r.AccountId, Opportunity__r.Account.PersonEmail, Opportunity__r.Account.PersonContactId,
						Trust_Account_Receipt_Number__c, Trust_Account_Receipt_Number__r.TA_Receipt_Number__c
					From Receipt__c where Id = : receiptId];
		}
		catch(Exception e)
		{
			return 'ERROR: Unable to find receipt with id ' + receiptId;
		}

		
	    PageReference pdf = Page.trustAccountReceipt;
	    pdf.GetParameters().put('id', receiptId);
	    pdf.SetRedirect(true);

		Blob data = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.GetContentAsPDF();
	    String fileName = 'Receipt_' + r.Trust_Account_Receipt_Number__r.TA_Receipt_Number__c;
	    String errors = '';

	    // now we have the content, send to the email address specified
	    try
	    {
			if(r.Opportunity__r.Account.PersonEmail != null)
			{
		    	emailDocument(data, fileName, r.Opportunity__r.Account.PersonContactId, r.Opportunity__r.Account.PersonEmail);

		    	String subject = 'Trust Account Receipt Emailed to ' + r.Opportunity__r.Account.PersonEmail + ' for ' + r.Name;

		    	Task t = new Task();
		    	t.Subject = subject;
		    	t.WhatId = r.Id;
		    	t.Status = 'Completed';
		    	insert t;

		    	t = new Task();
		    	t.Subject = subject;
		    	t.WhatId = r.Opportunity__r.AccountId;
		    	t.Status = 'Completed';
		    	insert t;
		    }
	    }
	    catch(Exception e)
	    {
			errors += 'ERROR: Unable to email receipt with id ' + receiptId + ': ' + e.GetMessage() + '\n';
	    }

	    // store the receipt as an attacment to the rut account receipt number record
		storeAttachment(data, fileName + '_Original', r.Trust_Account_Receipt_Number__c);

		// generate the duplicate copy and store that too
		pdf = Page.trustAccountReceipt;
	    pdf.GetParameters().put('id', receiptId);
	    pdf.GetParameters().put('duplicate', '1');
	    pdf.SetRedirect(true);

		data = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.GetContentAsPDF();
		storeAttachment(data, fileName + '_Duplicate', r.Trust_Account_Receipt_Number__c);
	
        return receiptId;
    }

    public static void storeAttachment(Blob data, String fileName, Id parent)
    {
 		Attachment att = new Attachment();
	    att.Body = data;
        att.ContentType = 'application/pdf';
        att.ParentId = parent;
		att.Name = fileName;
        insert att;
    }

    public static void emailDocument(Blob data, String fileName, String targetId, String email)
    {
    	Boolean setDefaults = true;

 		Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.Setbody(data);
		efa.SetContentType('application/pdf');
        efa.SetFileName(fileName + '.pdf');

        //now send it in an email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        String templateName = Company_Information__c.GetInstance().Email_Template_Name__c;

		//mail.SetToAddresses(new String[] {email});
		//only to internal for the moment
		mail.SetToAddresses(new String[] {'sales.admin@oliverhume.com.au'});
        if(templateName != '')
        {
     
        	try
        	{
        		EmailTemplate et = [select Id from EmailTemplate where IsActive = true and Name = : templateName limit 1];
        		mail.templateId = et.Id;
        		mail.targetObjectId = targetId;
        		setDefaults = false;
        	}
        	catch (Exception e)
        	{
        		setDefaults = true;
        	}
        }
        
        if(setDefaults)
        {
			mail.SetSubject('Trust Account Receipt Attached');
        	mail.SetPlainTextBody('Please find attached a receipt for your trust account payment.\n\nIf you have any questions please feel free to contact me on NUMBER HERE.\n\nRegards\n\n');
        }


        //attachments here...
        mail.SetFileAttachments(new Messaging.EmailFileAttachment[]{efa});
        Messaging.SendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}