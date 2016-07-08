public class TASalesLedgerRptGeneratorController {

    public Trust_Account__c trustAccount {get; set;}
    public String reportMonth {get; set;}
    public String reportYear {get; set;}
    public List<SalesLedgerEntry> ledgerEntrie {get; set;}
	public List<SalesLedgerEntry> ledgerEntrie2 {get; set;}

    
    /*static Map<String, Id> reverseRecordTypeIds = new Map<String, Id>();
    static List<Id> recordTypeIds = new List<Id>();
    static {
    	for(RecordType rt : [SELECT Id, Name FROM Recordtype WHERE SobjectType = 'Receipt__c' AND Name IN ('Receipt','Payment','Refund','Reversal', 'Journal')]){
    		reverseRecordTypeIds.put(rt.Name, rt.Id);
            recordTypeIds.add(rt.Id);
		}
    }*/

    public TASalesLedgerRptGeneratorController() {
        
    }

    public PageReference generateSalesLedger() {
        Id trustAccountId = ApexPages.currentPage().getParameters().get('id');
        
        Integer month = Integer.valueOf(ApexPages.currentPage().getParameters().get('m'));
        Integer year = Integer.valueOf(ApexPages.currentPage().getParameters().get('y'));
        
        this.ledgerEntrie = new List<SalesLedgerEntry>();
        this.ledgerEntrie2 = new List<SalesLedgerEntry>();
        
        Map<Id, String> opportunityNames = new Map<Id, String>();
    	Map<Id, String> opportunityToVendorAddress = new Map<Id, String>();
    
    	Map<Id, List<SalesLedgerRecordWrapper>> salesLedgerRecordsForReceipts = new Map<Id, List<SalesLedgerRecordWrapper>>();
    	Map<Id, List<SalesLedgerRecordWrapper>> salesLedgerRecordsForPayments = new Map<Id, List<SalesLedgerRecordWrapper>>();
    	Map<Id, Closing_Balance__c> opportunityToOpeningBalance = new Map<Id, Closing_Balance__c>();
        
        Date reportStartingDate = Date.newInstance(year, month+1, 1).addDays(-1).toStartOfMonth();
		Date reportEndingDate = Date.newInstance(year, month+1, 1).addDays(-1);
        
        Datetime dt = Datetime.newInstance(reportStartingDate.year(), reportStartingDate.month(), reportStartingDate.day());
        reportMonth = dt.format('MMMMM');
        reportYear = dt.format('YYYY');
        
        trustAccount = [SELECT Id, Name, Oliver_Hume_Account__c, Oliver_Hume_Account__r.Name, ABN__c, TA_Code__c FROM Trust_Account__c WHERE Id = :trustAccountId];
        
        Integer receiptId = 0;
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
                             , Report_Reference__c
                             , Opportunity__c
                             , Opportunity__r.Name
                             , Date__c
                             , Trust_Account__c
                             , Date_Reconciled__c
                             , Reconciled__c
                             , X3rd_Party_Transaction__c
                             , Transaction_ID__c
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__c
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.Name
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingStreet
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCity
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingState
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingPostalCode
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCountry
                             FROM Receipt__c 
                             WHERE RecordTypeId IN :ohHelper.recordTypeIds.keySet() 
                             AND Audit_Date__c >= :reportStartingDate AND Audit_Date__c <= :reportEndingDate
                             AND Trust_Account__c = :trustAccount.Id
                             AND X3rd_Party_Transaction__c = false
                             //AND Reconciled__c = true
                             //AND Date_Reconciled__c != null
                             /*ORDER BY Audit_Date__c, Transaction_ID_Reference__c ASC*/]) {
            opportunityNames.put(r.Opportunity__c, r.Opportunity__r.Name);
                                 
            if (r.Opportunity__r.Primary_Product__r.Project__r.Vendor__c != null) {
            	String vendorAddress = sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.Name) + ', ' 
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingStreet) + ', '
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingCity) + ', '
                 					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingState) + ', '
                					 + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.BillingPostalCode);
                opportunityToVendorAddress.put(r.Opportunity__c, vendorAddress);
            }
                            
            if (r.Opportunity__c != null) {
                if ((r.RecordTypeId == ohHelper.recordTypes.get('Receipt')&& r.Reconciled__c == true && r.Date_Reconciled__c != null)
                 || (r.RecordTypeId == ohHelper.recordTypes.get('Reverse Payment') && (r.Description__c == 'Reverse Payment'
                                                                                    || r.Description__c == 'Reverse Refund'
                                                                                    || r.Description__c == 'Reverse Refund - Build'))
                 || (r.RecordTypeId == ohHelper.recordTypes.get('Journal') && (r.Description__c == 'Journal out of Creditor Ledger' 
                                                                            || r.Description__c == 'Journal out of Creditor Ledger - Build'
                                                                            || r.Description__c == 'Journal out of OH Creditor Ledger'
                             											    || r.Description__c == 'Journal into Sales Ledger'
                                                                            || r.Description__c == 'Journal into Sales Ledger - Build'))) {
                    List<SalesLedgerRecordWrapper> receiptSalesLedgerEntryList;
                    receiptSalesLedgerEntryList = (salesLedgerRecordsForReceipts.containsKey(r.Opportunity__c)) ? salesLedgerRecordsForReceipts.get(r.Opportunity__c) : new List<SalesLedgerRecordWrapper>(); 
                    salesLedgerRecordsForReceipts.put(r.Opportunity__c, receiptSalesLedgerEntryList);
                    
                    SalesLedgerRecordWrapper receiptRecord = new SalesLedgerRecordWrapper();
                    receiptRecord.typeChar = 'R';
                    receiptRecord.id = ++receiptId;
                    receiptRecord.ledgerEntry = r;
                    receiptSalesLedgerEntryList.add(receiptRecord);
                    
                } else if ((r.RecordTypeId == ohHelper.recordTypes.get('Payment') && (r.Description__c == 'Settlement Funds'
                                                                                   || r.Description__c == 'Miscellaneous Payment'
                                                                                   || r.Description__c == 'Refund Option Fee'
                                                                                   || r.Description__c == 'Refund Cancellation'
                                                                                   || r.Description__c == 'Refund Excess Deposit'
                                                                                   || r.Description__c == 'Refund Cancellation - Build'
                                                                                   || r.Description__c == 'Refund Excess Deposit - Build'))
                        || r.RecordTypeId == ohHelper.recordTypes.get('Reverse Receipt')
                        || (r.RecordTypeId == ohHelper.recordTypes.get('Journal') && (r.Description__c == 'Journal to Creditor Ledger' 
                                                                                   || r.Description__c == 'Journal to Creditor Ledger - Build'
                                                                                   || r.Description__c == 'Journal out of Sales Ledger'
                                                                                   || r.Description__c == 'Journal out of Sales Ledger - Build'
                                                                                   || r.Description__c == 'Journal to OH Creditor Ledger'))) {
                    List<SalesLedgerRecordWrapper> paymentSalesLedgerEntryList;
                    paymentSalesLedgerEntryList = (salesLedgerRecordsForPayments.containsKey(r.Opportunity__c)) ? salesLedgerRecordsForPayments.get(r.Opportunity__c) : new List<SalesLedgerRecordWrapper>(); 
                    salesLedgerRecordsForPayments.put(r.Opportunity__c, paymentSalesLedgerEntryList);
                    
                    SalesLedgerRecordWrapper paymentRecord = new SalesLedgerRecordWrapper();
                    paymentRecord.typeChar = 'P';
                    paymentRecord.id = ++paymentId;
                    paymentRecord.ledgerEntry = r;
                    paymentSalesLedgerEntryList.add(paymentRecord);
                }    
            }
        }
        
        try {
            Date openingBalanceDate = reportStartingDate.addDays(-1);
            for (Closing_Balance__c cb : [SELECT Id
                                          , Closing_Balance__c, Date__c
                                          , Ledger_Type__c
                                          , Trust_Account_Ledger__c
                                          , Opportunity_Ledger__c
                                          , Opportunity_Ledger__r.Name
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__c
                             			  , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.Name
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingStreet
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingCity
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingState
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingPostalCode
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingCountry
                                          FROM Closing_Balance__c 
                                          WHERE /*Opportunity_Ledger__c IN :salesLedgerRecordsForReceipts.keySet()
                                          AND*/ Date__c = :openingBalanceDate
                                          AND Ledger_Type__c = 'Sales Ledger'
                                          AND Trust_Account_Ledger__c = :trustAccount.Id]) {
                opportunityToOpeningBalance.put(cb.Opportunity_Ledger__c, cb); 
                
                //This is used to identify opportunities which doesn't have transactions but has an opening balance.
                if (!opportunityNames.containsKey(cb.Opportunity_Ledger__c) && cb.Closing_Balance__c > 0) {
                    String vendorAddress = sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.Name) + ', ' 
                					 + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingStreet) + ', '
                					 + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingCity) + ', '
                 					 + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingState) + ', '
                					 + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.BillingPostalCode);
                    
                	SalesLedgerEntry entry = new SalesLedgerEntry();
                    entry.opportunityName = cb.Opportunity_Ledger__r.Name;
                    entry.vendorAddress = vendorAddress;
                    entry.openingBalance = cb.Closing_Balance__c;
                    
                    ledgerEntrie.add(entry);
                } 
            }
        } catch (Exception e) {
            System.debug('##Error retrieving closing balance records.');
        }
        
        for (Id opp : salesLedgerRecordsForReceipts.keySet()) {
            salesLedgerRecordsForReceipts.get(opp).sort();
            Decimal balance = (opportunityToOpeningBalance.get(opp) != null) ? opportunityToOpeningBalance.get(opp).Closing_Balance__c : 0.0;
            for (SalesLedgerRecordWrapper slentry : salesLedgerRecordsForReceipts.get(opp)) {
                balance += slentry.ledgerEntry.Amount__c;
                slentry.balance = balance;
            }
        }
        
        for (Id opp : salesLedgerRecordsForPayments.keySet()) {
            salesLedgerRecordsForPayments.get(opp).sort();
            List<SalesLedgerRecordWrapper> slentries = salesLedgerRecordsForReceipts.get(opp);
            Decimal balance = 0.0;
            if (slentries != null) //slentries becomes null when there are no receipts for the month but has only payments
            	balance = slentries.get(slentries.size() - 1).balance;
            for (SalesLedgerRecordWrapper slentry : salesLedgerRecordsForPayments.get(opp)) {
            	balance -= slentry.ledgerEntry.Amount__c;
                slentry.balance = balance;
            }
        }
        
        for (Id oid : opportunityNames.keySet()) {
            SalesLedgerEntry entry = new SalesLedgerEntry();
            entry.opportunityId = oid;
            entry.opportunityName = opportunityNames.get(oid);
            entry.vendorAddress = opportunityToVendorAddress.get(oid);
            entry.openingBalance = (opportunityToOpeningBalance.get(oid) != null) ? opportunityToOpeningBalance.get(oid).Closing_Balance__c : 0.0;
            entry.salesLedgerRecordsForReceipts = salesLedgerRecordsForReceipts.get(oid);
            entry.salesLedgerRecordsForPayments = salesLedgerRecordsForPayments.get(oid);
            if (ledgerEntrie.size() < 1000)
            	ledgerEntrie.add(entry);
            else 
                ledgerEntrie2.add(entry);
        }

        ledgerEntrie.sort();
        ledgerEntrie2.sort();
        return null;
    }
    
    public String sanitize(String strValue) {
        String result = strValue;
        if (strValue == null)
            result = '';
        return result;   
    }
    
    public class SalesLedgerRecordWrapper implements Comparable {
        public Integer id {get; set;}
        public Decimal balance {get; set;}
        public Receipt__c ledgerEntry {get; set;}
        public String typeChar {get; set;}
        
        public Integer compareTo(Object compareTo) {
            SalesLedgerRecordWrapper other = (SalesLedgerRecordWrapper) compareTo;
            if (this.ledgerEntry != null && other.ledgerEntry != null && this.ledgerEntry.Transaction_ID__c > other.ledgerEntry.Transaction_ID__c)
                return 1;
            else if (this.ledgerEntry != null && other.ledgerEntry != null && this.ledgerEntry.Transaction_ID__c == other.ledgerEntry.Transaction_ID__c)
                return 0;
            return -1;
		}
    }
    
    public class SalesLedgerEntry implements Comparable {
        public Id opportunityId {get; set;}
        public String opportunityName {get; set;}
        public String vendorAddress {get; set;}
        public Decimal openingBalance {get; set;}
        public List<SalesLedgerRecordWrapper> salesLedgerRecordsForReceipts {get; set;}
    	public List<SalesLedgerRecordWrapper> salesLedgerRecordsForPayments {get; set;}
        
        public List<SalesLedgerRecordWrapper> transactions {
            get {
                List<SalesLedgerRecordWrapper> result = new List<SalesLedgerRecordWrapper>();
                if (salesLedgerRecordsForReceipts != null)
                	result.addAll(salesLedgerRecordsForReceipts);
                if (salesLedgerRecordsForPayments != null)
                result.addAll(salesLedgerRecordsForPayments);
                
                result.sort();
                return result;
            }
            set;
        }
        
        public Decimal closingBalanceDebit {
            get {
                Decimal value = 0.0;
                if (salesLedgerRecordsForPayments != null) {
                    for (SalesLedgerRecordWrapper rec: salesLedgerRecordsForPayments) {
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
                if (salesLedgerRecordsForReceipts != null) {
                    for (SalesLedgerRecordWrapper rec: salesLedgerRecordsForReceipts) {
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
        
        public Integer compareTo(Object compareTo) {
            SalesLedgerEntry other = (SalesLedgerEntry) compareTo;
            if (this.opportunityName != null && other.opportunityName != null && this.opportunityName > other.opportunityName)
                return 1;
            else if (this.opportunityName != null && other.opportunityName != null && this.opportunityName == other.opportunityName)
                return 0;
            return -1;
		}
        
    }
    
}