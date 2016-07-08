/**
 * Custom AppExchange apps were not compatible with the calculations of these roll up summaries. 
 * HR 29/06/2016 - Fix the 50001 query error by grouping the query
 **/

public class ReceiptRollupCalculationHelper {
    

    public static void calculateDepositReceivedAndBuild(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Received__c, Deposit_Received_Build__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c, RecordTypeId 
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Initial Deposit'
                                                             , 'Further Deposit'
                                                             , 'Balance of Deposit'
                                                             , 'Full Deposit'
                                                             , 'Refund Cancellation'
                                                             , 'Refund Excess Deposit'
                                                             , 'Reverse Deposit'
                                                             , 'Reverse Receipt'
                                                             , 'Journal out of Sales Ledger'
                                                             , 'Journal into Sales Ledger'
                                                             , 'Initial Deposit - Build'
                                                             , 'Further Deposit - Build'
                                                             , 'Balance of Deposit - Build'
                                                             , 'Full Deposit - Build'
                                                             , 'Journal into Sales Ledger - Build'
                                                             , 'Journal out of Sales Ledger - Build'
                                                             , 'Refund Cancellation - Build'
                                                             , 'Refund Excess Deposit - Build'
                                                             , 'Reverse Deposit - Build')
                                          AND (RecordTypeId = :reverseRecordTypeIds.get('Receipt') 
                                            OR RecordTypeId = :reverseRecordTypeIds.get('Reverse Receipt') 
                                            OR RecordTypeId = :reverseRecordTypeIds.get('Payment')
                                            OR RecordTypeId = :reverseRecordTypeIds.get('Journal'))) 
         				 		 FROM Opportunity 
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Received__c = 0;
                    ref.Deposit_Received_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        if (!r.Description__c.contains('- Build'))
                        	ref.Deposit_Received__c += r.Positive_Negative_Value__c; 
                        else
                            ref.Deposit_Received_Build__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Received__c = 0;
                    o.Deposit_Received_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        if (!r.Description__c.contains('- Build'))
                       		o.Deposit_Received__c += r.Positive_Negative_Value__c; 
                        else
                            o.Deposit_Received_Build__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
        		
    		}
        }
    }

    public static void calculateDepositReceivedReconciled(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Received_Reconciled__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c, RecordTypeId 
                                      FROM Transactions__r
                                      WHERE (RecordTypeId = :reverseRecordTypeIds.get('Receipt') AND Reconciled__c = true AND Description__c IN ('Initial Deposit'
                                                             																					, 'Further Deposit'
                                                             																					, 'Balance of Deposit'
                                                             																					, 'Full Deposit') ) OR
                                      (RecordTypeId = :reverseRecordTypeIds.get('Payment') AND Description__c IN ('Refund Cancellation', 'Refund Excess Deposit') ) OR
                                      (RecordTypeId = :reverseRecordTypeIds.get('Reverse Receipt') AND Description__c IN ('Reverse Deposit')) OR
                                      (RecordTypeId = :reverseRecordTypeIds.get('Journal') AND Description__c IN ('Journal out of Sales Ledger', 'Journal into Sales Ledger')))
         				 		 FROM Opportunity 
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Received_Reconciled__c = 0;
                    for (Receipt__c r : o.Transactions__r) {    
                    	ref.Deposit_Received_Reconciled__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Received_Reconciled__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                    	o.Deposit_Received_Reconciled__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }
    
    public static void calculateDepositRefunded(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Refunded__c,
                                     (SELECT Id, Positive_Negative_Value__c, Description__c, RecordTypeId 
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Reverse Refund'
                                                             , 'Refund Cancellation'
                                                             , 'Refund Excess Deposit')
                                      AND (RecordTypeId = :reverseRecordTypeIds.get('Reverse Payment')
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Payment'))) 
         				 		 FROM Opportunity 
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Refunded__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        ref.Deposit_Refunded__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Refunded__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        o.Deposit_Refunded__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }
    
    public static void calculateDepositRefundedBuild(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Refunded_Build__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c, RecordTypeId 
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Reverse Refund - Build'
                                                             , 'Refund Cancellation - Build'
                                                             , 'Refund Excess Deposit - Build')
                                      AND (RecordTypeId = :reverseRecordTypeIds.get('Reverse Payment')
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Payment'))) 
         				 		 FROM Opportunity
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Refunded_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        ref.Deposit_Refunded_Build__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Refunded_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        o.Deposit_Refunded_Build__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }
    
    public static void calculateDepositTransferredAndBuild(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Transferred__c, Deposit_Transferred_Build__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c, RecordTypeId
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Journal to Creditor Ledger'
                                                             , 'Journal out of Creditor Ledger'
                                                             , 'Journal out of Creditor Ledger - Build'
                                                             , 'Journal to Creditor Ledger - Build'
                                                             , 'Journal to OH Creditor Ledger'
                                                             , 'Journal out of OH Creditor Ledger')
                                      AND RecordTypeId = :reverseRecordTypeIds.get('Journal')) 
         				 		 FROM Opportunity 
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Transferred__c = 0;
                    ref.Deposit_Transferred_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        if (r.Description__c == 'Journal to Creditor Ledger' 
                            || r.Description__c == 'Journal out of Creditor Ledger' 
                            || r.Description__c == 'Journal out of Creditor Ledger - Build'
                            || r.Description__c == 'Journal to OH Creditor Ledger'
                            || r.Description__c == 'Journal out of OH Creditor Ledger')
                        	ref.Deposit_Transferred__c += r.Positive_Negative_Value__c; 
                        else
                            ref.Deposit_Transferred_Build__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Transferred__c = 0;
                    o.Deposit_Transferred_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        if (r.Description__c == 'Journal to Creditor Ledger' 
                            || r.Description__c == 'Journal out of Creditor Ledger' 
                            || r.Description__c == 'Journal out of Creditor Ledger - Build'
                            || r.Description__c == 'Journal to OH Creditor Ledger')
                       		o.Deposit_Transferred__c += r.Positive_Negative_Value__c; 
                        else
                            o.Deposit_Transferred_Build__c += r.Positive_Negative_Value__c;
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }
    
    public static void calculateTotalReconciledReceipts(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Total_Reconciled_Receipts__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c, Reconciled__c, RecordTypeId 
                                      FROM Transactions__r 
                                      WHERE  (RecordTypeId = :reverseRecordTypeIds.get('Receipt') AND Reconciled__c = true AND X3rd_Party_Transaction__c = false)
                                      	  OR (RecordTypeId = :reverseRecordTypeIds.get('Reverse Receipt'))
                                          OR (RecordTypeId = :reverseRecordTypeIds.get('Journal') AND Description__c IN ('Journal into Sales Ledger'
                                                                                                                       , 'Journal into Sales Ledger - Build'
                                                                                                                       , 'Journal Out of Creditor Ledger'
                                                                                                                       , 'Journal Out of Creditor Ledger - Build'
                                                                                                                       , 'Journal out of OH Creditor Ledger')))
         				 		 FROM Opportunity 
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Total_Reconciled_Receipts__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        ref.Total_Reconciled_Receipts__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Total_Reconciled_Receipts__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        o.Total_Reconciled_Receipts__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
        
    }
    
    public static void calculateTotalPaymentsAndOptionFee(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Total_Payments__c, Option_Fee_Received__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Amount__c, Description__c, Reconciled__c, RecordTypeId 
                                      FROM Transactions__r 
                                      WHERE ((RecordTypeId = :reverseRecordTypeIds.get('Payment'))
                                          OR (RecordTypeId = :reverseRecordTypeIds.get('Reverse Payment'))
                                          OR (RecordTypeId = :reverseRecordTypeIds.get('Journal') AND Description__c IN ('Journal to Creditor Ledger'
                                                                                                                       , 'Journal to Creditor Ledger - Build'
                                                                                                                       , 'Journal out of Sales Ledger'
                                                                                                                       , 'Journal out of Sales Ledger - Build'
                                                                                                                       , 'Journal to OH Creditor Ledger'))
                                          OR Description__c = 'Option Fee' OR Description__c = 'Refund Option Fee')) 
         				 		 FROM Opportunity 
                                 WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Total_Payments__c = 0;
                    ref.Option_Fee_Received__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        if (r.Description__c != 'Option Fee')
                        	ref.Total_Payments__c += r.Positive_Negative_Value__c; 
                        else
                            ref.Option_Fee_Received__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Total_Payments__c = 0;
                    o.Option_Fee_Received__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        if (r.Description__c != 'Option Fee')
                        	o.Total_Payments__c += r.Positive_Negative_Value__c; 
                        else
                            o.Option_Fee_Received__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
       
    }
    
    public static void calculateTotalPayments(final Map<String, Id> reverseRecordTypeIds, Map<Id, Trust_Account__c> resultMap, final List<Receipt__c> receipts) {
		Map<Id, Trust_Account__c> mapTrustAccounts = new Map<Id, Trust_Account__c>();
        for (Receipt__c objReceipt : receipts) {
        	mapTrustAccounts.put(objReceipt.Trust_Account__c, null);
    	}
        
        if (!mapTrustAccounts.isEmpty()) {
            for(Trust_Account__c ta : [SELECT Id, Total_Payments__c,
                                      	(SELECT Id, Amount__c, RecordTypeId
                                      	 FROM Transactions__r WHERE (RecordTypeId = :reverseRecordTypeIds.get('Reverse Payment')
                                           						  OR RecordTypeId = :reverseRecordTypeIds.get('Payment'))) 
         				 		 	   FROM Trust_Account__c 
                                       WHERE Id IN :mapTrustAccounts.keySet()]) {
            	if (resultMap.containsKey(ta.Id)) {
                    Trust_Account__c ref = resultMap.get(ta.Id);
                    ref.Total_Payments__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        if (r.RecordTypeId == reverseRecordTypeIds.get('Payment'))
                        	ref.Total_Payments__c += r.Amount__c == null ? 0 : r.Amount__c;
                        else if (r.RecordTypeId == reverseRecordTypeIds.get('Reverse Payment'))
                            ref.Total_Payments__c -= r.Amount__c == null ? 0 : r.Amount__c;
                    }
                } else {
                    ta.Total_Payments__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        if (r.RecordTypeId == reverseRecordTypeIds.get('Payment'))
                        	ta.Total_Payments__c += r.Amount__c == null ? 0 : r.Amount__c;
                        else if (r.RecordTypeId == reverseRecordTypeIds.get('Reverse Payment'))
                            ta.Total_Payments__c -= r.Amount__c == null ? 0 : r.Amount__c;
                    }
                    resultMap.put(ta.Id, ta);
                }                         
            }
        }
    }
    
    //Please change ClosingBalanceController::forceCalculateTotalPaymentsThisMonth as well when making changes to this method
    public static void calculateTotalPaymentsThisMonth(final Map<String, Id> reverseRecordTypeIds, Map<Id, Trust_Account__c> resultMap, final List<Receipt__c> receipts) {
		Map<Id, Trust_Account__c> mapTrustAccounts = new Map<Id, Trust_Account__c>();
        Date todaysDate = Date.today();
        Date startOfMonth = todaysDate.toStartOfMonth();
        Date endOfMonth = todaysDate.addMonths(1).toStartOfMonth().addDays(-1);
        
        for (Receipt__c objReceipt : receipts) {
        	mapTrustAccounts.put(objReceipt.Trust_Account__c, null);
    	}
        
        Map<Id, Date> closingBalanceMap = getClosingBalanceMap(mapTrustAccounts);
        
        if (!mapTrustAccounts.isEmpty()) {
            for(Trust_Account__c ta : [SELECT Id, Payments_This_Month__c, Closing_Balance_Date__c, 
                                      	(SELECT Id, Amount__c, RecordTypeId, Date__c, CreatedDate
                                      	 FROM Transactions__r 
                                         WHERE (RecordTypeId = :reverseRecordTypeIds.get('Reverse Payment') AND (CreatedDate = LAST_N_MONTHS:2 OR CreatedDate = THIS_MONTH) )
                                             OR (RecordTypeId = :reverseRecordTypeIds.get('Payment') AND (CreatedDate = LAST_N_MONTHS:2 OR CreatedDate = THIS_MONTH) ) )
                                       FROM Trust_Account__c 
                                       WHERE Id IN :mapTrustAccounts.keySet()]) {
                startOfMonth = (closingBalanceMap.get(ta.Id) != null) ? closingBalanceMap.get(ta.Id).addDays(1) : startOfMonth;
                endOfMonth = startOfMonth.addMonths(1).toStartOfMonth().addDays(-1);
                                           
            	if (resultMap.containsKey(ta.Id)) {
                    Trust_Account__c ref = resultMap.get(ta.Id);
                    ref.Payments_This_Month__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        if (r.Date__c >= startOfMonth && r.Date__c <= endOfMonth) {
                            if (r.RecordTypeId == reverseRecordTypeIds.get('Payment'))
                        		ref.Payments_This_Month__c += r.Amount__c == null ? 0 : r.Amount__c;
                        	else if (r.RecordTypeId == reverseRecordTypeIds.get('Reverse Payment'))
                            	ref.Payments_This_Month__c -= r.Amount__c == null ? 0 : r.Amount__c;
                        }
                    }
                } else {
                    ta.Payments_This_Month__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        if (r.Date__c >= startOfMonth && r.Date__c <= endOfMonth) {
                            if (r.RecordTypeId == reverseRecordTypeIds.get('Payment'))
                        		ta.Payments_This_Month__c += r.Amount__c == null ? 0 : r.Amount__c;
                        	else if (r.RecordTypeId == reverseRecordTypeIds.get('Reverse Payment'))
                            	ta.Payments_This_Month__c -= r.Amount__c == null ? 0 : r.Amount__c;
                        }
                    }
                    resultMap.put(ta.Id, ta);
                }                         
            }
        }
    }
    
    public static void calculateTotalReceipts(final Map<String, Id> reverseRecordTypeIds, Map<Id, Trust_Account__c> resultMap, final List<Receipt__c> receipts) {
		Map<Id, Trust_Account__c> mapTrustAccounts = new Map<Id, Trust_Account__c>();
        for (Receipt__c objReceipt : receipts) {
        	mapTrustAccounts.put(objReceipt.Trust_Account__c, null);
    	}
        
        if (!mapTrustAccounts.isEmpty()) {

            for(Trust_Account__c ta : [SELECT Id, Total_Receipts__c, 
                                      	(SELECT Id, Reconciled__c, Amount__c, X3rd_Party_Transaction__c, RecordTypeId 
                                         FROM Transactions__r 
                                         WHERE Reconciled__c = true AND X3rd_Party_Transaction__c = false
					 					 AND ((RecordTypeId = :reverseRecordTypeIds.get('Receipt')) 
                                           OR (RecordTypeId = :reverseRecordTypeIds.get('Reverse Receipt'))))
         				 		 	   FROM Trust_Account__c 
                                       WHERE Id IN :mapTrustAccounts.keySet()]) {
            	if (resultMap.containsKey(ta.Id)) {
                    Trust_Account__c ref = resultMap.get(ta.Id);
                    ref.Total_Receipts__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        if (r.RecordTypeId == reverseRecordTypeIds.get('Receipt'))
                        	ref.Total_Receipts__c += r.Amount__c == null ? 0 : r.Amount__c;
                        else
                            ref.Total_Receipts__c -= r.Amount__c == null ? 0 : r.Amount__c;
                    }
                } else {
                    ta.Total_Receipts__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        if (r.RecordTypeId == reverseRecordTypeIds.get('Receipt'))
                        	ta.Total_Receipts__c += r.Amount__c == null ? 0 : r.Amount__c;
                        else
                            ta.Total_Receipts__c -= r.Amount__c == null ? 0 : r.Amount__c;
                    }
                    resultMap.put(ta.Id, ta);
                }                         
            }

        }
    }
    
    //Please change ClosingBalanceController::forceCalculateTotalReceiptsThisMonth as well when making changes to this method
    public static void calculateTotalReceiptsThisMonth(final Map<String, Id> reverseRecordTypeIds, Map<Id, Trust_Account__c> resultMap, final List<Receipt__c> receipts) {
		Map<Id, Trust_Account__c> mapTrustAccounts = new Map<Id, Trust_Account__c>();
        Date todaysDate = Date.today();
        Date startOfMonth = todaysDate.toStartOfMonth();
        Date endOfMonth = todaysDate.addMonths(1).toStartOfMonth().addDays(-1);
        
        for (Receipt__c objReceipt : receipts) {
            mapTrustAccounts.put(objReceipt.Trust_Account__c, null);
        }
        
system.debug(reverseRecordTypeIds.get('Receipt')+'  :xx-3:  '+[SELECT Sum(Amount__c), Trust_Account__c, RecordTypeId, Date_Reconciled__c, Date__c
                                            FROM Receipt__c  
                                            WHERE (Reconciled__c = true AND RecordTypeId = :reverseRecordTypeIds.get('Receipt') AND X3rd_Party_Transaction__c = false 
                                            AND (CreatedDate = LAST_N_MONTHS:3 OR CreatedDate = THIS_MONTH))
                                            AND Trust_Account__c IN : mapTrustAccounts.keySet()
                                            GROUP BY Trust_Account__c, RecordTypeId, Date_Reconciled__c, Date__c]);
        
system.debug('xx-2: '+maptrustaccounts.keySet());
        Map<Id, Date> closingBalanceMap = getClosingBalanceMap(mapTrustAccounts);
        //HR 29/06/2016 - Fix the 50001 query error by grouping the query
        Map<String, List<AggregateResult>> receiptRollupSum = new Map<String, List<AggregateResult>>();
        List<AggregateResult> aResult;
        for(AggregateResult receiptAgg : [SELECT Sum(Amount__c), Trust_Account__c, RecordTypeId, Date_Reconciled__c, Date__c
                                            FROM Receipt__c  
                                            WHERE (Reconciled__c = true AND RecordTypeId = :reverseRecordTypeIds.get('Receipt') AND X3rd_Party_Transaction__c = false 
                                            AND (CreatedDate = LAST_N_MONTHS:3 OR CreatedDate = THIS_MONTH))
                                            AND Trust_Account__c IN : mapTrustAccounts.keySet()
                                            GROUP BY Trust_Account__c, RecordTypeId, Date_Reconciled__c, Date__c]){
            String taId = (String)receiptAgg.get('Trust_Account__c');

            if(receiptRollupSum.containsKey(taId))
                aResult = receiptRollupSum.get(taId);
            else
                aResult = new List<AggregateResult>();

            aResult.add(receiptAgg);

            receiptRollupSum.put(taID, aResult);
        }

        aResult = null;
        for(AggregateResult receiptAgg : [SELECT Sum(Amount__c), Trust_Account__c, RecordTypeId, Date_Reconciled__c, Date__c
                                            FROM Receipt__c  
                                            WHERE (Reconciled__c = true AND RecordTypeId = :reverseRecordTypeIds.get('Reverse Receipt') AND (CreatedDate = LAST_N_MONTHS:2 OR CreatedDate = THIS_MONTH))
                                            AND Trust_Account__c IN : mapTrustAccounts.keySet()
                                            GROUP BY Trust_Account__c, RecordTypeId, Date_Reconciled__c, Date__c]){
            String taId = (String)receiptAgg.get('Trust_Account__c');

            if(receiptRollupSum.containsKey(taId))
                aResult = receiptRollupSum.get(taId);
            else
                aResult = new List<AggregateResult>();

            aResult.add(receiptAgg);

            receiptRollupSum.put(taID, aResult);
        }

system.debug('xx-1: '+receiptRollupSum.keySet());
        if (!mapTrustAccounts.isEmpty()) {
system.debug('xx0');
            for(Trust_Account__c ta : [SELECT Id, Receipts_This_Month__c, Closing_Balance_Date__c                                        
                                       FROM Trust_Account__c 
                                       WHERE Id IN :mapTrustAccounts.keySet()]) {
                startOfMonth = (closingBalanceMap.get(ta.Id) != null) ? closingBalanceMap.get(ta.Id).addDays(1) : startOfMonth;
                endOfMonth = startOfMonth.addMonths(1).toStartOfMonth().addDays(-1);
                
                if (resultMap.containsKey(ta.Id)) {
system.debug('xx1');
                    Trust_Account__c ref = resultMap.get(ta.Id);
                    ref.Receipts_This_Month__c = 0;
                    
                    if(receiptRollupSum.containsKey(ta.Id)){
system.debug('xx2');
                        List<AggregateResult> aResultList = receiptRollupSum.get(ta.Id);                        
                        for (AggregateResult r : aResultList) {
system.debug('xx3');
                           if (String.valueOf(r.get('RecordTypeId')) == reverseRecordTypeIds.get('Receipt')) {
system.debug('xx4');
                                Date rDate = r.get('Date_Reconciled__c')==null ? null : Date.valueOf(r.get('Date_Reconciled__c'));
                                if (rDate >= startOfMonth && rDate <= endOfMonth) {
system.debug('xx5');
                                  ref.Receipts_This_Month__c += r.get('expr0') == null ? 0 : Double.valueOf(r.get('expr0'));    
                                } 
                            } else if (String.valueOf(r.get('RecordTypeId')) == reverseRecordTypeIds.get('Reverse Receipt'))  {
system.debug('xx6');
                                Date rDate = r.get('Date__c')==null ? null : Date.valueOf(r.get('Date__c'));
                                if (rDate >= startOfMonth && rDate <= endOfMonth) {
system.debug('xx7');
                                    ref.Receipts_This_Month__c -= r.get('expr0') == null ? 0 : Double.valueOf(r.get('expr0'));
                                }
                            }
                        }
                    }                
                } else {
system.debug('xx8');
                    ta.Receipts_This_Month__c = 0;
                    if(receiptRollupSum.containsKey(ta.Id)){
system.debug('xx9');
                        List<AggregateResult> aResultList = receiptRollupSum.get(ta.Id);
                        for (AggregateResult r : aResultList) {
system.debug('xx10');
                            if (String.valueOf(r.get('RecordTypeId')) == reverseRecordTypeIds.get('Receipt')) {
system.debug('xx11');
                                Date rDate = r.get('Date_Reconciled__c')==null ? null : Date.valueOf(r.get('Date_Reconciled__c'));
                                if (rDate >= startOfMonth && rDate <= endOfMonth) {
system.debug('xx12');
                                    ta.Receipts_This_Month__c += r.get('expr0') == null ? 0 : Double.valueOf(r.get('expr0'));
                                } 
                            } else if (String.valueOf(r.get('RecordTypeId')) == reverseRecordTypeIds.get('Reverse Receipt'))  {
system.debug('xx13');
                                Date rDate = r.get('Date__c')==null ? null : Date.valueOf(r.get('Date__c'));
                                if (rDate >= startOfMonth && rDate <= endOfMonth) {
system.debug('xx14');
                                    ta.Receipts_This_Month__c -= r.get('expr0') == null ? 0 : Double.valueOf(r.get('expr0'));
                                }
                            }
                        }
                    }
                    resultMap.put(ta.Id, ta);
                }

//throw new myexception('STOP');
            }
        }
    }
    
    public static void calculateUnpresentedPayments(final Map<String, Id> reverseRecordTypeIds, Map<Id, Trust_Account__c> resultMap, final List<Receipt__c> receipts) {
		Map<Id, Trust_Account__c> mapTrustAccounts = new Map<Id, Trust_Account__c>();
        for (Receipt__c objReceipt : receipts) {
        	mapTrustAccounts.put(objReceipt.Trust_Account__c, null);
    	}
        
        if (!mapTrustAccounts.isEmpty()) {
            for(Trust_Account__c ta : [SELECT Id, Unpresented_Payments__c, 
                                      	(SELECT Id, Amount__c, Reconciled__c, Type__c, RecordTypeId 
                                      	 FROM Transactions__r WHERE Reconciled__c = false
                                         AND X3rd_Party_Transaction__c = false
                                         AND RecordTypeId = :reverseRecordTypeIds.get('Payment')) 
         				 		 	   FROM Trust_Account__c
                                       WHERE Id IN :mapTrustAccounts.keySet()]) {
            	if (resultMap.containsKey(ta.Id)) {
                    Trust_Account__c ref = resultMap.get(ta.Id);
                    ref.Unpresented_Payments__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        ref.Unpresented_Payments__c += r.Amount__c; 
                    }
                } else {
                    ta.Unpresented_Payments__c = 0;
                    for (Receipt__c r : ta.Transactions__r) {
                        ta.Unpresented_Payments__c += r.Amount__c; 
                    }
                    resultMap.put(ta.Id, ta);
                }                         
            }
        }
    }
    
    public static void calculateLedgerBalance(Map<Id, Creditor_Ledger__c> resultMap, final List<Receipt__c> receipts) {
		Map<Id, Creditor_Ledger__c> mapCreditorLedgers = new Map<Id, Creditor_Ledger__c>();
        for (Receipt__c objReceipt : receipts) {
        	mapCreditorLedgers.put(objReceipt.Creditor__c, null);
    	}
        
        if (!mapCreditorLedgers.isEmpty()) {
            for(Creditor_Ledger__c c : [SELECT Id, Ledger_Balance__c, 
                                      		(SELECT Id, Amount__c, Description__c 
                                      	 	 FROM Transactions__r WHERE Description__c IN ('Journal to Creditor Ledger'
                                                                                         , 'Journal to Creditor Ledger - Build'
                                                                                         , 'Deposit Transfer Payment'
																					     , 'Deposit Transfer Payment - Build'
                                                                                         , 'Reverse Bulk Payment'
                                                                                         , 'Journal out of Creditor Ledger'
                                                                                         , 'Journal out of Creditor Ledger - Build'
                                                                                         , 'Journal to OH Creditor Ledger'
                                                                                         , 'Journal out of OH Creditor Ledger'
                                                                                         , 'Full Commission'
                                                                                         , 'Part Commission')) 
         				 		 	    FROM Creditor_Ledger__c
                                        WHERE Id IN :mapCreditorLedgers.keySet()]) {
            	if (resultMap.containsKey(c.Id)) {
                    Creditor_Ledger__c ref = resultMap.get(c.Id);
                    ref.Ledger_Balance__c = 0;
                    for (Receipt__c r : c.Transactions__r) {
                        if (r.Description__c == 'Deposit Transfer Payment' 
                            || r.Description__c == 'Deposit Transfer Payment - Build' 
                            || r.Description__c == 'Journal out of Creditor Ledger' 
                            || r.Description__c == 'Journal out of Creditor Ledger - Build'
                            || r.Description__c == 'Journal out of OH Creditor Ledger'
                            || r.Description__c == 'Full Commission'
                            || r.Description__c == 'Part Commission')
                        	ref.Ledger_Balance__c -= r.Amount__c == null ? 0 : r.Amount__c;
                        else
                            ref.Ledger_Balance__c += r.Amount__c == null ? 0 : r.Amount__c;
                    }
                } else {
                    c.Ledger_Balance__c = 0;
                    for (Receipt__c r : c.Transactions__r) {
                        if (r.Description__c == 'Deposit Transfer Payment' 
                            || r.Description__c == 'Deposit Transfer Payment - Build' 
                            || r.Description__c == 'Journal out of Creditor Ledger' 
                            || r.Description__c == 'Journal out of Creditor Ledger - Build'
                            || r.Description__c == 'Journal out of OH Creditor Ledger'
                            || r.Description__c == 'Full Commission'
                            || r.Description__c == 'Part Commission')
                        	c.Ledger_Balance__c -= r.Amount__c == null ? 0 : r.Amount__c;
                        else
                            c.Ledger_Balance__c += r.Amount__c == null ? 0 : r.Amount__c;
                    }
                    resultMap.put(c.Id, c);
                }                         
            }
        }
    }
    
    public static Map<Id, Date> getClosingBalanceMap(Map<Id, Trust_Account__c> mapTrustAccounts) {
        Map<Id, Date> result = new Map<Id, Date>();
        for (Trust_Account__c ta : [SELECT Id, Closing_Balance_Date__c FROM Trust_Account__c WHERE Id IN :mapTrustAccounts.keySet()]) {
            result.put(ta.Id, ta.Closing_Balance_Date__c);
        }
        
        return result;
    }
    
    /*public static void calculateDepositReceivedBuild(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        calculateDepositReceived(reverseRecordTypeIds, resultMap, receipts);
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Received_Build__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c 
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Initial Deposit - Build','Further Deposit - Build','Balance of Deposit - Build','Full Deposit - Build'
                                                              ,'Reverse Refund - Build','Reverse Deposit - Build'
                                                              ,'Refund Cancellation - Build','Refund Excess Deposit - Build'
                                                              ,'Journal out of Sales Ledger - Build', 'Journal into Sales Ledger - Build')
                                      AND (RecordTypeId = :reverseRecordTypeIds.get('Receipt') 
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Reversal')
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Refund')
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Journal')) ) 
         				 		 FROM Opportunity WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Received_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        ref.Deposit_Received_Build__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Received_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        o.Deposit_Received_Build__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }*/
    
    /*public static void setMostRecentDepositDate(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Most_Recent_Deposit__c, 
                                     (SELECT Id, Date__c, Description__c 
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Initial Deposit','Further Deposit','Balance of Deposit','Full Deposit'
                                                  ,'Initial Deposit - Land','Further Deposit - Land','Balance of Deposit - Land'
                                                  ,'Full Deposit - Land')
                                      AND (RecordTypeId = :reverseRecordTypeIds.get('Receipt') 
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Reversal')
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Refund'))
                                      ORDER BY Date__c ASC) 
         				 		 FROM Opportunity WHERE Id IN :mapOpportunities.keySet()]) {					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    if (!o.Transactions__r.isEmpty())
                    	ref.Most_Recent_Deposit__c = o.Transactions__r.get(o.Transactions__r.size() - 1).Date__c; 
                    
                } else {
                    if (!o.Transactions__r.isEmpty())
                    	o.Most_Recent_Deposit__c = o.Transactions__r.get(o.Transactions__r.size() - 1).Date__c; 
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }*/
    
    /*public static void calculateOptionFeeReceived(Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Option_Fee_Received__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c 
                                      FROM Transactions__r WHERE Description__c = 'Option Fee' OR Description__c = 'Refund Option Fee') 
         				 		 FROM Opportunity WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Option_Fee_Received__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        ref.Option_Fee_Received__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Option_Fee_Received__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        o.Option_Fee_Received__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }*/
    
    /*public static void calculateDepositTransferredBuild(final Map<String, Id> reverseRecordTypeIds, Map<Id, Opportunity> resultMap, final List<Receipt__c> receipts) {
        calculateDepositTransferred(reverseRecordTypeIds, resultMap, receipts);
        Map<Id, Opportunity> mapOpportunities = new Map<Id, Opportunity>();
        for (Receipt__c objReceipt : receipts) {
        	mapOpportunities.put(objReceipt.Opportunity__c, null);
    	}
    	
        if (!mapOpportunities.isEmpty()) {
    		for(Opportunity o : [SELECT Id, Deposit_Transferred_Build__c, 
                                     (SELECT Id, Positive_Negative_Value__c, Description__c 
                                      FROM Transactions__r
                                      WHERE Description__c IN ('Reverse Journal Deposit Transfer - Build','Journal to Creditor Ledger - Build','Reverse Journal to Creditor Ledger - Build')
                                      AND (RecordTypeId = :reverseRecordTypeIds.get('Journal') 
                                        OR RecordTypeId = :reverseRecordTypeIds.get('Reversal'))) 
         				 		 FROM Opportunity WHERE Id IN :mapOpportunities.keySet()]) {
                					 
             	if (resultMap.containsKey(o.Id)) {
                    Opportunity ref = resultMap.get(o.Id);
                    ref.Deposit_Transferred_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        ref.Deposit_Transferred_Build__c += r.Positive_Negative_Value__c; 
                    }
                } else {
                    o.Deposit_Transferred_Build__c = 0;
                    for (Receipt__c r : o.Transactions__r) {
                        o.Deposit_Transferred_Build__c += r.Positive_Negative_Value__c; 
                    }
                    resultMap.put(o.Id, o);
                }
    		}
        }
    }*/
    
    class myexception extends Exception{}
}