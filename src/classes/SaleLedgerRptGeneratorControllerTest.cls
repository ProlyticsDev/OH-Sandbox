@isTest
private class SaleLedgerRptGeneratorControllerTest {

    static TestMethod void testSalesReport() {
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
                
                Vendor_Authority__c testVA = new Vendor_Authority__c(Project__c = objProject.Id);
                testVA.General_Start_Date__c = date.today().addDays(-5);
                testVA.General_End_Date__c = date.today().addDays(5);
                testVA.OH_Commission_Percent__c = 10;
                testVA.OH_Commission_Dollars__c = 100;
                testVA.P1_Payment_Trigger__c = 'Unconditional';
                testVA.P1_Payment_Percentage__c = 50;
                testVA.P2_Payment_Trigger__c = 'Unconditional';
                testVA.P2_Payment_Percentage__c = 50;
                insert testVA;
                
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
                    objProduct.List_Price__c = 2000; 
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
                objOpportunity.Full_Deposit_Required__c = 500;
                objOpportunity.AccountId = objAccount.Id;
                insert objOpportunity;
                
                Trust_Account__c objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
                insert objTrustAccount;
                
                List<Receipt__c> objReceipts = new List<Receipt__c>();
                for(integer counter = 0; counter < 4; counter++)
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
                    objReceipt.Product__c = listProduct[counter/2].Id;
                    objReceipt.Manager_Override__c = true;
                    objReceipt.Reconciled__c = true;
                    objReceipt.Date_Reconciled__c = date.today();
					objReceipts.add(objReceipt);                   
                }
                insert objReceipts;
                
                ApexPages.StandardController sc = new ApexPages.StandardController(objOpportunity);
        		SaleLedgerReportGeneratorControllerMain controller = new SaleLedgerReportGeneratorControllerMain(sc);
                
                System.assert(controller.getReportIFrameUrl() != null);
                System.assert(controller.saveSaleLedgerReport() != null);
                
                ApexPages.currentPage().getParameters().put('id', objOpportunity.Id);
                SaleLedgerRptGeneratorController controllerSub = new SaleLedgerRptGeneratorController();
                System.assert(controllerSub.generateSalesLedger() == null);

            }
        }
    }
        
}