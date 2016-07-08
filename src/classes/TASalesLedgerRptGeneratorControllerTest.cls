@isTest
public class TASalesLedgerRptGeneratorControllerTest {


	static testMethod void sanitizePositiveTest() {
		String sanitizedStr = null;
		TASalesLedgerRptGeneratorController reportGen = new TASalesLedgerRptGeneratorController(); 
		String emptyString = reportGen.sanitize(sanitizedStr); 
		system.assert(String.isEmpty(emptyString)); 
	}

	static testMethod void salesLedgerRecordWrapperPositiveTest() {
		List<Account> accs = TestData.createAccounts(1); 
		RecordType rtypeOpp = UtilClass.orgRecordTypeMap.get('opportunity_apartments'); 
		List<Opportunity> opps = TestData.createOpportunities(1, rtypeOpp.Id, accs[0].Id); 

		Account ohAccount = new Account();
                ohAccount.Name = 'Oliver Hume';
                ohAccount.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_oliver_hume_account').Id; 
                insert ohAccount;

                Trust_Account__c objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccount.Id;
                insert objTrustAccount;

        		Receipt__c objReceipt = new Receipt__c();
                objReceipt.RecordTypeId = UtilClass.orgRecordTypeMap.get('receipt__c_receipt').Id;
                objReceipt.Amount__c = 1000;
                objReceipt.Date__c = Date.newInstance(2015, 06, 25);
                objReceipt.Received_From__c = 'Test Customer 01';
                objReceipt.Payment_Method__c = 'Credit Card';
                objReceipt.Type__c = 'Receipt';
                objReceipt.Description__c = 'Balance of Deposit';
                objReceipt.Trust_Account__c = objTrustAccount.Id;
                objReceipt.Opportunity__c = opps[0].Id;
                //objReceipt.Product__c = objProduct.Id;
                objReceipt.Reconciled__c = true;
                objReceipt.Date_Reconciled__c = Date.newInstance(2015, 06, 25);
                objReceipt.X3rd_Party_Transaction__c = false;
                insert objReceipt; 

               

                TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper wrapper = new TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper(); 
                wrapper.Balance = 1000; 
                wrapper.ledgerEntry = objReceipt; 
                wrapper.typeChar = 'P'; 
                wrapper.id = 0; 

                TASalesLedgerRptGeneratorController reportGen = new TASalesLedgerRptGeneratorController(); 
		TASalesLedgerRptGeneratorController.SalesLedgerEntry entry = new TASalesLedgerRptGeneratorController.SalesLedgerEntry(); 
		entry.opportunityId = opps[0].Id; 
		entry.opportunityName = opps[0].Name; 
		entry.openingBalance = 2000; 
		entry.salesLedgerRecordsForPayments = new List<TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper>{wrapper};

		Test.startTest(); 
                List<TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper> theTransactions = entry.transactions; 
                system.assert(!theTransactions.isEmpty()); 
		Test.stopTest();  

	}

