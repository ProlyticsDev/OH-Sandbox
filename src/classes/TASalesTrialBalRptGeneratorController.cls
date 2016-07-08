public class TASalesTrialBalRptGeneratorController {
	
    public Trust_Account__c trustAccount {get; set;}
    public String reportMonth {get; set;}
    public String reportYear {get; set;}
    
    public List<SalesTrialBalanceEntry> saleTrialBalanceEntries {get; set;}
    public List<SalesTrialBalanceEntry> saleTrialBalanceEntries2 {get; set;}
    
    public Decimal reportTotalOpening {
        get{
            Decimal result = 0.0;
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries) {
                result += entry.opening;
            }
            
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries2) {
                result += entry.opening;
            }
            return result;
        } 
        private set;
    }
    public Decimal reportTotalCredits {
    	get{
            Decimal result = 0.0;
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries) {
                result += entry.credits;
            }
            
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries2) {
                result += entry.credits;
            }
            return result;
        } 
        private set;
    }
    public Decimal reportTotalDebits {
        get{
            Decimal result = 0.0;
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries) {
                result += entry.debits;
            }
            
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries2) {
                result += entry.debits;
            }
            return result;
        } 
        private set;
    }
    public Decimal reportTotalClosing {
    	get{
            Decimal result = 0.0;
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries) {
                result += entry.closing;
            }
            
            for (SalesTrialBalanceEntry entry : saleTrialBalanceEntries2) {
                result += entry.closing;
            }
            return result;
        } 
        private set;
    }
    
    /*static Map<String, Id> reverseRecordTypeIds = new Map<String, Id>();
    static List<Id> recordTypeIds = new List<Id>();
    static {
    	for(RecordType rt : [SELECT Id, Name FROM Recordtype WHERE SobjectType = 'Receipt__c' AND Name IN ('Receipt','Payment','Journal')]){
    		reverseRecordTypeIds.put(rt.Name, rt.Id);
            recordTypeIds.add(rt.Id);
		}
    }*/
    
    public PageReference generateSalesTrialBalance() {
        Id trustAccountId = ApexPages.currentPage().getParameters().get('id');
        
        Integer month = Integer.valueOf(ApexPages.currentPage().getParameters().get('m'));
        Integer year = Integer.valueOf(ApexPages.currentPage().getParameters().get('y'));
     
        this.saleTrialBalanceEntries = new List<SalesTrialBalanceEntry>();
        this.saleTrialBalanceEntries2 = new List<SalesTrialBalanceEntry>();
        
        Map<Id, String> opportunityNames = new Map<Id, String>();
        Map<Id, String> opportunityNames2 = new Map<Id, String>();
        
        Map<Id, String> opportunityToProjectAddress = new Map<Id, String>();
        Map<Id, String> opportunityToVendorName = new Map<Id, String>();
        Map<Id, List<Receipt__c>> opportunityToReceipts = new Map<Id, List<Receipt__c>>();
        Map<Id, Closing_Balance__c> opportunityToOpeningBalance = new Map<Id, Closing_Balance__c>();
        
        Date reportStartingDate = Date.newInstance(year, month+1, 1).addDays(-1).toStartOfMonth();
		Date reportEndingDate = Date.newInstance(year, month+1, 1).addDays(-1);
        
        Datetime dt = Datetime.newInstance(reportStartingDate.year(), reportStartingDate.month(), reportStartingDate.day());
        reportMonth = dt.format('MMMMM');
        reportYear = dt.format('YYYY');
        
        trustAccount = [SELECT Id, Name, Oliver_Hume_Account__c, Oliver_Hume_Account__r.Name, ABN__c, TA_Code__c FROM Trust_Account__c WHERE Id = :trustAccountId];
        
        integer counter = 0;
        for (Receipt__c r : [SELECT Id
                             , Name
                             , RecordTypeId
                             , Audit_Date__c
                             , Amount__c
                             , Opportunity__c
                             , Opportunity__r.Name
                             , Date__c
                             , Trust_Account__c
                             , Reconciled__c
                             , Description__c
                             , X3rd_Party_Transaction__c	
                             , Date_Reconciled__c
                             , Opportunity__r.Primary_Product__r.Name
                             , Opportunity__r.Primary_Product__r.Street_Name__c
                             , Opportunity__r.Primary_Product__r.Project__r.Name
                             , Opportunity__r.Primary_Product__r.Project__r.City__c
                             , Opportunity__r.Primary_Product__r.Project__r.Zip_Postal_Code__c
                             , Opportunity__r.Primary_Product__r.Project__r.State_Province__c
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__c
                             , Opportunity__r.Primary_Product__r.Project__r.Vendor__r.Name
                             FROM Receipt__c 
                             WHERE //RecordTypeId IN :recordTypeIds 
                             //AND ((RecordTypeId = :reverseRecordTypeIds.get('Receipt') AND Reconciled__c = true AND X3rd_Party_Transaction__c = false) 
                             //OR (RecordTypeId = :reverseRecordTypeIds.get('Payment') OR RecordTypeId = :reverseRecordTypeIds.get('Journal')) )
                             /*AND*/ Audit_Date__c >= :reportStartingDate AND Audit_Date__c <= :reportEndingDate
                                 AND Trust_Account__c = :trustAccount.Id
                             AND Opportunity__c != null //Ignore Deposit Transfer Payments
                             AND X3rd_Party_Transaction__c = false
                             //AND Reconciled__c = true {Disabled to get un-presented payments}
                             //AND Date_Reconciled__c != null
                             ORDER BY Opportunity__r.Name]) {
                                 
                                 opportunityNames.put(r.Opportunity__c, r.Opportunity__r.Name);
                
                                 if (r.Opportunity__r.Primary_Product__r.Project__r.Vendor__c != null) {
                                     String projectAddress = sanitize(r.Opportunity__r.Primary_Product__r.Name) + ', ' 
                                         + sanitize(r.Opportunity__r.Primary_Product__r.Street_Name__c) + ', '
                                         + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Name) + ', '
                                         + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.City__c) + ', '
                                         + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.Zip_Postal_Code__c) + ', '
                                         + sanitize(r.Opportunity__r.Primary_Product__r.Project__r.State_Province__c);
                                     opportunityToProjectAddress.put(r.Opportunity__c, projectAddress);
                                     opportunityToVendorName.put(r.Opportunity__c, r.Opportunity__r.Primary_Product__r.Project__r.Vendor__r.Name);
                                 }  
                                 
                                 if (opportunityToReceipts.containsKey(r.Opportunity__c)) {
                                     opportunityToReceipts.get(r.Opportunity__c).add(r);
                                 } else {
                                     List<Receipt__c> receipts = new List<Receipt__c>();
                                     receipts.add(r);
                                     opportunityToReceipts.put(r.Opportunity__c, receipts);
                                 }
                             }
        try {
            Date openingBalanceDate = reportStartingDate.addDays(-1);
            for (Closing_Balance__c cb : [SELECT Id
                                          , Closing_Balance__c
                                          , Date__c
                                          , Ledger_Type__c
                                          , Trust_Account_Ledger__c
                                          , Opportunity_Ledger__c
                                          , Opportunity_Ledger__r.Name
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__c
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.Name
                                          , Opportunity_Ledger__r.Primary_Product__r.Name
                                          , Opportunity_Ledger__r.Primary_Product__r.Street_Name__c
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Name
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.City__c
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.Zip_Postal_Code__c
                                          , Opportunity_Ledger__r.Primary_Product__r.Project__r.State_Province__c
                                          FROM Closing_Balance__c 
                                          WHERE Date__c = :openingBalanceDate
                                          AND Ledger_Type__c = 'Sales Ledger'
                                          AND Closing_Balance__c > 0
                                          AND Trust_Account_Ledger__c = :trustAccount.Id
                                          ORDER BY Opportunity_Ledger__r.Name]) {
                                              opportunityToOpeningBalance.put(cb.Opportunity_Ledger__c, cb);
                                              
                                              if (!opportunityNames.containsKey(cb.Opportunity_Ledger__c)) //Avoid doubling up ledger entries
                                                  opportunityNames2.put(cb.Opportunity_Ledger__c, cb.Opportunity_Ledger__r.Name);
                                              
                                              //This is used to identify opportunities which doesn't have transactions but has an opening balance.
                                              String projectAddress = sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Name) + ', ' 
                                                  + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Street_Name__c) + ', '
                                                  + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Name) + ', '
                                                  + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.City__c) + ', '
                                                  + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Zip_Postal_Code__c) + ', '
                                                  + sanitize(cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.State_Province__c);
                                              opportunityToProjectAddress.put(cb.Opportunity_Ledger__c, projectAddress);
                                              opportunityToVendorName.put(cb.Opportunity_Ledger__c, cb.Opportunity_Ledger__r.Primary_Product__r.Project__r.Vendor__r.Name); 
                                          }
            
        } catch (Exception e) {
            System.debug('##Error retrieving closing balance records.');
        }
        
        
        for (Id oid : opportunityNames.keySet()) {
            SalesTrialBalanceEntry stbentry = new SalesTrialBalanceEntry();
            stbentry.ref = opportunityNames.get(oid);
            stbentry.account = opportunityToVendorName.get(oid);
            stbentry.address = opportunityToProjectAddress.get(oid);
            stbentry.opening = (opportunityToOpeningBalance.get(oid) != null) ? opportunityToOpeningBalance.get(oid).Closing_Balance__c : 0.0;
            stbentry.receipts = opportunityToReceipts.get(oid);
            saleTrialBalanceEntries.add(stbentry);
        }
        
        for (Id oid : opportunityNames2.keySet()) {
            SalesTrialBalanceEntry stbentry = new SalesTrialBalanceEntry();
            stbentry.ref = opportunityNames2.get(oid);
            stbentry.account = opportunityToVendorName.get(oid);
            stbentry.address = opportunityToProjectAddress.get(oid);
            stbentry.opening = (opportunityToOpeningBalance.get(oid) != null) ? opportunityToOpeningBalance.get(oid).Closing_Balance__c : 0.0;
            stbentry.receipts = opportunityToReceipts.get(oid);
            saleTrialBalanceEntries2.add(stbentry);
        }
        
        System.debug('WWWWW: ' + saleTrialBalanceEntries.size());
        System.debug('XXXX: ' + saleTrialBalanceEntries2.size());
        
            
        return null;
    }
    
    public String sanitize(String strValue) {
        String result = strValue;
        if (strValue == null)
            result = '';
        return result;   
    }
    
    public class SalesTrialBalanceEntry {
        public String ref {get; set;}
        public String account {get; set;}
        public String address {get; set;}
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
                        if ((r.RecordTypeId == ohHelper.recordTypes.get('Receipt') && r.Reconciled__c == true && r.Date_Reconciled__c != null) 
                         || (r.RecordTypeId == ohHelper.recordTypes.get('Reverse Payment') && (r.Description__c == 'Reverse Payment'
                                                                                            || r.Description__c == 'Reverse Refund'
                                                                                            || r.Description__c == 'Reverse Refund - Build')) 
                         || (r.RecordTypeId == ohHelper.recordTypes.get('Journal') && (r.Description__c == 'Journal out of Creditor Ledger' 
                                                                                    || r.Description__c == 'Journal out of Creditor Ledger - Build'
                                                                                    || r.Description__c == 'Journal out of OH Creditor Ledger'
                             														|| r.Description__c == 'Journal into Sales Ledger'
                                                                                    || r.Description__c == 'Journal into Sales Ledger - Build')) ) {
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
                        if ((r.RecordTypeId == ohHelper.recordTypes.get('Payment') && (r.Description__c == 'Settlement Funds'
                                                                                    || r.Description__c == 'Miscellaneous Payment'
                                                                                    || r.Description__c == 'Refund Option Fee'
                                                                                    || r.Description__c == 'Refund Cancellation'
                                                                                    || r.Description__c == 'Refund Excess Deposit'
                                                                                    || r.Description__c == 'Refund Cancellation - Build'
                                                                                    || r.Description__c == 'Refund Excess Deposit - Build')) 
                         || (r.RecordTypeId == ohHelper.recordTypes.get('Reverse Receipt')) 
                         || (r.RecordTypeId == ohHelper.recordTypes.get('Journal') && (r.Description__c == 'Journal to Creditor Ledger' 
                                                                                    || r.Description__c == 'Journal to Creditor Ledger - Build'
                                                                                    || r.Description__c == 'Journal out of Sales Ledger'
                                                                                    || r.Description__c == 'Journal out of Sales Ledger - Build'
                                                                                    || r.Description__c == 'Journal to OH Creditor Ledger')) ) {
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