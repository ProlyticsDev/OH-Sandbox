/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class trustAccountRecTests {

    static Project__c testProject;
    static Product__c[] testProducts;
    static Account[] companyAccounts;
    static Contact[] companyContacts;
    static Bank_Account__c[] bankAccounts;
    static Trust_Account__c[] trustAccounts;
    static Cheque__c[] cheques;
    static Account[] clientAccounts;
    static Opportunity[] clientOpps;
    static Receipt__c[] receipts;
    static Receipt__c[] payments;
    static Adjustment__c[] adjustments;
    static Receipt__c[] journals;
    static Map<String, Id> recordTypeIds;

    static void createData(){
        //create all data needed for the test methods.
        recordTypeIds = new Map<String, Id>(); 
        for(RecordType r: [select Id, DeveloperName from RecordType where sObjectType = 'Account' or sObjectType = 'Contact'
                           OR (SobjectType='Receipt__c' AND Name IN ('Receipt','Payment','Journal', 'Reverse Receipt', 'Reverse Payment', 'Reversal', 'Refund')) ]){
            recordTypeIds.put(r.DeveloperName, r.Id);
        }
        
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
            
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        //Create the Company Accounts
        companyAccounts = new Account[]{};
        companyAccounts.add(new Account(RecordTypeId = recordTypeIds.get('Business_Account'), Name = 'Solicitor Account'));
        companyAccounts.add(new Account(RecordTypeId = recordTypeIds.get('Business_Account'), Name = 'OH Account'));
        insert companyAccounts;
        //Create the company Contacts
        companyContacts = new Contact[]{};
        companyContacts.add(new Contact(RecordTypeId = recordTypeIds.get('Contact'), FirstName = 'Test 1', LastName = 'Contact', Email = 'test1@test.com', AccountId = companyAccounts[0].Id));
        companyContacts.add(new Contact(RecordTypeId = recordTypeIds.get('Contact'), FirstName = 'Test 2', LastName = 'Contact', Email = 'test1@oh.com', AccountId = companyAccounts[1].Id));
        insert companyContacts;
        //Create the bank accounts
        bankAccounts = new Bank_Account__c[]{};
        //Solicitor Account
        bankAccounts.add(new Bank_Account__c(Name = 'Solicitor Account', BSB_Number__c = '123-123', Bank_NAme__c = 'ANZ', Bank_Account_Number__c = '123123123', Account__c = companyAccounts[0].Id, Contact__c = companyContacts[0].Id));
        bankAccounts.add(new Bank_Account__c(Name = 'Alt Solicitor Account', BSB_Number__c = '123-123', Bank_NAme__c = 'ANZ', Bank_Account_Number__c = '123123123', Account__c = companyAccounts[0].Id, Contact__c = companyContacts[0].Id));
        //OH Bank Account
        bankAccounts.add(new Bank_Account__c(Name = 'OH Account', BSB_Number__c = '321-321', Bank_NAme__c = 'NAB', Bank_Account_Number__c = '321321321', Account__c = companyAccounts[1].Id, Contact__c = companyContacts[1].Id));
        insert bankAccounts;
        //Create the Trust Accounts
        trustAccounts  = new Trust_Account__c[]{};
        trustAccounts.add(new Trust_Account__c(Name = 'Trust Account 1', Oliver_Hume_Account__c = ohAccuont.Id, Payment_Method__c = 'Cheque', Cheque_Type__c = 'Printed', Bank_Account__c = bankAccounts[2].Id, Trust_Account_Id__c = 123456));
        trustAccounts.add(new Trust_Account__c(Name = 'Trust Account 1', Oliver_Hume_Account__c = ohAccuont.Id, Payment_Method__c = 'EFT', Cheque_Type__c = 'Printed', Bank_Account__c = bankAccounts[2].Id, Trust_Account_Id__c = 123456, Bank__c = 'National Australia Bank', Name_of_Use_Text__c = 'OLIVER HUME', Name_of_Use_Number__c = '123123'));
        insert trustAccounts;
        //Create Some Cheques
        cheques = new Cheque__c[]{};
        for(integer i = 1; i < 20; i++){
            //create and add the cheques
            cheques.add(new Cheque__c(Bank_Account__c = bankAccounts[2].Id, Status__c = 'Available', Cheque_Number__c = i));
        }
        insert cheques;
        //Create the Project
        testProject = new Project__c(Name = 'Test Project', 
                                     Trust_Account__c = trustAccounts[0].Id, 
                                     Project_Manager__c = UserInfo.getUserId(),
                                     City__c = 'Test', 
                                     Description__c = 'Sample Description', 
                                     Region__c = 'Melbourne', 
                                     Street_Address__c = '12 Test', 
                                     Zip_Postal_Code__c = 'Victoria',
                                     Status__c = 'Planned'
                                     );
        insert testProject;
        //Create Some Products
        testProducts = new Product__c[]{};
        for(integer i = 0; i < 10; i++){
            testProducts.add(new Product__c(Name = 'Lot'+i,
                                            Qty_Available__c =1, 
                                            Project__c = testProject.Id, 
                                            Solicitor__c = companyAccounts[0].Id, 
                                            Solicitors_Bank_Account__c = bankAccounts[0].Id, 
                                            Solicitors_Payment_Method__c = 'EFT', 
                                            List_Price__c = 2000, 
                                            Bdr__c = '1', 
                                            Bth__c = '1', 
                                            Car_Parks__c = '1', 
                                            Description__c = 'Test this', 
                                            Features__c = 'Stainless Steel', 
                                            Study__c = '0',
                                            Level__c = '4', 
                                            Orientation__c = 'N',
                                            Size__c = 20,
                                            Viewline__c = 'Sea', 
                                            X_End__c = 2, 
                                            X_Start__c = 3, 
                                            Y_End__c = 2, 
                                            Y_Start__c = 3
                                            ));
        }
        insert testProducts;
        //Create Some Person Client Accounts
        clientAccounts = new Account[]{};
        clientAccounts.add(new Account(RecordTypeId = recordTypeIds.get('PersonAccount'), FirstName = 'Test', LastName = 'Client 1', PersonEmail = 'client1@test.com', Phone = '0412123123'));
        clientAccounts.add(new Account(RecordTypeId = recordTypeIds.get('PersonAccount'), FirstName = 'Test', LastName = 'Client 2', PersonEmail = 'client2@test.com', Phone = '0412123123'));
        clientAccounts.add(new Account(RecordTypeId = recordTypeIds.get('PersonAccount'), FirstName = 'Test', LastName = 'Client 3', PersonEmail = 'client3@test.com', Phone = '0412123123'));
        insert clientAccounts;
        //Create some client opportunities
        clientOpps = new Opportunity[]{};
        clientOpps.add(new Opportunity(Name = 'Client Opp 1', StageName = 'Enquiry', CloseDate = date.today().addDays(30), AccountId = clientAccounts[0].Id, Amount = 300000, Primary_Product__c = testProducts[0].Id, Project__c = testProject.Id));
        clientOpps.add(new Opportunity(Name = 'Client Opp 2', StageName = 'Enquiry', CloseDate = date.today().addDays(30), AccountId = clientAccounts[1].Id, Amount = 600000, Primary_Product__c = testProducts[1].Id, Project__c = testProject.Id));
        clientOpps.add(new Opportunity(Name = 'Client Opp 3', StageName = 'Enquiry', CloseDate = date.today().addDays(30), AccountId = clientAccounts[2].Id, Amount = 300000, Primary_Product__c = testProducts[2].Id, Project__c = testProject.Id));
        clientOpps.add(new Opportunity(Name = 'Client Opp 4', StageName = 'Enquiry', CloseDate = date.today().addDays(30), AccountId = clientAccounts[2].Id, Amount = 600000, Primary_Product__c = testProducts[3].Id, Project__c = testProject.Id));
        insert clientOpps;
        //Add some initial deposit receipts.
        receipts = new Receipt__c[]{};
        receipts.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Receipt'), Type__c = 'Receipt', Date__c = date.today().addDays(-10), Received_From__c = 'Test Client 1', Payment_Method__c = 'EFT', Description__c = 'Initial Deposit', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[0].Id, Amount__c = 20000, Product__c = testProducts[0].Id, Customer_Ref__c = 'a b c', Reconciled__c = true, Date_Reconciled__c =  date.today()));
        receipts.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Receipt'),Type__c = 'Receipt', Date__c = date.today().addDays(-10), Received_From__c = 'Test Client 2', Payment_Method__c = 'EFT', Description__c = 'Initial Deposit', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[1].Id, Amount__c = 20000, Product__c = testProducts[1].Id, Customer_Ref__c = 'abc',Reconciled__c = true, Date_Reconciled__c =  date.today()));
        receipts.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Receipt'),Type__c = 'Receipt', Date__c = date.today().addDays(-10), Received_From__c = 'Test Client 3', Payment_Method__c = 'EFT', Description__c = 'Initial Deposit', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[2].Id, Amount__c = 20000, Product__c = testProducts[2].Id, Customer_Ref__c = 'abc def',Reconciled__c = true, Date_Reconciled__c =  date.today()));
        receipts.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Receipt'),Type__c = 'Receipt', Date__c = date.today().addDays(-10), Received_From__c = 'Test Client 3', Payment_Method__c = 'EFT', Description__c = 'Initial Deposit', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[3].Id, Amount__c = 20000, Product__c = testProducts[3].Id, Customer_Ref__c = 'def',Reconciled__c = true, Date_Reconciled__c =  date.today()));
        receipts.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Receipt'),Type__c = 'Receipt', Date__c = date.today().addDays(-10), Received_From__c = 'Test Client 3', Payment_Method__c = 'EFT', Description__c = 'Initial Deposit', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[3].Id, Amount__c = 20000, Product__c = testProducts[3].Id, Customer_Ref__c = 'def',Reconciled__c = false, Date_Reconciled__c =  date.today()));
        //insert receipts;
        
        //create some transactions that need processing.
        payments = new Receipt__c[]{};
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'Cheque', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[0].Id, Opportunity__c = clientOpps[0].Id, Amount__c = 5000, Product__c = testProducts[0].Id, Manager_Override__c = true));
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'Cheque', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[1].Id, Amount__c = 5000, Product__c = testProducts[1].Id, Manager_Override__c = true));
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'Cheque', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[0].Id, Opportunity__c = clientOpps[0].Id, Amount__c = 5000, Product__c = testProducts[0].Id, Manager_Override__c = true));
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'Cheque', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[1].Id, Amount__c = 5000, Product__c = testProducts[1].Id, Manager_Override__c = true));
        //EFT Payments
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'EFT', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[0].Id, Opportunity__c = clientOpps[2].Id, Amount__c = 5000, Product__c = testProducts[2].Id, Manager_Override__c = true));
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'EFT', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[2].Id, Amount__c = 5000, Product__c = testProducts[2].Id, Manager_Override__c = true));
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'EFT', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[0].Id, Opportunity__c = clientOpps[2].Id, Amount__c = 5000, Product__c = testProducts[2].Id, Manager_Override__c = true));
        payments.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Payment'), Date__c = date.today(), Payment_Method__c = 'EFT', Description__c = 'Deposit Transfer - Build', Trust_Account__c = trustAccounts[0].Id, Bank_Account__c = bankAccounts[1].Id, Opportunity__c = clientOpps[2].Id, Amount__c = 5000, Product__c = testProducts[2].Id, Manager_Override__c = true));
       // insert payments;
        //Create some journal records for the payments.
        journals = new Receipt__c[]{};
        journals.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Journal'), Bulk_Payment__c = payments[4].Id,Trust_Account__c = trustAccounts[0].Id, Amount__c = 5000, Payment_Method__c = 'EFT', Bank_Account__c = bankAccounts[0].Id, Payment_Reference__c = 'Test Payment'));
        journals.add(new Receipt__c(RecordTypeId = recordTypeIds.get('Journal'), Bulk_Payment__c = payments[0].Id, Trust_Account__c = trustAccounts[0].Id, Amount__c = 5000, Payment_Method__c = 'Cheque', Bank_Account__c = bankAccounts[0].Id, Payment_Reference__c = 'Test Payment', Cheque_Number__c = cheques[0].Id));
        //insert journals;
        List<Receipt__c> sobj = new List<Receipt__c>(); 
        sobj.addAll(receipts); 
        sobj.addAll(payments); 
        sobj.addAll(journals); 
        insert sobj;

        //Create Some Adjustments
        adjustments = new Adjustment__c[]{};
        adjustments.add(new Adjustment__c(Trust_Account__c = trustAccounts[0].Id, Type__c = 'Fees', Status__c = 'Unresolved', Date__c = date.today().addDays(-3), Amount__c = -100, Notes__c = 'Bank Fees xx'));
        adjustments.add(new Adjustment__c(Trust_Account__c = trustAccounts[0].Id, Type__c = 'Credit', Status__c = 'Unassigned', Date__c = date.today().addDays(-5), Amount__c = 100, Notes__c = 'Credit Interest Paid'));
        //These shouldn't match as they are too old.
        adjustments.add(new Adjustment__c(Trust_Account__c = trustAccounts[0].Id, Type__c = 'Fees', Status__c = 'Unresolved', Date__c = date.today().addDays(-30), Amount__c = -100, Notes__c = 'Bank Fees xx'));
        adjustments.add(new Adjustment__c(Trust_Account__c = trustAccounts[0].Id, Type__c = 'Credit', Status__c = 'Unassigned', Date__c = date.today().addDays(-30), Amount__c = 100, Notes__c = 'Credit Interest Paid'));
        insert adjustments;
        
    }

    static testMethod void recTest() {
        createData();
        //this is the csv that we are going to upload.
        
        blob csvBody = blob.valueOf('NATAAU3M,AUD,140910268,16/06/2014,15,CLOSING BALANCE, , ,40000\r NATAAU3M,AUD,140910268,16/06/2014,910,CASH, ,Test Receipt 1 Test Client 1,20000\r NATAAU3M,AUD,140910268,16/06/2014,175,CHEQUES (LODGED) ;, ,Test Receipt 2 Lot1,20000\r NATAAU3M,AUD,140910268,16/06/2014,175,CHEQUES (LODGED) ;,,Test Receipt 3 Lot 2 abc,20000\r NATAAU3M,AUD,140910268,16/06/2014,175,CHEQUES (LODGED) ;,,Test Receipt 4 Test Project Lot 2,20000\r NATAAU3M,AUD,140910268,16/06/2014,175,CHEQUES (LODGED) ;,,Test Receipt 5,20000\r NATAAU3M,AUD,140910268,16/06/2014,175,CHEQUES (LODGED) ;,,Test Receipt 6,20000\r NATAAU3M,AUD,140910268,16/06/2014,910,CASH,,Credit Interest Paid,100\r NATAAU3M,AUD,140910268,16/06/2014,175,AUTOMATIC DRAWINGS, ,Test Payment 1 123123123 123-123,-5000\r NATAAU3M,AUD,140910268,16/06/2014,501,AUTOMATIC DRAWINGS, ,Test Payment 2 123123123,-5000\r NATAAU3M,AUD,140910268,16/06/2014,501,AUTOMATIC DRAWINGS, ,Test Payment 3 123-123,-5000\r NATAAU3M,AUD,140910268,16/06/2014,,AUTOMATIC DRAWINGS,,Test Payment 4,-5000\r NATAAU3M,AUD,140910268,16/06/2014,,AUTOMATIC DRAWINGS,1,Test Payment 5,-5000\r NATAAU3M,AUD,140910268,16/06/2014,,AUTOMATIC DRAWINGS,2,Test Payment 6,-5000\r NATAAU3M,AUD,140910268,16/06/2014,,AUTOMATIC DRAWINGS,,Bank Fees xx,-100\r NATAAU3M,AUD,140910268,16/06/2014,15,CLOSING BALANCE, , ,90000');
        Document csvDoc = new Document();
        csvDoc.body = csvBody;
        csvDoc.ContentType = 'text/csv';
        csvDoc.Name = 'Test CSV';
        //instance of the standard controller.
        ApexPages.StandardController std = new ApexPages.StandardController(trustAccounts[0]);
        //create an instance of the controller.
        Test.startTest();
        trustAccountRec tar = new trustAccountRec(std);
        system.assert(tar.trustAccountId != null);
        //test some page getters
        system.assertEquals(tar.getTrustAccountOptions().size(), 3);
        //set the CSV file.
        tar.csvFile = csvDoc;
        //now upload the csv.
        tar.processCSV();
        //assert the receipts and payments have been created succsessfully. 
        system.assertEquals(7, tar.payments.size());
        system.assertEquals(7, tar.receipts.size());
        //refresh unresolved adjustments
        tar.refreshUnresolvedAdjustments();
        system.assertEquals(tar.unresolvedAdjustments.size(), 4);
        //refresh unpresented payments
        tar.refreshPayments();

        //tar.refreshReceipts();
        //system.assertEquals(tar.unpresentedPayments.size(), 8);
        //system.assertEquals(tar.unpresentedReceipts.size(), 4);
        //check that some of the receipts matched successfully
        //system.assertEquals(3, tar.receipts[0].receipts.size());
        //check that some of the payments matched successfully.
        //system.assertEquals(3, tar.payments[0].payments.size());
        //select the matched payments and receipts
        //tar.receipts[0].receipts[0].isSelected = true;
        //tar.payments[0].payments[0].isSelected = true;
        tar.payments[0].newPayments[0].isSelected = true;
        tar.payments[0].newPayments[0].dummyAdjustment.Transaction__c = payments[0].Id;
        //add a new row to the payment
        tar.payments[0].newManualPayment();
        system.assertEquals(tar.payments[0].newPayments.size(), 2);
        //now the receipt has been selected, populate the data.
        tar.payments[0].newPayments[0].updateAmount();
        //try and load manual receipts for each record
        tar.receipts[1].newReceipts[0].isSelected = true;
        tar.receipts[1].newReceipts[0].dummyAdjustment.Transaction__c = receipts[1].Id;
        //now the receipt has been selected, populate the data.
        tar.receipts[1].newReceipts[0].updateAmount();
        //check that the correct receipt has been loaded.
        //system.assertEquals(tar.receipts[1].newReceipts[0].receipt.Id, receipts[1].Id);
        tar.receipts[1].newManualReceipt();
        system.assertEquals(tar.receipts[1].newReceipts.size(), 2);
        //and for payments
        tar.payments[1].newPayments[0].isSelected = true;
        tar.payments[1].newPayments[0].dummyAdjustment.Transaction__c = payments[1].Id;
        //now the receipt has been selected, populate the data.
        tar.payments[1].newPayments[0].updateAmount();
        //check that the correct receipt has been loaded.
        system.assertEquals(tar.payments[1].newPayments[0].payment.Id, payments[1].Id);
        
        //assert the credit interest paid row in the bank statement
        system.assertEquals(tar.receipts[6].xRow.xAmount, 100);
        //make sure it is selected
         tar.receipts[6].existingAdjustments[0].isSelected = true;
        //make sure that we have 1 matched adjustment record.
        system.assertEquals(tar.receipts[6].adjustments.size(), 2);
        //assert it is a fees adjustment
        system.assertEquals(tar.receipts[6].adjustments[0].adjustment.Type__c, 'Fees');
        //although this has matched, we'll manually match it.
        tar.receipts[6].existingAdjustments[0].adjustment.Adjustment__c = adjustments[0].Id;
        tar.receipts[6].existingAdjustments[0].loadExisting();
        //assert that the adjustment has been updated successfully.
        system.assertEquals(tar.receipts[6].existingAdjustments[0].adjustment.Amount__c, 100);
        //do the same for the payment adjustment
        //assert the Bank Fees paid row in the bank statement
        system.assertEquals(tar.payments[6].xRow.xAmount, -100);
        //make sure it is selected
         tar.payments[6].existingAdjustments[0].isSelected = true;
        //make sure that we have 1 matched adjustment record.
        system.assertEquals(tar.payments[6].adjustments.size(), 2);
        //assert it is a credit adjustment
        system.assertEquals(tar.payments[6].adjustments[0].adjustment.Type__c, 'Credit');
        //although this has matched, we'll manually match it.
        tar.payments[6].existingAdjustments[0].adjustment.Adjustment__c = adjustments[1].Id;
        tar.payments[6].existingAdjustments[0].loadExisting();
        //assert that the adjustment has been updated successfully.
        system.assertEquals(tar.payments[6].existingAdjustments[0].adjustment.Amount__c, -100);
        
        //refresh adjustments
        tar.refreshAdjustments();
        //we should be creating one adjustment.
        system.assertEquals(tar.adjustments.size(), 2);
        //validate the pages.
        tar.validateTransactions();
        //assert some of the summary values.
        system.assertEquals(tar.openingBalance, 40000);
        system.assertEquals(tar.closingBalance, 90000);
        system.assertEquals(tar.totalReceiptsBank, 120100);
        system.assertEquals(tar.totalPaymentsBank, 30100);
        //assert that the variance 0 as we haven't fully reconciled the page.
        //system.assertEquals(tar.varianceBalance, 60000.00);
        //check unpresented payments
        tar.refreshPayments();
        //there should be 7
        //system.assertEquals(tar.unpresentedPayments.size(), 6);
        //tar.refreshReceipts();
        //there should be 2
        //system.assertEquals(tar.unpresentedReceipts.size(), 2);
        //reconcile the remainder of the page.
        //tar.receipts[2].receipts[2].isSelected = true;
        //tar.receipts[3].receipts[2].isSelected = true;
        tar.receipts[3].newAdjustments[0].isSelected = true;
        tar.receipts[3].newAdjustments[0].adjustment.Amount__c = 20000;
        tar.receipts[3].newAdjustments[0].adjustment.Date__c = date.today();
        tar.receipts[3].newAdjustments[0].adjustment.Notes__c = 'Test Notes';
        tar.receipts[4].newAdjustments[0].isSelected = true;
        tar.receipts[4].newAdjustments[0].adjustment.Amount__c = 20000;
        tar.receipts[4].newAdjustments[0].adjustment.Date__c = date.today();
        tar.receipts[4].newAdjustments[0].adjustment.Notes__c = 'Test Notes';
        tar.receipts[5].newAdjustments[0].isSelected = true;
        tar.receipts[5].newAdjustments[0].adjustment.Amount__c = 20000;
        tar.receipts[5].newAdjustments[0].adjustment.Date__c = date.today();
        tar.receipts[5].newAdjustments[0].adjustment.Notes__c = 'Test Notes';
        
        tar.payments[2].newPayments[0].isSelected = true;
        tar.payments[3].newPayments[0].isSelected = true;
        tar.payments[4].newPayments[0].isSelected = true;
        tar.payments[5].newPayments[0].isSelected = true;
        tar.payments[2].newPayments[0].dummyAdjustment.Transaction__c = payments[2].Id;
        tar.payments[2].newPayments[0].updateAmount();
        tar.payments[3].newPayments[0].dummyAdjustment.Transaction__c = payments[3].Id;
        tar.payments[3].newPayments[0].updateAmount();
        tar.payments[4].newPayments[0].dummyAdjustment.Transaction__c = payments[4].Id;
        tar.payments[4].newPayments[0].updateAmount();
        tar.payments[5].newPayments[0].dummyAdjustment.Transaction__c = payments[5].Id;
        tar.payments[5].newPayments[0].updateAmount();
        /*
        tar.payments[2].payments[2].isSelected = true;
        tar.payments[3].payments[3].isSelected = true;
        tar.payments[4].payments[4].isSelected = true;
        tar.payments[5].payments[5].isSelected = true;
        */
        
        //all reconciled... validate again
        tar.validateTransactions();
        //system.assertEquals(tar.varianceBalance, 0.00);
        
        //now process
        tar.processTransactions();
        system.debug('$$$$$$' + Limits.getQueries());
        test.stopTest();
    }
}