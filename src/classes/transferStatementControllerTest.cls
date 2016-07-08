@isTest
private class transferStatementControllerTest 
{
    static testMethod void myUnitTest() 
    {
        list<Journal__c> listJournals = new list<Journal__c>();
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs (objCurrentUser) 
        {
            RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
            RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
            
            if(objRecordTypeAccount != null && objRecordTypeProduct != null)
            {
                list<Receipt__c> listReceipts = new list<Receipt__c>();
                
                Account objAccount = new Account();
                objAccount.FirstName = 'First Name';
                objAccount.LastName = 'Last Name';
                objAccount.RecordTypeId = objRecordTypeAccount.Id;
                insert objAccount;
                
                RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
            
				Account ohAccuont = new Account();
                ohAccuont.Name = 'Oliver Hume';
                ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
                insert ohAccuont;
                
                Opportunity objOpportunity = new Opportunity();
                objOpportunity.Name = 'Test Opportunity 01';
                objOpportunity.StageName = 'Prospecting';
                objOpportunity.CloseDate = date.today() + 1;
                objOpportunity.Full_Deposit_Required__c = 500;
                objOpportunity.AccountId = objAccount.Id;
                insert objOpportunity;
                
                Trust_Account__c  objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
                insert objTrustAccount;
                
                Bank_Account__c objBankAccount = new Bank_Account__c();
                objBankAccount.Account__c = objAccount.Id;
                insert objBankAccount;
                
                Project__c objProject = new Project__c();
                objProject.Name = 'Test Project';
                objProject.City__c = 'Test'; 
                objProject.Description__c = 'Sample Description'; 
                objProject.Region__c = 'Melbourne'; 
                objProject.Street_Address__c = '12 Test'; 
                objProject.Zip_Postal_Code__c = 'Victoria';    
                objProject.Status__c = 'Planned';
                insert objProject;
                
                Product__c objProduct = new Product__c();
                objProduct.Name = 'Product 00';
                objProduct.Project__c = objProject.Id;
                objProduct.Type__c = 'Apartment';
                objProduct.RecordTypeId = objRecordTypeProduct.Id;
                objProduct.Street_Name__c = 'Test Street ';
                objProduct.Stage_Number__c = '333';
                objProduct.Size__c = 200;
                objProduct.Solicitor__c = objAccount.Id;
                objProduct.Solicitors_Bank_Account__c = objBankAccount.Id;
                objProduct.Solicitors_Payment_Method__c = 'EFT';
                objProduct.Qty_Available__c  =1;
                objProduct.Bdr__c = '1'; 
                objProduct.Bth__c = '1'; 
                objProduct.Car_Parks__c = '1'; 
                objProduct.Description__c = 'Test this'; 
                objProduct.Features__c = 'Stainless Steel'; 
                objProduct.Study__c = '0';
                objProduct.Level__c = '4'; 
                objProduct.Orientation__c = 'N';
                objProduct.Viewline__c = 'Sea'; 
                objProduct.X_End__c = 2; 
                objProduct.X_Start__c = 3; 
                objProduct.Y_End__c = 2; 
                objProduct.Y_Start__c = 3 ;  
                objProduct.List_Price__c = 200;  
                insert objProduct;
                
                list<Cheque__c> listCheques = new list<Cheque__c>();
                
                for(integer counter = 0; counter < 5; counter++)
                {
                    Cheque__c objCheque = new Cheque__c();
                    objCheque.Bank_Account__c = objBankAccount.Id;
                    listCheques.add(objCheque);
                }
                insert listCheques;
                
                for(integer counter = 0; counter < 2; counter++)
                {
                    Journal__c objJournal = new Journal__c();
                    objJournal.Cheque_Number__c = listCheques[counter].Id;
                    objJournal.Bank_Account__c = objBankAccount.Id;
                    objJournal.Trust_Account__c = objTrustAccount.Id;
                    objJournal.Amount__c = 123456.99;
                    listJournals.add(objJournal);
                }
                insert listJournals;
                
                for(integer counter = 0; counter < 6; counter++)
                {
                    Receipt__c objReceipt = new Receipt__c();
                    objReceipt.Amount__c = 100;
                    objReceipt.Date__c = date.today();
                    objReceipt.Received_From__c = 'Test Customer 01';
                    objReceipt.Payment_Method__c = 'Credit Card';
                    objReceipt.Type__c = 'Receipt';
                    objReceipt.Description__c = 'Balance of Deposit';
                    objReceipt.Trust_Account__c = objTrustAccount.Id;
                    objReceipt.Opportunity__c = objOpportunity.Id;
                    objReceipt.Product__c = objProduct.Id;
                    objReceipt.Journal__c = listJournals[counter/3].Id;
                    listReceipts.add(objReceipt);
                }
                insert listReceipts;
            }
        }

        
        string journalIds = '';
        for(Journal__c objJournal : listJournals)
        {
            journalIds += objJournal.Id + ',';
        }
        
        test.setCurrentPageReference(new PageReference('/apex/transferStatementVfp')); 
        System.currentPageReference().getParameters().put('journalIds', journalIds);
        
        transferStatementController objTransferStatementController = new transferStatementController();
        system.assertEquals(2, objTransferStatementController.listCustomJournals.size());
        system.assertEquals(3, objTransferStatementController.listCustomJournals[0].listCustomReceipts.size());
    }
}