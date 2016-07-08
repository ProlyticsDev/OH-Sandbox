//SalesFix : Test class to test the email opt out field between Lead / Contact and Global unsubscribe campaign
@isTest
private class CampaignMemberTriggerTest {
	
	Private Static String unsubStatus = 'Unsubscribed';
	Private Static String GlobaUnsubscribeCampaign = 'Oliver Hume Master - Email Opt Out';

	@isTest static void TestLeadEmailOptOutSync() {
		Campaign c = new Campaign(Name=CampaignMemberTriggerTest.GlobaUnsubscribeCampaign);		
		insert c;

		CampaignMemberStatus cms = new CampaignMemberStatus(CampaignId = c.Id,Label=unsubStatus,SortOrder=0);
		insert cms;

		Project__c p = new Project__c(Name='test project', City__c = 'Test', Description__c = 'Sample Description', Region__c = 'Melbourne', Street_Address__c = '12 Test', 
        Zip_Postal_Code__c = 'Victoria', Status__c = 'Planned'); 
		insert p;

		Lead l = new Lead(Salutation = 'Mr', FirstName = 'Test', LastName='Lead',
			Email ='test@test.com', Auto_Convert__c =false); //, Project_Picklist__c = 'test project');
		insert l;

		CampaignMember cm = new CampaignMember(CampaignId = c.Id, LeadId =l.Id,Status=CampaignMemberTriggerTest.unsubStatus);		
		insert cm;

		cm.Status='Sent';		
		update cm;

		cm.Status = CampaignMemberTriggerTest.unsubStatus;
		update cm;

		delete cm;	
		l = [Select Id,HasOptedOutOfEmail From Lead where id=:l.Id limit 1];
		system.assertEquals(false,l.HasOptedOutOfEmail);
	}

	@isTest static void TestContactEmailOptOutSync() {

		Campaign c = new Campaign(Name=CampaignMemberTriggerTest.GlobaUnsubscribeCampaign);		
		insert c;

        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
		Account pa = new Account(FirstName = 'test',LastName='account');
        pa.RecordTypeId = objRecordTypeAccount.Id;
        insert pa;		
        pa = [Select Id,PersonContactId from Account where Id =:pa.Id limit 1];

		CampaignMember cm = new CampaignMember(CampaignId = c.Id, ContactId =pa.PersonContactId,Status=CampaignMemberTriggerTest.unsubStatus);		
		insert cm;

		cm.Status='Sent';		
		update cm;

		cm.Status = CampaignMemberTriggerTest.unsubStatus;
		update cm;

		delete cm;	
		pa = [Select Id,PersonHasOptedOutOfEmail From Account where id=:pa.Id limit 1];
		system.assertEquals(false,pa.PersonHasOptedOutOfEmail);

	}

	@isTest static void TestLeadEmailOptOutReverse(){
		Campaign c = new Campaign(Name=CampaignMemberTriggerTest.GlobaUnsubscribeCampaign);		
		insert c;
/*
		Project__c p = new Project__c(Name='test project',City__c = 'Test', Description__c = 'Sample Description', Region__c = 'Melbourne', Street_Address__c = '12 Test', 
        Zip_Postal_Code__c = 'Victoria', Status__c = 'Planned'); 
		insert p;

		Lead l = new Lead(Salutation = 'Mr', FirstName = 'Test', LastName='Lead',
			Email ='test@test.com', Auto_Convert__c =false, Project_Picklist__c = 'test project', HasOptedOutOfEmail = false);
		insert l;
*/

        List<Suburb__c> subs = TestData.createSuburbs(2);
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        List<Project__c> projs = TestData.createProjects(2);
        Project__c proj = projs[0]; 
        proj.RecordTypeId = UtilClass.orgRecordTypeMap.get('project__c_apartments').Id;
        update proj;
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.RecordTypeId = recordType.get('lead_apartments').Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Email ='test@test.com';
        newLead.HasOptedOutOfEmail = false;
        newLead.Project_Picklist__c = proj.Name; 
        newLead.Enquiry_Source__c = 'Not GO Portal'; 
        insert newLead; 

		//l.HasOptedOutOfEmail = false;
		//update l;
		Contact con = [SELECT Id, HasOptedOutOfEmail FROM Contact WHERE Id in (SELECT ConvertedContactId FROM Lead WHERE Id=:newLead.Id) LIMIT 1];
		system.assert(con.HasOptedOutOfEmail == FALSE);
	}

	@isTest static void TestContactEmailOptOutReverse(){
		Campaign c = new Campaign(Name=CampaignMemberTriggerTest.GlobaUnsubscribeCampaign);		
		insert c;

		RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
		Account pa = new Account(FirstName = 'test',LastName='account',PersonHasOptedOutOfEmail = true);
        pa.RecordTypeId = objRecordTypeAccount.Id;
        insert pa;		
        
        pa.PersonHasOptedOutOfEmail = false;
        update pa;	
	}
    
    //To test EmailOptOutContactTrigger 
    @isTest static void TestContactEmailOptOut() {

		Campaign c = new Campaign(Name=CampaignMemberTriggerTest.GlobaUnsubscribeCampaign);		
		insert c;

        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = false and sobjectType='account' limit 1];
		Account acc = new Account(Name = 'test account');
        acc.RecordTypeId = objRecordTypeAccount.Id;
        insert acc;		
       
        Contact con = new Contact(LastName = 'MrTest', AccountId = acc.Id, Status__c = 'Current', HasOptedOutOfEmail = true);
        insert con;
        
        List<CampaignMember> cm = new List<CampaignMember>();
        cm = [select Id, ContactId from CampaignMember where CampaignId =: c.id  and ContactId =:con.Id];
        
        System.assertEquals(cm.size(), 1);
        
        con.HasOptedOutOfEmail = false;
        update con;
        
        cm = [select Id, ContactId from CampaignMember where CampaignId =: c.id  and ContactId =:con.Id];
        System.assertEquals(cm.size(), 0);
	}
		
}