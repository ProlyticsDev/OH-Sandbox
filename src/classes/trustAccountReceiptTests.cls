@isTest
private class trustAccountReceiptTests
{
    @isTest static void testTrustAccountReceiptGeneratorController()
    {
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];

        List<Account> accs = new List<Account>();

        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        //insert ohAccuont;
        accs.add(ohAccuont);

        Id personAccountRT = [select Id from RecordType where SobjectType='Account' AND IsPersonType=True limit 1].Id;

        Bank_Account__c ba = new Bank_Account__c(Name = 'BA1', Bank_Name__c = 'TestBank', Bank_Account_Number__c = '123456');
        insert ba;



        Account acc1 = new Account(FirstName = 'Test', LastName = 'Account', PersonEmail = 'test@test.com', RecordTypeId = personAccountRT);
        //insert acc1;
        accs.add(acc1);

        insert accs;

        Trust_Account__c ta = new Trust_Account__c(Oliver_Hume_Account__c = ohAccuont.Id, Bank_Account__c = ba.Id);
        insert ta;

        Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
        Opportunity opp2 = new Opportunity(Name = 'Test Opp2', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today().addDays(+14), Enquiry_Source__c = 'Channel2', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
        Opportunity opp3 = new Opportunity(Name = 'Test Opp3', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today().addDays(+98), Enquiry_Source__c = 'Channel2', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
        Opportunity opp4 = new Opportunity(Name = 'Test Opp4', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel3', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 2');

        Opportunity[] opps = new Opportunity[]{opp1, opp2, opp3, opp4};
        insert opps;

        List<Receipt__c> receipts = new List<Receipt__c>
        {
            new Receipt__c(Opportunity__c = opp1.Id, Trust_Account__c = ta.Id, Communication_Preference__c = 'Email'),
            new Receipt__c(Opportunity__c = opp1.Id, Trust_Account__c = ta.Id, Communication_Preference__c = 'Email')
        };

        insert receipts;

        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController([select Id, Communication_Preference__c, Trust_Account_Receipt_Number__c, Trust_Account__c from Receipt__c]);
        ssc.SetSelected(ssc.GetRecords());

        // cover the empty constructor
        trustAccountReceiptHandling tarh = new trustAccountReceiptHandling(ssc);

        trustAccountReceiptGeneratorController targc = new trustAccountReceiptGeneratorController(ssc);

        System.Assert(targc.GetReceipts().Size() == 2, 'Expected one result, got: ' + targc.GetReceipts().Size());

        Id receiptId = targc.GetReceipts()[0].Id;
        System.Assert(targc.toEmail.Get(receiptId), 'To Email map should have defaulted to true.');

        // Actual generation and emailing is done by javascript so can't test that here
        // Running twice just to ensure records are skipped the second time
        targc.SaveAndEmail();
        targc.SaveAndEmail();
        System.Assert(targc.saved, 'Expected \'saved\' member variable to be true.');

        Test.startTest();
        // check printing parameter
        targc.toPrint.Put(receiptId, true);
        targc.toPrint.Put(targc.GetReceipts()[1].Id, true);
        targc.Print();
        System.Assert(targc.printIds.Contains(receiptId), 'printIds should have included ' + receiptId + ', got: ' + targc.printIds);

        Test.SetCurrentPage(Page.trustAccountReceiptsToPrint);
        ApexPages.CurrentPage().GetParameters().Put('ids', targc.printIds);

        trustAccountReceiptPrintController tarpc = new trustAccountReceiptPrintController();
        System.Assert(tarpc.receipts.Size() == 2);


        // now check the attachment creation etc.
        trustAccountReceiptHandling.SendAndStoreReceipt(receiptId);

        List<Task> tasks = [select Id from Task where WhatId = : receiptId];
        //System.Assert(tasks.Size() > 0);
        // error coverage
        trustAccountReceiptHandling.SendAndStoreReceipt('notarealid');
        Test.stopTest();

    }
}