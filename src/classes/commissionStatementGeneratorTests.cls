@IsTest
private class commissionStatementGeneratorTests
{
	/*
    @IsTest public static void commissionStatementGeneratorTests()
    {
        Id personAccountRT = [select Id from RecordType where SobjectType='Account' AND IsPersonType=True limit 1].Id;
		RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
            
        Account pa1 = new Account(FirstName = 'Test', LastName = 'Account', PersonEmail = 'test@test.com', RecordTypeId = personAccountRT, Commission_Structure__c = 'NotBlank');
        Account pa2 = new Account(FirstName = 'Test', LastName = 'Account2', PersonEmail = 'test2@test.com', RecordTypeId = personAccountRT, Commission_Structure__c = 'NotBlank');
        Account solAccount = new Account(Name = 'Sol Account');
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        insert new List<Account>{pa1, pa2, solAccount};

        Bank_Account__c ba = new Bank_Account__c(BSB_Number__c = '123456', Bank_Name__c = 'TestBank', Name = 'BA1');
        insert ba;

        Trust_Account__c ta = new Trust_Account__c(Oliver_Hume_Account__c = ohAccuont.Id, Bank_Account__c = ba.Id);
        insert ta;

        Project__c proj = new Project__c(Name = 'Super Apartments', Trust_Account__c = ta.Id);
        insert proj;

        Product__c prod = new Product__c(Project__c = proj.Id,Qty_Available__c =1,  Street_Name__c = 'Test Street', Solicitor__c = solAccount.Id, Solicitors_Bank_Account__c =  ba.Id, Solicitors_Payment_Method__c = 'EFT');
        insert prod;

        Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Exchanged_Date__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = pa1.Id, Project_Picklist__c = 'Test Project 1', Primary_Product__c = prod.Id, Project__c = proj.Id);
        Opportunity opp2 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Exchanged_Date__c = date.today().AddMonths(1), Enquiry_Source__c = 'Channel1', AccountID = pa1.Id, Project_Picklist__c = 'Test Project 1', Primary_Product__c = prod.Id, Project__c = proj.Id);

        insert new List<Opportunity>{opp1, opp2};
        // commission lines for the first account, none for the other
        insert new List<Commission__c>
        {
            new Commission__c(Opportunity__c = opp1.Id, Account__c = pa1.Id, Status__c = 'Payable', Type__c = 'Commission Generated', Amount__c = 10, Due_Date__c = date.today()),
            new Commission__c(Opportunity__c = opp1.Id, Account__c = pa1.Id, Status__c = 'Payable', Type__c = 'Commission Generated', Amount__c = 20, Due_Date__c = date.today()),
            new Commission__c(Opportunity__c = opp1.Id, Account__c = pa1.Id, Status__c = 'Pending', Type__c = 'Commission Generated', Amount__c = 40, Due_Date__c = date.today()),
            new Commission__c(Opportunity__c = opp2.Id, Account__c = pa1.Id, Status__c = 'Pending', Type__c = 'Commission Generated', Amount__c = 80)
        };


        Test.StartTest();

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController([select Id from Account]);
        ssc.SetSelected(ssc.GetRecords());

        commissionStatementGeneratorController csgc = new commissionStatementGeneratorController(ssc);
        System.Assert(csgc.showSettings);

        // should add an error on screen and keep the settings present if start > end (effective > due)
        csgc.inputObj.Effective_Date__c = System.Today();
        csgc.inputObj.Due_Date__c = System.Today().AddDays(-1);
        csgc.ShowGenerator();
        System.Assert(csgc.showSettings);

        csgc.inputObj.Due_Date__c = System.Today().AddDays(1);
        csgc.ShowGenerator();
        System.Assert(!csgc.showSettings);


        csgc.selectAll = false;
        csgc.ToggleAll();

        for(Boolean selected : csgc.selectedAccounts.Values())
        {
            System.Assert(!selected);
        }

        csgc.selectAll = true;
        csgc.ToggleAll();

        csgc.Generate();

        //system.assertEquals('www.fixme.com', csgc.statementURL);
        
        pageReference pr = page.commissionStatement;

        // Use the new page reference with the statement controller... add a bad 'id' at the start to test the exception handling
        Test.SetCurrentPage(pr);

        pr.GetParameters().Put('account', 'abc;');
        
        commissionStatementController csc = new commissionStatementController();
        System.Assert(csc.accountIds.Size() == 0, 'Expected 0 account ids, got: ' + csc.accountIds.Size());

        // fix the parameter
        pr.GetParameters().Put('account', pa1.Id);
        //add the start and end dates.
        pr.GetParameters().Put('start', string.valueOf(System.Today().AddDays(-7)));
        pr.GetParameters().Put('end', string.valueOf(System.Today().AddDays(7)));
        
        csc = new commissionStatementController();
        System.Assert(csc.accountIds.Size() == 1, 'Expected 2 account ids, got: ' + csc.accountIds.Size());
        

        System.Assert(csc.commissions[0].GetAcct().Name == 'Test Account', 'Expected account name to be \'Test Account\', got: ' + csc.commissions[0].GetAcct().Name);

        // should have two months of data for pending:
        System.Assert(csc.commissions[0].GetMonths().Size() == 1, 'Expecting 1 months of data, got: ' + csc.commissions[0].GetMonths().Size());
        System.Assert(csc.commissions[0].GetStatementStart() == System.Today().AddDays(-7));

        Double runningTotal = 0;

        System.Debug(csc.commissions[0].GetRunningTotal());

        // running total should have two lines, $10 in the first, $30 (20 + 10) in the second
        System.assertEquals(2, csc.commissions[0].GetRunningTotal().Size());


        for(Double total : csc.commissions[0].GetRunningTotal().Values())
        {
            if(total > runningTotal)
            {
                runningTotal = total;
            }
        }

        System.Assert(runningTotal == 30, 'Expected final running total of $30, got: ' + runningTotal);


        Test.StopTest();
    }
    */
}