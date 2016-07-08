public with sharing class chequePreviewController 
{
	public boolean isPDF {get;set;}
	public list<CustomJournal> listCustomJournals {get;set;}
	public string journalIDs
	{
		get;
		set
		{
			this.journalIds = value;
			this.InitializeData();
		}
	}
	public Journal__c objJournalParam
	{
		get;
		set
		{
			this.objJournalParam = value;
			this.InitializeData();
		}
	}
	
	public integer journalCounter {get;set;}
	
	private User objSalesAdminUser = null;
	private boolean isSalesAdminChecked = false;
	
	public chequePreviewController() {}
	
	//Initializes the data for component's repeater
	private void InitializeData()
	{
		list<Id> listJournalIds = new list<Id>();
		list<Journal__c> listJournals = new list<Journal__c>();
		map<Id, Bank_Account__c> mapBankAccounts = new map<Id, Bank_Account__c>();
		
		this.isPDF = false;
		this.journalCounter = 0;
		
		map<string,string> mapParameters = apexPages.currentPage().getParameters();
		
		system.debug('ChequeDebug:' + journalIDs);
		system.debug('ChequeDebug:' + isPDF);
		
		if(string.isNotBlank(journalIDs))
		{
			listJournalIds = journalIDs.split(',');
			listJournals = ([
			Select Id, Payment_Method__c, Cheque_Text__c, Amount__c, 
				Bank_Account__c, Bank_Account__r.Bank_Name__c, Bank_Account__r.Name, Bank_Account__r.Bank_Account_Number__c,
				Cheque_Number__c, Cheque_Number__r.Cheque_Number__c 
			From Journal__c
			Where Id IN : listJournalIds
			order by Cheque_Number__r.Cheque_Number__c asc]);
		
		}
		else if(objJournalParam != null)
		{
			listJournals.add(objJournalParam);
		}
		
		for(Journal__c objJournal : listJournals)
		{
			mapBankAccounts.put(objJournal.Bank_Account__c, null);
		}
		
		mapBankAccounts = new map<Id, Bank_Account__c>([
			Select Id, 
				Account__r.PersonMailingCountry, Account__r.PersonMailingPostalCode, Account__r.PersonMailingState, 
				Account__r.PersonMailingCity, Account__r.PersonMailingStreet, Account__r.Name, Account__c
			From Bank_Account__c
			Where Id =: mapBankAccounts.keySet()]);
		
		listCustomJournals = new list<CustomJournal>();
		for(Journal__c objJournal : listJournals)
		{
			this.journalCounter++;
			
			CustomJournal objCustomJournal = new CustomJournal();
			objCustomJournal.objJournal = objJournal;
			objCustomJournal.objBankAccount = mapBankAccounts.get(objJournal.Bank_Account__c);
			this.SetChequeText(objCustomJournal);
			this.SetChequeWords(objCustomJournal.objJournal.Amount__c, objCustomJournal);
			objCustomJournal.journalCount = this.journalCounter;
			listCustomJournals.add(objCustomJournal);
		}
	}
	
	//Sets the initial text for the cheque if text is empty
	private void SetChequeText(CustomJournal objCustomJournal)
	{
		string chequeText = '';
		string mailingAddress = '';
		if(string.isNotBlank(objCustomJournal.objJournal.Cheque_Text__c) && objCustomJournal.objJournal.Cheque_Text__c.trim() != '<br>')
		{
			objCustomJournal.objJournal.Cheque_Text__c = ohHelper.NormalizeLineBreakHTML(objCustomJournal.objJournal.Cheque_Text__c);
		}
		else if(objSalesAdminUser != null || isSalesAdminChecked == false)
		{
			if(this.isSalesAdminChecked == false)
			{
				objSalesAdminUser = [Select Id, Name From User Where User.UserRole.Name = 'Sales Administration' limit 1];
				isSalesAdminChecked = true;
			}
			
			chequeText += 'REF: ' + objCustomJournal.objJournal.Cheque_Number__r.Cheque_Number__c + '<br />';
			chequeText += datetime.now().format('d MMMM yyyy') + '<br />';
			chequeText += '<br />';
			//chequeText += objCustomJournal.NameOfAccount + '<br />';
			//mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingStreet) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingStreet + '<br />');
			//mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingCity) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingCity + ', ');
			//mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingState) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingState + ' ');
			//mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingPostalCode) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingPostalCode + ' ');
			chequeText += objCustomJournal.NameOfAccount + '<br />';
			mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingStreet) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingStreet + '<br />');
			mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingCity) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingCity + ', ');
			mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingState) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingState + ' ');
			mailingAddress += (string.isBlank(objCustomJournal.objBankAccount.Account__r.PersonMailingPostalCode) ? '' : objCustomJournal.objBankAccount.Account__r.PersonMailingPostalCode + ' ');
			chequeText += (string.isBlank(mailingAddress) ? '' : mailingAddress + '<br />');
			chequeText += '<br />';
			chequeText += 'Dear Sir/Madam,' + '<br />';
			chequeText += '<br />';
			chequeText += '<br />';
			chequeText += 'Yours faithfully,';
			chequeText += '<br />';
			chequeText += '<br />';
			chequeText += '<br />';
			chequeText += '<br />';
			chequeText += objSalesAdminUser.Name + '<br />';
			chequeText += '<strong>' + 'General Manager' + '</strong><br />';
			chequeText += '<strong>' + 'Sales Administration' + '</strong><br />';
			objCustomJournal.objJournal.Cheque_Text__c = chequeText;
		}
	}
	
	//Gets words for numbers at different denomination positions
	private void SetChequeWords(decimal amount, CustomJournal objCustomJournal)
	{
		amount = ohHelper.NormalizeDecimal(amount);
		list<string> listNumberWordsAscending = new list<string>();
		objCustomJournal.listNumberWords = new list<string>();
		amount = amount.setScale(2, system.Roundingmode.HALF_UP);
		string stringAmount = string.valueOf(amount);
		string stringDecimalValue = (stringAmount.contains('.') ? stringAmount.substring(stringAmount.indexOf('.') + 1, stringAmount.length()) : '0');
		
		stringAmount = stringAmount.substring(0,stringAmount.indexOf('.'));
		string[] individualNumbers = stringAmount.split('');
		individualNumbers.remove(0);
		
		for(integer counter = individualNumbers.size() - 1; counter >= 0; counter--)
		{
			if(individualNumbers.size() - counter == 6)
			{
				listNumberWordsAscending.add('');
				listNumberWordsAscending[5] = individualNumbers[counter] + listNumberWordsAscending[5];
			}
			else if(individualNumbers.size() - counter > 6)
			{
				listNumberWordsAscending[5] = individualNumbers[counter] + listNumberWordsAscending[5];
			}
			else
			{
				listNumberWordsAscending.add(individualNumbers[counter]);
			}
		}
		
		for(integer counter = listNumberWordsAscending.size() - 1; counter < 5; counter++)
		{
			listNumberWordsAscending.add('0');
		}
		
		for(integer counter = listNumberWordsAscending.size() - 1; counter >= 0; counter--)
		{
			objCustomJournal.listNumberWords.add(numberToWord.EnglishNumbers(long.valueOf(listNumberWordsAscending[counter])));
		}
		objCustomJournal.listNumberWords.add(stringDecimalValue);
	}
	
	public class CustomJournal
	{
		public Bank_Account__c objBankAccount 
		{
			get;
			set 
			{
				this.objBankAccount = value;
				if(value != null)
				{
					this.NameOfAccount = (string.isBlank(value.Account__r.Name) ? '' : value.Account__r.Name);
				}
				else
				{
					this.NameOfAccount = 'Account Name not found';
				}
			}
		}
		
		public Journal__c objJournal
		{
			get;
			set
			{
				this.objJournal = value;
				this.FormatedDate = datetime.now().format('d/MM/yyyy');
				if(value != null)
				{
					this.RoundedAmount = '$' + string.valueOf(ohHelper.NormalizeDecimal(value.Amount__c).setScale(2, system.Roundingmode.HALF_UP).format());
				}
			}
		}
		
		public list<string> listNumberWords {get;set;}
		public string FormatedDate {get;set;}
		public string RoundedAmount {get;set;}
		public string NameOfAccount {get;set;}
		public integer journalCount {get;set;}
	}
	
}