@isTest
private class createJournalTransactionsExtensionTest {

    static RecordType objRecordTypeOHAccount;
    static RecordType objRecordTypeBusinessAccount;
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
    static Account mblAccount;
    static Trust_Account__c  objTrustAccount;
    static Account objVendorAccount;
    static Bank_Account__c objBankAccount;
    static Project__c objProject;
    static Product__c objProduct;
    
    static Opportunity objOpportunity;
    static Closing_Balance__c cbo;
    static Closing_Balance__c cbc;
    static Creditor_Ledger__c cl;
    
    static TestMethod void testCreateJournalTransactions() {
        objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
        objRecordTypeBusinessAccount = [Select id from RecordType where Name = 'Business Account' and sobjectType='Account' limit 1];
        objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
        objRecordTypeReceipt = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Receipt'];
        objRecordTypePayment = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Payment'];
        objRecordTypeJournal = [Select id from recordtype where sobjecttype = 'Receipt__c' and name = 'Journal'];
        
        listReceipts = new list<Receipt__c>();
        listPayments = new list<Receipt__c>();
        listJournals = new list<Receipt__c>();
            	
        objAccount = new Account();
        objAccount.FirstName = 'First Name';
        objAccount.LastName = 'Last Name';
        objAccount.RecordTypeId = objRecordTypeAccount.Id;
        insert objAccount;
        
        ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        mblAccount = new Account();
        mblAccount.Name = 'MBL';
        mblAccount.RecordTypeId = objRecordTypeBusinessAccount.Id;
        insert mblAccount;
        
        Bank_Account__c ohBank = new Bank_Account__c();
        ohBank.Name = 'Test Bank Account';
        ohBank.BSB_Number__c = '083347';
        ohBank.Bank_Account_Number__c = '140910268';
        ohBank.Bank_Name__c = 'Oliver Hume Real Estate Group Pty Ltd Statutory Trust';
        ohBank.Type__c = 'General';
        ohBank.Account__c = ohAccuont.Id;
        insert ohBank;
        
    	objTrustAccount = new Trust_Account__c();
        objTrustAccount.Bank__c = 'National Australia Bank';
        objTrustAccount.Name = 'Oliver Hume Real Estate Group Pty Ltd Statutory Trust';
        objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
        objTrustAccount.Name_of_Use_Text__c = 'OHREG';
		objTrustAccount.Name_of_Use_Number__c = '110101';
        objTrustAccount.Bank_Account__c = ohBank.Id;
        insert objTrustAccount;
        
        cl = new Creditor_Ledger__c();
        cl.Account__c = objAccount.Id;
        cl.Name = 'Test Creditor Ledger';
        cl.Trust_Account__c = objTrustAccount.Id;
        insert cl;
        
        objVendorAccount = new Account();
        objVendorAccount.Name = 'Test Vendor';
        insert objVendorAccount;
        
        objBankAccount = new Bank_Account__c();
        objBankAccount.Account__c = objAccount.Id;
        objBankAccount.Name = 'Test Bank Account';
        objBankAccount.BSB_Number__c = '083347';
        objBankAccount.Bank_Account_Number__c = '140910268';
        objBankAccount.Bank_Name__c = 'NAB';
        insert objBankAccount;
        
        objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.Vendor__c = objVendorAccount.id;
        objProject.Trust_Account__c = objTrustAccount.Id;
        objProject.OH_Account__c = ohAccuont.Id;
        objProject.Solicitor__c = objAccount.Id;
        objProject.Solicitors_Bank_Account__c = objBankAccount.Id;
        objProject.Solicitors_Payment_Method__c = 'EFT';
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
        objProduct.Size__c = 20;
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
        
        Trust_Account_Receipt_Number__c tarn = new Trust_Account_Receipt_Number__c();
        tarn.TA_Receipt_Number__c = 1000;
        tarn.Trust_Account__c = objTrustAccount.Id;
        insert tarn;
        
        objOpportunity = new Opportunity();
        objOpportunity.Name = 'Test Opportunity 01';
        objOpportunity.Primary_Product__c = objProduct.id;
        objOpportunity.StageName = 'Prospecting';
        objOpportunity.CloseDate = date.today() + 1;
        objOpportunity.Full_Deposit_Required__c = 10000;
        objOpportunity.AccountId = objAccount.Id;
        objOpportunity.Amount = 300000;
        insert objOpportunity;
        
        Receipt__c r = new Receipt__c(RecordTypeId = objRecordTypeReceipt.Id, Date__c = date.today(), Received_From__c = 'Test Client 1', Payment_Method__c = 'EFT', Description__c = 'Initial Deposit'
                                    , Trust_Account__c = objTrustAccount.Id, Bank_Account__c = ohBank.Id, Opportunity__c = objOpportunity.Id, Amount__c = 1000, Product__c = objProduct.Id, Customer_Ref__c = 'a b c', Reconciled__c = true, Date_Reconciled__c =  date.today());
        insert r;
        
        List<Opportunity> opps = new List<Opportunity>();
        opps.add(objOpportunity);
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(opps);
        sc.setSelected(opps);
        createJournalTransactionsExtension controller = new createJournalTransactionsExtension(sc);
        controller.process();
        System.assertEquals(1, controller.opportunitiesSize);
        if (!controller.receipts.isEmpty()) {
            for (Trust_Account__c ta : controller.receipts.keySet()) {
                List<createJournalTransactionsExtension.ReceiptWrapper> rws = controller.receipts.get(ta);
                for (createJournalTransactionsExtension.ReceiptWrapper rw : rws) {
                    //rw.getJournal_amount();
                    rw.journal_amount = 500;
                    rw.setChecked(true);
                    if (rw.ohJournalTransfer != null) {
                        rw.ohJournalTransfer.setChecked(true);
                    }
                }
            }
        }
		        
        controller.generatePayments();
        
        System.assert(controller.transactionsSize > 0);
        
        if (!controller.transactions2.isEmpty()) {
            for (createJournalTransactionsExtension.TrustAccountWrapper ta : controller.transactions2.keySet()) {
                ta.abaReference = 'ABAREFERENCE';
                System.assert(ta.getTotalJournalAmount() != null);
                System.assert(ta.getTotalChequeAmount() != null);
                System.assert(ta.getTotalEftAmount() != null);
                
                List<createJournalTransactionsExtension.PaymentWrapper> pws = controller.transactions2.get(ta);
                for (createJournalTransactionsExtension.PaymentWrapper pw : pws) {
                    pw.getPayment();
                    pw.setChecked(true);
                    pw.reference = 'SampleReference';
                    pw.paymentMethod = 'EFT';
                    System.assert(pw.getPaymentMethods() != null);
                }
            }
        }
        
        Test.startTest();
        controller.create();
        System.assert(controller.abaPreviews != null);
        
        controller.generateAccountSales();
        Test.stopTest();
        
        System.assertEquals('3 Closing Balance records have been created:\n\n1 Trust Account Closing Balance Record\n1 Creditor Ledger Closing Balance Record(s)\n1 Opportunity Closing Balance Record(s)\n\n', ClosingBalanceController.createClosingBalance(objTrustAccount.Id, Date.today(), false));
        
    }    
        
}