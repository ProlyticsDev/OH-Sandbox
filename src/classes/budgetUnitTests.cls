@IsTest
/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 19th February 2013
Purpose: Test Methods for the Budget Solution
*/
Private class budgetUnitTests{

    //Declare variables
    static User testUser;
    static Account testAccount;
    static Account testAccountChannel;
    static Budget__c testBudget;
    static Budget_Item__c testBudgetItemUser;
    static Budget_Item__c testBudgetItemAgent;
    
    static Account customerAccount;
    static Opportunity testOppty;
    static Item__c testSelection;
    static Project__c project;
    static Product__c[] testProducts;
    static Bank_Account__c solicitorBank;
    
    
    //Create the sample data for testing
    static void createData(){
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //Create the User record
        Profile p1 = [select id from profile where name = 'System Administrator' limit 1];        
        testUser = new User(username = 'test.user@aprika.com.au', profileId = p1.Id, email='test.user@aprika.com.au', firstName='Test', lastName = 'User', alias = 'tuer', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        insert testUser;
        
        Id staffRecordType;
        Id productRecordType;
        Id channelRecordType;
        //create a vendor sales authority record.
        for(RecordType r: [select Id, isPersonType, DeveloperName, sOBjectType from RecordType where sObjectType in ('Account', 'Product__c') and DeveloperName in ('Channel_Account','Staff_Account', 'Apartment')]){
            if(r.DeveloperName == 'Apartment' && r.sObjectType == 'Product__c') productRecordType = r.Id;
            if(r.DeveloperName == 'Staff_Account' && r.sObjectType == 'Account') staffRecordType = r.Id;
            if(r.DeveloperName == 'Channel_Account' && r.sObjectType == 'Account') channelRecordType = r.Id;
        }
        
        //Create the Account record
        testAccount = new Account(FirstName = 'Test', LastName = 'Staff Account', RecordTypeId = staffRecordType);
        testAccountChannel = new Account(Name = 'Channel Account', RecordTypeId = channelRecordType);
        //insert testAccount;
        //insert testAccountChannel;

        customerAccount = new Account();
        customerAccount.Salutation = 'Mr';
        customerAccount.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        customerAccount.LastName = 'pLastName';
        customerAccount.PersonMailingStreet = 'Street';
        customerAccount.PersonEmail = 'test@test.com';
        //insert customerAccount;

        insert new List<Account>{testAccount, testAccountChannel, customerAccount};
        
        solicitorBank = new Bank_Account__c(Account__c = testAccount.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
        insert solicitorBank;
        
        project = new Project__c();
        project.Name = 'Test Project';
        project.Sales_Cycle__c = 8;
        project.Conversion_Rate__c = 10;
        project.Owner_Assignment__c = userInfo.getUserId();
         project.City__c = 'Test'; 
        project.Description__c = 'Sample Description'; 
        project.Region__c = 'Melbourne'; 
        project.Street_Address__c = '12 Test'; 
        project.Zip_Postal_Code__c = 'Victoria';    
        project.Status__c = 'Planned';
        insert project;
        testProducts = new Product__c[]{};
        for(integer i = 0; i < 1; i++){
            testProducts.add(new Product__c(Name = 'Lot'+i, 
                                            Qty_Available__c =1,
                                            Project__c = project.Id, 
                                            List_Price__c = 20000, 
                                            RecordTypeId = productRecordType, 
                                            Solicitor__c = testAccount.Id, 
                                            Solicitors_Bank_Account__c = solicitorBank.Id, 
                                            Solicitors_Payment_Method__c = 'EFT',
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
        //Create the Budget record
        testBudget = new Budget__c(Name = 'March 13', End_Date__c = date.today().addMonths(1).toStartOfMonth().addDays(-1), Start_Date__c =  date.today().toStartOfMonth(), Type__c = 'Actual', Project__c = project.Id, Vendor_Budget_Qty__c = 10, OH_Budget_Qty__c = 10);
        insert testBudget;
        
        //Create the Budget Item records
        testBudgetItemUser = new Budget_Item__c(Name = 'March 13', Budget__c = testBudget.Id, Budget_Qty__c = 5, Budget_Dollar__c = 50000, End_Date__c = date.today().addMonths(1).toStartOfMonth().addDays(-1), Salesperson__c = testUser.Id, Start_Date__c = date.today().toStartOfMonth(), Type__c = 'Actual');
        //insert testBudgetItemUser;
        
        testBudgetItemAgent = new Budget_Item__c(Name = 'March 13', Agent__c = testAccount.Id, Budget__c = testBudget.Id, Budget_Qty__c = 5, Budget_Dollar__c = 50000, End_Date__c = date.today().addMonths(1).toStartOfMonth().addDays(-1), Start_Date__c = date.today().toStartOfMonth(), Type__c = 'Actual');
        //insert testBudgetItemAgent;
        insert new List<Budget_Item__c>{testBudgetItemUser, testBudgetItemAgent};
        
        customerAccount = new Account();
        customerAccount.Salutation = 'Mr';
        customerAccount.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        customerAccount.LastName = 'pLastName';
        customerAccount.PersonMailingStreet = 'Street';
        customerAccount.PersonEmail = 'test@test.com';
        insert customerAccount;
        
        testOppty = new Opportunity();
        testOppty.OwnerId = testUser.Id;
        testOppty.Salesperson__c = testUser.Id;
        testOppty.Salesperson_pa__c = testAccount.Id;
        testOppty.Name = 'oppTest';
        testOppty.stageName = 'New Enquiry';
        testOppty.closeDate = date.Today();
        testOppty.Date_of_Enquiry__c = date.Today();
        testOppty.Enquiry_Method__c = 'Web Form';
        testOppty.Enquiry_Source__c = 'Web';       
        testOppty.AccountId = customerAccount.Id;
        testOppty.Project__c = project.Id;
        testOppty.Primary_Product__c = testProducts[0].Id;
        testOppty.Amount = 20000;
        insert testOppty;
        
        testSelection = new Item__c(Product__c = testProducts[0].Id, Opportunity__c = testOppty.Id, Price__c = 20000);
        insert testSelection;
        
    }
     
    //Test Method for the budgetTrigger
    static testMethod void budgetTrigger(){
        
        //Create the sample data
        createData();
        test.startTest();
        //Check there is a Balance record created
        Budget__c b = [SELECT Id, Name, Related_Record__c, Type__c FROM Budget__c WHERE Related_Record__c =: testBudget.Id ORDER BY CreatedDate DESC LIMIT 1];
        system.assertEquals(testBudget.Name + ' (Balance)', b.Name);
        system.assertEquals('Balance', b.Type__c);
        test.stopTest();
    }
    
    //Test Method for the budgetitemTrigger
    static testMethod void budgetitemTrigger(){
    
    
        //Create the sample data
        createData();
        test.startTest();
        //Check there is a balance record created for the Salesperson record
        Budget_Item__c bSales = [SELECT Id, Name, Agent__c, Related_Record__c, Salesperson__c, Type__c FROM Budget_Item__c WHERE Related_Record__c =: testBudgetItemUser.Id ORDER BY CreatedDate DESC LIMIT 1];
        system.assertEquals(testBudgetItemUser.Name + ' (Balance)', bSales.Name);
        system.assertEquals('Balance', bSales.Type__c);
        
        Budget_Item__c bAgent = [SELECT Id, Name, Agent__c, Related_Record__c, Salesperson__c, Type__c FROM Budget_Item__c WHERE Related_Record__c =: testBudgetItemAgent.Id ORDER BY CreatedDate DESC LIMIT 1];
        test.stopTest();
        system.assertEquals(testBudgetItemAgent.Name + ' (Balance)', bSales.Name);
        system.assertEquals('Balance', bAgent.Type__c);
            
    }
    
    static testMethod void opportunityBudgetTriggerTests(){
        //create sample data
        createData();
        
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'standt', Email='oh@prolytics.com.au', 
                    EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
                    LocaleSidKey='en_US', ProfileId = p.Id, 
                    TimeZoneSidKey='Australia/Sydney', UserName='admin@.test.oh.com.au');
        
        test.startTest();
        System.runAs(u) {
            testOppty.StageName = 'Purchaser Signed';
            testOppty.Purchaser_Signed_Date__c = date.today();
            testOppty.Registered_File__c = true;
/*
HR - 22-06-2016: commented the testOppty.Registered_File_Date__c = date.today(); as it's not valid for the File_Registration_Stage validation
*/
            //testOppty.Registered_File_Date__c = date.today();
            //change the close date to next month
            testOppty.CloseDate = date.today().addMonths(-2);
            testOppty.Date_of_Enquiry__c = date.today().addMonths(-2);
            testOppty.Suburb__c = 'Test Suburb';
            testOppty.GM_OK_to_Register__c = true;
            testOppty.Registered_File__c = false;
            //reset for test reasons only
            utility.budgetOppIdSet = new set<String>();

            update testOppty;
            //add a channel account
            testOppty.Channel_Account__c = testAccountChannel.Id;
            //reset for test reasons only
            utility.budgetOppIdSet = new set<String>();
            update testOppty;
            //reset for test reasons only
            utility.budgetOppIdSet = new set<String>();
            //delete the opportunity
            delete testOppty;
        }
        test.stopTest();
        
    }
    
    static testMethod void opportunityBudgetTriggerTestsRecalc(){
        //create sample data
        createData();
        test.startTest();
        testOppty.StageName = 'Purchaser Signed';
        //change the close date to next month
        testOppty.CloseDate = date.today().addMonths(-1);
        update testOppty;
        
        //create a new won opp
        
        Opportunity testOppty1 = new Opportunity();
        testOppty1.OwnerId = testUser.Id;
        testOppty1.Salesperson__c = testUser.Id;
        testOppty1.Name = 'oppTest';
        testOppty1.stageName = 'Purchaser Signed';
        testOppty1.Purchaser_Signed_Date__c = date.today();
        testOppty1.closeDate = date.Today();
        testOppty1.Date_of_Enquiry__c = date.Today();
        testOppty1.Enquiry_Method__c = 'Web Form';
        testOppty1.Enquiry_Source__c = 'Web';       
        testOppty1.AccountId = customerAccount.Id;
        testOppty1.Project__c = project.Id;
        insert testOppty1;
        
        test.stopTest();
        budgetUtility.recalcAll();
    }
    
    static testMethod void MarketingBudgetTestsRecalc(){
        //create sample data
        createData();
        test.startTest();
            //run the chained batch scripts.
            database.executebatch(new budgetRecalcBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Project__c from Budget__c where Type__c = \'Actual\''));
        test.stopTest();
        //assert that the actuals have been updated, any missing budgets created and marketing lead forecast is updated.
        //query all actual budget records.
        Budget__c[] allActualBudgets = [select Id, Lead_Actual__c, Vendor_Lead_Budget__c, Type__c from Budget__c where Type__c = 'Actual'];
        //there should be 3 budgets
        system.assertEquals(allActualBudgets.size(), 3);
        Integer totalLeads = 0;
        for(Budget__c b: allActualBudgets){
            if(b.Id == testBudget.Id){
                system.assertEquals(b.Lead_Actual__c, 1);   
            }
            else{
                totalLeads += integer.valueOf(b.Vendor_Lead_Budget__c);
            }
        }
        //total leads across all related budgets should be 100
        system.assertEquals(totalLeads, 100);
    }
    
    //test scheduled classes
    static testMethod void testMarketingBudgetSchedule(){
        String jobId;
        Test.startTest();
        // Schedule the test job
        jobId = System.schedule('setMarketingSchedule','0 45 * * 1-12 ? *', new budgetRecalcSchedule());
        Test.stopTest(); 
        //assert that the job was created.
        system.assert(jobId != null);
    
    }
    
    //test scheduled classes
    static testMethod void testVendorBudgetSchedule(){
        String jobId;
        Test.startTest();
        // Schedule the test job
        jobId = System.schedule('setVendorBudgetSchedule','0 45 * * 1-12 ? *', new budgetCalculateVendorSchedule());
        Test.stopTest(); 
        //assert that the job was created.
        system.assert(jobId != null);
    
    }
    
    static testMethod void opportunityVendorBudgetTests(){
        //create sample data
        createData();
        test.startTest();
            testOppty.StageName = 'Reservation';
            testOppty.Reservation_Date__c = date.today();
            testOppty.Suburb__c = 'Test Suburb';
            update testOppty;
            
            testOppty.Purchaser_Signed_Date__c = date.today();
            testOppty.StageName = 'Signed Contract';
        	testOppty.Settlement_Terms_Days__c = 30.0;
            //update testOppty;
        
            testOppty.stageName = 'Contract Exchanged';
            testOppty.Exchanged_Date__c = date.today();
            testOppty.Vendor_Signed_Date__c = date.today();
            update testOppty;
            /*
            testOppty.Registered_File__c = true;
            testOppty.Registered_File_Date__c = date.today();
            */
            testOppty.StageName = 'Contract + Full Deposit';
            testOppty.Full_Deposit_Received_Date__c = Date.today();
            testOppty.Purchaser_Signed_Date__c = date.today();
            update testOppty;
        
            database.executebatch(new budgetCalculateVendorBatch('select Id, Type__c, Start_Date__c, Unique_Id__c, Actual_Dollar_Vendor__c, Actual_Qty_Vendor__c, Project__c from Budget__c where Type__c = \'Actual\''));
        test.stopTest();
        testBudget = [select Id, Actual_Qty_Vendor__c, Actual_Dollar_Vendor__c from Budget__c where Id =: testBudget.Id];
        system.assertEquals(1, testBudget.Actual_Qty_Vendor__c);
        system.assertEquals(20000, testBudget.Actual_Dollar_Vendor__c);
        
    }
    
    
    class meException extends Exception{}
}