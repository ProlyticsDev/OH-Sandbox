@isTest
private class chequePreviewControllerTest 
{
	static list<Journal__c> GenerateTestJournals()
	{
		list<Journal__c> listJournals = new list<Journal__c>();
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs (objCurrentUser) 
        {
            RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
            RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
            
            if(objRecordTypeAccount != null)
            {
            	Account objAccount = new Account();
                objAccount.FirstName = 'First Name';
                objAccount.LastName = 'Last Name';
                objAccount.RecordTypeId = objRecordTypeAccount.Id;
                insert objAccount;
                
                Account ohAccuont = new Account();
                ohAccuont.Name = 'Oliver Hume';
                ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
                insert ohAccuont;
                
                Trust_Account__c  objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
                insert objTrustAccount;
            	
            	Bank_Account__c objBankAccount = new Bank_Account__c();
            	objBankAccount.Account__c = objAccount.Id;
            	insert objBankAccount;
            	
            	list<Cheque__c> listCheques = new list<Cheque__c>();
            	
            	for(integer counter = 0; counter < 5; counter++)
            	{
            		Cheque__c objCheque = new Cheque__c();
            		objCheque.Bank_Account__c = objBankAccount.Id;
            		listCheques.add(objCheque);
            	}
            	insert listCheques;
            	
            	for(Integer counter = 0; counter < 5; counter++)
            	{
            		Journal__c objJournal = new Journal__c();
            		objJournal.Cheque_Number__c = listCheques[counter].Id;
            		objJournal.Bank_Account__c = objBankAccount.Id;
            		objJournal.Trust_Account__c = objTrustAccount.Id;
            		objJournal.Amount__c = 123456.99;
            		listJournals.add(objJournal);
            	}
            }
        }
        return listJournals;
	}
	
    static testMethod void CheckInitializeDataWithJournalIds() 
    {
    	list<Journal__c> listJournals = chequePreviewControllerTest.GenerateTestJournals();
    	insert listJournals;
    	
    	string journalIds = '';
    	for(Journal__c objJournal : listJournals)
    	{
    		journalIds += objJournal.Id + ',';
    	}
    	
        chequePreviewController objChequePreviewController = new chequePreviewController();
        objChequePreviewController.journalIds = journalIds;
        system.assertEquals(5, objChequePreviewController.listCustomJournals.size());
    }
    
    static testMethod void CheckInitializeDataWithJournalObject() 
    {
    	list<Journal__c> listJournals = chequePreviewControllerTest.GenerateTestJournals();
    	insert listJournals;
    	
        chequePreviewController objChequePreviewController = new chequePreviewController();
        objChequePreviewController.objJournalParam = listJournals[0];
        system.assertEquals(1, objChequePreviewController.listCustomJournals.size());
    }
    
    //Simple tests for the numberToWord Class
    static testMethod void numberToWordTests(){
    	string less100 = numberToWord.ConvertNN(100);
    	system.assertEquals('ONE HUNDRED', less100);
    	less100 = numberToWord.ConvertNN(66);
    	system.assertEquals('SIXTY SIX', less100);
    	string less1000 = numberToWord.ConvertNNN(999);
    	system.assertEquals('NINE HUNDRED NINETY NINE', less1000);
    	string enString = numberToWord.EnglishNumbers(20);
    	system.assertEquals('TWENTY', enString);
    	enString = numberToWord.EnglishNumbers(333);
    	system.assertEquals('THREE HUNDRED THIRTY THREE', enString);
    	enString = numberToWord.EnglishNumbers(9999);
    	system.assertEquals('NINE THOUSAND, NINE HUNDRED NINETY NINE', enString);
    	
    	
    	
    }
}