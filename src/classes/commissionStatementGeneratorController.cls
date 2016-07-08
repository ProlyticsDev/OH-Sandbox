public with sharing class commissionStatementGeneratorController
{
	/*
    private List<Account> accounts = null;
	public String startString{get; set;}
	public String endString{get; set;}
    public Boolean showSettings {get; set;}
    public Boolean selectAll {get; set;}

    public Map<Id, Boolean> selectedAccounts {get; set;}

    public Commission__c inputObj {get; set;}

    public commissionStatementGeneratorController(ApexPages.StandardSetController ssc)
    {
        accounts = ssc.GetSelected();
        showSettings = true;

        // Just used for date inputs
        inputObj = new Commission__c();

        selectedAccounts = new Map<Id, Boolean>();
        selectAll = true;

        for(Account a : accounts)
        {
            selectedAccounts.Put(a.Id, true);
        }
    }

    public void ShowGenerator()
    {
        if(inputObj.Effective_Date__c > inputObj.Due_Date__c)
        {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.Error, 'End date can not be before start date.'));
            return;
        }
		startString = inputObj.Due_Date__c.format();
		endString = inputObj.Effective_Date__c.format();
        showSettings = false;
    }

    public void ToggleAll()
    {
        for(Id acctId : selectedAccounts.KeySet())
        {
            selectedAccounts.Put(acctId, selectAll);
        }
    }
    
    public string statementURL{get; set;}
    public void Generate()
    {
        String accountIds = '';

        for(Id acctId : selectedAccounts.KeySet())
        {
            if(selectedAccounts.Get(acctId))
            {
                accountIds += acctId + ';';
            }
        }

        ApexPages.PageReference pr = Page.commissionStatement;
        pr.GetParameters().Put('account', accountIds);
        pr.GetParameters().Put('start', '' + inputObj.Effective_Date__c);
        pr.GetParameters().Put('end', '' + inputObj.Due_Date__c);
        
        //convert the page reference to a string to be used in a javascript open command on the page.
        statementURL = pr.getURL();
    }
    
    @remoteAction
    public static Id saveStatement(String accountId, String startString, String endString){
    	Date startDate = date.parse(startString);
    	Date endDate = date.parse(endString);
    	//get the commission statement page
    	ApexPages.PageReference pdf = Page.commissionStatement;
    	//pass in the correct parameters
        pdf.GetParameters().Put('account', accountId);
        pdf.GetParameters().Put('start', '' + startDate);
        pdf.GetParameters().Put('end', '' + endDate);
    	pdf.SetRedirect(true);
		string staffName = [select Id, Name from Account where Id =: accountId].Name;
		Blob data = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.GetContentAsPDF();
	    String fileName = 'Commission_Statement_'+staffName+'_'+startDate.format();
    	
    	//store the attachment against the account
    	storeAttachment(data, fileName, accountId);
    	
    	return accountId;
    }
    
    
    public static void storeAttachment(Blob data, String fileName, Id parent)
    {
 		Attachment att = new Attachment();
	    att.Body = data;
        att.ContentType = 'application/pdf';
        att.ParentId = parent;
		att.Name = fileName;
        insert att;
    }*/
}