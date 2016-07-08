public class SaleLedgerRptGeneratorController {
	public TrustAccountWrapper trustAccount {get; set;}
    public SalesLedgerEntry entry {get; set;}

    static Map<String, Id> reverseRecordTypeIds = new Map<String, Id>();
    static List<Id> recordTypeIds = new List<Id>();
    static {
    	for(RecordType rt : [SELECT Id, Name FROM Recordtype WHERE SobjectType = 'Receipt__c' AND Name IN ('Receipt','Payment', 'Reverse Receipt', 'Reverse Payment', 'Refund','Reversal','Journal')]){
    		reverseRecordTypeIds.put(rt.Name, rt.Id);
            recordTypeIds.add(rt.Id);
		}
    }

    public SaleLedgerRptGeneratorController() {
        trustAccount = new TrustAccountWrapper();
    }

    public PageReference generateSalesLedger() {
        Id oId = ApexPages.currentPage().getParameters().get('id');
    	List<SalesLedgerRecordWrapper> salesLedgerRecords = new List<SalesLedgerRecordWrapper>();
    	//List<SalesLedgerRecordWrapper> salesLedgerRecordsForPayments = new List<SalesLedgerRecordWrapper>();
    	
        //Integer receiptId = 0;
        //Integer paymentId = 0;
        String vendorAddress;
        String opportunityName;
        
        for (Receipt__c r : [SELECT Id
                             , Name
                             , RecordTypeId
                             , Transaction_ID_Reference__c
                             , Audit_Date__c
                             , Payment_Method__c
                             , Description__c
                             , Notes__c
                             , Amount__c
                             , X3rd_Party_Transaction__c
                             , Report_Reference__c
                             , Opportunity__c
                             , Opportunity__r.Name
                             , Date__c
                             , Trust_Account__c
                             , Trust_Account__r.Name
                        	 , Trust_Account__r.Oliver_Hume_Account__c
                         	 , Trust_Account__r.Oliver_Hume_Account__r.Name
                        	 , Trust_Account__r.ABN__c
                        	 , Trust_Account__r.TA_Code__c 
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__c
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.Name
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingStreet
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCity
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingState
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingPostalCode
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCountry
                             FROM Receipt__c 
                             WHERE RecordTypeId IN :recordTypeIds 
                             AND Opportunity__c = :oId
                             AND X3rd_Party_Transaction__c = false
                             ORDER BY Audit_Date__c, Name ASC]) {
            
            //Assumption: Only one trust account will exist
            trustAccount.code = r.Trust_Account__r.TA_Code__c;
            trustAccount.name = r.Trust_Account__r.Name;
            trustAccount.abn = r.Trust_Account__r.ABN__c;
			trustAccount.accountname = r.Trust_Account__r.Oliver_Hume_Account__r.Name;
			opportunityName = r.Opportunity__r.Name;                          
            
            if (r.Opportunity__r.Primary_Product__r.Project__r.Vendor__c != null) {
            	vendorAddress = sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.Name) + ', ' 
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingStreet) + ', '
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCity) + ', '
                 					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingState) + ', '
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingPostalCode) + ', '
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCountry);
            }
                            
            if (r.Opportunity__c != null) {
                if (r.RecordTypeId == reverseRecordTypeIds.get('Receipt')
                 || r.RecordTypeId == reverseRecordTypeIds.get('Reverse Payment')
                 || (r.RecordTypeId == reverseRecordTypeIds.get('Journal') && (r.Description__c == 'Journal into Sales Ledger' || r.Description__c == 'Journal out of Creditor Ledger' || r.Description__c == 'Journal out of OH Creditor Ledger'))) {
                    SalesLedgerRecordWrapper receiptRecord = new SalesLedgerRecordWrapper();
                    //receiptRecord.id = ++receiptId;
                    receiptRecord.typeChar = 'R';
                    receiptRecord.ledgerEntry = r;
                    salesLedgerRecords.add(receiptRecord);
                    
                } else if (r.RecordTypeId == reverseRecordTypeIds.get('Payment') 
                           || r.RecordTypeId == reverseRecordTypeIds.get('Refund')
                           || r.RecordTypeId == reverseRecordTypeIds.get('Reversal')
                           || r.RecordTypeId == reverseRecordTypeIds.get('Journal')
                           || r.RecordTypeId == reverseRecordTypeIds.get('Reverse Receipt')) {
                    SalesLedgerRecordWrapper paymentRecord = new SalesLedgerRecordWrapper();
                    //paymentRecord.id = ++paymentId;
                    paymentRecord.typeChar = 'P';
                    paymentRecord.ledgerEntry = r;
                    //paymentRecord.ledgerEntry = r;
                    salesLedgerRecords.add(paymentRecord);
                    //salesLedgerRecordsForPayments.add(paymentRecord);
                }    
            }
        }
        
        //salesLedgerRecordsForReceipts.sort();
        //salesLedgerRecordsForPayments.sort();
        
        Decimal balance = 0.0;
        for (SalesLedgerRecordWrapper rec : salesLedgerRecords) {
            if (rec.typeChar == 'R')
            	balance += rec.ledgerEntry.Amount__c;
            else if (rec.typeChar == 'P')
                balance -= rec.ledgerEntry.Amount__c;
            rec.balance = balance;
        }
                
        /*Decimal balance = (!salesLedgerRecordsForPayments.isEmpty()) ? salesLedgerRecordsForPayments.get(salesLedgerRecordsForPayments.size() - 1).balance : 0.0;
        for (SalesLedgerRecordWrapper rec : salesLedgerRecordsForPayments) {
        	balance -= rec.ledgerEntry.Amount__c;
            rec.balance = balance;
        }*/
        
        entry = new SalesLedgerEntry();
        entry.opportunityId = oid;
        entry.opportunityName = opportunityName;
        entry.vendorAddress = vendorAddress;
        entry.openingBalance = 0.0;
        entry.salesLedgerRecords = salesLedgerRecords;
        //entry.salesLedgerRecordsForPayments = salesLedgerRecordsForPayments;
        
        return null;
    }
    
    public String sanitize(String strValue) {
        String result = strValue;
        if (strValue == null)
            result = '';
        return result;   
    }
    
    public class TrustAccountWrapper {
        public String code {get; set;}
        public String name {get; set;}
        public String abn {get; set;}
        public String accountname {get; set;}
    }
    
    public class SalesLedgerRecordWrapper /*implements Comparable*/ {
        //public Integer id {get; set;}
        public String typeChar {get; set;}
        public Decimal balance {
            get {
                if (balance != null)
                    return balance;
                return 0.0;
            }
            set;
        }
        public Receipt__c ledgerEntry {get; set;}
        
        /*public Integer compareTo(Object compareTo) {
            SalesLedgerRecordWrapper other = (SalesLedgerRecordWrapper) compareTo;
            if (this.id > other.id)
                return 1;
            else if (this.id == other.id)
                return 0;
            return -1;
		}*/
    }
    
    public class SalesLedgerEntry {
        public Id opportunityId {get; set;}
        public String opportunityName {get; set;}
        public String vendorAddress {get; set;}
        public Decimal openingBalance {get; set;}
        public List<SalesLedgerRecordWrapper> salesLedgerRecords {get; set;}
    	//public List<SalesLedgerRecordWrapper> salesLedgerRecordsForPayments {get; set;}
        
        public Decimal closingBalanceDebit {
            get {
                Decimal value = 0.0;
                if (salesLedgerRecords != null) {
                    for (SalesLedgerRecordWrapper rec: salesLedgerRecords) {
                        if (rec.typeChar == 'P')
                        	value += rec.ledgerEntry.Amount__c;
                    }
                }
                return value;
            }
            private set;
        }
        public Decimal closingBalanceCredit {
            get {
                Decimal value = 0.0;
                if (salesLedgerRecords != null) {
                    for (SalesLedgerRecordWrapper rec: salesLedgerRecords) {
                        if (rec.typeChar == 'R')
                        	value += rec.ledgerEntry.Amount__c;
                    }
                }
                return value;
            }
            private set;
        }
        public Decimal closingBalanceBalance {
            get {
            	return closingBalanceCredit - closingBalanceDebit + openingBalance;
            }
            private set;
        }
        
    }
}