@isTest
private class CommissionDetailControllerHelperTests { 
    private static Vendor_Authority__c va;
    private static Vendor_Sales_Authority__c vsa;
    private static Product_Assignment__c pa;
    private static Vendor_Sales_Product_Assignment__c vspa;
    private static Project__c project;
    private static Account OHAcct;
    private static Opportunity oppty;
    private static Bank_Account__c solicitorBank;

    @IsTest public static void SetupBaseData()
    {

        RecordType rt = [select id from RecordType where SobjectType ='Account' and Name = 'Oliver Hume Account' limit 1];

        Account acct = new Account
        (
            Name = 'Test Account',
            RecordTypeId = rt.Id,
            GST_Status__c='GST'
        );

        OHAcct = new Account
        (
            Name = 'Oliver Hume',
            RecordTypeId = rt.Id,
            GST_Status__c = 'GST'
            //OH_Account__c = true
        );
        
        
        insert new List<Account>{acct, OHAcct};
        
        solicitorBank = new Bank_Account__c(Account__c = acct.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
        insert solicitorBank;
        
        project = new Project__c
        (
            Name = 'Test Project',
            Status__c = 'In Progress',
            Type__c = 'Apartments',
            OH_Account__c = OHAcct.Id,
            City__c = 'Test', 
            Description__c = 'Sample Description', 
            Region__c = 'Melbourne', 
            Street_Address__c = '12 Test', 
            Zip_Postal_Code__c = 'Victoria'
        );

        insert project;

        System.Assert(project.Id != null, 'Project was not created successfully.');

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
            Project__c = project.Id,
            Status__c = 'Approved',
            Approval_PD__c = true,
            Approval_GM_SA__c = true,
            Admin_Fee__c = 5,
            Commission_Based_On__c = 'Margin Scheme Price',
            Type__c = 'General',
            Commission_Claim_Type__c = 'Standard',
            General_Expired__c = false,
            P1_Payment_Trigger__c = 'Settled',
            P1_Payment_Percentage__c = 100
        );

        insert va;

        

        Product__c product = new Product__c
        (
            Name = 'Test Apartments',
            Project__c = project.Id,
            Type__c = 'Apartment',
            Name_of_Stage__c = 'Stage 1',
            Contract_Type__c = 'One Part Contract',
            GST_Status__c = 'Inclusive',
            List_Price__c = 400000,
            Internal_Status_Override__c = 'Available',
            Solicitor__c = acct.Id,
            Solicitors_Bank_Account__c = solicitorBank.Id,
            Solicitors_Payment_Method__c = 'EFT',
            Qty_Available__c = 1, 
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

        

        insert product;

        vsa = new Vendor_Sales_Authority__c
        (
            Vendor_Authority__c = va.Id,
            Account__c = acct.Id,
            Active__c = true,
            Role__c = 'Sales Consultant',
            Commission_Dollars__c = 4,
            Commission_Percent__c = 4,
            //Consultancy fee Values?
            Project__c = project.id,
            Settled_Percent__c = 50,
            Unconditional_Percent__c = 50,
            P1_Payment_Trigger__c = 'Settled',
            P1_Payment_Percentage__c = 100
        );
        insert vsa;

        pa = new Product_Assignment__c
        (
            Vendor_Authority__c = va.Id,
            Product__c = product.Id,
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

        System.debug('COMBO\n' + [select VA_Product_Combo__c from Product_Assignment__c]);
        RecordType rType = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = 'Apartments' limit 1]; 

        oppty = new Opportunity
        (
            Name = 'Test Oppty',
            AccountId = acct.Id,
            Project__c = project.Id,
            Primary_Product__c = product.Id,
            StageName = 'Settled',
            CloseDate = System.today(),
            Actual_Settlement_Date__c = System.today(),
            Purchaser__c = 'Michael Knight',
            Margin_Scheme_Price__c = 100.00, //,
            RecordTypeId = rType.Id,
            Deposit_Due_Date__c = Date.today().addDays(10), 
            //Conditions_Other_Due_Date__c = Date.today(),
            Subject_to_Finance_Due_Date__c = null,
            Subject_to_FIRB_Due_Date__c = null,
            Subject_to_Soil_Test_Due_Date__c = null,
            Subject_to_Sale_of_Property_Due_Date__c = null,
            Conditions_Other_Due_Date__c = null
            //Rebate_Total__c = 0
        );

        insert oppty;

        va.P1_Payment_Trigger__c = 'unconditional';
        va.P2_Payment_Trigger__c = 'unconditional';
        va.OH_Commission_Percent__c = 20;
        //oppty.Unconditional_Due_Date__c = System.today();
        

        Item__c item = new Item__c();
        item.Opportunity__c = oppty.Id; 
        item.Price__c = 240000; 
        item.Product__c = product.Id; 

        insert item;
        
        //jh gotta do this to get the updated value from the roll up summar
        oppty = [SELECT Name, AccountId, Project__c , Primary_Product__c ,StageName ,CloseDate , Actual_Settlement_Date__c ,
            Purchaser__c , Margin_Scheme_Price__c, RecordTypeId , List_Price__c, Net_Price__c,  Unconditional_Due_Date__c FROM Opportunity WHERE Id = :oppty.Id limit 1]; 

        oppty.Project__r = project;
        project.Vendor__r = OHAcct;
        OHAcct.Vendor_Payment_Terms_Days__c = 60;
        vsa.Account__r = OHAcct;        
        OHAcct.GST_Status__c='GST';
        vsa.OH_Commission__c = 20;
        vsa.commission_percent__c = 20;

    }


    static testMethod void TestHelperMethods(){
        CommissionDetail_Helper.GetSectionHeader('oliver hume','1');
        CommissionDetail_Helper.GetSectionHeader('staff','1');
        CommissionDetail_Helper.GetSectionHeader('management','1');
        CommissionDetail_Helper.GetSectionHeader('channel','1');
        CommissionDetail_Helper.GetSectionHeader('house','1');
        CommissionDetail_Helper.GetSectionHeader('','1');

        CommissionDetail_Helper.GetShortName('oliver hume');
        CommissionDetail_Helper.GetShortName('staff');
        CommissionDetail_Helper.GetShortName('management');
        CommissionDetail_Helper.GetShortName('channel');
        CommissionDetail_Helper.GetShortName('house');
        CommissionDetail_Helper.GetShortName('');

        CommissionDetail_Helper.GetLabelPrefix('oliver hume','1');
        CommissionDetail_Helper.GetLabelPrefix('staff','1');
        CommissionDetail_Helper.GetLabelPrefix('management','1');
        CommissionDetail_Helper.GetLabelPrefix('channel','1');
        CommissionDetail_Helper.GetLabelPrefix('house','1');
        CommissionDetail_Helper.GetLabelPrefix('','1');

        System.assert(CommissionDetail_Helper.getCategories(new Map<String,String>())!=null);

        Map<string,CommissionModel> mp = new Map<string,CommissionModel>();
        mp.put('abc',new CommissionModel());
        CommissionDetail_Helper.RemoveCommissionCategory(new Opportunity(),mp);

        CommissionDetail_Helper.getRenderSection('oliver hume','oliver hume');

        CommissionDetail_Helper.getRenderSection('oliver hume','Development Sites');

        CommissionDetail_Helper.getCommissionRecordType('oliver hume');


        Account acc = new Account();
        acc.GST_Status__c = 'GST';
        Decimal dec= CommissionDetail_Helper.GSTInclusive(acc,200);
        System.assert(dec>0);
        acc.GST_Status__c = '';
        dec= CommissionDetail_Helper.GSTInclusive(acc,200);
        System.assert(dec>0);

        string s = CommissionDetail_Helper.ToCurrency(dec);


        SetupBaseData();
        RecordType staffCommission = [SELECT Id FROM RecordType WHERE SobjectType = 'Commission__c' AND DeveloperName = 'Oliver_Hume' limit 1]; 
        Commission__c c = new Commission__c();
        Commission__c c2 = new Commission__c();
        CommissionData cd=new CommissionData(c,c2);
        cd.isValid = true;
        
        

        CommissionDetail_Helper.CreateOliverHumeEntityCommissionDetails(cd,oppty,OHAcct.Id,va,1);

        ApexPages.StandardController std = new ApexPages.StandardController(oppty);
        opportunityCommissionController ctlr = new opportunityCommissionController(std);
        
        ctlr.Init();
        oppty = ctlr.Opp;

        oppty.Project__r.Vendor__r = OHAcct;
        System.assert(oppty.net_Price__c != null);
        System.assert(oppty.Project__r.Vendor__r != null);
        System.assert(oppty.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c != null);
        

        CommissionDetail_Helper.CreateChannelCommissionDetails(cd,oppty,OHAcct.Id,vsa,acc);
        CommissionDetail_Helper.CreateSalesConsultantCommissionDetails(cd,oppty,OHAcct.Id,vsa,acc);
        
        
    }

    static testmethod void TestController(){
        SetupBaseData();
        ApexPages.StandardController std = new ApexPages.StandardController(oppty);
        
        opportunityCommissionController ctlr = new opportunityCommissionController(std);
        Commission__c coms = new Commission__c(); 
        RecordType staffCommission = [SELECT Id FROM RecordType WHERE SobjectType = 'Commission__c' AND DeveloperName = 'Oliver_Hume' limit 1]; 
        coms.RecordTypeId = staffCommission.Id; 
        Account acc = [SELECT Id FROM Account limit 1]; 
        coms.Account__c = acc.Id; 
        coms.Opportunity__c = [SELECT Id FROM Opportunity limit 1].Id; 
        insert coms;  

        Test.startTest(); 
        ctlr.Init();
        ctlr.SaveData();
        ctlr.getMsg();
        Test.stopTest(); 
    }
}