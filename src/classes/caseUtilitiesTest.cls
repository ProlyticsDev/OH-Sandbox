/* HISTORY
	
	2016-03-30 Richard Clarke (RC) created class to add support to prepopulate Case.Contact and Case.User__c
	
*/
@isTest public without sharing class caseUtilitiesTest {

	// RC get record types and apartment sales consultant profile
	static final ID ITRequestRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType='Case' AND DeveloperName='IT_Request' LIMIT 1].Id;
	static final ID OHAccountRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType='Account' AND DeveloperName='Oliver_Hume_Account' LIMIT 1].Id;
	static final ID OHStaffRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType='Contact' AND DeveloperName='Oliver_Hume_Staff' LIMIT 1].Id;
	static final ID SalesProfileId = [Select Id from Profile where name = 'Apartments - Sales Consultant' LIMIT 1].Id;
	
	@testSetup static void testDataSetup() {
system.debug('***RC*** in testDataSetup');

		// RC create sales consultants
		User user1 = new User();
		user1.Username= 'test00001@caseUtilitiesTest.com';
		user1.Email = 'test00001@test.com';
		user1.Lastname = 'test00001';
		user1.Firstname = 'test00001';
		user1.Alias = 'test0001';
		user1.CommunityNickname = 'test00001';
		user1.TimeZoneSidKey = 'GMT';
		user1.LocaleSidKey = 'en_US';
		user1.EmailEncodingKey = 'ISO-8859-1';
		user1.LanguageLocaleKey = 'en_US';
		user1.ProfileId = SalesProfileId;
		insert user1;
		system.assertNotEquals(null,user1.Id);
system.debug('***RC*** Created test User test00001 Id=' + user1.Id + ' with Email=' + user1.Email );

		User user2 = new User();
		user2.Username= 'test00002@caseUtilitiesTest.com';
		user2.Email = 'test00002@test.com';
		user2.Lastname = 'test00002';
		user2.Firstname = 'test00002';
		user2.Alias = 'test0002';
		user2.CommunityNickname = 'test00002';
		user2.TimeZoneSidKey = 'GMT';
		user2.LocaleSidKey = 'en_US';
		user2.EmailEncodingKey = 'ISO-8859-1';
		user2.LanguageLocaleKey = 'en_US';
		user2.ProfileId = SalesProfileId;
		insert user2;
		system.assertNotEquals(null,user2.Id);
system.debug('***RC*** Created test User test00002 Id=' + user2.Id + ' with Email=' + user2.Email );
		
		// RC create OH business account and contact record to match user above
		Account OHAccount = new Account(Name = 'Oliver Hume Real Estate', ownerId = user1.ID, RecordTypeId = OHAccountRecordTypeId);
		insert OHAccount;
		system.assertNotEquals(null,OHAccount.Id);
system.debug('***RC*** Created test Accountt Oliver Hume Real Estate Id=' + OHAccount.Id );

		Contact OHContact1 = new Contact(Firstname = 'test00001', Lastname = 'test00001', Email = 'test00001@test.com', AccountId = OHAccount.Id, Business_Account__c = OHAccount.Id, RecordTypeId = OHStaffRecordTypeId);
		insert OHContact1;
		system.assertNotEquals(null,OHContact1.Id);
system.debug('***RC*** Created test Contact test00001 Id=' + OHContact1.Id + ' with Email=' + OHContact1.Email );

		Contact OHContact3 = new Contact(Firstname = 'test00003', Lastname = 'test00003', Email = 'test00003@test.com', AccountId = OHAccount.Id, Business_Account__c = OHAccount.Id, RecordTypeId = OHStaffRecordTypeId);
		insert OHContact3;
		system.assertNotEquals(null,OHContact3.Id);
system.debug('***RC*** Created test Contact test00003 Id=' + OHContact3.Id + ' with Email=' + OHContact3.Email );

		List<Contact> testOHContacts = [Select Id, Email, Business_Account__r.Name from Contact where Business_Account__r.Name = 'Oliver Hume Real Estate'];
		system.assertEquals(2,testOHContacts.size());
system.debug('***RC*** Created ' + testOHContacts.size() + ' first test OH Contacts');

		Set<string> SuppliedEmails = new Set<String>();
		SuppliedEmails.add('nomatches@test.com');
		SuppliedEmails.add('test00003@test.com');
		List<Contact> testOHContacts2 = [Select Id, Email, Business_Account__r.Name from Contact where Business_Account__r.Name = 'Oliver Hume Real Estate' and Email in :SuppliedEmails];
		system.assertEquals(1,testOHContacts2.size());
system.debug('***RC*** Created ' + testOHContacts2.size() + ' second test OH Contacts');

		// RC Make sure both user2 can see the Contacts under the test account (user1 can as it is the owner)
		AccountShare AccShare2 = new AccountShare(AccountId = OHAccount.Id, AccountAccessLevel = 'Read', OpportunityAccessLevel = 'None', CaseAccessLevel = 'None', UserOrGroupId = user2.Id);
		Insert AccShare2;
		system.assertNotEquals(null,AccShare2.Id);
system.debug('***RC*** Added account share for user2 ' + AccShare2.Id );
	}

	static testMethod void ContactAndUserAssignmentTestsUser1() 
	{
		// RC check record types
		system.assertNotEquals(null,ITRequestRecordTypeId);
		system.assertNotEquals(null,OHAccountRecordTypeId);
		system.assertNotEquals(null,OHStaffRecordTypeId);

		// RC check profile
		system.assertNotEquals(null,SalesProfileId);

		// RC recover sales consultant user
		User user1 = [Select Id from User where Username= 'test00001@caseUtilitiesTest.com' LIMIT 1];
		system.assertNotEquals(null,user1.Id);

		// RC Recover Account and Contacts
		Account OHAccount = [select Id from Account where Name = 'Oliver Hume Real Estate' LIMIT 1];
		system.assertNotEquals(null,OHAccount.Id);
		
		Contact OHContact1 = [Select Id from Contact where Email = 'test00001@test.com' and AccountId = :OHAccount.Id LIMIT 1];
		system.assertNotEquals(null,OHContact1.Id);
		
		Contact OHContact3 = [Select Id from Contact where Email = 'test00003@test.com' and AccountId = :OHAccount.Id LIMIT 1];
		system.assertNotEquals(null,OHContact3.Id);

		// RC test created cases end up assigned to the right contact and user
		test.startTest();

		List<Case> User1Cases = new List<Case>();

		// Test 1 - case without supplied email created by an active user with a matching OH contact record
	   	Case case01 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00001', Description = 'test0001', RecordTypeId = ITRequestRecordTypeId);
		User1Cases.add(case01);

		// Test 3 - case with supplied email not matching an OH contact or user created by an user active user with a matching OH contact record
	   	Case case03 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00003', Description = 'test0003', RecordTypeId = ITRequestRecordTypeId, SuppliedEmail = 'nomatches@test.com');
		User1Cases.add(case03);

		// Test 7 - case with supplied email matches user and OH contact
	   	Case case07 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00007', Description = 'test0007', RecordTypeId = ITRequestRecordTypeId, SuppliedEmail = 'test00001@test.com');
		User1Cases.add(case07);

		System.runAs (user1) {
		   	insert User1Cases;
			system.assertNotEquals(null,case01.Id);
system.debug('***RC*** Created test Case test00001 Id=' + case01.Id );
			system.assertNotEquals(null,case03.Id);
system.debug('***RC*** Created test Case test00003 Id=' + case03.Id );
			system.assertNotEquals(null,case07.Id);
system.debug('***RC*** Created test Case test00007 Id=' + case07.Id );
		}

		// Test 1 - case should be connected to OH contact and creating user
		case01 = [select Id, ContactId, User__c from Case where Id = :case01.Id LIMIT 1];
		system.assertEquals(OHContact1.Id,case01.ContactId);
		system.assertEquals(user1.Id,case01.User__c);

		// Test 3 - case should not be connected to a OH contact or user
		case03 = [select Id, ContactId, User__c from Case where Id = :case03.Id LIMIT 1];
		system.assertEquals(null,case03.ContactId);
		system.assertEquals(null,case03.User__c);

		// Test 7 - case should be linked to user and OH contact
		case07 = [select Id, ContactId, User__c from Case where Id = :case07.Id LIMIT 1];
		system.assertEquals(OHContact1.Id,case07.ContactId);
		system.assertEquals(user1.Id,case07.User__c);

		test.stopTest();
	}

	static testMethod void ContactAndUserAssignmentTestsUser2() 
	{
		// RC check record types
		system.assertNotEquals(null,ITRequestRecordTypeId);
		system.assertNotEquals(null,OHAccountRecordTypeId);
		system.assertNotEquals(null,OHStaffRecordTypeId);

		// RC check profile
		system.assertNotEquals(null,SalesProfileId);

		// RC recover sales consultant users
		User user2 = [Select Id from User where Username= 'test00002@caseUtilitiesTest.com' LIMIT 1];
		system.assertNotEquals(null,user2.Id);

		// RC Recover Account and Contacts
		Account OHAccount = [select Id from Account where Name = 'Oliver Hume Real Estate' LIMIT 1];
		system.assertNotEquals(null,OHAccount.Id);
		
		Contact OHContact1 = [Select Id from Contact where Email = 'test00001@test.com' and AccountId = :OHAccount.Id LIMIT 1];
		system.assertNotEquals(null,OHContact1.Id);
		
		Contact OHContact3 = [Select Id from Contact where Email = 'test00003@test.com' and AccountId = :OHAccount.Id LIMIT 1];
		system.assertNotEquals(null,OHContact3.Id);

		// RC test created cases end up assigned to the right contact and user
		test.startTest();

		List<Case> User2Cases = new List<Case>();

		// Test 2 - case without supplied email created by an active user without a matching OH contact record
	   	Case case02 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00002', Description = 'test0002', RecordTypeId = ITRequestRecordTypeId);
		User2Cases.add(case02);

		// Test 4- case with supplied email not matching an OH contact or user created by an user active user without a matching OH contact record
	   	Case case04 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00004', Description = 'test0004', RecordTypeId = ITRequestRecordTypeId, SuppliedEmail = 'nomatches@test.com');
		User2Cases.add(case04);

		// Test 5 - case with supplied email matches OH contact but not a user
	   	Case case05 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00005', Description = 'test0005', RecordTypeId = ITRequestRecordTypeId, SuppliedEmail = 'test00003@test.com');
		User2Cases.add(case05);
		
		// Test 6 - case with supplied email matches user but not an OH contacts
	   	Case case06 = new Case(Status='Queued for Assessment', Origin='Salesforce UI', Type='Changed Functionality', Subject='test00006', Description = 'test0006', RecordTypeId = ITRequestRecordTypeId, SuppliedEmail = 'test00002@test.com');
		User2Cases.add(case06);
		
		System.runAs (user2) {
		   	insert User2Cases;
			system.assertNotEquals(null,case02.Id);
system.debug('***RC*** Created test Case test00002 Id=' + case02.Id );
			system.assertNotEquals(null,case04.Id);
system.debug('***RC*** Created test Case test00004 Id=' + case04.Id );
			system.assertNotEquals(null,case05.Id);
system.debug('***RC*** Created test Case test00005 Id=' + case05.Id );
			system.assertNotEquals(null,case06.Id);
system.debug('***RC*** Created test Case test00005 Id=' + case06.Id );
		}

		// Test 2 - case should be connected to creating user only
		case02 = [select Id, ContactId, User__c from Case where Id = :case02.Id LIMIT 1];
		system.assertEquals(null,case02.ContactId);
		system.assertEquals(user2.Id,case02.User__c);

		// Test 4 - case should not be connected to a OH contact or user
		case04 = [select Id, ContactId, User__c from Case where Id = :case04.Id LIMIT 1];
		system.assertEquals(null,case04.ContactId);
		system.assertEquals(null,case04.User__c);
		
		// Test 5 - case should be linked to OH contact but not a user
		case05 = [select Id, ContactId, User__c from Case where Id = :case05.Id LIMIT 1];
		system.assertEquals(OHContact3.Id,case05.ContactId);
		system.assertEquals(null,case05.User__c);

		// Test 6 - case should be linked to user but not an OH contact
		case06 = [select Id, ContactId, User__c from Case where Id = :case06.Id LIMIT 1];
		system.assertEquals(null,case06.ContactId);
		system.assertEquals(user2.Id,case06.User__c);

		test.stopTest();
	}
}