public class TACreditorLedgerRptGeneratorController {

    public Trust_Account__c trustAccount {get; set;}
    public String reportMonth {get; set;}
    public String reportYear {get; set;}
    public List<CreditorLedgerEntry> ledgerEntrie {get; set;}
    
    public Set<Id> recordTypeIds {get; set;}
    //public List<Id> recordTypeIds {get; set;}
    
    public PageReference generateCreditorLedger() {
        Id trustAccountId = ApexPages.currentPage().getParameters().get('id');
        
        Integer month = Integer.valueOf(ApexPages.currentPage().getParameters().get('m'));
        Integer year = Integer.valueOf(ApexPages.currentPage().getParameters().get('y'));
     
        this.ledgerEntrie = new List<CreditorLedgerEntry>();
        
        this.recordTypeIds = new Set<Id>();
        recordTypeIds.add(ohHelper.recordTypes.get('Journal'));
        recordTypeIds.add(ohHelper.recordTypes.get('Payment'));
        recordTypeIds.add(ohHelper.recordTypes.get('Reverse Payment'));
        //this.recordTypeIds = new List<Id>();
        
        
        Map<Id, String> creditorLedgerNames = new Map<Id, String>();
        
        //Map<Id, List<CreditorLedgerRecordWrapper>> creditorLedgerRecordsForJournals = new Map<Id, List<CreditorLedgerRecordWrapper>>();
    	//Map<Id, List<CreditorLedgerRecordWrapper>> creditorLedgerRecordsForPayments = new Map<Id, List<CreditorLedgerRecordWrapper>>();
    	Map<Id, List<CreditorLedgerRecordWrapper>> creditorLedgerRecords = new Map<Id, List<CreditorLedgerRecordWrapper>>();
    	Map<Id, Closing_Balance__c> creditorLedgerToOpeningBalance = new Map<Id, Closing_Balance__c>();
        
        Date reportStartingDate = Date.newInstance(year, month+1, 1).addDays(-1).toStartOfMonth();
		Date reportEndingDate = Date.newInstance(year, month+1, 1).addDays(-1);
        
        Datetime dt = Datetime.newInstance(reportStartingDate.year(), reportStartingDate.month(), reportStartingDate.day());
        reportMonth = dt.format('MMMMM');
        reportYear = dt.format('YYYY');
        
        trustAccount = [SELECT Id, Name, Oliver_Hume_Account__c, Oliver_Hume_Account__r.Name, ABN__c, TA_Code__c FROM Trust_Account__c WHERE Id = :trustAccountId];
        
        Integer journalId = 0;
        Integer paymentId = 0;
        
        for (Receipt__c r : [SELECT Id
                                 , Name
                                 , RecordTypeId
                                 , Transaction_ID_Reference__c
                                 , Audit_Date__c
                                 , Payment_Method__c
                                 , Description__c
                                 , Notes__c
                                 , Amount__c
                                 , Creditor__c
                                 , Creditor__r.Name
                                 , Date__c
                                 , Trust_Account__c
                             FROM Receipt__c 
                             WHERE RecordTypeId IN :recordTypeIds 
                             AND Date__c >= :reportStartingDate AND Date__c <= :reportEndingDate
                             AND Trust_Account__c = :trustAccount.Id
                             AND Creditor__c != NULL
                             ORDER BY Creditor__r.Name, Audit_Date__c, Transaction_ID_Reference__c]) {
        	creditorLedgerNames.put(r.Creditor__c, r.Creditor__r.Name);
            
            if (r.Creditor__c != null) {
                /*if (r.RecordTypeId == reverseRecordTypeIds.get('Journal')) {
                    List<CreditorLedgerRecordWrapper> creditorLedgerEntryList;
                    creditorLedgerEntryList = (creditorLedgerRecordsForJournals.containsKey(r.Creditor__c)) ? creditorLedgerRecordsForJournals.get(r.Creditor__c) : new List<CreditorLedgerRecordWrapper>(); 
                    creditorLedgerRecordsForJournals.put(r.Creditor__c, creditorLedgerEntryList);
                    
                    CreditorLedgerRecordWrapper journalRecord = new CreditorLedgerRecordWrapper();
                    journalRecord.id = ++journalId;
                    journalRecord.ledgerEntry = r;
                    creditorLedgerEntryList.add(journalRecord);
                } else if (r.RecordTypeId == reverseRecordTypeIds.get('Payment') && r.Creditor__c != null) {
                    List<CreditorLedgerRecordWrapper> paymentLedgerEntryList;
                    paymentLedgerEntryList = (creditorLedgerRecordsForPayments.containsKey(r.Creditor__c)) ? creditorLedgerRecordsForPayments.get(r.Creditor__c) : new List<CreditorLedgerRecordWrapper>(); 
                    creditorLedgerRecordsForPayments.put(r.Creditor__c, paymentLedgerEntryList);
                    
                    CreditorLedgerRecordWrapper paymentRecord = new CreditorLedgerRecordWrapper();
                    paymentRecord.id = ++paymentId;
                    paymentRecord.ledgerEntry = r;
                    paymentLedgerEntryList.add(paymentRecord);
                }*/
                
                List<CreditorLedgerRecordWrapper> creditorLedgerEntryList;
                creditorLedgerEntryList = (creditorLedgerRecords.containsKey(r.Creditor__c)) ? creditorLedgerRecords.get(r.Creditor__c) : new List<CreditorLedgerRecordWrapper>(); 
                creditorLedgerRecords.put(r.Creditor__c, creditorLedgerEntryList);
                
                CreditorLedgerRecordWrapper record = new CreditorLedgerRecordWrapper();
                //record.id = ++journalId;
                
                record.ledgerEntry = r;
                
                /*if (r.RecordTypeId == ohHelper.recordTypes.get('Journal'))
                	record.strRecordType = 'Journal';
                else if (r.RecordTypeId == ohHelper.recordTypes.get('Payment'))
                    record.strRecordType = 'Payment';
                else if (r.RecordTypeId == ohHelper.recordTypes.get('Reverse Payment'))
                    record.strRecordType = 'Reverse Payment';*/
                record.isDebit = false;
                if ((r.RecordTypeId == ohHelper.recordTypes.get('Reverse Payment')) || (r.RecordTypeId == ohHelper.recordTypes.get('Journal')) 
                         && (r.Description__c == 'Reverse Bulk Payment' 
                             || r.Description__c == 'Journal to Creditor Ledger'
                             || r.Description__c == 'Journal to Creditor Ledger - Build'
                             || r.Description__c == 'Journal to OH Creditor Ledger')) {
                        	record.isDebit = false;
                } else if ((r.RecordTypeId == ohHelper.recordTypes.get('Payment')) || (r.RecordTypeId == ohHelper.recordTypes.get('Journal') 
                         && (r.Description__c == 'Deposit Transfer Payment'
                             || r.Description__c == 'Deposit Transfer Payment - Build'
                             || r.Description__c == 'Full Commission'
                             || r.Description__c == 'Part Commission'
                             || r.Description__c == 'Journal out of Creditor Ledger'
                             || r.Description__c == 'Journal out of Creditor Ledger - Build'
                             || r.Description__c == 'Journal out of OH Creditor Ledger')) ) {
                        	record.isDebit = true;
                } 
                
                creditorLedgerEntryList.add(record);
                
            }
                                 
        }
        
        try {
            Date openingBalanceDate = reportStartingDate.addDays(-1);
            for (Closing_Balance__c cb : [SELECT Id
                                          , Closing_Balance__c
                                          , Date__c
                                          , Ledger_Type__c
                                          , Trust_Account_Ledger__c
                                          , Creditor_Ledger__c
                                          , Creditor_Ledger__r.Name
                                          FROM Closing_Balance__c 
                                          WHERE Date__c = :openingBalanceDate
                                          AND Ledger_Type__c = 'Creditor Ledger'
                                          AND Trust_Account_Ledger__c = :trustAccount.Id
                                          ORDER BY Creditor_Ledger__r.Name]) {
                creditorLedgerToOpeningBalance.put(cb.Creditor_Ledger__c, cb); 
                
                //This is used to identify creditor ledgers which doesn't have transactions but has an opening balance.
                if (!creditorLedgerNames.containsKey(cb.Creditor_Ledger__c) && cb.Closing_Balance__c > 0) {
                	CreditorLedgerEntry entry = new CreditorLedgerEntry();
                    entry.creditorLedgerName = cb.Creditor_Ledger__r.Name;
                    entry.openingBalance = cb.Closing_Balance__c;
                    ledgerEntrie.add(entry);
                } 
            }
        } catch (Exception e) {
            System.debug('##Error retrieving closing balance records.');
        }

        /*for (Id cl : creditorLedgerRecordsForJournals.keySet()) {
            creditorLedgerRecordsForJournals.get(cl).sort();
            Decimal balance = (creditorLedgerToOpeningBalance.get(cl) != null) ? creditorLedgerToOpeningBalance.get(cl).Closing_Balance__c : 0.0;
            for (CreditorLedgerRecordWrapper clentry : creditorLedgerRecordsForJournals.get(cl)) {
                balance += clentry.ledgerEntry.Amount__c;
                clentry.balance = balance;
            }
        }
        
        for (Id cl : creditorLedgerRecordsForPayments.keySet()) {
            creditorLedgerRecordsForPayments.get(cl).sort();
            List<CreditorLedgerRecordWrapper> clentries = creditorLedgerRecordsForJournals.get(cl);
            Decimal balance = (clentries != null) ? clentries.get(clentries.size() - 1).balance : 0.0;
            for (CreditorLedgerRecordWrapper clentry : creditorLedgerRecordsForPayments.get(cl)) {
            	balance -= clentry.ledgerEntry.Amount__c;
                clentry.balance = balance;
            }
        }*/
        
        for (Id cl : creditorLedgerRecords.keySet()) {
            //creditorLedgerRecordsForJournals.get(cl).sort();
            Decimal balance = (creditorLedgerToOpeningBalance.get(cl) != null) ? creditorLedgerToOpeningBalance.get(cl).Closing_Balance__c : 0.0;
            for (CreditorLedgerRecordWrapper clentry : creditorLedgerRecords.get(cl)) {
                if (clentry.ledgerEntry.RecordTypeId == ohHelper.recordTypes.get('Journal')) {
                	balance += clentry.ledgerEntry.Amount__c;
                } else {
                    balance -= clentry.ledgerEntry.Amount__c;
                }
                clentry.balance = balance;
                
            }
        }
        
        
        for (Id clid : creditorLedgerNames.keySet()) {
            CreditorLedgerEntry entry = new CreditorLedgerEntry();
            entry.creditorLedgerId = clid;
            entry.creditorLedgerName = creditorLedgerNames.get(clid);
            entry.openingBalance = (creditorLedgerToOpeningBalance.get(clid) != null) ? creditorLedgerToOpeningBalance.get(clid).Closing_Balance__c : 0.0;
            //entry.creditorLedgerRecordsForJournals = creditorLedgerRecordsForJournals.get(clid);
            //entry.creditorLedgerRecordsForPayments = creditorLedgerRecordsForPayments.get(clid);
            entry.creditorLedgerRecords = creditorLedgerRecords.get(clid);
            entry.creditorLedgerRecords.sort();
            ledgerEntrie.add(entry);
        }
        
        return null;
    }
    
