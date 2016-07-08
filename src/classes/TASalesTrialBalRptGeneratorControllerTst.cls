@isTest
public class TASalesTrialBalRptGeneratorControllerTst{

	 static {
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
        RecordType objRecordTypeReceipt = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Receipt'];
        RecordType objRecordTypePayment = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Payment'];
        RecordType objRecordTypeJournal = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Journal'];

        List<Receipt__c> listReceipts = new list<Receipt__c>();
        List<Receipt__c> listPayments = new list<Receipt__c>();
        List<Receipt__c> listJournals = new list<Receipt__c>();

        List<Account> accs = new List<Account>();

        Account objAccount = new Account();
        objAccount.FirstName = 'First Name';
        objAccount.LastName = 'Last Name';
        objAccount.RecordTypeId = objRecordTypeAccount.Id;
        //insert objAccount;
        accs.add(objAccount);

        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        //insert ohAccuont;
        accs.add(ohAccuont);

        Account objVendorAccount = new Account();
        objVendorAccount.Name = 'Test Vendor';
        objVendorAccount.BillingStreet = 'Test Street'; 
        objVendorAccount.BillingCity = 'Test City'; 
        objVendorAccount.BillingState = 'VIC'; 
        objVendorAccount.BillingPostalCode = '2222'; 
        //insert objVendorAccount;
        accs.add(objVendorAccount);
        insert accs;

    	Trust_Account__c objTrustAccount = new Trust_Account__c();
        objTrustAccount.Name = 'TestNumberID';
        objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
        insert objTrustAccount;



        Bank_Account__c objBankAccount = new Bank_Account__c();
        objBankAccount.Account__c = objAccount.Id;
        insert objBankAccount;

        Project__c objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.Vendor__c = objVendorAccount.id;
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

        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'Test Opportunity 01';
        objOpportunity.Primary_Product__c = objProduct.id;
        objOpportunity.StageName = 'Prospecting';
        objOpportunity.CloseDate = date.today() + 1;
        objOpportunity.Full_Deposit_Required__c = 500;
        objOpportunity.AccountId = objAccount.Id;
        insert objOpportunity;

        Creditor_Ledger__c cl = new Creditor_Ledger__c();
        cl.Name = 'Test SOL';
        cl.Trust_Account__c = objTrustAccount.Id;
        insert cl;

        for(integer counter = 0; counter < 3; counter++) {
            Receipt__c objReceipt = new Receipt__c();
            objReceipt.RecordTypeId = objRecordTypeReceipt.Id;
            objReceipt.Amount__c = 100;
            objReceipt.Date__c = Date.today();
            objReceipt.Received_From__c = 'Test Customer 01';
            objReceipt.Payment_Method__c = 'Credit Card';
            objReceipt.Type__c = 'Receipt';
            objReceipt.Description__c = 'Journal to Creditor Ledger';
            objReceipt.Trust_Account__c = objTrustAccount.Id;
            objReceipt.Opportunity__c = objOpportunity.Id;
            objReceipt.Product__c = objProduct.Id;
            objReceipt.Reconciled__c = true;
            objReceipt.Date_Reconciled__c = Date.today();
            objReceipt.X3rd_Party_Transaction__c = false;
            listReceipts.add(objReceipt);
        }
        //insert listReceipts;

        for(integer counter = 0; counter < 3; counter++) {
            Receipt__c objReceipt = new Receipt__c();
            objReceipt.RecordTypeId = objRecordTypePayment.Id;
            objReceipt.Manager_Override__c = true;
            objReceipt.Amount__c = 100;
            objReceipt.Creditor__c = cl.Id;
            objReceipt.Date__c = Date.today();
            objReceipt.Received_From__c = 'Test Customer 01';
            objReceipt.Payment_Method__c = 'Credit Card';
            objReceipt.Type__c = 'Payment';
            objReceipt.Description__c = 'Journal to Creditor Ledger';
            objReceipt.Trust_Account__c = objTrustAccount.Id;
            objReceipt.Opportunity__c = objOpportunity.Id;
            objReceipt.Product__c = objProduct.Id;
            objReceipt.X3rd_Party_Transaction__c = false;
            listPayments.add(objReceipt);
        }
        //insert listPayments;
        List<Receipt__c> receipts = new List<Receipt__c>();
        receipts.addAll(listReceipts);
        receipts.addAll(listPayments);
        insert receipts;

        Closing_Balance__c cbo = new Closing_Balance__c();
        cbo.name = 'Closing Balance June-2015 - Test - Test Project - Product 00 - TestNumberID';
        cbo.Closing_Balance__c = 1000.00;
        cbo.Date__c = Date.today();
        cbo.Trust_Account_Ledger__c = objTrustAccount.Id;
        cbo.Opportunity_Ledger__c = objOpportunity.Id;
        insert cbo;

        Closing_Balance__c cbc = new Closing_Balance__c();
        cbc.name = 'Closing Balance June-2015 - Test - Test Project - Product 00 - TestNumberID';
        cbc.Closing_Balance__c = 1000.00;
        cbc.Creditor_Ledger__c = cl.Id;
        cbc.Date__c = Date.today();
        cbc.Trust_Account_Ledger__c = objTrustAccount.Id;
        insert cbc;

    }

    static testMethod void testSalesTrialBalanceReport() {
    	Trust_Account__c trustAcc = [SELECT Id FROM Trust_Account__c limit 1]; 
        TASalesTrialBalRptGeneratorController saleTrialBalance = new TASalesTrialBalRptGeneratorController();
        Test.setCurrentPage(Page.trustAccountSalesTrialBalance);
        ApexPages.currentPage().getParameters().put('id', trustAcc.id);
        ApexPages.currentPage().getParameters().put('m', String.valueOf(Date.today().month()));
        ApexPages.currentPage().getParameters().put('y', String.valueOf(Date.today().year()));

        System.assert(saleTrialBalance.generateSalesTrialBalance() == null);
        System.assert(saleTrialBalance.saleTrialBalanceEntries2 != null);
        System.assert(saleTrialBalance.reportTotalOpening != null);
        System.assert(saleTrialBalance.reportTotalClosing != null);
        System.assert(saleTrialBalance.reportTotalCredits != null);
        System.assert(saleTrialBalance.reportTotalDebits != null);
	}
}