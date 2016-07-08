global class ClosingBalanceController {
    //
    static List<Closing_Balance__c> closingBalanceList;
    static Integer trustAccountClosingBalanceCount = 0;
    static Integer creditorLedgerClosingBalanceCount = 0;
    static Integer opportunityClosingBalanceCount = 0;
    
    static final Set<Id> recordTypes;
    static final Map<String, Id> reverseRecordTypes;
    static {
        recordTypes = new Set<Id>();
        reverseRecordTypes = new Map<String, Id>();
        for(RecordType rt : [SELECT Id, Name 
                             FROM Recordtype 
                             WHERE SobjectType='Receipt__c' AND Name IN ('Payment','Receipt','Reversal','Journal','Refund')]){
            recordTypes.add(rt.Id);
            reverseRecordTypes.put(rt.Name, rt.Id);
        }
    } 
    
    webservice static String createClosingBalance(Id trustAccountId, Date closingBalanceDate, boolean isLedgerBalanceForPastMonths) {
        Datetime cbDateTime = (closingBalanceDate != null) ? Datetime.newInstance(closingBalanceDate.year(), closingBalanceDate.month(), closingBalanceDate.day()) : null;
        closingBalanceList = new List<Closing_Balance__c>();
        
        Trust_Account__c trustAccount = [SELECT Id, TA_Code__c, Ledger_Balance__c, Closing_Balance_Date__c, Receipts_This_Month__c, Payments_This_Month__c 
                                         FROM Trust_Account__c WHERE Id = :trustAccountId];
        
        closingBalanceList.add(getTrustAccountClosingBalance(trustAccount, cbDateTime));
        closingBalanceList.addAll(getCreditorLedgerClosingBalance(trustAccount, cbDateTime));
        closingBalanceList.addAll(getOpportunityClosingBalance(trustAccount, cbDateTime, isLedgerBalanceForPastMonths));
        
        try {
            if (!closingBalanceList.isEmpty()) {
                upsert closingBalanceList;  
                Integer total = trustAccountClosingBalanceCount + creditorLedgerClosingBalanceCount + opportunityClosingBalanceCount;
                
                trustAccount.Closing_Balance_Date__c = cbDateTime.date();
                
                forceCalculateTotalReceiptsThisMonth(trustAccount);
                forceCalculateTotalPaymentsThisMonth(trustAccount);
                update trustAccount;
                
                String returnStr = '' + total + ' Closing Balance records have been created:\n\n' 
                                + trustAccountClosingBalanceCount + ' Trust Account Closing Balance Record\n'
                                + creditorLedgerClosingBalanceCount + ' Creditor Ledger Closing Balance Record(s)\n'
                                + opportunityClosingBalanceCount + ' Opportunity Closing Balance Record(s)\n\n';
                                //+ 'Click OK to view a report of Closing Balance records created.';
                return returnStr;
            }
            return 'No Closing Balance Records were generated nor updated.';
        } catch (Exception e) {
            System.debug('Error when creating closing balance for Trust Account: ' + e.getMessage());
            return e.getMessage();
        }
    }
    
    private static Closing_Balance__c getTrustAccountClosingBalance(Trust_Account__c trustAccount, Datetime cbDateTime) {
        Closing_Balance__c balance;
        if (trustAccount != null && cbDateTime != null) {
            String closingBalanceName;
            try {
                closingBalanceName = 'CB ' + cbDateTime.format('MM-YYYY') + ' - ' + trustAccount.TA_Code__c;
                balance = [SELECT Id, Name, Trust_Account_Ledger__c, Date__c 
                           FROM Closing_Balance__c 
                           WHERE Trust_Account_Ledger__c = :trustAccount.Id AND Date__c = :cbDateTime.date() 
                           AND Name = :closingBalanceName LIMIT 1];    
            } catch (QueryException e) {
                balance = new Closing_Balance__c();
            }
            balance.Name = closingBalanceName;
            balance.Closing_Balance__c = trustAccount.Ledger_Balance__c;
            balance.Date__c = cbDateTime.date();
            balance.Trust_Account_Ledger__c = trustAccount.Id;
            trustAccountClosingBalanceCount++;
        }
        return balance;
    }
    
    private static List<Closing_Balance__c> getCreditorLedgerClosingBalance(Trust_Account__c trustAccount, Datetime cbDateTime) {
        List<Closing_Balance__c> balanceList = new List<Closing_Balance__c>();
        if (trustAccount != null && cbDateTime != null) {
            Date monthStartDate = cbDateTime.date().toStartOfMonth();
            Datetime monthStartDatetime = Datetime.newInstance(monthStartDate.year(), monthStartDate.month(), monthStartDate.day());
            Map<Id, Creditor_Ledger__c> creditorLedgerMap = new Map<Id, Creditor_Ledger__c>([SELECT Id, Name, Trust_Account__c, Ledger_Balance__c, 
                                                                                                (SELECT Id, Name, Date__c, Ledger_Balance__c FROM Transactions__r
                                                                                                 WHERE Date__c >= :monthStartDate AND Date__c <= :cbDateTime.date() ) 
                                                                                             FROM Creditor_Ledger__c WHERE Trust_Account__c = :trustAccount.Id]);
            Map<Id, Closing_Balance__c> closingBalanceForCreditorLedger = new Map<Id, Closing_Balance__c>();
            try {
                for(Closing_Balance__c cb :[SELECT Id, Name, Trust_Account_Ledger__c, Creditor_Ledger__c, Date__c, Closing_Balance__c
                                            FROM Closing_Balance__c 
                                            WHERE Trust_Account_Ledger__c = :trustAccount.Id 
                                                AND Date__c = :cbDateTime.date() 
                                                AND Creditor_Ledger__c IN :creditorLedgerMap.keySet()]) {
                    closingBalanceForCreditorLedger.put(cb.Creditor_Ledger__c, cb);                              
                 }    
            } catch (QueryException e) {
                
            }
        
            for(Id creditorId: creditorLedgerMap.keySet()) {
                Creditor_Ledger__c creditor = creditorLedgerMap.get(creditorId);
                creditor.Ledger_Balance__c = (creditor.Ledger_Balance__c == null) ? 0 : creditor.Ledger_Balance__c;
                if((creditor.Transactions__r != null && !creditor.Transactions__r.isEmpty()) || creditor.Ledger_Balance__c != 0) {
                    
                    /*boolean atLeastOneTxnWithinRange = false;
                    for (Receipt__c r : creditor.Transactions__r) {
                        Datetime receiptDate = Datetime.newInstance(r.Date__c.year(), r.Date__c.month(), r.Date__c.day());
                        if (receiptDate >= monthStartDatetime && receiptDate <= cbDateTime) {
                            atLeastOneTxnWithinRange = true;
                            break;
                        }
                    }*/
                    
                    //if(atLeastOneTxnWithinRange) {
                        Closing_Balance__c balance = (closingBalanceForCreditorLedger.containsKey(creditorId)) ? closingBalanceForCreditorLedger.get(creditorId) : new Closing_Balance__c();
                        String creditorName = (creditor.Name.length() > 55) ? creditor.Name.substring(0, 55) : creditor.Name;
                        balance.Name = 'CB ' + cbDateTime.format('MM-YYYY') + ' - ' + creditorName + ' - ' + trustAccount.TA_Code__c;
                        balance.Closing_Balance__c = creditor.Ledger_Balance__c;
                        balance.Creditor_Ledger__c = creditor.Id;
                        balance.Date__c = cbDateTime.date();
                        balance.Trust_Account_Ledger__c = trustAccount.Id;
                        balanceList.add(balance);
                        creditorLedgerClosingBalanceCount++;
                    //}
                }
            }
        }
        
        return balanceList;
    }
    
    private static List<Closing_Balance__c> getOpportunityClosingBalance(Trust_Account__c trustAccount, Datetime cbDateTime, boolean isLedgerBalanceForPastMonths) {
        List<Closing_Balance__c> balanceList = new List<Closing_Balance__c>();
        if (trustAccount != null && cbDateTime != null) {
            Date monthStartDate = cbDateTime.date().toStartOfMonth();
            Datetime monthStartDatetime = Datetime.newInstance(monthStartDate.year(), monthStartDate.month(), monthStartDate.day());
            
            Set<Id> projectIds = new Set<Id>();
            for (Project__c p : [SELECT Id, Trust_Account__c FROM Project__c WHERE Trust_Account__c = :trustAccount.Id]) {
                projectIds.add(p.Id);    
            }
            
            Set<Id> productIds = new Set<Id>();
            for (Product__c product : [SELECT Id, Project__c FROM Product__C WHERE Project__c IN :projectIds]) {
                productIds.add(product.Id);
            }
            
            /*Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([SELECT Id, Name, Primary_Product__c, Ledger_Balance_Correct__c, 
                                                                            (SELECT Id, Name, Date__c, RecordTypeId, Description__c, Reconciled__c, Positive_Negative_Value__c FROM Transactions__r 
                                                                             )
                                                                           FROM Opportunity 
                                                                           WHERE Ledger_Balance_Correct__c != NULL AND Ledger_Balance_Correct__c != 0 AND Primary_Product__c IN :productIds]);*/
            
            Map<Id, List<Receipt__c>> opportunityToReceipts = new Map<Id, List<Receipt__c>>();
            for (Receipt__c r : [SELECT Id, Name, Audit_Date__c, Date__c, Date_Reconciled__c, RecordTypeId, Description__c, Reconciled__c, Positive_Negative_Value__c, Opportunity__c, Opportunity__r.Name, Opportunity__r.Primary_Product__c, Opportunity__r.Ledger_Balance_Correct__c
             					 FROM Receipt__c 
             					 WHERE Opportunity__r.Primary_Product__c IN :productIds
                                 AND ((Opportunity__r.Ledger_Balance_Correct__c != NULL AND Opportunity__r.Ledger_Balance_Correct__c != 0) 
                                      OR ( Audit_Date__c >= :monthStartDate AND Audit_Date__c <= :cbDateTime.date()/*(RecordTypeId = :ohHelper.recordTypes.get('Receipt') AND Date_Reconciled__c = LAST_MONTH) OR Date__c = LAST_MONTH)*/))]) {
            	if (opportunityToReceipts.get(r.Opportunity__c) != null) {
                	opportunityToReceipts.get(r.Opportunity__c).add(r);                         
                } else {
                    List<Receipt__c> receipts = new List<Receipt__c>();
                    receipts.add(r);
                    opportunityToReceipts.put(r.Opportunity__c, receipts);
                }
            }
            Map<Id, Closing_Balance__c> closingBalanceForOpportunity = new Map<Id, Closing_Balance__c>();
            
            try {
                for(Closing_Balance__c cb :[SELECT Id, Name, Trust_Account_Ledger__c, Opportunity_Ledger__c, Date__c, Closing_Balance__c
                                            FROM Closing_Balance__c 
                                            WHERE Trust_Account_Ledger__c = :trustAccount.Id 
                                                AND Date__c = :cbDateTime.date() 
                                                AND Opportunity_Ledger__c IN :opportunityToReceipts.keyset()]) {
                    closingBalanceForOpportunity.put(cb.Opportunity_Ledger__c, cb);                              
                }    
            } catch (QueryException e) {
                
            }
            
            for(Id oid : opportunityToReceipts.keyset()) {
                //Opportunity o = opportunityToReceipts.get(oId);
                Closing_Balance__c balance = (closingBalanceForOpportunity.containsKey(oId)) ? closingBalanceForOpportunity.get(oId) : new Closing_Balance__c();
                String oName = (opportunityToReceipts.get(oId).get(0).Opportunity__r.Name.length() > 55) ? opportunityToReceipts.get(oId).get(0).Opportunity__r.Name.substring(0, 55) : opportunityToReceipts.get(oId).get(0).Opportunity__r.Name;
                balance.Name = 'CB ' + cbDateTime.format('MM-YYYY') + ' - ' + oName + ' - ' + trustAccount.TA_Code__c;
                balance.Opportunity_Ledger__c = oId;
                balance.Date__c = cbDateTime.date();
                balance.Trust_Account_Ledger__c = trustAccount.Id;
                //if (opportunityToReceipts.get(oId).get(0).Opportunity__r.Ledger_Balance_Correct__c != null && opportunityToReceipts.get(oId).get(0).Opportunity__r.Ledger_Balance_Correct__c != 0) {
                    if (!isLedgerBalanceForPastMonths) {
                        balance.Closing_Balance__c = opportunityToReceipts.get(oId).get(0).Opportunity__r.Ledger_Balance_Correct__c;
                    } else {
                        Decimal closingBalance = 0;//o.Ledger_Balance_Correct__c;
                        for (Receipt__c r: opportunityToReceipts.get(oId)) {
                            if (/*r.Reconciled__c && r.Date__c >= monthStartDate && */r.Audit_Date__c <= cbDateTime.date()) {
                                closingBalance += r.Positive_Negative_Value__c;
                            }
                        }
                        balance.Closing_Balance__c = closingBalance;
                    }
                    balanceList.add(balance);
                    opportunityClosingBalanceCount++;                        
                /*} else if (opportunityToReceipts.get(oId) != null && !opportunityToReceipts.get(oId).isEmpty()) {*/
                    //balance.Closing_Balance__c = (opportunityToReceipts.get(oId).get(0).Opportunity__r.Ledger_Balance_Correct__c == null) ? 0 : opportunityToReceipts.get(oId).get(0).Opportunity__r.Ledger_Balance_Correct__c;
                    
                    /*Decimal closingBalance = 0;
                    for (Receipt__c r: opportunityToReceipts.get(oId)) {
                        if (r.Audit_Date__c <= cbDateTime.date()) {
                            closingBalance += r.Positive_Negative_Value__c;
                        }
                    }
                    balance.Closing_Balance__c = closingBalance;
                    balanceList.add(balance);
                    opportunityClosingBalanceCount++;
                }*/
            }
            
        }
        
        return balanceList;
    }
    
    public static void setMostRecentClosingBalanceAmount(Set<Id> trustAccountsToProcess) {
        
        if (!trustAccountsToProcess.isEmpty()) {
            List<Trust_Account__c> trustAccountsToUpdate = new List<Trust_Account__c>();
            try {
                for (Closing_Balance__c c : [SELECT Id, Date__c, Closing_Balance__c, Trust_Account_Ledger__c, Ledger_Type__c, Opportunity_Ledger__c, Creditor_Ledger__c
                                             FROM Closing_Balance__c 
                                             WHERE Trust_Account_Ledger__c IN :trustAccountsToProcess AND Ledger_Type__c = 'Bank Ledger'
                                             AND Creditor_Ledger__c = NULL AND Opportunity_Ledger__c = NULL
                                             ORDER BY Date__c DESC LIMIT 1]) {
                    trustAccountsToUpdate.add(new Trust_Account__c(id = c.Trust_Account_Ledger__c, Opening_Cashbook_Balance__c = c.Closing_Balance__c));
                }
                /*
                for(Trust_Account__c t : [SELECT Id, Opening_Cashbook_Balance__c, 
                                          (SELECT Id, Date__c, Closing_Balance__c, Trust_Account_Ledger__c
                                           FROM Closing_Balances__r
                                           ORDER BY Date__c DESC LIMIT 1) 
                                          FROM Trust_Account__c WHERE Id IN :trustAccountsToProcess]) { 
                    if (!t.Closing_Balances__r.isEmpty()) {
                        t.Opening_Cashbook_Balance__c = t.Closing_Balances__r.get(0).Closing_Balance__c;  
                        trustAccountsToUpdate.add(t);
                    }
                }*/
            
                if (!trustAccountsToUpdate.isEmpty())
                    update trustAccountsToUpdate;
            } catch (Exception e) {
                
            }
            
        }
        
    }
    
    private static void forceCalculateTotalReceiptsThisMonth(Trust_Account__c t) {
		Map<String, Id> reverseRecordTypeIds = ohHelper.recordTypes;
        
        Date todaysDate = Date.today();
        Date startOfMonth = t.Closing_Balance_Date__c != null ? t.Closing_Balance_Date__c.addDays(1) : todaysDate.toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).toStartOfMonth().addDays(-1);
        
        t.Receipts_This_Month__c = 0;
        
        for (Receipt__c r : [SELECT Id, RecordTypeId, Reconciled__c, Date_Reconciled__c, Amount__c, X3rd_Party_Transaction__c, Date__c, Trust_Account__c, CreatedDate
                             FROM Receipt__c 
                             WHERE (Trust_Account__c = :t.Id AND Reconciled__c = true 
                                    AND RecordTypeId = :reverseRecordTypeIds.get('Receipt') AND X3rd_Party_Transaction__c = false AND 
                                    (CreatedDate = LAST_N_MONTHS:3 OR CreatedDate = THIS_MONTH))
                             	OR (Trust_Account__c = :t.Id AND Reconciled__c = true AND RecordTypeId = :reverseRecordTypeIds.get('Reverse Receipt') AND 
                                    (CreatedDate = LAST_N_MONTHS:2 OR CreatedDate = THIS_MONTH))]) {
            if (r.RecordTypeId == reverseRecordTypeIds.get('Receipt')) {
            	if (r.Date_Reconciled__c >= startOfMonth && r.Date_Reconciled__c <= endOfMonth) {
                	t.Receipts_This_Month__c += r.Amount__c == null ? 0 : r.Amount__c;    
                }
            } else if (r.RecordTypeId == reverseRecordTypeIds.get('Reverse Receipt'))  {
                if (r.Date__c >= startOfMonth && r.Date__c <= endOfMonth) {
                	t.Receipts_This_Month__c -= r.Amount__c == null ? 0 : r.Amount__c;
                }
            }        	                      
        }
    }
    
    private static void forceCalculateTotalPaymentsThisMonth(Trust_Account__c t) {
		Map<String, Id> reverseRecordTypeIds = ohHelper.recordTypes;
        
        Date todaysDate = Date.today();
        Date startOfMonth = t.Closing_Balance_Date__c != null ? t.Closing_Balance_Date__c.addDays(1) : todaysDate.toStartOfMonth();
        Date endOfMonth = startOfMonth.addMonths(1).toStartOfMonth().addDays(-1);
        
        t.Payments_This_Month__c = 0;
        
        for (Receipt__c r : [SELECT Id, Amount__c, RecordTypeId, Date__c, Trust_Account__c, CreatedDate
                             FROM Receipt__c 
                             WHERE (Trust_Account__c = :t.Id AND RecordTypeId = :reverseRecordTypeIds.get('Reverse Payment') AND (CreatedDate = LAST_N_MONTHS:2 OR CreatedDate = THIS_MONTH))  
                                OR (Trust_Account__c = :t.Id AND RecordTypeId = :reverseRecordTypeIds.get('Payment') AND (CreatedDate = LAST_N_MONTHS:2 OR CreatedDate = THIS_MONTH)) ]) {
        	if (r.Date__c >= startOfMonth && r.Date__c <= endOfMonth) { 
            	if (r.RecordTypeId == reverseRecordTypeIds.get('Payment'))
                	t.Payments_This_Month__c += r.Amount__c == null ? 0 : r.Amount__c;
            	else if (r.RecordTypeId == reverseRecordTypeIds.get('Reverse Payment'))
            		t.Payments_This_Month__c -= r.Amount__c == null ? 0 : r.Amount__c;    
            }           
        }
        
    }
    
    
}