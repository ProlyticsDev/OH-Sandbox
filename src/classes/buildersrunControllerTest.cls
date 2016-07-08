@IsTest
/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 26th August 2013
Purpose: Test Methods for the Builders Run Solution
*/

Private class buildersrunControllerTest{

    //Declare variables
    static User testUser;
    static Account testAccount;
    static Project__c project;
    
    //Create the sample data for testing
    static testMethod void validatebuildersrunController(){
    
        //Create the User record
        Profile p1 = [select id from profile where name = 'System Administrator' limit 1];        
        testUser = new User(username = 'test.user@aprika.com.au', profileId = p1.Id, email='test.user@aprika.com.au', firstName='Test', lastName = 'User', alias = 'tuer', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        insert testUser;
        
        //Create the Account record
        testAccount = new Account(Name='Aprika Test Agent');
        insert testAccount;
        
        project = new Project__c();
        project.Name = 'Test Project';
        project.Owner_Assignment__c = userInfo.getUserId();
         project.City__c = 'Test'; 
        project.Description__c = 'Sample Description'; 
        project.Region__c = 'Melbourne'; 
        project.Street_Address__c = '12 Test'; 
        project.Zip_Postal_Code__c = 'Victoria';    
        project.Status__c = 'Planned';
        insert project;
        
        //Create an instance of the Controller
        ApexPages.StandardController std = new ApexPages.StandardController(project);
        buildersrunController brc = new buildersrunController(std);
        
        brc.dummyRun.Project__c = project.Id;
        brc.dummyRun.Date__c = date.today();
        brc.dummyRun.Display_Village__c = 'Sample Village A';
        
        brc.addRow();
        brc.newBRs[1].deleteRow();
        
        brc.newBRs[0].newBR.Display_Builder__c = 'Metricon';
        brc.newBRs[0].newBR.Comments__c = 'Some notes';
        
        brc.createRuns();
        
        Builders_Run__c br = [select Id, Name FROM Builders_Run__c ORDER BY CreatedDate DESC LIMIT 1];
        system.assertEquals(br.Name, 'Sample Village A (Metricon - ' + brc.dummyRun.Date__c.format() +')');
        
        }
   
    }