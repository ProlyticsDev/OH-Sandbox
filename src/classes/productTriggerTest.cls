@isTest
private class productTriggerTest 
{
    
    //Base Data used for commission testing
    private static Vendor_Authority__c va;
    private static Vendor_Sales_Authority__c vsa;
    private static Product_Assignment__c pa;
    private static Vendor_Sales_Product_Assignment__c vspa;
    private static Product__c testProduct;
    private static Project__c testProject;
    private static Opportunity testOpp;
    private static Commission__c ucCommission;
    private static Commission__c ccCommission;
    private static Commission__c bluCommission;
    private static Commission__c sCommission;
    private static Commission__c ssCommission;

    @IsTest
    public static void setupBaseData(){
        
        RecordType rt = [select id from RecordType where SobjectType ='Account' and Name = 'Oliver Hume Account' limit 1];
        Account acct = new Account
        (
            Name = 'Test Account',
            RecordTypeId = rt.Id
        );

        Account OHAcct = new Account
        (
            Name = 'Oliver Hume',
            RecordTypeId = rt.Id,
            OH_Account__c = true
        );

        insert new List<Account>{acct, OHAcct};
        Bank_Account__c solicitorBank = new Bank_Account__c(Account__c = acct.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
        insert solicitorBank;
        testProject = new Project__c
        (
            Name = 'Test Project',
            City__c = 'Test', 
            Description__c = 'Sample Description', 
            Region__c = 'Melbourne', 
            Street_Address__c = '12 Test', 
            Zip_Postal_Code__c = 'Victoria',
            Status__c = 'Planned'
        );

        insert testProject;

        System.Assert(testProject.Id != null, 'Project was not created successfully.');

        va = new Vendor_Authority__c
        (
            OH_Build_Lockup_Dollars__c = 10,
            OH_Build_Lockup_Percent__c = 10,
            OH_Cancellation_Dollars__c = 20,
            OH_Cancellation_Percent__c = 20,
            OH_Commission_Dollars__c = 30,
            OH_Commission_Percent__c = 30,
            OH_Construction_Commenced_Dollars__c = 40,
            OH_Construction_Commenced_Percent__c = 40,
            OH_Settled_Dollars__c = 50,
            OH_Settled_Percent__c = 50,
            OH_Unconditional_Dollars__c = 60,
            OH_Unconditional_Percent__c = 60,
            Channel_Build_Lockup_Dollars__c = 10,
            Channel_Build_Lockup_Percent__c = 10,
            Channel_Cancellation_Dollars__c = 20,
            Channel_Cancellation_Percent__c = 20,
            Channel_Commission_Dollars__c = 30,
            Channel_Commission_Percent__c = 30,
            Channel_Construction_Commenced_Dollars__c = 40,
            Channel_Construction_Commenced_Percent__c = 40,
            Channel_Settled_Dollars__c = 50,
            Channel_Settled_Percent__c = 50,
            Channel_Unconditional_Dollars__c = 60,
            Channel_Unconditional_Percent__c = 60,
            Project__c = testProject.Id,
            Status__c = 'Approved',
            Approval_PD__c = true,
            Approval_GM_SA__c = true,
            Admin_Fee__c = 5,
            Commission_Based_On__c = 'Margin Scheme Price',
            P1_Payment_Trigger__c = 'Settled',
            P1_Payment_Percentage__c = 100
        );

        insert va;

        testProduct = new Product__c
        (
            Name = 'Test Apartments',
            Project__c = testProject.Id,
            Solicitor__c = acct.Id,
            Solicitors_Bank_Account__c = solicitorBank.Id,
            Solicitors_Payment_Method__c = 'EFT',
            Qty_Available__c =1,
            List_Price__c = 2000, 
            Bdr__c = '1', 
            Bth__c = '1', 
            Car_Parks__c = '1', 
            Description__c = 'Test this', 
            Features__c = 'Stainless Steel', 
            Study__c = '0',
            Level__c = '4', 
            Orientation__c = 'N',
            Viewline__c = 'Sea', 
            X_End__c = 2, 
            X_Start__c = 3, 
            Y_End__c = 2, 
            Y_Start__c = 3,  
            Size__c = 12     
        );

        insert testProduct;

        pa = new Product_Assignment__c
        (
            Vendor_Authority__c = va.Id,
            Product__c = testProduct.Id,
            Active__c = false, 
            OH_Build_Lockup_Dollars__c = 5,
            OH_Build_Lockup_Percent__c = 5,
            OH_Cancellation_Dollars__c = 10,
            OH_Cancellation_Percent__c = 10,
            OH_Commission_Dollars__c = 15,
            OH_Commission_Percent__c = 15,
            OH_Construction_Commenced_Dollars__c = 20,
            OH_Construction_Commenced_Percent__c = 20,
            OH_Settled_Dollars__c = 25,
            OH_Settled_Percent__c = 25,
            OH_Unconditional_Dollars__c = 0,
            OH_Unconditional_Percent__c = 0,
            Channel_Build_Lockup_Dollars__c = 10,
            Channel_Build_Lockup_Percent__c = 10,
            Channel_Cancellation_Dollars__c = 20,
            Channel_Cancellation_Percent__c = 20,
            Channel_Commission_Dollars__c = 30,
            Channel_Commission_Percent__c = 30,
            Channel_Construction_Commenced_Dollars__c = 40,
            Channel_Construction_Commenced_Percent__c = 40,
            Channel_Settled_Dollars__c = 50,
            Channel_Settled_Percent__c = 50,
            Channel_Unconditional_Dollars__c = 60,
            Channel_Unconditional_Percent__c = 60
        );

        insert pa;
        
        testOpp = new Opportunity(
            Name = 'Test Oppty',
            AccountId = acct.Id,
            Project__c = testProject.Id,
            Primary_Product__c = testProduct.Id,
            StageName = 'Settled',
            Actual_Settlement_Date__c = date.today(),
            CloseDate = System.today(),
            Purchaser__c = 'Michael Knight',
            Margin_Scheme_Price__c = 100.00,
            Date_of_Enquiry__c = date.today(),
            Enquiry_Method__c = 'Web Form',
            Enquiry_Source__c = 'Web'
        );

        insert testOpp;
        //reset the recursion test
        utility.commOppIdSet = new Set<String>();
        
        //add some commission records.
        Commission__c[] testComms = new Commission__c[]{new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Status__c = 'Pending', Category__c = 'Oliver Hume')};
        insert testComms;
    }
    
