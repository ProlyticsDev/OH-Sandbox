/*
 * This is an expensive call and there is a high risk of hitting the governer limits during bulk update.
 * */

trigger ReceiptRollUpCalculationTrigger on Receipt__c (after insert, after update, after delete) {
	Map<Id, String> recordTypeIds = ohHelper.recordTypeIds;//new Map<Id, String>();
    Map<String, Id> reverseRecordTypeIds = ohHelper.recordTypes;//new Map<String, Id>();
    Map<Id, Opportunity> opportunitiesToBeUpdated = new Map<Id, Opportunity>();
    Map<Id, Trust_Account__c> trustAccountsToBeUpdated = new Map<Id, Trust_Account__c>();
    Map<Id, Creditor_Ledger__c> creditorLedgersToBeUpdated = new Map<Id, Creditor_Ledger__c>();
    
    /*for(RecordType rt : [SELECT Id, Name FROM Recordtype WHERE SobjectType='Receipt__c' and Name IN ('Receipt', 'Reverse Receipt', 'Reverse Payment', 'Reversal','Payment','Refund','Journal')]){
    	recordTypeIds.put(rt.Id, rt.Name);
        reverseRecordTypeIds.put(rt.Name, rt.Id);
	}*/
    
    List<Receipt__c> depositReceivedReceipts = new List<Receipt__c>();
    List<Receipt__c> totalReconciledReceipts = new List<Receipt__c>();
    List<Receipt__c> totalPaymentsAndOptionFee = new List<Receipt__c>();
    List<Receipt__c> depositRefundedReceipts = new List<Receipt__c>();
    List<Receipt__c> depositTransferredReceipts = new List<Receipt__c>();
    List<Receipt__c> totalTAReceipts = new List<Receipt__c>();
    List<Receipt__c> totalTAPayments = new List<Receipt__c>();
    List<Receipt__c> unpresentedPayments = new List<Receipt__c>();
    List<Receipt__c> allReceipts = new List<Receipt__c>();
    
    for (Receipt__c r : (Trigger.isDelete ? Trigger.old : Trigger.new)) {
        if (recordTypeIds.get(r.RecordTypeId) == 'Receipt' || recordTypeIds.get(r.RecordTypeId) == 'Reverse Receipt' 
            	|| recordTypeIds.get(r.RecordTypeId) == 'Payment' || recordTypeIds.get(r.RecordTypeId) == 'Journal') {
            depositReceivedReceipts.add(r);
        }
        if (recordTypeIds.get(r.RecordTypeId) == 'Receipt' || recordTypeIds.get(r.RecordTypeId) == 'Payment' || recordTypeIds.get(r.RecordTypeId) == 'Reverse Payment' 
            	|| recordTypeIds.get(r.RecordTypeId) == 'Journal') {
            totalPaymentsAndOptionFee.add(r);
        }
        if (recordTypeIds.get(r.RecordTypeId) == 'Reverse Payment' || recordTypeIds.get(r.RecordTypeId) == 'Payment') {
        	depositRefundedReceipts.add(r);    
        }
        if (recordTypeIds.get(r.RecordTypeId) == 'Journal') {
        	depositTransferredReceipts.add(r);    
        }
        if (recordTypeIds.get(r.RecordTypeId) == 'Receipt' || recordTypeIds.get(r.RecordTypeId) == 'Reverse Receipt') {
        	totalTAReceipts.add(r);    
        }
        if (recordTypeIds.get(r.RecordTypeId) == 'Reverse Payment' || recordTypeIds.get(r.RecordTypeId) == 'Payment') {
        	totalTAPayments.add(r);    
        }
        if (recordTypeIds.get(r.RecordTypeId) == 'Payment') {
        	unpresentedPayments.add(r);    
        }
        allReceipts.add(r);
    }
    
    ReceiptRollupCalculationHelper.calculateDepositReceivedAndBuild(reverseRecordTypeIds, opportunitiesToBeUpdated, depositReceivedReceipts);
    ReceiptRollupCalculationHelper.calculateDepositReceivedReconciled(reverseRecordTypeIds, opportunitiesToBeUpdated, depositReceivedReceipts);
    ReceiptRollupCalculationHelper.calculateDepositRefunded(reverseRecordTypeIds, opportunitiesToBeUpdated, totalTAPayments);
    ReceiptRollupCalculationHelper.calculateDepositRefundedBuild(reverseRecordTypeIds, opportunitiesToBeUpdated, depositRefundedReceipts);
	ReceiptRollupCalculationHelper.calculateDepositTransferredAndBuild(reverseRecordTypeIds, opportunitiesToBeUpdated, depositTransferredReceipts);
    ReceiptRollupCalculationHelper.calculateTotalReconciledReceipts(reverseRecordTypeIds, opportunitiesToBeUpdated, allReceipts);
    ReceiptRollupCalculationHelper.calculateTotalPaymentsAndOptionFee(reverseRecordTypeIds, opportunitiesToBeUpdated, totalPaymentsAndOptionFee);
    ReceiptRollupCalculationHelper.calculateTotalPayments(reverseRecordTypeIds, trustAccountsToBeUpdated, totalTAPayments);
    ReceiptRollupCalculationHelper.calculateTotalPaymentsThisMonth(reverseRecordTypeIds, trustAccountsToBeUpdated, totalTAPayments);
    ReceiptRollupCalculationHelper.calculateTotalReceiptsThisMonth(reverseRecordTypeIds, trustAccountsToBeUpdated, totalTAReceipts);
    ReceiptRollupCalculationHelper.calculateTotalReceipts(reverseRecordTypeIds, trustAccountsToBeUpdated, totalTAReceipts);
    ReceiptRollupCalculationHelper.calculateUnpresentedPayments(reverseRecordTypeIds, trustAccountsToBeUpdated, unpresentedPayments);
    ReceiptRollupCalculationHelper.calculateLedgerBalance(creditorLedgersToBeUpdated, allReceipts);
    
    //ReceiptRollupCalculationHelper.calculateDepositReceivedBuild(reverseRecordTypeIds, opportunitiesToBeUpdated, depositReceivedReceipts);
    //ReceiptRollupCalculationHelper.setMostRecentDepositDate(reverseRecordTypeIds, opportunitiesToBeUpdated, depositReceivedReceipts);
    //ReceiptRollupCalculationHelper.calculateDepositTransferredBuild(reverseRecordTypeIds, opportunitiesToBeUpdated, depositTransferredReceipts);
    //ReceiptRollupCalculationHelper.calculateOptionFeeReceived(opportunitiesToBeUpdated, allReceipts);
    //ReceiptRollupCalculationHelper.calculateTotalReceipts(reverseRecordTypeIds, trustAccountsToBeUpdated, totalTAReceipts);
    
    
    update opportunitiesToBeUpdated.values();
    update trustAccountsToBeUpdated.values();
    update creditorLedgersToBeUpdated.values();
}