@isTest
private class commissionTriggerTests {

    //Base Data used for commission testing
    private static Vendor_Authority__c va;
    private static Vendor_Sales_Authority__c vsa;
    private static Product_Assignment__c pa;
    private static Vendor_Sales_Product_Assignment__c vspa;
    private static Product__c testProduct;
    private static Project__c testProject;
    private static Opportunity testOpp;
    private static Account staffAcct;
    private static Bank_Account__c solicitorBank;
    private static MAP<String, ID> acctRtMap;
    private static MAP<String, ID> commRtMap;

    @IsTest
    public static void setupBaseData(){
        
        acctRtMap = new MAP<String, ID>();
        for (RecordType rT : [SELECT Id, DeveloperName FROM RecordType 
                              WHERE SObjectType = 'Account' 
                              AND IsActive = True]) {
            acctRtMap.put(rT.DeveloperName, rT.Id);
        }
        
        Account acct = new Account
        (
            Name = 'Test Account',
            RecordTypeId = acctRtMap.get('Channel_Account')
        );
        
        staffAcct = new Account
        (
            FirstName = 'Staff',
            LastNAme = 'Account',
            RecordTypeId = acctRtMap.get('Staff_Account')
        );

        Account OHAcct = new Account
        (
            Name = 'Oliver Hume',
            OH_Account__c = true,
            RecordTypeId = acctRtMap.get('Oliver_Hume_Account')
        );

        insert new List<Account>{acct, OHAcct, staffAcct};

        solicitorBank = new Bank_Account__c(Account__c = acct.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
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
            Size__c = 20,
            Viewline__c = 'Sea', 
            X_End__c = 2, 
            X_Start__c = 3, 
            Y_End__c = 2, 
            Y_Start__c = 3
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
            Name = 'Test Opp1',
            AccountId = acct.Id,
            Project__c = testProject.Id,
            Primary_Product__c = testProduct.Id,
            StageName = 'Settled',
            CloseDate = System.today(),
            Actual_Settlement_Date__c = System.today(),
            Purchaser__c = 'Michael Knight',
            Margin_Scheme_Price__c = 100.00,
            Date_of_Enquiry__c = date.today(),
            Enquiry_Method__c = 'Web Form',
            Enquiry_Source__c = 'Web'
        );

        insert testOpp;

        commRtMap = new MAP<String, ID>();
        for (RecordType rT : [SELECT Id, DeveloperName FROM RecordType 
                              WHERE SObjectType = 'Commission__c' 
                              AND IsActive = True]) {
            commRtMap.put(rT.DeveloperName, rT.Id);
        }
        
        //add some commission records.
        Id OHRecTypeId = commRtMap.get('Oliver_Hume');
        Id StaffRecTypeId = commRtMap.get('Staff');
        Commission__c[] testComms = new Commission__c[]{};
        testComms.add(new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Payment_Type__c = 'P1', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Unconditional Contract', Amount__c = 10000, Amount_Excl__c = 9000, RecordTypeId = OHRecTypeId));
        testComms.add(new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Payment_Type__c = 'P1', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Construction Commenced', Amount__c = 1000, Amount_Excl__c = 900, RecordTypeId = OHRecTypeId));
        testComms.add(new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Payment_Type__c = 'P2', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Build Lock Up', Amount__c = 1000, RecordTypeId = OHRecTypeId));
        testComms.add(new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Payment_Type__c = 'P2', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Settled', Amount__c = 1000, RecordTypeId = OHRecTypeId));
        testComms.add(new Commission__c(Opportunity__c = testOpp.Id, Account__c = staffAcct.Id, Type__c = 'Commission Generated', Payment_Type__c = 'P1', Status__c = 'Pending', Category__c = 'Staff', Role__c = 'Sales Consultant', Payment_Stage__c = 'Unconditional Contract', Amount__c = 2000, RecordTypeId = StaffRecTypeId, Due_Date__c = Date.Today()));
        testComms.add(new Commission__c(Opportunity__c = testOpp.Id, Account__c = staffAcct.Id, Type__c = 'Commission Generated', Payment_Type__c = 'P2', Status__c = 'Pending', Category__c = 'Staff', Role__c = 'Sales Consultant', Payment_Stage__c = 'Unconditional Contract', Amount__c = 2000, RecordTypeId = StaffRecTypeId, Due_Date__c = Date.Today()));

        insert testComms;
    }

    static testMethod void testCommPaidFlagUpdate(){
        //create some data.
        setupBaseData();
        
        //confirm that 'Commissons Paid to OH' flag is false
        Opportunity opp = [Select Id, Commissions_Paid_to_OH__c FROM Opportunity WHERE Name = 'Test Account - Test Project - Test Apartments' LIMIT 1];
        System.AssertEquals(false, opp.Commissions_Paid_to_OH__c);
    
        //update OH Commissions to Paid
        LIST<Commission__c> commsOH = [Select Id FROM Commission__c WHERE Opportunity__c = :opp.Id AND RecordTypeID=:commRtMap.get('Oliver_Hume')];
        for (Commission__c c : commsOH) {
            c.Status__c = 'Paid';
        }
        update commsOH;

        //confirm that the 'Commissons Paid to OH' flag was updated to true
        opp = [Select Commissions_Paid_to_OH__c FROM Opportunity WHERE Id = :opp.Id];
        System.AssertEquals(true, opp.Commissions_Paid_to_OH__c);
    }

    static testMethod void testStatusUpdateToPayable(){
        //create some data.
        setupBaseData();
        
        Opportunity opp = [Select Id FROM Opportunity WHERE Name = 'Test Account - Test Project - Test Apartments' LIMIT 1];
    
        //update OH P1 Commissions to Paid
        LIST<Commission__c> commsOH = [Select Id FROM Commission__c 
                                       WHERE Opportunity__c = :opp.Id
                                       AND Payment_Type__c = 'P1'
                                       AND RecordTypeID=:commRtMap.get('Oliver_Hume')];
        for (Commission__c c : commsOH) {
            c.Status__c = 'Paid';
        }
        update commsOH;

        //confirm that non-Oliver Hume P1 commissions were updated to Payable
        LIST<Commission__c> commsOH2 = [Select Id, Status__c, Payment_Type__c FROM Commission__c 
                                        WHERE Opportunity__c = :opp.Id
                                        AND Payment_Type__c = 'P1'
                                        AND RecordTypeID!=:commRtMap.get('Oliver_Hume')];        
        System.Assert(!commsOH2.isEmpty());
        for (Commission__c c : commsOH2) {
            System.AssertEquals('Payable', c.Status__c);
        }

        //confirm that non-Oliver Hume P2 commissions were not updated
        commsOH2 = [Select Id, Status__c FROM Commission__c 
                    WHERE Opportunity__c = :opp.Id
                    AND Payment_Type__c = 'P2'
                    AND RecordTypeID!=:commRtMap.get('Oliver_Hume')];        
        System.Assert(!commsOH2.isEmpty());
        for (Commission__c c : commsOH2) {
            System.AssertEquals('Pending', c.Status__c);
        }

        //update OH P2 Commissions to Paid
        commsOH = [Select Id FROM Commission__c 
                   WHERE Opportunity__c = :opp.Id
                   AND Payment_Type__c = 'P2'
                   AND RecordTypeID=:commRtMap.get('Oliver_Hume')];
        for (Commission__c c : commsOH) {
            c.Status__c = 'Paid';
        }
        update commsOH;

        //confirm that non-Oliver Hume P2 commissions were updated to Payable
        commsOH2 = [Select Id, Status__c FROM Commission__c 
                    WHERE Opportunity__c = :opp.Id
                    AND Payment_Type__c = 'P2'
                    AND RecordTypeID!=:commRtMap.get('Oliver_Hume')];        
        System.Assert(!commsOH2.isEmpty());
        for (Commission__c c : commsOH2) {
            System.AssertEquals('Payable', c.Status__c);
        }

    }

    static testMethod void testPaidStatusUpdateFromFinanceChecked(){
        //Create some data.
        setupBaseData();
        
        Commission__c c = [SELECT Id, Amount__c FROM Commission__c 
                           WHERE Status__c != 'Paid'
                           AND Category__c = 'Oliver Hume'
                           AND Payment_Stage__c = 'Unconditional Contract'
                           LIMIT 1];
        
        // Assert we dont update the status unless we have set all fields
        c.Actual_Paid_Amount__c = c.Amount__c + 1;
        c.Finance_Dept_Approved__c = true;
        c.Finance_Comment__c = 'testing';
        update c;

        c = [SELECT Id, Actual_Paid_Amount__c, Amount__c, Amount_Excl__c, Finance_Dept_Approved__c, Status__c 
             FROM Commission__c 
             WHERE ID = :c.Id];
        System.AssertEquals('Pending', c.Status__c);

        c.Finance_Dept_Approved__c = false;
        c.Actual_Date_Paid__c = system.date.today();
        update c;
        
        c = [SELECT Id, Actual_Paid_Amount__c, Amount__c, Amount_Excl__c, Finance_Dept_Approved__c, Status__c 
             FROM Commission__c 
             WHERE ID = :c.Id];
        System.AssertEquals('Pending', c.Status__c);


        c.Finance_Dept_Approved__c = true;
        update c;
        c = [SELECT Id, Actual_Paid_Amount__c, Amount__c, Amount_Excl__c, Finance_Dept_Approved__c, Status__c 
             FROM Commission__c 
             WHERE ID = :c.Id];
        System.AssertEquals('Paid', c.Status__c);        
    }
        
        
    static testMethod void testPaidStatusUpdateAndFinanceChecked(){
  //Create some data.
        setupBaseData();
        
        Commission__c c = [SELECT Id, Amount__c FROM Commission__c 
                           WHERE Status__c != 'Paid'
                           AND Category__c = 'Oliver Hume'
                           AND Payment_Stage__c = 'Unconditional Contract'
                           LIMIT 1];                     
        
        // Test status and Finance Dept Approved checkbox updates
        c.Status__c = 'Paid';
        update c;
        
        Commission__c updatedC = [SELECT Id, Actual_Paid_Amount__c, Amount__c, Amount_Excl__c, Finance_Dept_Approved__c,Actual_Date_Paid__c,  Status__c 
             FROM Commission__c 
             WHERE ID = :c.Id];
        System.AssertEquals(true, updatedC.Finance_Dept_Approved__c);
        System.AssertEquals(c.Amount__c, updatedC.Actual_Paid_Amount__c);
        System.AssertEquals(system.date.today(), updatedC.Actual_Date_Paid__c);
    }

    static testMethod void testRollupFlagUpdates(){
        //create some data.
        setupBaseData();
        
        Commission__c c = [SELECT Id, Include_In_OHCommissionRollups__c, Irrevocable_Retain__c FROM Commission__c LIMIT 1];
        System.AssertEquals(false, c.Include_In_OHCommissionRollups__c);
        System.AssertEquals(false, c.Irrevocable_Retain__c);        
        
        va = [SELECT Id FROM Vendor_Authority__c LIMIT 1];
        va.Commission_Claim_Type__c = 'Irrevocable - Retain';
        c.Vendor_Authority__c = va.id;
        c.Category__c = 'House';
        update va;
        update c;
        
        c = [SELECT Id, Include_In_OHCommissionRollups__c, Irrevocable_Retain__c FROM Commission__c LIMIT 1];
        System.AssertEquals(true, c.Include_In_OHCommissionRollups__c);
        System.AssertEquals(true, c.Irrevocable_Retain__c);
    }
    

    static testMethod void testValidationRule(){
        //create some data.
        setupBaseData();
        Commission__c c = [SELECT Id, Amount__c FROM Commission__c
                           WHERE Category__c = 'Oliver Hume' AND Payment_Stage__c = 'Unconditional Contract'
                           LIMIT 1];
        
        // Change the amount and ensure the validation rule is triggered
        // e.g. 'You must specify a change amount reason'
        c.Amount__c = c.Amount__c + 1;
        try {
            update c;
        }
        catch(Exception e) {
            System.Assert(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'));
        }
    }    
    
    static testMethod void testCommissionCongaHelper(){
        //create some data.
        setupBaseData();

        LIST<id> idList = new LIST<id>();
        Commission__c c = [Select Id FROM Commission__c LIMIT 1];
        idList.add(c.Id);

        Integer i = CommissionCongaHelper.taxInvoicesAlreadyGenerated(idList);
        System.assertEquals(0, i);

        //Set the TaxInvoiceGenerated flag to true for a Commission
        c.TaxInvoiceGenerated__c = true;
        update c;
        
        i = CommissionCongaHelper.taxInvoicesAlreadyGenerated(idList);
        System.assertEquals(1, i);
        
        idList = new LIST<id>();
        LIST<Account> accs = [SELECT Id FROM Account LIMIT 10];
        for (Account a: accs) {
            idList.add(a.Id);
        }
        LIST<String> filteredIds = CommissionCongaHelper.filterIDs(idList);
        System.AssertEquals(1, filteredIds.size());
    }

    /*
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
    private static Commission__c rCommission;
    private static Commission__c aCommission;
    private static Account staffAcct;
    private static Bank_Account__c solicitorBank;

    @IsTest
    public static void setupBaseData(){
        Id chRtId = [select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Channel_Account' limit 1].Id;
        Account acct = new Account
        (
            Name = 'Test Account',
            RecordTypeId = chRtId
        );
        Id personId = [select Id from RecordType where sObjectType = 'Account' and isPersonType = true and DeveloperName = 'Staff_Account' limit 1].Id;
        staffAcct = new Account
        (
            FirstName = 'Staff',
            LastNAme = 'Account',
            RecordTypeId = personId
        );

        Id OHrTId = [select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Oliver_Hume_Account' limit 1].Id;
        Account OHAcct = new Account
        (
            Name = 'Oliver Hume',
            OH_Account__c = true,
            RecordTypeId = OHrTId
        );

        insert new List<Account>{acct, OHAcct, staffAcct};

        solicitorBank = new Bank_Account__c(Account__c = acct.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
        insert solicitorBank;

        testProject = new Project__c
        (
            Name = 'Test Project'
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
            Qty_Available__c =1
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
            CloseDate = System.today(),
            Actual_Settlement_Date__c = System.today(),
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
        Id OHRecTypeId = [select Id from RecordType where sObjectType = 'Commission__c' and DeveloperName = 'Oliver_Hume'].Id;
        Id StaffRecTypeId = [select Id from RecordType where sObjectType = 'Commission__c' and DeveloperName = 'Staff'].Id;
        ucCommission = new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Unconditional Contract', Amount__c = 10000, RecordTypeId = OHRecTypeId);
        ccCommission = new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Construction Commenced', Amount__c = 1000, RecordTypeId = OHRecTypeId);
        bluCommission = new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Build Lock Up', Amount__c = 1000, RecordTypeId = OHRecTypeId);
        sCommission = new Commission__c(Opportunity__c = testOpp.Id, Account__c = acct.Id, Type__c = 'Commission Generated', Status__c = 'Pending', Category__c = 'Oliver Hume', Payment_Stage__c = 'Settled', Amount__c = 1000, RecordTypeId = OHRecTypeId);
        ssCommission = new Commission__c(Opportunity__c = testOpp.Id, Account__c = staffAcct.Id, Type__c = 'Commission Generated', Status__c = 'Pending', Category__c = 'Staff', Role__c = 'Sales Consultant', Payment_Stage__c = 'Unconditional Contract', Amount__c = 2000, RecordTypeId = StaffRecTypeId);
        //rCommission = new Commission__c(Account__c = staffAcct.Id, Type__c = 'Retainer Paid', Status__c = 'Paid', Category__c = 'Staff', Role__c = 'Sales Consultant', Amount__c = 1000, Due_Date__c = date.today(), RecordTypeId = StaffRecTypeId);
        //aCommission = new Commission__c(Account__c = staffAcct.Id, Type__c = 'Advance', Status__c = 'Paid', Category__c = 'Staff', Role__c = 'Sales Consultant', Amount__c = 500, Due_Date__c = date.today(), RecordTypeId = StaffRecTypeId);
        Commission__c[] testComms = new Commission__c[]{ucCommission, ccCommission, bluCommission, sCommission, ssCommission};
        insert testComms;
    }
 
    /*   
    static testMethod void commissionPaidTriggerTest(){
        //create some data.
        setupBaseData();
        //set the recursion testing set.
        utility.commissionIdSet = new Set<String>();
        test.startTest();
            //check that the account rollups related to retainers advances is working
            staffAcct = [select Id, Retainer_Paid_Total__c, Retainer_Repaid__c, Advance_Paid_Total__c, Advance_Repaid__c, Retainer_Balance__c from Account where Id =: staffAcct.Id];
            system.assertEquals(1000, staffAcct.Retainer_Paid_Total__c);
            system.assertEquals(null, staffAcct.Retainer_Repaid__c);
            system.assertEquals(500, staffAcct.Advance_Paid_Total__c);
            system.assertEquals(null, staffAcct.Advance_Repaid__c);
            //change one of the commission records to Paid.
            ucCommission.Status__c = 'Paid';
            update ucCommission;
            //there should be 1 Commission Paid Record of the same type.
            system.assertEquals(1, [select Count() from Commission__c where Category__c = 'Oliver Hume' and Status__c = 'Paid' and Type__c = 'Commission Paid' and Payment_Stage__c = 'Unconditional Contract']);
            
            //the 1000 staff commission should be marked as payable
            ssCommission = [select Status__c from Commission__c where id =:ssCommission.Id];
            system.assertEquals('Payable', ssCommission.Status__c);
            
            //update the staff payable commission to paid
            //set the recursion testing set.
            utility.commissionIdSet = new Set<String>();
            ssCommission.Status__c = 'Paid';
            update ssCommission;
            
            //there should also be a retainer paid commission record for the staff account.
            Commission__c rpCommission = [select Amount__c from Commission__c where Category__c = 'Staff' and Status__c = 'Paid' and Type__c = 'Retainer Repaid' and Account__c =: staffAcct.Id limit 1];
            //there should be 1000 repaid 
            system.assertEquals(1000, rpCommission.Amount__c);
            //there should also be a advance paid commission record for the staff account.
            Commission__c apCommission = [select Amount__c from Commission__c where Category__c = 'Staff' and Status__c = 'Paid' and Type__c = 'Advance Repaid' and Account__c =: staffAcct.Id limit 1];
            //there should be 1000 repaid 
            system.assertEquals(500, apCommission.Amount__c);
            
            //there should now be a total 1000 retainer repaid total.
            //check that the account rollups related to retainers advances is working
            staffAcct = [select Id, Retainer_Paid_Total__c, Retainer_Repaid__c, Advance_Paid_Total__c, Advance_Repaid__c, Retainer_Balance__c from Account where Id =: staffAcct.Id];
            system.assertEquals(1000, staffAcct.Retainer_Paid_Total__c);
            system.assertEquals(1000, staffAcct.Retainer_Repaid__c);
            system.assertEquals(500, staffAcct.Advance_Paid_Total__c);
            system.assertEquals(500, staffAcct.Advance_Repaid__c);
            
            //also check that there is a commission paid record create for the excess $500
            Commission__c pcCommission = [select Amount__c from Commission__c where Category__c = 'Staff' and Status__c = 'Paid' and Type__c = 'Commission Paid' and Account__c =: staffAcct.Id limit 1];
            system.assertEquals(500, pcCommission.Amount__c);
        test.stopTest();
        
    }
        static testMethod void commissionOpptyRollupTest(){
        //create some data.
        setupBaseData();
        //set the recursion testing set.
        utility.commissionIdSet = new Set<String>();
        ucCommission.Status__c = 'Paid';
        update ucCommission;
        test.startTest();
            //check that the account rollups related to retainers advances is working
            testOpp = [select OH_Commission_Total__c, OH_Commission_Retain__c, OH_Commission_Received__c from Opportunity where Id =: testOpp.Id];
            system.assertEquals(13000, testOpp.OH_Commission_Total__c);
            system.assertEquals(null, testOpp.OH_Commission_Retain__c);
            system.assertEquals(10000, testOpp.OH_Commission_Received__c);
        test.stopTest();
    }
    */
}