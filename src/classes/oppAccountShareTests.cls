@isTest
private class oppAccountShareTests{

    static testMethod void opportunityShareTest(){
    	//Test Passes as is an oppty creation, not lead convert.
    	
    	//Create an opportunity owned by the running user. assign this opportunity to another user and back again and check to see if the account shares are updated accordingly.
    	//create 2 users.
    	//get a sales USER profile
    	profile salesProfile = [select id from profile where name = 'New Communities - Sales Consultant' limit 1];
    	//test user
    	User U1 = new user(username = 'ohtestappt123@test.com', profileId = salesProfile.Id, email='testing@test.com', lastName = 'test1', alias = 'alias1', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        User U2 = new user(username = 'ohtestappt1234@test.com', profileId = salesProfile.Id, email='testing@test.com', lastName = 'test1', alias = 'alias2', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        insert new User[]{U1,U2};
        
        Project__c[] projects = new Project__c[]{};
        Project__c p1 = new Project__c(Name = 'Test Project 1',
                                       City__c = 'Test', 
                                       Description__c = 'Sample Description', 
                                       Region__c = 'Melbourne', 
                                       Street_Address__c = '12 Test', 
                                       Zip_Postal_Code__c = 'Victoria',
                                       Status__c = 'Planned');
        projects.add(p1);
        insert projects;
        //create some sample opportunities to test campaign assignment.
        Account acc1 = new Account(Name = 'Account 1');
        insert acc1;
        Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1', OwnerId = U1.Id);
        Opportunity[] opps = new Opportunity[]{opp1};
        //run some tests
        test.startTest();
        insert opps;
        test.stopTest();
        //assert there is an account team member for user 1
        system.assertEquals(1, [select Count() from AccountTeamMember where AccountId =: acc1.Id and UserId =: U1.Id and TeamMemberRole = 'Opportunity Owner']);
    }
    
    static testMethod void opportunityShareChangeOwnerTest(){
    	//Test Passes as is an oppty creation, not lead convert.
    	
    	//Create an opportunity owned by the running user. assign this opportunity to another user and back again and check to see if the account shares are updated accordingly.
    	//create 2 users.
    	//get a sales USER profile
    	profile salesProfile = [select id from profile where name = 'New Communities - Sales Consultant' limit 1];
    	//test user
    	User U1 = new user(username = 'ohtestappt123@test.com', profileId = salesProfile.Id, email='testing@test.com', lastName = 'test1', alias = 'alias1', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        User U2 = new user(username = 'ohtestappt1234@test.com', profileId = salesProfile.Id, email='testing@test.com', lastName = 'test1', alias = 'alias2', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        insert new User[]{U1,U2};
        
        Project__c[] projects = new Project__c[]{};
        Project__c p1 = new Project__c(Name = 'Test Project 1',
                                       City__c = 'Test', 
                                       Description__c = 'Sample Description', 
                                       Region__c = 'Melbourne', 
                                       Street_Address__c = '12 Test', 
                                       Zip_Postal_Code__c = 'Victoria',
                                       Status__c = 'Planned'
                                      );
        projects.add(p1);
        insert projects;
        //create some sample opportunities to test campaign assignment.
        Account acc1 = new Account(Name = 'Account 1');
        insert acc1;
        Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1', OwnerId = U1.Id);
        Opportunity[] opps = new Opportunity[]{opp1};
        insert opps;
        test.startTest();
        //assert there is an account team member for user 1
        utility.oppAccIdSet = new Set<String>();
        //change the user
        opp1.OwnerId = U2.Id;
        update opp1;
        //assert that there is an account team member for user 2
        test.stopTest();
        system.assertEquals(1, [select Count() from AccountTeamMember where AccountId =: acc1.Id and UserId =: U2.Id and TeamMemberRole = 'Opportunity Owner']);
    }
    
    static testMethod void opportunityShareTestConvert(){
		//Test Passes as is an oppty creation, not lead convert.
    	
    	//Create an opportunity owned by the running user. assign this opportunity to another user and back again and check to see if the account shares are updated accordingly.
    	//create 2 users.
    	//get a sales USER profile
    	profile salesProfile = [select id from profile where name = 'New Communities - Sales Consultant' limit 1];
    	//test user
    	User U1 = new user(username = 'ohtestappt123@test.com', profileId = salesProfile.Id, email='testing@test.com', lastName = 'test1', alias = 'alias1', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        User U2 = new user(username = 'ohtestappt1234@test.com', profileId = salesProfile.Id, email='testing@test.com', lastName = 'test1', alias = 'alias2', TimeZoneSidKey = 'Australia/Sydney', LocaleSidKey = 'en_AU', LanguageLocaleKey = 'en_US', EmailEncodingKey = 'ISO-8859-1');
        insert new User[]{U1,U2};
        
        Project__c[] projects = new Project__c[]{};
        Project__c p1 = new Project__c(Name = 'Test Project 1', 
                                        Owner_Assignment__c = U1.Id,
                                         City__c = 'Test', 
                                         Description__c = 'Sample Description', 
                                         Region__c = 'Melbourne', 
                                         Street_Address__c = '12 Test', 
                                         Zip_Postal_Code__c = 'Victoria',
                                         Status__c = 'Planned');
        projects.add(p1);
        insert projects;
        
        
        Map<String, Id> recordTypeIds = new Map<String, Id>();
        for(RecordType r: [select Id, DeveloperName from RecordType where sObjectType = 'Lead']){
        	recordTypeIds.put(r.DeveloperName, r.Id);
        }
        //create a lead and insert is, should auto convert.
        Lead lead;
        system.runAs(U1){
	        lead = new Lead();
	        lead.Salutation = 'Mr';
	        lead.FirstName = 'fname';
	        lead.LastName = 'lname';
	        lead.Date_of_Enquiry__c = date.today();
	        lead.Enquiry_Method__c = 'Web Form';
	        lead.Enquiry_Source__c = 'Google';
	        lead.Property_Type__c = 'Land Only';
	        //HR - Set this flag to true to validate the conversion
	        lead.Auto_Convert__c = true;
	        //lead.Auto_Convert__c = true; //true;
	        lead.Project_Picklist__c = 'Test Project 1';
	        lead.email = 'test@email.com';
	        lead.Search_Campaign__c = true;
	        lead.Rating = 'Warm';
	        lead.RecordTypeId = recordTypeIds.get('New_Communities');
            lead.Web_2_Lead__c = true;
	        test.startTest();
	        insert lead;
	        test.stopTest();
        }
        //assert the lead is converted to an account
        lead = [select IsConverted, ConvertedAccountId from Lead where Id =: lead.Id];
        system.assertEquals(true, lead.IsConverted);
        //check the opportunity owner is U1
        Opportunity convertedOpp = [select Id, Name, OwnerId from Opportunity where AccountId =: lead.ConvertedAccountId];
        system.assertEquals(U1.Id, convertedOpp.OwnerId);
        system.assertEquals(1, [select Count() from AccountTeamMember where AccountId =: lead.ConvertedAccountId and UserId =: U1.Id and TeamMemberRole = 'Opportunity Owner']);
        //utility.oppAccIdSet = new Set<String>();
        
        
    }
}