    public class CreditorLedgerRecordWrapper implements Comparable {
        public Integer id {get; set;}
        //public String strRecordType {get; set;}
        public boolean isDebit {get; set;}
        
        public Decimal balance {
            get{
            	if (balance != null)
                    return balance;
                return 0.0;
            } 
            set;
        }
        public Receipt__c ledgerEntry {get; set;}
        
        public Integer compareTo(Object compareTo) {
            CreditorLedgerRecordWrapper other = (CreditorLedgerRecordWrapper) compareTo;
            /*if (this.id > other.id)
                return 1;
            else if (this.id == other.id)
                return 0;
            return -1;*/
            if (this.ledgerEntry.Audit_Date__c > other.ledgerEntry.Audit_Date__c)
                return 1;
            else if (this.ledgerEntry.Audit_Date__c == this.ledgerEntry.Audit_Date__c)
                return 0;
            return -1;
		}
    }
    
    public class CreditorLedgerEntry {
        public Id creditorLedgerId {get; set;}
        public String creditorLedgerName {get; set;}
        public Decimal openingBalance {get; set;}
        //public List<CreditorLedgerRecordWrapper> creditorLedgerRecordsForJournals {get; set;}
    	//public List<CreditorLedgerRecordWrapper> creditorLedgerRecordsForPayments {get; set;}
    	public List<CreditorLedgerRecordWrapper> creditorLedgerRecords {get; set;}
        //public Map<String, Id> reverseRecordTypeIds;
        
