trigger receiptTrigger on Receipt__c (before insert, before update, after delete) 
{
    list<Receipt__c> listReceiptWithRelatedData = new list<Receipt__c>();
    list<Task> listTasksToBeInserted = new list<Task>();
    list<Trust_Account__c> listTrustAccountsToBeUpdated = new list<Trust_Account__c>();
    list<Id> listContactIds = new list<Id>();
    list<User> listGMOfSalesUser = new list<User>();
    list<date> listReconciledDates = new list<date>();
    
    boolean isGmUserChecked = false;
    
    map<Id, Opportunity> mapOpportunities = new map<Id, Opportunity>();
    map<Id, Trust_Account__c> mapTrustAccounts = new map<Id, Trust_Account__c>();
    map<id, Product__c> mapProducts = new map<Id, Product__c>();
    //map<Id, list<Receipt__c>> mapTrustAccountReceipts = new map<Id, list<Receipt__c>>();
    map<Id, Opportunity> mapOpportunitiesToBeUpdated = new map<Id, Opportunity>();
    map<Id, decimal> mapOpportunityLedgerBalance = new map<Id, decimal>();
    map<Id, decimal> mapOpportunityDepositBalance = new map<Id, decimal>();
    map<Id, Opportunity> mapOppotunityLedgerNumber = new map<Id, Opportunity>();
    map<Id, Trust_Account__c> mapTrustAccountLedgerNumber = new map<Id, Trust_Account__c>();
    map<Id, Product__c> mapProductProduct = new map<Id, Product__c>();
    map<date, list<Receipt__c>> mapReconciledDateReceipts = new map<date, list<Receipt__c>>();
    map<date, set<decimal>> mapReconciledDateOrder = new map<date, set<decimal>>();
    
    EmailTemplate objEmailTemplate = null;
    
    for(Receipt__c objReceipt : (trigger.isDelete ? trigger.old : trigger.new))
    {
        mapOpportunities.put(objReceipt.Opportunity__c, null);
        mapTrustAccounts.put(objReceipt.Trust_Account__c, null);
        mapProductProduct.put(objReceipt.Product__c, null);
    }

    mapProductProduct = new map<id, Product__c>([
        Select Id, Total_Receipts__c, Total_Payments__c
        From Product__c
        Where Id IN : mapProductProduct.keySet()]);
    
    if(trigger.isInsert || trigger.isUpdate)
    {
        //YP
        /*mapOpportunities = new map<Id, Opportunity>([
            Select Id, Balance_Of_Deposit__c, Ledger_Number__c, Full_Deposit_Required__c, OwnerId, Ledger_Balance_Correct__c,
                Account.Id, Account.PersonEmail, Account.PersonHasOptedOutOfEmail, Account.PersonContactId
            From Opportunity
            Where Id IN : mapOpportunities.keySet()]);*/
        mapOpportunities = new map<Id, Opportunity>([
            Select Id, Customer_Reference__c, Balance_Of_Deposit__c, Deposit_Due_Date__c, Purchaser_Signed_Date__c, Ledger_Number__c, Full_Deposit_Required__c, OwnerId, Ledger_Balance_Correct__c,
                Account.Id, Account.PersonEmail, Account.PersonHasOptedOutOfEmail, Account.PersonContactId
            From Opportunity
            Where Id IN : mapOpportunities.keySet()]);
        //YP
        
        mapTrustAccounts = new map<Id, Trust_Account__c>([
            Select Id, Ledger_Balance__c, Total_Payments__c, Total_Receipts__c, Ledger_Number__c
            From Trust_Account__c
            Where Id IN : mapTrustAccounts.keySet()]);
    }
    
    mapProducts = mapProductProduct;
    
    for(Receipt__c objReceipt : (trigger.isDelete ? trigger.old : trigger.new))
    {
        if(trigger.isInsert || trigger.isUpdate)
        {
            objReceipt.Opportunity__r = mapOpportunities.get(objReceipt.Opportunity__c);
            objReceipt.Trust_Account__r = mapTrustAccounts.get(objReceipt.Trust_Account__c);
        }
        listReceiptWithRelatedData.add(objReceipt); 
    }
  
    Map<Id, Opportunity> opportunitiesToBeUpdated = new Map<Id, Opportunity>();
    ReceiptRollupCalculationHelper.calculateTotalReconciledReceipts(ohHelper.recordTypes, opportunitiesToBeUpdated, listReceiptWithRelatedData);
    ReceiptRollupCalculationHelper.calculateTotalPaymentsAndOptionFee(ohHelper.recordTypes, opportunitiesToBeUpdated, listReceiptWithRelatedData);
    
    ohHelper.calculateLedgerBalances(opportunitiesToBeUpdated, mapOpportunityLedgerBalance);
    
    mapProductProduct = new map<Id, Product__c>();
    for(Receipt__c objReceipt : listReceiptWithRelatedData) {
        
        if(trigger.isInsert || trigger.isUpdate) {
            //Add customer reference from Opportunity
            if (objReceipt.Reconciled__c == false) {
                objReceipt.Customer_Ref__c = objReceipt.Opportunity__r.Customer_Reference__c;
            }
            
            //Generate Emails for Reverse Payments
            if(objReceipt.Type__c == 'Payment' && objReceipt.Description__c == 'Reverse Receipt' && (trigger.isInsert || (trigger.isUpdate && trigger.oldMap.get(objReceipt.Id).Description__c != 'Reverse Receipt' && trigger.oldMap.get(objReceipt.Id).Description__c != 'Payment')))
            {
                ohHelper.GenerateEmail(objReceipt, listContactIds, listTasksToBeInserted);
            }
            
            //Check Ledger Number for the Receipt's Opportunity
            ohHelper.GenerateLedgerNumbers(objReceipt, mapTrustAccountLedgerNumber, mapOppotunityLedgerNumber);
            
            //Calculate Running Balance
            if(objReceipt.Reconciled__c == true)
            {
                ohHelper.PrepareRunningBalanceMaps(objReceipt, mapReconciledDateReceipts, mapReconciledDateOrder, listReconciledDates);
            }
            
            if(trigger.isInsert ||
               (trigger.isUpdate && objReceipt.Positive_Negative_Value__c != trigger.oldMap.get(objReceipt.Id).Positive_Negative_Value__c))
            {
                //Add the Positive Negative Value to respective Opportunities
                //ohHelper.CalculateLedgerBalance(objReceipt, 
                //                                mapOpportunityLedgerBalance,
                //                                (trigger.isInsert ? 0 : (trigger.oldMap.get(objReceipt.Id).Positive_Negative_Value__c == null ? 0 : trigger.oldMap.get(objReceipt.Id).Positive_Negative_Value__c)));
                
                //Subtract the Positive Negative Value of respective Receipts from Opportunity
                if(objReceipt.Description__c == 'Initial Deposit' || objReceipt.Description__c == 'Further Deposit' || 
                   objReceipt.Description__c == 'Balance of Deposit' || objReceipt.Description__c == 'Full Deposit' || 
                   objReceipt.Description__c == 'Reverse Refund' || objReceipt.Description__c == 'Refund Cancellation' || 
                   objReceipt.Description__c == 'Refund Excess Deposit' || objReceipt.Description__c == 'Reverse Journal Deposit Transfer')
                {
                    ohHelper.CalculateDepositBalance(objReceipt, 
                                                     mapOpportunityDepositBalance, 
                                                     (trigger.isInsert ? 0 : (trigger.oldMap.get(objReceipt.Id).Positive_Negative_Value__c == null ? 0 : trigger.oldMap.get(objReceipt.Id).Positive_Negative_Value__c)));
                }
                
            }
            
            //YP
            if (objReceipt.Description__c == 'Balance of Deposit' 
                || objReceipt.Description__c == 'Full Deposit' 
                || objReceipt.Description__c == 'Balance of Deposit - Land'
                || objReceipt.Description__c == 'Full Deposit - Land') {
                    ohHelper.updateFullDepositReceivedDate(objReceipt, mapOpportunitiesToBeUpdated);
                }   
        }
        //Calculate Receipts and Payments for respective Product
        if(((trigger.isInsert || trigger.isDelete) ||
            (trigger.isUpdate && objReceipt.Debit_Amount__c != trigger.oldMap.get(objReceipt.Id).Debit_Amount__c) ||
            (trigger.isUpdate && objReceipt.Credit_Amount__c != trigger.oldMap.get(objReceipt.Id).Credit_Amount__c)) &&
            (mapProducts.containsKey(objReceipt.Product__c)))
        {
            ohHelper.CalculateProductRollups(objReceipt, 
                mapProducts.get(objReceipt.Product__c),
                mapProductProduct, 
                (trigger.isInsert ? 0 : (trigger.oldMap.get(objReceipt.Id).Debit_Amount__c == null ? 0 : trigger.oldMap.get(objReceipt.Id).Debit_Amount__c)),
                (trigger.isInsert ? 0 : (trigger.oldMap.get(objReceipt.Id).Credit_Amount__c == null ? 0 : trigger.oldMap.get(objReceipt.Id).Credit_Amount__c)),
                trigger.isDelete);
        }
    }
    
    //Calculate Running Balance
    if(listReconciledDates.size() > 0)
    {
        ohHelper.CalculateRunningBalance(mapReconciledDateReceipts, mapReconciledDateOrder, listReconciledDates, (trigger.isUpdate ? trigger.oldMap : null));
    }
    
    //Send Emails
    if(listContactIds.size() > 0)
    {
        objEmailTemplate = [Select Id From EmailTemplate Where DeveloperName = 'Reverse_Transaction_Email_Template'];
    }
    if(objEmailTemplate != null)
    {
        /*
        list<Id> contactIds = new list<Id>();
        for(integer counter = 0; counter < listContactIds.size(); counter++)
        {
            contactIds.add(listContactIds[counter]);
            if(math.mod(counter + 1, 250) == 0)
            {
                Messaging.MassEmailMessage objEmail = new Messaging.MassEmailMessage();
                objEmail.setTargetObjectIds(contactIds);
                objEmail.setTemplateID(objEmailTemplate.Id);
                Messaging.sendEmail(new Messaging.MassEmailMessage[] {objEmail});
                contactIds = new list<Id>();
            }
        }
        if(contactIds.size() > 0)
        {
            Messaging.MassEmailMessage objEmail = new Messaging.MassEmailMessage();
            objEmail.setTargetObjectIds(contactIds);
            objEmail.setTemplateID(objEmailTemplate.Id);
            Messaging.sendEmail(new Messaging.MassEmailMessage[] {objEmail});
        }
        */
    }
    
    //Generate Receipt Numbers based on Trust Accounts for all Receipts
    //And assign to Receipts
    /*ohHelper.GenerateReceiptNumber(mapTrustAccountReceipts);*/
    
    //Generate Tasks for Ledger Balance less than zero
    isGmUserChecked = ohHelper.GenerateTasksForLedgerBalanceBelowZero(mapOpportunityLedgerBalance, listTasksToBeInserted, isGmUserChecked, listGMOfSalesUser);
    
    //Generate Tasks for Deposit Balance less than zero
    isGmUserChecked = ohHelper.GenerateTasksForDepositBalanceBelowZero(mapOpportunityDepositBalance, listTasksToBeInserted, isGmUserChecked, listGMOfSalesUser);
    
    List<Receipt__c> journalsToUpdate = ohHelper.reconcileChildJournalTransactions(listReceiptWithRelatedData);
    //ohHelper.assignReversingTransaction(listReceiptWithRelatedData);
    
    update journalsToUpdate;
    update mapTrustAccountLedgerNumber.values();
    update mapOppotunityLedgerNumber.values();
    update mapProductProduct.values();
    
    //YP
    update mapOpportunitiesToBeUpdated.values();
    //YP
    
    Database.DMLOptions notifyOption = new Database.DMLOptions();
    notifyOption.EmailHeader.triggerUserEmail = true;
    Database.insert(listTasksToBeInserted, notifyOption);
}