	/*static testMethod void compareToPositiveTest() {
		List<Account> accs = TestData.createAccounts(1); 
		RecordType rtypeOpp = UtilClass.orgRecordTypeMap.get('opportunity_apartments'); 
		List<Opportunity> opps = TestData.createOpportunities(1, rtypeOpp.Id, accs[0].Id); 

		Account ohAccount = new Account();
                ohAccount.Name = 'Oliver Hume';
                ohAccount.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_oliver_hume_account').Id; 
                insert ohAccount;

                Trust_Account__c objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccount.Id;
                insert objTrustAccount;

        		Receipt__c objReceipt = new Receipt__c();
                objReceipt.RecordTypeId = UtilClass.orgRecordTypeMap.get('receipt__c_receipt').Id;
                objReceipt.Amount__c = 1000;
                objReceipt.Date__c = Date.newInstance(2015, 06, 25);
                objReceipt.Received_From__c = 'Test Customer 01';
                objReceipt.Payment_Method__c = 'Credit Card';
                objReceipt.Type__c = 'Receipt';
                objReceipt.Description__c = 'Balance of Deposit';
                objReceipt.Trust_Account__c = objTrustAccount.Id;
                objReceipt.Opportunity__c = opps[0].Id;
                //objReceipt.Product__c = objProduct.Id;
                objReceipt.Reconciled__c = true;
                objReceipt.Date_Reconciled__c = Date.newInstance(2015, 06, 25);
                objReceipt.X3rd_Party_Transaction__c = false;
                insert objReceipt; 

               

                TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper wrapper = new TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper(); 
                wrapper.Balance = 1000; 
                wrapper.ledgerEntry = objReceipt; 
                wrapper.typeChar = 'P'; 
                wrapper.id = 0; 

                TASalesLedgerRptGeneratorController reportGen = new TASalesLedgerRptGeneratorController(); 
                List<TASalesLedgerRptGeneratorController.SalesLedgerEntry> entries = new List<TASalesLedgerRptGeneratorController.SalesLedgerEntry>(); 

		TASalesLedgerRptGeneratorController.SalesLedgerEntry entry = new TASalesLedgerRptGeneratorController.SalesLedgerEntry(); 
		entry.opportunityId = opps[0].Id; 
		entry.opportunityName = opps[0].Name; 
		entry.openingBalance = 2000; 
		entry.salesLedgerRecordsForPayments = new List<TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper>{wrapper};
		entries.add(entry); 

		TASalesLedgerRptGeneratorController.SalesLedgerEntry entry2 = new TASalesLedgerRptGeneratorController.SalesLedgerEntry(); 
		entry2.opportunityId = opps[0].Id; 
		entry2.opportunityName = 'Entry 2'; 
		entry2.openingBalance = 2000; 
		entry2.salesLedgerRecordsForPayments = new List<TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper>{wrapper};
		entries.add(entry2); 

		Test.startTest(); 
                entries.sort(); 
		Test.stopTest();  

	}*/ 

        //jh - in future this could get moved into the testdata factory cls
        static void createTestData() {
                List<Account> accs = new List<Account>(); 
                Account objAccount = new Account();
                objAccount.FirstName = 'First Name';
                objAccount.LastName = 'Last Name';
                objAccount.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_personaccount').Id;
                //insert objAccount;
                accs.add(objAccount);

                Account ohAccuont = new Account();
                ohAccuont.Name = 'Oliver Hume';
                ohAccuont.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_oliver_hume_account').Id;
                //insert ohAccuont;
                accs.add(ohAccuont);

                Account objVendorAccount = new Account();
                objVendorAccount.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_vendor_account').Id; 
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
                objProduct.RecordTypeId = UtilClass.orgRecordTypeMap.get('product__c_apartment').Id;
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

                List<Receipt__c> receipts = new List<Receipt__c>(); 
                Receipt__c objReceipt = new Receipt__c();
                objReceipt.RecordTypeId = UtilClass.orgRecordTypeMap.get('receipt__c_journal').Id;
                objReceipt.Amount__c = 100;
                objReceipt.Date__c = Date.today();
                objReceipt.Received_From__c = 'Test Customer 01';
                objReceipt.Payment_Method__c = 'Credit Card';
                objReceipt.Type__c = 'Receipt';
                objReceipt.Description__c = 'Journal out of OH Creditor Ledger';
                objReceipt.Trust_Account__c = objTrustAccount.Id;
                objReceipt.Opportunity__c = objOpportunity.Id;
                objReceipt.Product__c = objProduct.Id;
                objReceipt.Reconciled__c = true;
                objReceipt.Date_Reconciled__c = Date.today();
                objReceipt.X3rd_Party_Transaction__c = false;
                objReceipt.Date_Reconciled__c = Date.today(); 
                receipts.add(objReceipt); 

                Receipt__c payment = new Receipt__c();
                payment.RecordTypeId = UtilClass.orgRecordTypeMap.get('receipt__c_reverse_receipt').Id;
                payment.Amount__c = 100;
                payment.Date__c = Date.today();
                payment.Received_From__c = 'Test Customer 01';
                payment.Payment_Method__c = 'Credit Card';
                payment.Type__c = 'Receipt';
                payment.Description__c = 'Journal out of OH Creditor Ledger';
                payment.Trust_Account__c = objTrustAccount.Id;
                payment.Opportunity__c = objOpportunity.Id;
                payment.Product__c = objProduct.Id;
                payment.Reconciled__c = true;
                payment.Date_Reconciled__c = Date.today();
                payment.X3rd_Party_Transaction__c = false;
                payment.Date_Reconciled__c = Date.today(); 
                receipts.add(payment); 

                insert receipts; 

                Creditor_Ledger__c cl = new Creditor_Ledger__c();
                cl.Name = 'Test SOL';
                cl.Trust_Account__c = objTrustAccount.Id;
                insert cl;
        }

