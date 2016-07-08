@isTest
private  class vendorAuthorityTests {
    
    private static Project__c testProject;
    private static Product__c[] testProducts;
    private static Vendor_Authority__c testVA;
    private static Product_Assignment__c[] testAssignments;
    private static Vendor_Sales_Authority__c salesVSA;
    private static Vendor_Sales_Authority__c cadetVSA;
    private static Account salesAccount;
    private static Account cadetAccount;
    private static Account[] accounts;
    private static Vendor_Sales_Authority__c[] VSAs;
    private static Document__c[] testDocs;
    
    static void createData(){
        //create some data.
        testProject = new Project__c(Name = 'Test Project', 
                                     Project_Manager__c = UserInfo.getUserId(), 
                                     VA_Override__c = false, 
                                     City__c = 'Test', 
                                     Description__c = 'Sample Description', 
                                     Region__c = 'Melbourne', 
                                     Street_Address__c = '12 Test', 
                                     Zip_Postal_Code__c = 'Victoria',
                                     Status__c = 'Planned'
                                     );
        insert testProject;
        //Create Some Products
        //create a vendor sales authority record.
        Id staffRecordType = [select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Staff_Account' and isPersonType = true limit 1].Id;
        salesAccount = new Account(FirstName = 'Test', LastName = 'Staff Account', RecordTypeId = staffRecordType, VSA_Override__c = false);
        cadetAccount = new Account(FirstName = 'Test', LastName = 'Cadet Account', RecordTypeId = staffRecordType, VSA_Override__c = false);
        Account solAccount = new Account(Name = 'Test Solicitor Account');
        accounts = new Account[]{salesAccount, cadetAccount, solAccount};
        insert accounts;
        Bank_Account__c solBank = new Bank_Account__c(Name = 'Sol Bank Account', Bank_Account_Number__c = '12345678', BSB_Number__c = '123123', Bank_Name__c = 'Test Bank');
        insert solBank;
        
        testProducts = new Product__c[]{};
        for(integer i = 0; i < 10; i++){
            testProducts.add(new Product__c(Name = 'Lot'+i, 
                                            Qty_Available__c =1,
                                            Project__c = testProject.Id, 
                                            Solicitor__c = solAccount.Id, 
                                            Solicitors_Bank_Account__c = solBank.Id, 
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
                                            Viewline__c = 'Sea', 
                                            X_End__c = 2, 
                                            X_Start__c = 3, 
                                            Y_End__c = 2, 
                                            Y_Start__c = 3,  
                                            Size__c = 12     
                                            ));
        }
        insert testProducts;
        
        testVA = new Vendor_Authority__c(Project__c = testProject.Id, 
                                         OH_Commission_Percent__c = 3,
                                         P1_Payment_Trigger__c = 'Settled',
                                         P1_Payment_Percentage__c = 100);
        testVA.Exclusive_Start_Date__c = date.today().addDays(-10);
        testVA.Exclusive_End_Date__c = date.today().addDays(-5);
        testVA.General_Start_Date__c = date.today().addDays(-5);
        testVA.General_End_Date__c = date.today().addDays(1);
        insert testVA;
        testAssignments = new Product_Assignment__c[]{};
        //create some product assignment records.
        for(Product__c p: testProducts){
            //create test assigments for each product
            testAssignments.add(new Product_Assignment__c(Active__c = true, Product__c = p.Id, Vendor_Authority__c = testVA.Id));
        }
        insert testAssignments;
        
        salesVSA = new Vendor_Sales_Authority__c(Account__c = salesAccount.Id, Role__c = 'Sales Consultant', Vendor_Authority__c = testVA.Id, Active__c = true, P1_Payment_Trigger__c = 'Settled', P1_Payment_Percentage__c = 100, Commission_Dollars__c = 1000);
        cadetVSA = new Vendor_Sales_Authority__c(Account__c = cadetAccount.Id, Role__c = 'Cadet', Vendor_Authority__c = testVA.Id, Active__c = true, P1_Payment_Trigger__c = 'Settled', P1_Payment_Percentage__c = 100, Commission_Dollars__c = 1000);
        VSAs = new Vendor_Sales_Authority__c[]{cadetVSA, salesVSA};
        insert VSAs;
        //create the test documents.
        testDocs = new Document__c[]{};
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Agent Rep Authority', Expiry_Date__c = date.today().addDays(-1), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Agent�s Rep Licence', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Authority to Recruit', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Eligibility Declaration', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Employment Contract', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'MGS Profile', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'OH&S Policies', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Personal Details Form', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Police Check', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Superannuation Form', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Project Acceptance Letter', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = salesAccount.Id, Type__c = 'Commission Agreement', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Agent Rep Authority', Expiry_Date__c = date.today().addDays(-1), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Agent�s Rep Licence', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Authority to Recruit', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Eligibility Declaration', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Employment Contract', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        //testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'MGS Profile', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'OH&S Policies', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Personal Details Form', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Police Check', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Superannuation Form', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true));
        //testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Project Acceptance Letter', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        //testDocs.add(new Document__c(Staff_Member__c = cadetAccount.Id, Type__c = 'Commission Agreement', Expiry_Date__c = date.today().addDays(10), Name = 'Test Doc', Active__c = true, Validated__c = true, Project__c = testProject.Id));
        insert testDocs;
    }
        
    static testMethod void vendorAuthTriggerTest(){
        createData();
        
        test.startTest();
        
        testVA.Exclusive_Expired__c = true;
        update testVA;
        //check that the product assignments haven't updated as there is still a general agreement in place.
        for(Product_Assignment__c pa: [select Active__c from Product_Assignment__c where Vendor_Authority__c =: testVA.Id]){
            system.assertEquals(pa.Active__c, true);
        }
        
        //now update the general period
        testVA.General_End_Date__c = date.today().addDays(0);
        testVA.General_Expired__c = true;
        update testVA;
        
        for(Product_Assignment__c pa: [select Active__c from Product_Assignment__c where Vendor_Authority__c =: testVA.Id]){
            system.assertEquals(pa.Active__c, false);
        }
        //create the data again
        createData();
        //change it so there is no general
        testVA.General_Start_Date__c = null;
        testVA.General_End_Date__c = null;
        testVA.General_Expired__c = true;
        update testVA;
        //check thay the PA's are all false
        for(Product_Assignment__c pa: [select Active__c from Product_Assignment__c where Vendor_Authority__c =: testVA.Id]){
            system.assertEquals(pa.Active__c, false);
        }
        test.stopTest();
    }
    
    static testMethod void vendorAuthBatchTest(){
        createData();
        
        test.startTest();
        //vendorAuthorityUtility.checkProjectDocuments(database.query('select Id, (select Id, Vendor_Authority__r.Project__c, Vendor_Authority__r.Project__r.Name, Role__c from Vendor_Sales_Authorities__r where Active__c = true and (Role__c = \'Host\' or Role__c = \'Cadet\' or Role__c = \'Sales Consultant\')), (select Id, Name, Project__c, Type__c, Validated__c, Active__c, Expiry_Date__c from Documents__r where Active__c = true and Validated__c = true and Expiry_Date__c > TODAY) from Account where VSA_Override__c = false and isPersonAccount = true and (RecordType.DeveloperName = \'Staff_Account\')'));
        database.executebatch(new vendorAuthorityBatch('select Id, (select Id, Vendor_Authority__r.Project__c, Vendor_Authority__r.Project__r.Name, Role__c from Vendor_Sales_Authorities__r where Active__c = true and (Role__c = \'Host\' or Role__c = \'Cadet\' or Role__c = \'Sales Consultant\')), (select Id, Name, Project__c, Type__c, Validated__c, Active__c, Expiry_Date__c from Documents__r where Active__c = true and Validated__c = true and Expiry_Date__c > TODAY) from Account where VSA_Override__c = false and isPersonAccount = true and (RecordType.DeveloperName = \'Staff_Account\')'));
        test.stopTest();
        system.assertEquals(false, [select Active__c from Vendor_Sales_Authority__c where Id =: salesVSA.Id].Active__c);
    }
    
    static testMethod void vendorAuthScheduleTest(){
        String jobId;
        Test.startTest();
        // Schedule the test job
        jobId = System.schedule('setVendorTestSchedule','0 45 * * 1-12 ? *', new vendorAuthoritySchedule());
        Test.stopTest(); 
        //assert that the job was created.
        system.assert(jobId != null);
    }
}