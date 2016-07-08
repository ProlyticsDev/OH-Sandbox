trigger closingBalanceTrigger on Closing_Balance__c (after insert, after update) {

    Set<Id> trustAccountsToProcess = new Set<Id>();
    
    for (Closing_Balance__c c : Trigger.new) {
        if (c.Trust_Account_Ledger__c != null) {
            trustAccountsToProcess.add(c.Trust_Account_Ledger__c);
        }
    }
    
    ClosingBalanceController.setMostRecentClosingBalanceAmount(trustAccountsToProcess);
}