        //jh these classes really confuse me at first glance they seem to be the same but both are in use.. 
        static testMethod void generateSalesLedgerPositiveTest() {
                createTestData(); 
                Opportunity opp = [SELECT Id FROM Opportunity limit 1]; 

                Test.startTest(); 
                ApexPages.currentPage().getParameters().put('id', opp.Id);
                ApexPages.currentPage().getParameters().put('m', String.valueOf(Date.today().month())); 
                ApexPages.currentPage().getParameters().put('y',String.valueOf(Date.today().year()));

                SaleLedgerRptGeneratorController controllerSub = new SaleLedgerRptGeneratorController();
                System.assert(controllerSub.generateSalesLedger() == null);
                Test.stopTest(); 

        }

        static testMethod void generateTASalesLedgerPositiveTest() {
                createTestData(); 
                Opportunity opp = [SELECT Id FROM Opportunity limit 1]; 
                Trust_Account__c trustAcc = [SELECT Id FROM Trust_Account__c limit 1]; 

                Test.startTest(); 
                ApexPages.currentPage().getParameters().put('id', trustAcc.Id);
                ApexPages.currentPage().getParameters().put('m', String.valueOf(Date.today().month())); 
                ApexPages.currentPage().getParameters().put('y',String.valueOf(Date.today().year()));

                TASalesLedgerRptGeneratorController controllerSub = new TASalesLedgerRptGeneratorController();
                System.assert(controllerSub.generateSalesLedger() == null);
                Test.stopTest(); 

        }

        static testMethod void TAsalesLedgerRecordWrapperPositiveTest() {
                List<Account> accs = TestData.createAccounts(1); 
                RecordType rtypeOpp = UtilClass.orgRecordTypeMap.get('opportunity_apartments'); 
                List<Opportunity> opps = TestData.createOpportunities(1, rtypeOpp.Id, accs[0].Id); 

                Account ohAccount = new Account();
                ohAccount.Name = 'Oliver Hume';
                ohAccount.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_oliver_hume_account').Id; 
                insert ohAccount;

                Trust_Account__c objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccount.Id;
                insert objTrustAccount;

                Receipt__c objReceipt = new Receipt__c();
                objReceipt.RecordTypeId = UtilClass.orgRecordTypeMap.get('receipt__c_receipt').Id;
                objReceipt.Amount__c = 1000;
                objReceipt.Date__c = Date.newInstance(2015, 06, 25);
                objReceipt.Received_From__c = 'Test Customer 01';
                objReceipt.Payment_Method__c = 'Credit Card';
                objReceipt.Type__c = 'Receipt';
                objReceipt.Description__c = 'Balance of Deposit';
                objReceipt.Trust_Account__c = objTrustAccount.Id;
                objReceipt.Opportunity__c = opps[0].Id;
                //objReceipt.Product__c = objProduct.Id;
                objReceipt.Reconciled__c = true;
                objReceipt.Date_Reconciled__c = Date.newInstance(2015, 06, 25);
                objReceipt.X3rd_Party_Transaction__c = false;
                insert objReceipt; 

                TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper wrapper = new TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper(); 
                wrapper.Balance = 1000; 
                wrapper.ledgerEntry = objReceipt; 
                wrapper.typeChar = 'P'; 
                wrapper.id = 0; 

                TASalesLedgerRptGeneratorController reportGen = new TASalesLedgerRptGeneratorController(); 
                TASalesLedgerRptGeneratorController.SalesLedgerEntry entry = new TASalesLedgerRptGeneratorController.SalesLedgerEntry(); 
                entry.opportunityId = opps[0].Id; 
                entry.opportunityName = opps[0].Name; 
                entry.openingBalance = 2000; 
                Decimal dec = entry.closingBalanceDebit; 
                System.assertNotEquals(dec, null); 

                Decimal dec2 = entry.closingBalanceCredit; 
                System.assertNotEquals(dec2, null); 

                Decimal dec3 = entry.closingBalanceBalance ; 
                System.assertNotEquals(dec3, null); 

                entry.salesLedgerRecordsForPayments = new List<TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper>{wrapper};

                Test.startTest(); 
                List<TASalesLedgerRptGeneratorController.SalesLedgerRecordWrapper> theTransactions = entry.transactions; 
                system.assert(!theTransactions.isEmpty()); 
                Test.stopTest();  

        }


}