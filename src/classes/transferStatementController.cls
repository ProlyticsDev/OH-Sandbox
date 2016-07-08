public with sharing class transferStatementController 
{
    public list<CustomJournal> listCustomJournals {get; private set;}
    public integer index {get;private set;}
    
    public transferStatementController()
    {
        list<string> listJournalIds = this.GetParameters();
        this.CreateJournalList(listJournalIds);
    }
    
    
    private list<string> GetParameters()
    {
        string journalIdsKey = 'journalIds';
        string journalIds = '';
        list<string> listJournalIds = new list<string>();
        
        if(apexPages.currentPage().getParameters().containsKey(journalIdsKey))
        {
            journalIds = apexPages.currentPage().getParameters().get(journalIdsKey);
        }
        listJournalIds = journalIds.split(',');
        return listJournalIds;
    }
    
    private void CreateJournalList(list<string> listJournalIds)
    {
        this.listCustomJournals = new list<CustomJournal>();
        list<Journal__c> listJournals = [
            Select Id, Amount__c, ABA_Reference__c, Name,
                Bank_Account__c, Bank_Account__r.Name, Bank_Account__r.Account__r.PersonMailingCountry,
                    Bank_Account__r.Account__r.PersonMailingPostalCode, Bank_Account__r.Account__r.PersonMailingState,
                    Bank_Account__r.Account__r.PersonMailingCity, Bank_Account__r.Account__r.PersonMailingStreet,
                    Bank_Account__r.Account__r.Name,
                Trust_Account__c, Trust_Account__r.Name,
                (Select Id, Type__c, Product__r.Name, Project__c, Credit_Amount__c, Debit_Amount__c, Ledger_Balance__c From Receipts__r)
            From Journal__c
            Where Id =: listJournalIds];
        
        index = 0;
        for(Journal__c objJournal : listJournals)
        {
            this.listCustomJournals.add(new CustomJournal(objJournal, ++index));
        }
    }
    
    public class CustomJournal
    {
        public Journal__c objJournal {get; private set;}
        public list<CustomReceipt> listCustomReceipts {get; private set;}
        public string solicitorAddress {get; private set;}
        public string todayDate {get; private set;}
        public string todayYear {get; private set;}
        public string todayMonthDay {get; private set;}
        public decimal sumDebits {get; private set;}
        public decimal sumCredits {get; private set;}
        public integer index {get; private set;}
        
        public CustomJournal(Journal__c paramJournal, integer paramIndex)
        {
            this.objJournal = paramJournal;
            this.sumDebits = 0;
            this.sumCredits = 0;
            this.index = paramIndex;
            
            listCustomReceipts = new list<CustomReceipt>();
            for(Receipt__c objReceipt : objJournal.Receipts__r)
            {
                this.sumDebits += ohHelper.NormalizeDecimal(objReceipt.Debit_Amount__c);
                this.sumCredits += ohHelper.NormalizeDecimal(objReceipt.Credit_Amount__c);
                listCustomReceipts.add(new CustomReceipt(objReceipt));
            }
            
            this.solicitorAddress = '';
            this.solicitorAddress += (string.isBlank(objJournal.Bank_Account__r.Account__r.PersonMailingStreet) ? '' : objJournal.Bank_Account__r.Account__r.PersonMailingStreet + '<br />');
            this.solicitorAddress += (string.isBlank(objJournal.Bank_Account__r.Account__r.PersonMailingCity) ? '' : objJournal.Bank_Account__r.Account__r.PersonMailingCity + ', ');
            this.solicitorAddress += (string.isBlank(objJournal.Bank_Account__r.Account__r.PersonMailingState) ? '' : objJournal.Bank_Account__r.Account__r.PersonMailingState + ' ');
            this.solicitorAddress += (string.isBlank(objJournal.Bank_Account__r.Account__r.PersonMailingPostalCode) ? '' : objJournal.Bank_Account__r.Account__r.PersonMailingPostalCode + ' ');
            
            this.todayDate = datetime.now().format('d MMM yyyy');
            this.todayYear = datetime.now().format('yyyy');
            this.todayMonthDay = datetime.now().format('d MMM');
        }
    }
    
    public class CustomReceipt
    {
        public Receipt__c objReceipt {get; private set;}
        public string details {get; private set;}
        public decimal debitAmount {get; private set;}
        public decimal creditAmount {get; private set;}
        public decimal ledgerBalance {get; private set;}
        
        public CustomReceipt(Receipt__c paramReceipt)
        {
            this.objReceipt = paramReceipt;
            this.details = paramReceipt.Type__c + ' - ' + paramReceipt.Product__r.Name + ' ' + paramReceipt.Project__c;
            this.debitAmount = ohHelper.NormalizeDecimal(this.objReceipt.Debit_Amount__c);
            this.creditAmount = ohHelper.NormalizeDecimal(this.objReceipt.Credit_Amount__c);
            this.ledgerBalance = ohHelper.NormalizeDecimal(this.objReceipt.Ledger_Balance__c);
        }
    }
    
}