@isTest
private class receiptTriggerTest {

    static list<Receipt__c> GenerateTestReceipts() 
    {
        list<Receipt__c> listReceipts = new list<Receipt__c>();
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs ( objCurrentUser ) 
        {
            RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
            RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
            Profile objProfile = [Select Id from Profile where name = 'System Administrator' limit 1];
            UserRole objUserRole = [Select Id From UserRole Where Name = 'Sales Administration'];
            
            list<Product__c> listProduct = new list<Product__c>();
            
            if(objRecordTypeAccount != null && objRecordTypeProduct != null && objProfile != null && objUserRole != null)
            {
                User objUser1 = new User();
                objUser1.Username= 'test@oliverhume.com.au';
                objUser1.Email = 'test@oliverhume.com.au';
                objUser1.Lastname = 'Hume';
                objUser1.Firstname = 'Oliver';
                objUser1.Alias = 'oHume';
                objUser1.CommunityNickname = 'oHume01';
                objUser1.TimeZoneSidKey = 'GMT';
                objUser1.LocaleSidKey = 'en_US';
                objUser1.EmailEncodingKey = 'ISO-8859-1';
                objUser1.LanguageLocaleKey = 'en_US';
                objUser1.ProfileId = objProfile.Id;
                objUser1.UserRoleId = objUserRole.Id;
                insert objUser1;
                
                Project__c objProject = new Project__c();
                objProject.Name = 'Test Project';
                objProject.City__c = 'Test'; 
                objProject.Description__c = 'Sample Description'; 
                objProject.Region__c = 'Melbourne'; 
                objProject.Street_Address__c = '12 Test'; 
                objProject.Zip_Postal_Code__c = 'Victoria';    
                objProject.Status__c = 'Planned';
                insert objProject;
                
                Account solAccount = new Account(Name = 'Test Solicitor Account');
                insert SolAccount;
                Bank_Account__c solBank = new Bank_Account__c(Name = 'Sol Bank Account', Bank_Account_Number__c = '12345678', BSB_Number__c = '123123', Bank_Name__c = 'Test Bank');
                insert solBank;
                
                for(integer counter = 0; counter < 2; counter++)
                {
                    Product__c objProduct = new Product__c();
                    objProduct.Name = 'Product 00' + counter;
                    objProduct.Project__c = objProject.Id;
                    objProduct.Type__c = 'Apartment';
                    objProduct.RecordTypeId = objRecordTypeProduct.Id;
                    objProduct.Street_Name__c = 'Test Street ' + counter;
                    objProduct.Stage_Number__c = '03';
                    objProduct.Size__c = 200;
                    objProduct.Solicitor__c = solAccount.Id;
                    objProduct.Solicitors_Bank_Account__c = solBank.Id;
                    objProduct.Solicitors_Payment_Method__c = 'EFT';
                    objProduct.Qty_Available__c =1;
                    objProduct.List_Price__c = 2000; 
                    objProduct.Bdr__c = '1'; 
                    objProduct.Bth__c = '1'; 
                    objProduct.Car_Parks__c = '1'; 
                    objProduct.Description__c = 'Test this'; 
                    objProduct.Features__c = 'Stainless Steel'; 
                    objProduct.Study__c = '0';
                    objProduct.Level__c = '4'; 
                    objProduct.Orientation__c = 'N';
                    objProduct.Size__c = 20;
                    objProduct.Viewline__c = 'Sea'; 
                    objProduct.X_End__c = 2; 
                    objProduct.X_Start__c = 3; 
                    objProduct.Y_End__c = 2; 
                    objProduct.Y_Start__c = 3;
                    listProduct.add(objProduct);
                }
                insert listProduct;
                
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
                objOpportunity.Full_Deposit_Required__c = 50000;
                objOpportunity.AccountId = objAccount.Id;
                insert objOpportunity;
                
                Trust_Account__c objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
                insert objTrustAccount;
                
                Receipt__c objReceipt;
                for(integer counter = 0; counter < 4; counter++)
                {
                    objReceipt = new Receipt__c();
                    objReceipt.Amount__c = 10000;
                    objReceipt.Date__c = date.today();
                    objReceipt.Received_From__c = 'Test Customer 01';
                    objReceipt.Payment_Method__c = 'Credit Card';
                    objReceipt.Type__c = 'Receipt';
                    objReceipt.Description__c = 'Balance of Deposit';
                    objReceipt.Trust_Account__c = objTrustAccount.Id;
                    objReceipt.Opportunity__c = objOpportunity.Id;
                    objReceipt.Product__c = listProduct[counter/2].Id;
                    objReceipt.Manager_Override__c = true;
                    listReceipts.add(objReceipt);
                }
            }
        }
        return listReceipts;
    }

    static TestMethod void CheckLedgerNumbers()
    {
        list<Receipt__c> listReceipts = receiptTriggerTest.GenerateTestReceipts();
        insert listReceipts;
        
        listReceipts = [Select Id, Opportunity__c, Trust_Account__c From Receipt__c Where Id =: listReceipts];
        Opportunity objOpportunity = [Select Id, Ledger_Number__c From Opportunity Where Id =: listReceipts[0].Opportunity__c];
        Trust_Account__c objTrustAccount = [Select Id, Ledger_Number__c From Trust_Account__c Where Id =: listReceipts[0].Trust_Account__c];
        system.assertEquals('1', objOpportunity.Ledger_Number__c);
        system.assertEquals(1, objTrustAccount.Ledger_Number__c);
    }
    
