public with sharing class ohHelper 
{
    //static final RecordType paymentRecordType = [SELECT Id, Name FROM Recordtype WHERE SobjectType='Receipt__c' AND Name = 'Payment'];
    //static final RecordType journalRecordType = [SELECT Id, Name FROM Recordtype WHERE SobjectType='Receipt__c' AND Name = 'Journal'];
    
    public static final Map<String, Id> recordTypes;
    public static final Map<Id, String> recordTypeIds;
    static {
        recordTypes = new Map<String, Id>();
        recordTypeIds = new Map<Id, String>();
        for(RecordType rt : [SELECT Id, Name 
                             FROM Recordtype 
                             WHERE SobjectType='Receipt__c' AND Name IN ('Receipt','Payment','Journal', 'Reverse Receipt', 'Reverse Payment'/*, 'Reversal', 'Refund'*/)]){
    		recordTypes.put(rt.Name, rt.Id);
            recordTypeIds.put(rt.Id, rt.Name);
        }
    } 
	
    //YP
    public static void updateFullDepositReceivedDate(Receipt__c objReceipt, Map<Id, Opportunity> mapOpportunitiesToBeUpdated) {
        if (objReceipt.Opportunity__r.Balance_of_Deposit__c == 0 && objReceipt.Opportunity__r.Purchaser_Signed_Date__c != null
            && objReceipt.Opportunity__r.Deposit_Due_Date__c != null) {
        	objReceipt.Opportunity__r.Full_Deposit_Received_Date__c = objReceipt.Date__c; 
            mapOpportunitiesToBeUpdated.put(objReceipt.Opportunity__r.Id, objReceipt.Opportunity__r);
        }
    }
    //YP
    
    public static void GenerateEmail(Receipt__c objReceipt, list<Id> listContactIds, list<Task> listTasksToBeInserted)
    {
        system.debug('Trigger Testing: Generate Email method');
        //Check if the Account is Person Account and Email Opt Out is False
        //If above is true create contact list for emails
        //Othewise create tasks for opportunity owner
        if(objReceipt.Opportunity__r.Account.PersonContactId != null && string.isNotBlank(objReceipt.Opportunity__r.Account.PersonEmail) && objReceipt.Opportunity__r.Account.PersonHasOptedOutOfEmail == false)
        {
            system.debug('Trigger Testing: Found Email:' + objReceipt.Opportunity__r.Account.PersonEmail);
            listContactIds.add(objReceipt.Opportunity__r.Account.PersonContactId);
            
            Task objTask = new Task();
            objTask.Subject ='Dishonored Payment Email Sent to Client';
            objTask.ActivityDate = date.today();
            objTask.Status = 'Completed';
            objTask.Description = 'Hi, An email has been sent to the purchaser for dishonored payment. Thanks, Sys Admin';
            objTask.WhatId = objReceipt.Opportunity__r.Account.Id;
            objTask.OwnerId = objReceipt.Opportunity__r.OwnerId;
            listTasksToBeInserted.add(objTask);
        }
        else
        {
            system.debug('Trigger Testing: Generating Tasks for Opportunity Owner');
            
            Task objTask = new Task();
            objTask.Subject ='Trust Account Receipt to be returned';
            objTask.ActivityDate = date.today();
            objTask.Description = 'Hi, The purchaser needs to return the Trust Account Receipt. Please contact them and make the necessary arrangements. Thanks, Sys Admin';
            objTask.WhatId = objReceipt.Opportunity__r.Account.Id;
            objTask.OwnerId = objReceipt.Opportunity__r.OwnerId;
            listTasksToBeInserted.add(objTask);
        }
    }
    
    /*public static map<Id, list<Receipt__c>> RelateTrustAccountAndReceipts(list<Receipt__c> listReceipts)
    {
        map<Id, list<Receipt__c>> mapTrustAccountReceipts = new map<Id, list<Receipt__c>>();
        for(Receipt__c objReceipt : listReceipts)
        {
            //Check matching criteria for Empty Receipt Numbers
            //Type = Receipt
            //Description: Initial Deposit; Further Deposit; Balance of Deposit; 
            //  Full Deposit; Initial Deposit - Build; Further Deposit - Build;
            //  Balance of Deposit - Build; Full Deposit - Build
            //Trust Account Receipt Number: Is Empty
            //Trust Account: Is not empty
            if(objReceipt.Trust_Account_Receipt_Number__c == null &&
                objReceipt.Trust_Account__c != null &&
                objReceipt.Type__c == 'Receipt' &&
                (objReceipt.Description__c == 'Initial Deposit' || objReceipt.Description__c == 'Further Deposit' ||
                    objReceipt.Description__c == 'Balance of Deposit' || objReceipt.Description__c == 'Full Deposit' ||
                    objReceipt.Description__c == 'Initial Deposit - Build' || objReceipt.Description__c == 'Further Deposit - Build' ||
                    objReceipt.Description__c == 'Balance of Deposit - Build' || objReceipt.Description__c == 'Full Deposit - Build'))
            {
                //Add Receipts as a children of Trust Accounts
                if(!mapTrustAccountReceipts.containsKey(objReceipt.Trust_Account__c))
                {
                    mapTrustAccountReceipts.put(objReceipt.Trust_Account__c, new list<Receipt__c>());
                }
                
                mapTrustAccountReceipts.get(objReceipt.Trust_Account__c).add(objReceipt);
            }
        }
        return mapTrustAccountReceipts;
    }*/
    
    public static void GenerateReceiptNumber(map<id, list<Receipt__c>> mapTrustAccountReceipts)
    {
        if(mapTrustAccountReceipts.size() > 0)
        {
            map<id, decimal> mapTrustAccountReceiptNumber = new map<id, decimal>();
            list<Trust_Account_Receipt_Number__c> listNewTrustAccountReceiptNumbers = new list<Trust_Account_Receipt_Number__c>();
            decimal receiptNumber = 0;
        
            //Get max receipt numbers for Trust Accounts in the parameter
            for(AggregateResult objMaxReceiptNumber : [
                Select Trust_Account__c, Max(TA_Receipt_Number__c) MaxReceiptNumber
                From Trust_Account_Receipt_Number__c
                Where Trust_Account__c IN : mapTrustAccountReceipts.keySet()
                Group By Trust_Account__c])
            {
                //Create a ID/Decimal map for Trust Accounts and Max Receipt Numbers
                mapTrustAccountReceiptNumber.put((Id)objMaxReceiptNumber.get('Trust_Account__c'), (decimal)objMaxReceiptNumber.get('MaxReceiptNumber'));
            }
            
            //Generate new receipt numbers
            for(Id trustAccountId : mapTrustAccountReceipts.keySet())
            {
                //If a Receipt Number was not found for a given Trust Account, create a seed Receipt Number
                if(!mapTrustAccountReceiptNumber.containsKey(trustAccountId))
                {
                    mapTrustAccountReceiptNumber.put(trustAccountId, 0);
                }
                
                //Loop through all Receipts for a given Trust Account
                //Create new Receipt Numbers for each Receipt
                receiptNumber = mapTrustAccountReceiptNumber.get(trustAccountId);
                for(Receipt__c objReceipt : mapTrustAccountReceipts.get(trustAccountId))
                {
                    receiptNumber++;
                    Trust_Account_Receipt_Number__c objReceiptNumber = new Trust_Account_Receipt_Number__c();
                    objReceiptNumber.Trust_Account__c = trustAccountId;
                    objReceiptNumber.TA_Receipt_Number__c = receiptNumber;
                    listNewTrustAccountReceiptNumbers.add(objReceiptNumber);
                }
            }
        
            //Insert the newly created Receipt Numbers
            insert listNewTrustAccountReceiptNumbers;
            
            //Assign newly created Receipt Numbers to Receipts
            for(Trust_Account_Receipt_Number__c objReceiptNumber : listNewTrustAccountReceiptNumbers)
            {
                for(Receipt__c objReceipt : mapTrustAccountReceipts.get(objReceiptNumber.Trust_Account__c))
                {
                    if(objReceipt.Trust_Account_Receipt_Number__c == null)
                    {
                        objReceipt.Trust_Account_Receipt_Number__c = objReceiptNumber.Id;
                    }
                }
            }
        }
    }
    
    public static void PrepareRunningBalanceMaps(Receipt__c objReceipt, map<date, list<Receipt__c>> mapReconciledDateReceipts, map<date, set<decimal>> mapReconciledDateOrder, list<date> listReconciledDates)
    {
        if(!mapReconciledDateReceipts.containsKey(objReceipt.Date_Reconciled__c))
        {
            mapReconciledDateReceipts.put(objReceipt.Date_Reconciled__c, new list<Receipt__c>());
            mapReconciledDateOrder.put(objReceipt.Date_Reconciled__c, new set<decimal>());
            listReconciledDates.add(objReceipt.Date_Reconciled__c);
        }
        mapReconciledDateReceipts.get(objReceipt.Date_Reconciled__c).add(objReceipt);
        mapReconciledDateOrder.get(objReceipt.Date_Reconciled__c).add(objReceipt.Ledger_Balance_Order__c);
    }
    
    public static void CalculateRunningBalance(map<date, list<Receipt__c>> mapReconciledDateReceipts, map<date, set<decimal>> mapReconciledDateOrder, list<date> listReconciledDates, map<id, Receipt__c> mapOldReceipts)
    {
        list<decimal> listLedgerBalanceOrder = new list<decimal>();
        decimal runningBalance = 0;
        listReconciledDates.sort();
        map<id, decimal> mapOpportunityRunningBalance = new map<id, decimal>();
        
        for(Date reconciledDate : listReconciledDates)
        {
            listLedgerBalanceOrder = new list<decimal>();
            for(decimal ledgerBalanceOrder : mapReconciledDateOrder.get(reconciledDate))
            {
                listLedgerBalanceOrder.add(ledgerBalanceOrder);
            }
            
            listLedgerBalanceOrder.sort();
            for(Decimal ledgerBalanceOrder : listLedgerBalanceOrder)
            {
                for(Receipt__c objReceipt : mapReconciledDateReceipts.get(reconciledDate))
                {
                    if(ledgerBalanceOrder == objReceipt.Ledger_Balance_Order__c)
                    {
                        if(!mapOpportunityRunningBalance.containsKey(objReceipt.Opportunity__c))
                        {
                            mapOpportunityRunningBalance.put(objReceipt.Opportunity__c, ohHelper.NormalizeDecimal(objReceipt.Opportunity__r.Ledger_Balance_Correct__c));
                        }
                        
                        runningBalance = mapOpportunityRunningBalance.get(objReceipt.Opportunity__c);
                        if(mapOldReceipts != null)
                        {
                            runningBalance = runningBalance - ohHelper.NormalizeDecimal(mapOldReceipts.get(objReceipt.Id).Positive_Negative_Value__c);
                        }
                        runningBalance = runningBalance + ohHelper.NormalizeDecimal(objReceipt.Positive_Negative_Value__c);
                        mapOpportunityRunningBalance.put(objReceipt.Opportunity__c, runningBalance);
                        objReceipt.Ledger_Balance__c = runningBalance;
                    }
                }
            }
        }
    }
    
    public static void GenerateLedgerNumbers(Receipt__c objReceipt, map<Id, Trust_Account__c> mapTrustAccountLedgerNumber, map<Id, Opportunity> mapOppotunityLedgerNumber)
    {
        decimal ledgerNumber = 0;
        if(objReceipt.Trust_Account__c != null && objReceipt.Opportunity__r != null && string.isBlank(objReceipt.Opportunity__r.Ledger_Number__c))
        {
            if(!mapTrustAccountLedgerNumber.containsKey(objReceipt.Trust_Account__c))
            {
                mapTrustAccountLedgerNumber.put(objReceipt.Trust_Account__c, new Trust_Account__c(Id = objReceipt.Trust_Account__c, Ledger_Number__c = ohHelper.NormalizeDecimal(objReceipt.Trust_Account__r.Ledger_Number__c)));
            }
            if(!mapOppotunityLedgerNumber.containsKey(objReceipt.Opportunity__c))
            {
                ledgerNumber = mapTrustAccountLedgerNumber.get(objReceipt.Trust_Account__c).Ledger_Number__c + 1;
                if (objReceipt.RecordTypeId != recordTypes.get('Payment'))
                	mapOppotunityLedgerNumber.put(objReceipt.Opportunity__c, new Opportunity(Id = objReceipt.Opportunity__c, Ledger_Number__c = string.valueOf(ledgerNumber)));
                mapTrustAccountLedgerNumber.get(objReceipt.Trust_Account__c).Ledger_Number__c = ledgerNumber;
            }
        }
    }
    
    /*public static void CalculateLedgerBalance(Receipt__c objReceipt, map<Id, decimal> mapOpportunityLedgerBalance, decimal oldPositiveNegativeValue)
    {
        decimal ledgerBalance = 0;
        
        if(!mapOpportunityLedgerBalance.containsKey(objReceipt.Opportunity__c))
        {
            mapOpportunityLedgerBalance.put(objReceipt.Opportunity__c, ohHelper.NormalizeDecimal(objReceipt.Opportunity__r.Ledger_Balance_Correct__c));
            //system.debug('Ledger Balance Initialised is: '+objReceipt.Opportunity__r.Ledger_Balance__c);
        }
        
        ledgerBalance = mapOpportunityLedgerBalance.get(objReceipt.Opportunity__c);
        if(oldPositiveNegativeValue != 0)
        {
            ledgerBalance = ledgerBalance  - ohHelper.NormalizeDecimal(oldPositiveNegativeValue);
        } 
        ledgerBalance = ledgerBalance + ohHelper.NormalizeDecimal(objReceipt.Positive_Negative_Value__c);
        system.debug('Ledger Balance Added is: '+ledgerBalance);
        mapOpportunityLedgerBalance.put(objReceipt.Opportunity__c, ledgerBalance);
    }*/
    
    public static void calculateLedgerBalances(Map<Id, Opportunity> opportunitiesToBeUpdated, Map<Id, Decimal> mapOpportunityLedgerBalance) {
        for (Id oId : opportunitiesToBeUpdated.keySet()) {
            Opportunity o = opportunitiesToBeUpdated.get(oId);
            mapOpportunityLedgerBalance.put(o.Id, o.Total_Reconciled_Receipts__c + o.Total_Payments__c);
        }
        System.debug('Ledger Balance Map: ' + mapOpportunityLedgerBalance);
    }
    
    public static void CalculateDepositBalance(Receipt__c objReceipt, map<Id, decimal> mapOpportunityDepositBalance, decimal oldPositiveNegativeValue)
    {
        decimal depositBalance = 0;
        if(!mapOpportunityDepositBalance.containsKey(objReceipt.Opportunity__c))
        {
            mapOpportunityDepositBalance.put(objReceipt.Opportunity__c, ohHelper.NormalizeDecimal(objReceipt.Opportunity__r.Balance_of_Deposit__c));
        }
        depositBalance = mapOpportunityDepositBalance.get(objReceipt.Opportunity__c);
        if(oldPositiveNegativeValue != 0)
        {
            depositBalance = depositBalance + ohHelper.NormalizeDecimal(oldPositiveNegativeValue);
        }
        depositBalance = depositBalance + ohHelper.NormalizeDecimal(objReceipt.Positive_Negative_Value__c);
        system.debug('Deposit Balance is: '+depositBalance);
        mapOpportunityDepositBalance.put(objReceipt.Opportunity__c, depositBalance);
    }
    
    public static void CalculateProductRollups(Receipt__c objReceipt, Product__c objProduct, map<Id, Product__c> mapProductProduct, decimal oldDebitAmount, decimal oldCreditAmount, boolean isDelete)
    {
        if(!mapProductProduct.containsKey(objReceipt.Product__c))
        {
            objProduct.Total_Payments__c = ohHelper.NormalizeDecimal(objProduct.Total_Payments__c);
            objProduct.Total_Receipts__c = ohHelper.NormalizeDecimal(objProduct.Total_Receipts__c);
            mapProductProduct.put(objReceipt.Product__c, objProduct);
        }
        
        if(oldDebitAmount != 0 || oldCreditAmount != 0)
        {
            mapProductProduct.get(objReceipt.Product__c).Total_Payments__c = mapProductProduct.get(objReceipt.Product__c).Total_Payments__c - oldDebitAmount;
            mapProductProduct.get(objReceipt.Product__c).Total_Receipts__c = mapProductProduct.get(objReceipt.Product__c).Total_Receipts__c - oldCreditAmount;
        }
        
        if(!isDelete)
        {
            mapProductProduct.get(objReceipt.Product__c).Total_Payments__c = 
                mapProductProduct.get(objReceipt.Product__c).Total_Payments__c + 
                ohHelper.NormalizeDecimal(objReceipt.Debit_Amount__c);
            
            mapProductProduct.get(objReceipt.Product__c).Total_Receipts__c = 
                mapProductProduct.get(objReceipt.Product__c).Total_Receipts__c + 
                ohHelper.NormalizeDecimal(objReceipt.Credit_Amount__c);
        }
    }
    
    private static list<User> GetGMUser()
    {
        return [Select Id From User Where User.UserRole.Name = 'Sales Administration' limit 1];
    }
    
    public static boolean GenerateTasksForLedgerBalanceBelowZero(map<Id, decimal> mapOpportunityLedgerBalance, list<Task> listTasksToBeInserted, boolean isGmUserChecked, list<User> listGMOfSalesUser)
    {
        for(Id opportunityId : mapOpportunityLedgerBalance.keySet())
        {
            system.debug('The Ledger Balance is: '+mapOpportunityLedgerBalance.get(opportunityId));
            if(mapOpportunityLedgerBalance.get(opportunityId) < 0)
            {
                if(!isGmUserChecked)
                {
                    listGMOfSalesUser = ohHelper.GetGMUser();
                    isGmUserChecked = true;
                }
                if(listGMOfSalesUser.size() > 0)
                {
                    Task objTask = new Task();
                    objTask.Subject ='Ledger Balance is less than zero';
                    objTask.ActivityDate = date.today();
                    objTask.Description = 'Hi, A Transaction has been created which has placed the Ledger Balance for this Opportunity below zero. Please review and take the necessary action. Thanks, Sys Admin';
                    objTask.WhatId = opportunityId;
                    objTask.OwnerId = listGMOfSalesUser[0].Id;
                    listTasksToBeInserted.add(objTask);
                }
            }
        }
        return isGmUserChecked;
    }
    
    public static boolean GenerateTasksForDepositBalanceBelowZero(map<Id, decimal> mapOpportunityDepositBalance, list<Task> listTasksToBeInserted, boolean isGmUserChecked, list<User> listGMOfSalesUser)
    {
        for(Id oppotunityID : mapOpportunityDepositBalance.keySet())
        {
            system.debug('The Deposit Balance is: '+mapOpportunityDepositBalance.get(oppotunityID));
            if(mapOpportunityDepositBalance.get(oppotunityID) < 0)
            {
                if(!isGmUserChecked)
                {
                    listGMOfSalesUser = ohHelper.GetGMUser();
                    isGmUserChecked = true;
                }
                if(listGMOfSalesUser.size() > 0)
                {
                    Task objTask = new Task();
                    objTask.Subject ='Deposit Balance is less than zero';
                    objTask.ActivityDate = date.today();
                    objTask.Description = 'Hi, A Transaction has been created which has placed the Deposit Balance for this Opportunity below zero. Please review and take the necessary action. Thanks, Sys Admin';
                    objTask.WhatId = oppotunityID;
                    objTask.OwnerId = listGMOfSalesUser[0].Id;
                    listTasksToBeInserted.add(objTask);
                }
            }
        }
        return isGmUserChecked;
    }
    
    public static void AdjustEqualAmountCaseWithoutTransaction(Adjustment__c objAdjustment, map<Id, Receipt__c> mapAdjustmentReceipts, map<Id, list<Adjustment__c>> mapAdjustmentAdjustments)
    {
        ohHelper.UpdateExistingAdjustemnt(objAdjustment, mapAdjustmentAdjustments);
        
        Receipt__c objReceipt = new Receipt__c();
        objReceipt.Type__c = 'Receipt';
        objReceipt.Description__c = objAdjustment.Transaction_Description__c;
        objReceipt.Amount__c = objAdjustment.Transaction_Amount__c;
        objReceipt.Reconciled__c = true;
        objReceipt.Date_Reconciled__c = date.today();
        objReceipt.Display_on_Account_Sale__c = true;
        objReceipt.Opportunity__c = objAdjustment.Opportunity__c;
        objReceipt.Trust_Account__c = objAdjustment.Trust_Account__c;
        objReceipt.Deposited_Date__c = objAdjustment.Date__c;
        mapAdjustmentReceipts.put(objAdjustment.Id, objReceipt);
    }
    
    public static void AdjustLessAmountCaseWithoutTransaction(Adjustment__c objAdjustment, map<Id, Receipt__c> mapAdjustmentReceipts, map<id, list<Adjustment__c>> mapAdjustmentAdjustments)
    {
        ohHelper.AdjustEqualAmountCaseWithoutTransaction(objAdjustment, mapAdjustmentReceipts, mapAdjustmentAdjustments);
        ohHelper.CreateNewAdjustment(objAdjustment, mapAdjustmentAdjustments);
    }
    
    private static void UpdateExistingAdjustemnt(Adjustment__c objAdjustment, map<Id, list<Adjustment__c>> mapAdjustmentAdjustments)
    {
        if(!mapAdjustmentAdjustments.containsKey(objAdjustment.Id))
        {
            mapAdjustmentAdjustments.put(objAdjustment.Id, new list<Adjustment__c>());
        }
        Adjustment__c objNewAdjustment = new Adjustment__c();
        objNewAdjustment.Id = objAdjustment.Id;
        objNewAdjustment.Resolved_Date__c = date.today();
        objNewAdjustment.Status__c = 'Assigned';
        mapAdjustmentAdjustments.get(objAdjustment.Id).add(objNewAdjustment);
    }
    
    private static void CreateNewAdjustment(Adjustment__c objAdjustment, map<id, list<Adjustment__c>> mapAdjustmentAdjustments)
    {
        Adjustment__c objNewAdjustment = new Adjustment__c();
        objNewAdjustment.Date__c = objAdjustment.Date__c;
        objNewAdjustment.Notes__c = objAdjustment.Notes__c;
        objNewAdjustment.Opportunity__c = objAdjustment.Opportunity__c;
        objNewAdjustment.Transaction_Description__c = objAdjustment.Transaction_Description__c;
        objNewAdjustment.Trust_Account__c = objAdjustment.Trust_Account__c;
        objNewAdjustment.Type__c = objAdjustment.Type__c;
        
        objNewAdjustment.Amount__c = objAdjustment.Amount__c - objAdjustment.Transaction_Amount__c;
        objNewAdjustment.Status__c = 'Unassigned';
        
        if(!mapAdjustmentAdjustments.containsKey(objAdjustment.Id))
        {
            mapAdjustmentAdjustments.put(objAdjustment.Id, new list<Adjustment__c>());
        }
        mapAdjustmentAdjustments.get(objAdjustment.Id).add(objNewAdjustment);
    }
    
    public static void AdjustEqualAmountCaseWithTransaction(Adjustment__c objAdjustment, map<id, list<Adjustment__c>> mapAdjustmentAdjustments, map<id, Receipt__c> mapAdjustmentReceipts)
    {
        ohHelper.UpdateExistingAdjustemnt(objAdjustment, mapAdjustmentAdjustments);
        
        Receipt__c objReceipt = new Receipt__c();
        objReceipt.Id = objAdjustment.Transaction__c;
        objReceipt.Reconciled__c = true;
        objReceipt.Date_Reconciled__c = date.today();
        objReceipt.Opportunity__c = objAdjustment.Opportunity__c;
        mapAdjustmentReceipts.put(objAdjustment.Id, objReceipt);
    }
    
    public static void AdjustLessAmountCaseWithTransaction(Adjustment__c objAdjustment, map<id, list<Adjustment__c>> mapAdjustmentAdjustments, map<id, Receipt__c> mapAdjustmentReceipts)
    {
        ohHelper.AdjustEqualAmountCaseWithTransaction(objAdjustment, mapAdjustmentAdjustments, mapAdjustmentReceipts);
        ohHelper.CreateNewAdjustment(objAdjustment, mapAdjustmentAdjustments);
    }
    
    public static void createOrAssignCreditorLedger(List<sObject> objects) {
        List<Creditor_Ledger__c> ledgers = new List<Creditor_Ledger__c>();
        if (objects instanceof List<Product__c>) {
            List<Product__c> products = (List<Product__c>)objects;
            Map<Id, Product__c> solicitorToProductMapping = new Map<Id, Product__c>();
            Map<Id, Product__c> solicitorToProductMapping2 = new Map<Id, Product__c>();
            Map<Id, Id> productToSolicitorMapping = new Map<Id, Id>();
            Set<Id> productKeys = new Set<Id>();
            for (Product__c product : products) {
                if (product.Solicitor__c != null) {
                    productKeys.add(product.Id);
                    solicitorToProductMapping.put(product.Solicitor__c, product);
                    productToSolicitorMapping.put(product.Id, product.Solicitor__c);
                }
            }
            
            if (!productKeys.isEmpty()) {
                for (Product__c product : [SELECT Id
                                           , Solicitor__r.Id
                                           , Project__r.Trust_Account__r.Id
                                           , Project__r.Trust_Account__r.TA_Code__c FROM Product__c WHERE Id IN :productKeys]) {
                	solicitorToProductMapping2.put(productToSolicitorMapping.get(product.Id), product);
                }  
                for (Account solicitor : [SELECT Id, Name, (SELECT Id, Trust_Account__c, Account__c FROM Creditors__r)
                                          FROM Account WHERE Type = 'Solicitor' AND Id IN :solicitorToProductMapping2.keySet()]) {
                	if ((solicitor.Creditors__r).isEmpty()) {
                    	Creditor_Ledger__c ledger = new Creditor_Ledger__c();
                        ledger.Account__c = solicitor.Id;
                        ledger.Trust_Account__c = solicitorToProductMapping2.get(solicitor.Id).Project__r.Trust_Account__r.Id;
                        ledger.Name = solicitor.Name + ' ' + '-' + ' ' + solicitorToProductMapping2.get(solicitor.Id).Project__r.Trust_Account__r.TA_Code__c;
                        ledgers.add(ledger);
                    }                        
                }
            }       
        } else if (objects instanceof List<Project__c>) {
            List<Project__c> projects = (List<Project__c>)objects;
            Map<Id, Project__c> solicitorToProjectMapping = new Map<Id, Project__c>();
            Map<Id, Project__c> solicitorToProjectMapping2 = new Map<Id, Project__c>();
            Map<Id, Id> projectToSolicitorMapping = new Map<Id, Id>();
            Set<Id> projectKeys = new Set<Id>();
            for (Project__c project : projects) {
                if (project.Solicitor__c != null) {
                    projectKeys.add(project.Id);
                    solicitorToProjectMapping.put(project.Solicitor__c, project);
                    projectToSolicitorMapping.put(project.Id, project.Solicitor__c);
                }
            }
            if (!projectKeys.isEmpty()) {
                for (Project__c project : [SELECT Id
                                           		, Solicitor__r.Id
                                          		, Trust_Account__r.Id
                                           		, Trust_Account__r.TA_Code__c FROM Project__c WHERE Id IN :projectKeys]) {
                	solicitorToProjectMapping2.put(projectToSolicitorMapping.get(project.Id), project);
                }
                for (Account solicitor : [SELECT Id, Name, (SELECT Id, Trust_Account__c, Account__c FROM Creditors__r)
                                          FROM Account WHERE Type = 'Solicitor' AND Id IN :solicitorToProjectMapping2.keySet()]) {
                	if ((solicitor.Creditors__r).isEmpty()) {
                    	Creditor_Ledger__c ledger = new Creditor_Ledger__c();
                        ledger.Account__c = solicitor.Id;
                        ledger.Trust_Account__c = solicitorToProjectMapping2.get(solicitor.Id).Trust_Account__r.Id;
                        ledger.Name = solicitor.Name + ' ' + '-' + ' ' + solicitorToProjectMapping2.get(solicitor.Id).Trust_Account__r.TA_Code__c;
                        ledgers.add(ledger);
                    }  	                             
                }
                 
            }
        }
        insert ledgers;
    }
    
    public static List<Receipt__c> reconcileChildJournalTransactions(List<Receipt__c> receipts) {
        //Set<Id> paymentIds = new Set<Id>();
        Map<Id, Receipt__c> receiptsMap = new Map<Id, Receipt__c>();
        List<Receipt__c> journalsToUpdate = new List<Receipt__c>();
        if (receipts != null && !receipts.isEmpty()) {
            for (Receipt__c r : receipts) {
                if (r.RecordTypeId == recordTypes.get('Payment') && r.Reconciled__c) {
                    receiptsMap.put(r.Id, r);
                    //paymentIds.add(r.Id);
                }
            }
         	
            for (Receipt__c journal : [SELECT Id, Reconciled__c, Date_Reconciled__c, RecordTypeId, Bulk_Payment__c
                                       FROM Receipt__c 
                                       WHERE RecordTypeId = :recordTypes.get('Journal') AND Reconciled__c != true AND Bulk_Payment__c IN :receiptsMap.keySet()]) {
            	journal.Reconciled__c = true;
                //journal.Date_Reconciled__c = date.today();
                journal.Date_Reconciled__c = receiptsMap.get(journal.Bulk_Payment__c).Date_Reconciled__c;
                journalsToUpdate.add(journal);
            }
        }
        return journalsToUpdate;
        
    }
    
    /*public static void assignReversingTransaction(List<Receipt__c> txns) {
        List<Receipt__c> relatedTxns = new List<Receipt__c>();
        
        if (txns != null && !txns.isEmpty()) {
            for (Receipt__c r : txns) {
                if (r.RecordTypeId == recordTypes.get('Reverse Receipt') || r.RecordTypeId == recordTypes.get('Reverse Payment')) {
                    if (r.Reversed_Transaction__c != null) {
                        Receipt__c reversed = new Receipt__c(Id = r.Reversed_Transaction__c);
                        reversed.Reversed__c = true;
                        relatedTxns.add(reversed);
                    }
                }
            }    
        }
        
        try {
        	update relatedTxns;
        } catch (Exception e) {
            System.debug('Error in assignReversingTransaction: ' + e.getStackTraceString());
        }
    }*/
    
    public static decimal NormalizeDecimal(decimal input)
    {
        if(input == null)
        {
            return 0;
        }
        return input;
    }
    
    public static string NormalizeLineBreakHTML(string inputHTML)
    {
        if(string.isNotBlank(inputHTML))
        {
            return inputHTML.replace('<br>', '<br />');
        }
        return inputHTML;
    }
    
    public class ApplicationException extends Exception { }
    
}