        public Decimal closingBalanceDebit {
            get {
                Decimal value = 0.0;
                /*if (creditorLedgerRecordsForPayments != null) {
                    for (CreditorLedgerRecordWrapper rec: creditorLedgerRecordsForPayments) {
                        value += rec.ledgerEntry.Amount__c;
                    }
                }*/
                if (creditorLedgerRecords != null) {
                    /*for (CreditorLedgerRecordWrapper rec: creditorLedgerRecords) {
                        if (rec.ledgerEntry.RecordTypeId == reverseRecordTypeIds.get('Payment') || rec.ledgerEntry.Description__c == 'Journal out of OH Creditor Ledger')
                        	value += rec.ledgerEntry.Amount__c;
                    }*/
                    for (CreditorLedgerRecordWrapper rec: creditorLedgerRecords) {
                        if (rec.isDebit) {
                        	value += rec.ledgerEntry.Amount__c;
                        }
                    }
                }
                return value;
            }
            private set;
        }
        public Decimal closingBalanceCredit {
            get {
                Decimal value = 0.0;
                if (creditorLedgerRecords != null) {
                    /*for (CreditorLedgerRecordWrapper rec: creditorLedgerRecords) {
                        if (rec.ledgerEntry.RecordTypeId == reverseRecordTypeIds.get('Journal') && rec.ledgerEntry.Description__c != 'Journal out of OH Creditor Ledger')
                       		value += rec.ledgerEntry.Amount__c;
                    }*/
                    for (CreditorLedgerRecordWrapper rec: creditorLedgerRecords) {
                        if (!rec.isDebit) {
                        	value += rec.ledgerEntry.Amount__c;
                        }
                    }
                }
                return value;
            }
            private set;
        }
        public Decimal closingBalanceBalance {
            get {
            	return (closingBalanceCredit + openingBalance) - closingBalanceDebit;
            }
            private set;
        }
        
    }
    
}