    static TestMethod void CheckLedgerBalance()
    {
        list<Receipt__c> listReceipts = receiptTriggerTest.GenerateTestReceipts();
        insert listReceipts;
        
        listReceipts[0].Type__c = 'Payment';
        listReceipts[0].Description__c = 'Refund Collection';
        listReceipts[0].Amount__c = 5000;
        update listReceipts;
        
        //Task objTask = [Select Id From Task where Subject = 'Ledger Balance is less than zero' limit 1];
        //system.assertNotEquals(null, objTask);
    }
    
    static TestMethod void CheckDepositBalance()
    {
        list<Receipt__c> listReceipts = receiptTriggerTest.GenerateTestReceipts();
        //add a receipt that isn't deposit.
        Receipt__c newReceipt = new Receipt__c();
        newReceipt.Reconciled__c = true;
        newReceipt.Type__c = 'Receipt';
        newReceipt.Description__c = 'Miscellaneous';
        newReceipt.Manager_Override__c = true;
        newReceipt.Amount__c = 10000;
        newReceipt.Opportunity__c = listReceipts[0].Opportunity__c;
        newReceipt.Date__c = date.today();
        newReceipt.Received_From__c = 'Test Customer 01';
        newReceipt.Payment_Method__c = 'Credit Card';
        newReceipt.Product__c = listReceipts[0].Product__c;
        newReceipt.Trust_Account__c = listReceipts[0].Trust_Account__c;
        newReceipt.Reconciled__c = true;
        newReceipt.Date_Reconciled__c = Date.today();
        listReceipts.add(newReceipt);
        insert listReceipts;
        
        Receipt__c newPayment = new Receipt__c();
        newPayment.Type__c = 'Payment';
        newPayment.Description__c = 'Journal into Sales Ledger';
        newPayment.Manager_Override__c = true;
        newPayment.Amount__c = 5000;
        newPayment.Opportunity__c = listReceipts[0].Opportunity__c;
        newPayment.Date__c = date.today();
        newPayment.Received_From__c = 'Test Customer 01';
        newPayment.Payment_Method__c = 'Credit Card';
        newPayment.Product__c = listReceipts[0].Product__c;
        newPayment.Trust_Account__c = listReceipts[0].Trust_Account__c;
        
        
        insert newPayment;
        //Task objTask = [Select Id From Task where Subject = 'Deposit Balance is less than zero' limit 1];
        //system.assertNotEquals(null, objTask);
    }
    
    static TestMethod void CheckReverseTransaction()
    {
        list<Receipt__c> listReceipts = receiptTriggerTest.GenerateTestReceipts();
        insert listReceipts;
        
        listReceipts[0].Type__c = 'Payment';
        listReceipts[0].Description__c = 'Reverse Receipt';
        listReceipts[0].Amount__c = 5000;
        update listReceipts;
        
        //Task objTask = [Select Id From Task where Subject = 'Trust Account Receipt to be returned' limit 1];
        //system.assertNotEquals(null, objTask);
    }
    
    static TestMethod void CheckRunningBalance()
    {
        list<Receipt__c> listReceipts = receiptTriggerTest.GenerateTestReceipts();
        
        listReceipts[0].Reconciled__c = true;
        listReceipts[0].Date_Reconciled__c = date.today();
        listReceipts[0].Description__c = 'Full Deposit - Build';
        
        listReceipts[1].Reconciled__c = true;
        listReceipts[1].Date_Reconciled__c = date.today();
        listReceipts[1].Description__c = 'Further Deposit - Build';
        
        listReceipts[2].Reconciled__c = true;
        listReceipts[2].Date_Reconciled__c = date.today();
        listReceipts[2].Description__c = 'Initial Deposit';
        
        listReceipts[3].Reconciled__c = true;
        listReceipts[3].Date_Reconciled__c = date.today() - 1;
        listReceipts[3].Description__c = 'Initial Deposit';
        
        insert listReceipts;
        
        list<Receipt__c> listUpdatedReceipts = [Select Id, Ledger_Balance__c From Receipt__c Where Id =: listReceipts];
        System.assertEquals(4, listUpdatedReceipts.size());
        for(Receipt__c objReceipt : listUpdatedReceipts)
        {
            if(objReceipt.Id == listReceipts[0].Id)
            {
                system.assertEquals(30000, objReceipt.Ledger_Balance__c);
                //system.assertEquals(0, objReceipt.Ledger_Balance__c);
            }
            else if(objReceipt.Id == listReceipts[1].Id)
            {
                system.assertEquals(40000, objReceipt.Ledger_Balance__c);
                //system.assertEquals(0, objReceipt.Ledger_Balance__c);
            }
            else if(objReceipt.Id == listReceipts[2].Id)
            {
                system.assertEquals(20000, objReceipt.Ledger_Balance__c);
                //system.assertEquals(0, objReceipt.Ledger_Balance__c);
            }
            else if(objReceipt.Id == listReceipts[3].Id)
            {
                system.assertEquals(10000, objReceipt.Ledger_Balance__c);
                //system.assertEquals(0, objReceipt.Ledger_Balance__c);
            }
            else
            {
                system.assert(false);
            }
        }
    }
    
}