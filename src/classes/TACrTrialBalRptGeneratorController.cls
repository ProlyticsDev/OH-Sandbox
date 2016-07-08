public class TACrTrialBalRptGeneratorController {

    public Trust_Account__c trustAccount {get; set;}
    public String reportMonth {get; set;}
    public String reportYear {get; set;}
    
    public List<CreditorsTrialBalanceEntry> balanceList {get; set;}
    public Decimal reportTotalOpening {
        get{
            Decimal result = 0.0;
                for (CreditorsTrialBalanceEntry entry : balanceList) {
                    result += entry.opening;
                }
                return result;
        } 
        private set;
    }
    public Decimal reportTotalCredits {
    	get{
            Decimal result = 0.0;
                for (CreditorsTrialBalanceEntry entry : balanceList) {
                    result += entry.credits;
                }
                return result;
        } 
        private set;
    }
    public Decimal reportTotalDebits {
        get{
            Decimal result = 0.0;
                for (CreditorsTrialBalanceEntry entry : balanceList) {
                    result += entry.debits;
                }
                return result;
        } 
        private set;
    }
    public Decimal reportTotalClosing {
    	get{
            Decimal result = 0.0;
                for (CreditorsTrialBalanceEntry entry : balanceList) {
                    result += entry.closing;
                }
                return result;
        } 
        private set;
    }
    
    /*static Map<String, Id> reverseRecordTypeIds = new Map<String, Id>();
    static List<Id> recordTypeIds = new List<Id>();
    static {
    	for(RecordType rt : [SELECT Id, Name FROM Recordtype WHERE SobjectType = 'Receipt__c' AND Name IN ('Journal','Payment')]){
    		reverseRecordTypeIds.put(rt.Name, rt.Id);
            recordTypeIds.add(rt.Id);
		}
    }*/
    
    public PageReference generateCreditorsTrialBalance() {
        Id trustAccountId = ApexPages.currentPage().getParameters().get('id');
        
        Integer month = Integer.valueOf(ApexPages.currentPage().getParameters().get('m'));
        Integer year = Integer.valueOf(ApexPages.currentPage().getParameters().get('y'));
     
        this.balanceList = new List<CreditorsTrialBalanceEntry>();
        Map<Id, String> creditorLedgerNames = new Map<Id, String>();
        Map<Id, String> creditorLedgerToAccount = new Map<Id, String>();
        Map<Id, List<Receipt__c>> creditorLedgerToReceipts = new Map<Id, List<Receipt__c>>();
        Map<Id, Closing_Balance__c> creditorLedgerToOpeningBalance = new Map<Id, Closing_Balance__c>();
        
        Date reportStartingDate = Date.newInstance(year, month+1, 1).addDays(-1).toStartOfMonth();
		Date reportEndingDate = Date.newInstance(year, month+1, 1).addDays(-1);
        
        Datetime dt = Datetime.newInstance(reportStartingDate.year(), reportStartingDate.month(), reportStartingDate.day());
        reportMonth = dt.format('MMMMM');
        reportYear = dt.format('YYYY');
        
        trustAccount = [SELECT Id, Name, Oliver_Hume_Account__c, Oliver_Hume_Account__r.Name, ABN__c, TA_Code__c FROM Trust_Account__c WHERE Id = :trustAccountId];
        
        for (Receipt__c r : [SELECT Id
                             , Name
                             , RecordTypeId
                             , Audit_Date__c
                             , Amount__c
                             , Creditor__c
                             , Creditor__r.Name
                             , Creditor__r.Account__c
                             , Creditor__r.Account__r.Name
                             , Date__c
                             , Trust_Account__c
                             , Description__c
                             FROM Receipt__c 
                             WHERE /*RecordTypeId IN :recordTypeIds 
                             AND */Creditor__c != null
                             AND Date__c >= :reportStartingDate AND Date__c <= :reportEndingDate
                             AND Trust_Account__c = :trustAccount.Id
                             ORDER BY Audit_Date__c]) {
        	creditorLedgerNames.put(r.Creditor__c, r.Creditor__r.Name);
            creditorLedgerToAccount.put(r.Creditor__c, r.Creditor__r.Account__r.Name);
           
            
            if (creditorLedgerToReceipts.containsKey(r.Creditor__c)) {
                creditorLedgerToReceipts.get(r.Creditor__c).add(r);
            } else {
                List<Receipt__c> receipts = new List<Receipt__c>();
                receipts.add(r);
                creditorLedgerToReceipts.put(r.Creditor__c, receipts);
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
                                          , Creditor_Ledger__r.Account__c
                                          , Creditor_Ledger__r.Account__r.Name
                                          FROM Closing_Balance__c 
                                          WHERE Date__c = :openingBalanceDate
                                          AND Ledger_Type__c = 'Creditor Ledger'
                                          AND Trust_Account_Ledger__c = :trustAccount.Id]) {
                if (cb.Date__c == openingBalanceDate)
                	creditorLedgerToOpeningBalance.put(cb.Creditor_Ledger__c, cb);
                
                //This is used to identify opportunities which doesn't have transactions but has an opening balance.
                if (!creditorLedgerNames.containsKey(cb.Creditor_Ledger__c) && cb.Closing_Balance__c > 0) {
                    creditorLedgerNames.put(cb.Creditor_Ledger__c, cb.Creditor_Ledger__r.Name);
                	creditorLedgerToAccount.put(cb.Creditor_Ledger__c, cb.Creditor_Ledger__r.Account__r.Name);
                } 
            }
        } catch (Exception e) {
            System.debug('##Error retrieving closing balance records.');
        }
        
        if (!creditorLedgerNames.isEmpty()) {
            for (Id cid : creditorLedgerNames.keySet()) {
                CreditorsTrialBalanceEntry ctbentry = new CreditorsTrialBalanceEntry();
                ctbentry.ref = creditorLedgerNames.get(cid);
                ctbentry.account = creditorLedgerToAccount.get(cid);
                ctbentry.opening = (creditorLedgerToOpeningBalance.get(cid) != null) ? creditorLedgerToOpeningBalance.get(cid).Closing_Balance__c : 0.0;
                ctbentry.receipts = creditorLedgerToReceipts.get(cid);
                balanceList.add(ctbentry);
            }
        }
        
        return null;
    }
    
    public class CreditorsTrialBalanceEntry {
        public String ref {get; set;}
        public String account {get; set;}
        public List<Receipt__c> receipts {private get; set;}
        
        public Decimal opening {
        	get{
            	if (opening != null)
                    return opening;
                return 0.0;
            } 
            set;
        }
        public Decimal credits {
            get{
                Decimal result = 0.0;
                if (receipts != null && !receipts.isEmpty()) {
                    for (Receipt__c r : receipts) {
                        if ((r.RecordTypeId == ohHelper.recordTypes.get('Reverse Payment')) || (r.RecordTypeId == ohHelper.recordTypes.get('Journal')) 
                         && (r.Description__c == 'Reverse Bulk Payment' 
                             || r.Description__c == 'Journal to Creditor Ledger'
                             || r.Description__c == 'Journal to Creditor Ledger - Build'
                             || r.Description__c == 'Journal to OH Creditor Ledger')) {
                        	result += r.Amount__c;
                        }
                    }
                }
                return result;
            } 
            set;
        }
        public Decimal debits {
        	get{
                Decimal result = 0.0;
                if (receipts != null && !receipts.isEmpty()) {
                    for (Receipt__c r : receipts) {
                        if ((r.RecordTypeId == ohHelper.recordTypes.get('Payment')) || (r.RecordTypeId == ohHelper.recordTypes.get('Journal') 
                         && (r.Description__c == 'Deposit Transfer Payment'
                             || r.Description__c == 'Deposit Transfer Payment - Build'
                             || r.Description__c == 'Full Commission'
                             || r.Description__c == 'Part Commission'
                             || r.Description__c == 'Journal out of Creditor Ledger'
                             || r.Description__c == 'Journal out of Creditor Ledger - Build'
                             || r.Description__c == 'Journal out of OH Creditor Ledger')) ) {
                        	result += r.Amount__c;
                        }
                    }
                }
                return result;
            } 
            set;
        }
        public Decimal closing {
        	get{
                try {
                	return (opening + credits) - debits;
                } catch (Exception e) {
                	return 0.0;
                }
                return 0.0;
            } 
            set;
        }
    }
}