    static testMethod void TestProductSettlementInvoiceDate() 
    {
        list<Product_Assignment__c> listProductAssignments = new list<Product_Assignment__c>();
        
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs (objCurrentUser) 
        {
            RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
            
            if(objRecordTypeProduct != null)
            {
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
                
                Product__c objProduct = new Product__c();
                objProduct.Name = 'Product 00';
                objProduct.Project__c = objProject.Id;
                objProduct.Type__c = 'Apartment';
                objProduct.RecordTypeId = objRecordTypeProduct.Id;
                objProduct.Street_Name__c = 'Test Street';
                objProduct.Stage_Number__c = '03';
                objProduct.Size__c = 200;
                objProduct.Active_VA__c = true;
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
                objProduct.Viewline__c = 'Sea'; 
                objProduct.X_End__c = 2; 
                objProduct.X_Start__c = 3; 
                objProduct.Y_End__c = 2; 
                objProduct.Y_Start__c = 3;       
                insert objProduct;
                
                objProduct = [Select Id, Settlement_Terms_Days__c, Titled_Date__c, Settlement_Invoice_Date__c From Product__c Where Id =: objProduct.Id];
                
                system.assertEquals(0, ohHelper.NormalizeDecimal(objProduct.Settlement_Terms_Days__c));
                system.assertEquals(null, objProduct.Titled_Date__c);
                
                objProduct.Titled_Date__c = date.today() - 2;
                objProduct.Settlement_Terms_Days__c = 1;
                update objProduct;
                objProduct = [Select Id, Settlement_Terms_Days__c, Titled_Date__c, Settlement_Invoice_Date__c From Product__c Where Id =: objProduct.Id];
                system.assertEquals(date.today(), objProduct.Settlement_Invoice_Date__c);
                
                objProduct.Titled_Date__c = date.today() - 1;
                objProduct.Settlement_Terms_Days__c = 2;
                update objProduct;
                objProduct = [Select Id, Settlement_Terms_Days__c, Titled_Date__c, Settlement_Invoice_Date__c From Product__c Where Id =: objProduct.Id];
                system.assertEquals(date.today() + 1, objProduct.Settlement_Invoice_Date__c);
            }
        }
    }
    
    static testMethod void productCommsPayableTest(){
        //create some data.
        setupBaseData();
    
        test.startTest();
            //update some of the checkboxes on the product that would cause the commissions to become payable.
            testProduct.Settled_Check__c = true;
            testProduct.Build_Lockup_Check__c = true;
            testProduct.Construction_Commenced_Check__c = true;
            testProduct.Unconditional_Check__c = true;
            update testProduct;
            //sCommission = [select Status__c from Commission__c where Id =: sCommission.Id];
            //these will be payable
            //system.assertEquals('Payable', sCommission.Status__c);
            //these won't be payable.
            //ssCommission = [select Status__c from Commission__c where Id=:ssCommission.Id];
        //    system.assertEquals('Pending', ssCommission.Status__c);
        test.stopTest();
    }
    
    static testMethod void productCommsPayableDateTest(){
        //create some data.
        setupBaseData();
    
        test.startTest();
            //update some of the dates on the product and check the dates on the commission get update accordingly.
            testProduct.Settlement_Date__c = date.today();
            testProduct.Settlement_Invoice_Date__c = date.today();
            testProduct.Build_Lockup_Date__c = date.today().addDays(1);
            testProduct.Construction_Commenced_Date__c = date.today().addDays(2);
            testProduct.Unconditional_Date__c  = date.today().addDays(3);
            update testProduct;
            //system.assertEquals(date.today().addDays(2), [select Due_Date__c from Commission__c where Id=: ccCommission.Id].Due_Date__c);
            //check that the salesperson commission is a month greater than the OH comms
           // system.assertEquals(date.today().addMonths(1), [select Due_Date__c from Commission__c where Id=: ssCommission.Id].Due_Date__c);
            
        test.stopTest();
    }
    
}