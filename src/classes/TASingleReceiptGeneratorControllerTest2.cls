@isTest
private class TASingleReceiptGeneratorControllerTest2 {

    static RecordType objRecordTypeOHAccount;
    static RecordType objRecordTypeAccount;
    static RecordType objRecordTypeProduct;
    static RecordType objRecordTypeReceipt;
    static RecordType objRecordTypePayment;
    static RecordType objRecordTypeJournal;

    static list<Receipt__c> listReceipts;
    static list<Receipt__c> listPayments;
    static list<Receipt__c> listJournals;

    static Account objAccount;
    static Account ohAccuont;
    static Trust_Account__c  objTrustAccount;
    static Account objVendorAccount;
    static Bank_Account__c objBankAccount;
    static Project__c objProject;
    static Product__c objProduct;

    static Opportunity objOpportunity;
    static Closing_Balance__c cbo;
    static Closing_Balance__c cbc;
    static Creditor_Ledger__c cl;

    static Receipt__c objReceipt;

    static testMethod void reportGeneratorTest() {
        objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
        objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
        objRecordTypeReceipt = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Receipt'];
        objRecordTypePayment = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Payment'];
        objRecordTypeJournal = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Journal'];

        listReceipts = new list<Receipt__c>();
        listPayments = new list<Receipt__c>();
        listJournals = new list<Receipt__c>();

        List<Account> accs = new List<Account>();

        objAccount = new Account();
        objAccount.FirstName = 'First Name';
        objAccount.LastName = 'Last Name';
        objAccount.RecordTypeId = objRecordTypeAccount.Id;
        //insert objAccount;
        accs.add(objAccount);

        objAccount = new Account();
        objAccount.FirstName = 'First Name';
        objAccount.LastName = 'Last Name';

        objAccount.RecordTypeId = objRecordTypeAccount.Id;
        //insert objAccount;
        accs.add(objAccount);

        ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        //insert ohAccuont;
        accs.add(ohAccuont);

        objVendorAccount = new Account();
        objVendorAccount.Name = 'Test Vendor';
        //insert objVendorAccount;
        accs.add(objVendorAccount);

        insert accs;

system.debug('xx1: '+Limits.getQueries());

    	objTrustAccount = new Trust_Account__c();
        objTrustAccount.Name = 'TestNumberID';
        objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
        insert objTrustAccount;


        objBankAccount = new Bank_Account__c();
        objBankAccount.Account__c = objAccount.Id;
        insert objBankAccount;
        
        objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.Vendor__c = objVendorAccount.id;
        objProject.City__c = 'Test'; 
        objProject.Description__c = 'Sample Description'; 
        objProject.Region__c = 'Melbourne'; 
        objProject.Street_Address__c = '12 Test'; 
        objProject.Zip_Postal_Code__c = 'Victoria';    
        objProject.Status__c = 'Planned';
        insert objProject;
        
        objProduct = new Product__c();
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
        objProduct.Qty_Available__c = 1;
        objProduct.List_Price__c = 2000; 
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
        objProduct.Y_Start__c = 3;       
        
        insert objProduct;

        Product_Assignment__c pa = new Product_Assignment__c();
        pa.Active__c = true;
        pa.Product__c = objProduct.Id;
        insert pa;

system.debug('xx2: '+Limits.getQueries());

        Trust_Account_Receipt_Number__c tarn = new Trust_Account_Receipt_Number__c();
        tarn.TA_Receipt_Number__c = 1000;
        tarn.Trust_Account__c = objTrustAccount.Id;
        insert tarn;
system.debug('xx3: '+Limits.getQueries());

        objOpportunity = new Opportunity();
        objOpportunity.Name = 'Test Opportunity 01';
        objOpportunity.Primary_Product__c = objProduct.id;
        objOpportunity.StageName = 'Prospecting';
        objOpportunity.CloseDate = date.today() + 1;
        objOpportunity.Full_Deposit_Required__c = 500;
        objOpportunity.AccountId = objAccount.Id;
        insert objOpportunity;
system.debug('xx4: '+Limits.getQueries());

        objReceipt = new Receipt__c();
        objReceipt.RecordTypeId = objRecordTypeReceipt.Id;
        objReceipt.Amount__c = 100;
        objReceipt.Date__c = Date.newInstance(2015, 06, 25);
        objReceipt.Received_From__c = 'Test Customer 01';
        objReceipt.Payment_Method__c = 'Credit Card';
        objReceipt.Type__c = 'Receipt';
        objReceipt.Description__c = 'Balance of Deposit';
        objReceipt.Trust_Account__c = objTrustAccount.Id;
        objReceipt.Opportunity__c = objOpportunity.Id;
        objReceipt.Product__c = objProduct.Id;

        insert objReceipt;

system.debug('xx5: '+Limits.getQueries());

		Profile p = [SELECT Id FROM Profile WHERE Name='Sales Administration Manager'];
      	User u = new User(Alias = 'knolan'
                          , Email='k.nolan@oliverhume.com.au'
                          , EmailEncodingKey='UTF-8'
                          , LastName='Nolan'
                          , LanguageLocaleKey='en_US'
                          , LocaleSidKey='en_US'
                          , ProfileId = p.Id
                          , TimeZoneSidKey='America/Los_Angeles'
                          , UserName='k.nolantest@oliverhume.com.au');
        System.runAs(u) {
            Test.startTest();
        	System.assert(TASingleReceiptGeneratorController.generateReceipt(objReceipt.Id) != null);
            Test.stopTest();
        }

    }

}