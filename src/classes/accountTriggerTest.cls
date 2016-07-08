@isTest
private class accountTriggerTest {

    static testMethod void AccountOwnerChangeTest() 
    {
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        list<Profile> listProfiles = new list<Profile>([Select Id from Profile where name = 'System Administrator']);
        if(listProfiles.size() > 0)
        {
            User user1 = new User();
            user1.Username= 'test00001' + Math.random() + '@test.com';
            user1.Email = 'test00001@test.com';
            user1.Lastname = 'test00001';
            user1.Firstname = 'test00001';
            user1.Alias = 'test0001';
            user1.CommunityNickname = 'test00001';
            user1.TimeZoneSidKey = 'GMT';
            user1.LocaleSidKey = 'en_US';
            user1.EmailEncodingKey = 'ISO-8859-1';
            user1.LanguageLocaleKey = 'en_US';
            user1.ProfileId = listProfiles[0].id;
            insert user1;
            
            User user2 = new User();
            user2.Username= 'test00002' + Math.random() + '@test.com';
            user2.Email = 'test00002@test.com';
            user2.Lastname = 'test00002';
            user2.Firstname = 'test00002';
            user2.Alias = 'test0002';
            user2.CommunityNickname = 'test00002';
            user2.TimeZoneSidKey = 'GMT';
            user2.LocaleSidKey = 'en_US';
            user2.EmailEncodingKey = 'ISO-8859-1';
            user2.LanguageLocaleKey = 'en_US';
            user2.ProfileId = listProfiles[0].id;
            insert user2;
        	test.startTest();
            Account objAccount = new Account(Name = 'Test Account', ownerId = user1.id);
            insert objAccount;
            
            Opportunity opp1 = new Opportunity(ownerId = user1.id, Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = objAccount.Id, Project_Picklist__c = 'Test Project 1');
            insert opp1;
            
            AccountTeamMember accountTM = new AccountTeamMember();
            accountTM.AccountId = objAccount.id;
            accountTM.TeamMemberRole = 'Marketo';
            accountTM.UserId = user1.id;
            insert accountTM;
			
            objAccount.ownerId = user2.id;
            update objAccount;
            test.stopTest();
            
            AccountShare objAccountShare = [Select id, AccountAccessLevel from AccountShare where AccountId =: objAccount.id limit 1];
            system.assertNotEquals(null,objAccountShare);
            system.assertEquals('Edit', objAccountShare.AccountAccessLevel);
            update objAccount;
        }
    }
}