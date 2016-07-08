/** 
* @author       JH 
* @date         10/03/2016
* @description  Contains all the unit tests for the lead framework. Tests each work module and entire end to end lead conversions based on record type. 
*/ 
@isTest 
public class LeadFrameworkTest {

    @testSetup static void setupData() {
        TestData.createSuburbs(1); 
    }

    /**
    * @author Jimmy Hesketh
    * @date 21/03/2016
    * @description Following unit test checks an apartment lead being converted into the following: 
    */ 
    static testMethod void apartmentLeadConversionTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        proj.RecordTypeId = UtilClass.orgRecordTypeMap.get('project__c_apartments').Id;
        update proj;
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.RecordTypeId = recordType.get('lead_apartments').Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Project_Picklist__c = proj.Name; 
        newLead.Enquiry_Source__c = 'website';
        insert newLead; 

        List<Lead> leadsForConversion = new List<Lead>(); 
        leadsForConversion.add(newLead); 
        Test.startTest();
        Lead convertedLead = [SELECT ConvertedOpportunityId FROM Lead WHERE Id = :newLead.Id limit 1]; 
        //jh in this scenario should be converted to a opportunity 
        system.assert(String.isNotBlank(convertedLead.ConvertedOpportunityId)); 

       // List<Apex_Error__c> errors = [SELECT Id FROM Apex_Error__c]; 
      //  system.assertEquals(errors.size(), 0);  
        Test.stopTest(); 
    }
    /*
    * @author Jimmy Hesketh
    * @date 20/06/2016
    * @description Following unit test checks an apartment lead being converted w a enquiry: 
    */ 
    static testMethod void apartmentCreateProjectEnquiriesPositive() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        List<Project__c> projs = TestData.createProjects(2);
        Project__c proj = projs[0]; 
        proj.RecordTypeId = UtilClass.orgRecordTypeMap.get('project__c_apartments').Id;
        update proj;
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.RecordTypeId = recordType.get('lead_apartments').Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Project_Picklist__c = proj.Name; 
        newLead.Enquiry_Source__c = 'Not GO Portal'; 
        insert newLead; 

        Test.startTest(); 
        Lead convertedOpp = [SELECT ConvertedOpportunityId FROM Lead WHERE Id = :newLead.Id limit 1]; 
        Opportunity theOpp = [SELECT Id, (SELECT Id FROM Project_Enquiries__r), RecordTypeId FROM Opportunity limit 1];

        RecordType rType = [SELECT Name FROM RecordType WHERE Id = :theOpp.RecordTypeId limit 1];  
        system.assertEquals(rType.Name, 'Apartments'); 

        system.assertEquals(theOpp.Project_Enquiries__r.size(), 1); 
        
        Project__c proj2 = projs[1];
        proj2.RecordTypeId = UtilClass.orgRecordTypeMap.get('project__c_apartments').Id; 
        update proj2; 
        Lead newLead2 = TestData.createLead(proj2.Name); 
        newLead2.RecordTypeId = recordType.get('lead_apartments').Id; 
        newLead2.Auto_Convert__c = false; 
        newLead2.Project_Picklist__c = proj2.Name; 
        newLead2.Project__c = proj2.Id; 
        newLead2.Enquiry_Source__c = 'Not GO Portal'; 
        insert newLead2; 

        Opportunity theOpp2 = [SELECT Id, (SELECT Id FROM Project_Enquiries__r), RecordTypeId FROM Opportunity limit 1];
        system.assertEquals(theOpp2.Project_Enquiries__r.size(), 2); 
        Test.stopTest(); 
    }

    /**
    * @author Jimmy Hesketh
    * @date 21/06/2016
    * @description Issue where the conversion logic hadn't populated the return oppty ID 
    */ 
    static testMethod void apartmentsCheckOppReturnPositive() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        proj.Business_Unit__c = 'Apartments'; 
        proj.RecordTypeId = UtilClass.orgRecordTypeMap.get('project__c_apartments').Id;
        update proj;
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.RecordTypeId = recordType.get('lead_apartments').Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Project_Picklist__c = proj.Name; 
        newLead.Enquiry_Source__c = 'Not GO Portal'; 
        
        ApexPages.StandardController stdCont = new ApexPages.StandardController(newLead); 
        LeadExcon leadExCon = new LeadExcon(stdCont); 
        leadExCon.leadRecord = newLead; 
        leadExCon.project = proj.Name;
        leadExCon.enquirySource = 'Unit test';  
        

        Test.startTest(); 
        PageReference pageRef = leadExCon.saveLead(); 
        system.debug('The reference returned: ' + pageRef.getUrl()); 
        system.assert(!pageRef.getUrl().contains('null')); 
        Test.stopTest(); 
    }

     /**
    * @author Jimmy Hesketh
    * @date 21/03/2016
    * @description Following unit test checks an apartment lead being converted into the following: 
    */ 
    static testMethod void propertyConnectAssignmentTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.RecordTypeId = recordType.get('lead_property_connect').Id; 
        newLead.Auto_Convert__c = false; 

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true; 
        newLead.setOptions(dmo); 
        newLead.Project__c = null; 
        newLead.Project_Picklist__c = ''; 
        insert newLead; 

        //jh - get the updated lead.. 
        Lead theLead = [SELECT OwnerId FROM Lead WHERE Id = :newLead.Id limit 1]; 

        Group pconnectQueue = [SELECT Id FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Property_Connect' limit 1]; 
        //jh - check that the lead has the property connect queue as the owner. 
        system.assert(theLead.OwnerId == pconnectQueue.Id); 
    }

    /**
    * @author Jimmy Hesketh
    * @date 21/03/2016
    * @description Following unit test checks a property connect lead being converted: 
    */ 
    static testMethod void propertyConnectConversionPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get('lead_property_connect').Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Project_Picklist__c = 'Test0'; 

        Test.startTest(); 
        LeadFramework.taskList = new List<Task>(); 
        LeadFramework.existingOppsToUpdate = new List<Opportunity>(); 
        LeadFramework.duplicateAccEmail = new Map<String, Account>(); 
        system.assert(LeadFramework.duplicateAccEmail != null);  
        insert newLead; 

        //jh - check that  the lead is automatically converted. 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :newLead.Id limit 1]; 
        system.assert(convertedLead.IsConverted); 

        //jh - check that the person acc from conversion has the website user category set 
        Account personAcc = [SELECT Website_User_Category__c FROM Account WHERE Id = :convertedLead.ConvertedAccountId limit 1]; 
       // system.assert(String.isNotBlank(personAcc.Website_User_Category__c)); 
        Test.stopTest(); 
    }

     /**
    * @author Jimmy Hesketh
    * @date 21/03/2016
    * @description Following unit test checks a membership enquiry is converted to a silver acc : 
    */ 
    static testMethod void membershipEnquiryConversionPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_MEMBERSHIPENQUIRY_RECORDTYPE).Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Project_Picklist__c = 'Test0'; 

        Test.startTest(); 
        //system.assert(LeadFramework.duplicateAccEmail != null);  
        system.debug('Enquiry conversion positive unit test: '); 
        insert newLead; 

        //jh - check that  the lead is automatically converted. 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :newLead.Id limit 1]; 
        system.assert(convertedLead.IsConverted); 

        //jh - check that the person acc from conversion has the website user category set 
        Account personAcc = [SELECT Website_User_Category__c FROM Account WHERE Id = :convertedLead.ConvertedAccountId limit 1]; 
        system.assertEquals(personAcc.Website_User_Category__c, 'Silver'); 
        Test.stopTest(); 
    }

     /**
    * @author Jimmy Hesketh
    * @date 21/03/2016
    * @description Following unit test checks a membership enquiry is converted to a silver acc : 
    */ 
    static testMethod void membershipEnquiryConversionGoldPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead('notavalidprojectname'); 
        newLead.Enquiry_Method__c = 'testing';
        newLead.Enquiry_Source__c = 'Walk-in';  
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_MEMBERSHIPENQUIRY_RECORDTYPE).Id; 
        newLead.Auto_Convert__c = true; 
        newLead.Project_Picklist__c = 'notavalidprojectname'; 

        Test.startTest(); 
        insert newLead; 

        Lead lead2 = newLead.clone(); 
        lead2.Comments__c = 'A Gold enquiry from the website'; 
        insert lead2; 
        //jh should be populated as is a duplicate email 
        system.assert(LeadFramework.duplicateAccEmail != null); 

        //jh - check that  the lead is automatically converted. 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :newLead.Id limit 1]; 
        system.assert(convertedLead.IsConverted); 

        //jh - check that the person acc from conversion has the website user category set 
        Task goldEnquiryTask = [SELECT Id, WhoId, WhatId, Description FROM Task WHERE WhatId = :convertedLead.ConvertedAccountId limit 1]; 
        system.assert(goldEnquiryTask.Description.contains('Gold')); 
        List<Apex_Error__c> errors = [SELECT Id FROM Apex_Error__c]; 
        system.debug('Gold errors' ); 
        system.assertEquals(errors.size(),0); 
        Test.stopTest(); 
    }

    /**
    * @author Jimmy Hesketh
    * @date 13/04/2016
    * @description 
    */ 
    static testMethod void dsaBusinessLeadConversionPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get('lead_development_sites').Id; 
        newLead.Auto_Convert__c = true; 
        newLead.Company = 'Test Company';
        newLead.Status = 'Qualified'; 

        Test.startTest(); 
        LeadFramework.taskList = new List<Task>(); 
        LeadFramework.existingOppsToUpdate = new List<Opportunity>(); 
        LeadFramework.duplicateAccEmail = new Map<String, Account>();
        insert newLead;  
        system.assert(LeadFramework.duplicateAccEmail != null); 
        //jh - check that  the lead is  converted. 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId, IsConverted FROM Lead WHERE Id = :newLead.Id limit 1]; 
        system.assert(convertedLead.IsConverted); 
        //jh - check that the record type of the account is business 
        Account convertedAcc = [SELECT RecordTypeId, Id FROM Account WHERE Id =:convertedLead.ConvertedAccountId limit 1]; 
        system.assertEquals(convertedAcc.RecordTypeId, UtilClass.orgRecordTypeMap.get('account_business_account').Id); 

        Test.stopTest(); 
    }

     /**
    * @author Jimmy Hesketh
    * @date 14/04/2016
    * @description tests that the subscription process just converts the lead into a person account with the subscription options. 
    */ 
    static testMethod void subscriptionLeadConversionPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get('lead_subscription').Id; 
        newLead.Web_2_Lead__c = false; 
        newLead.Sub_DSA__c = true; 
        newLead.Auto_Convert__c = true; 
        newLead.Status = 'Qualified';  

        insert newLead; 

        Test.startTest(); 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id =:newLead.Id]; 
        Account acc = [SELECT Id, Sub_DSA__pc FROM Account WHERE Id =:convertedLead.ConvertedAccountId]; 
        system.assertEquals(acc.Sub_DSA__pc, true); 
        system.assertEquals(convertedLead.ConvertedOpportunityId, null); 
        Test.stopTest(); 
    }

    /**
    * @author Jimmy Hesketh
    * @date 05/07/2016
    * @description Unit test to fix bug where the dedup wasn't populating the person accs sub fields after conversion. 
    */ 
    static testMethod void deduplicateWithSubscriptionsPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;

        Campaign camp = new Campaign(Name = 'Oliver Hume Master - Email Opt Out'); 
        insert camp; 

        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get('lead_subscription').Id; 
        newLead.Web_2_Lead__c = false; 
        newLead.Sub_DSA__c = true; 
        newLead.Auto_Convert__c = true; 
        newLead.Status = 'Qualified';  

        insert newLead; 

        Lead lead2 = newLead.clone(); 
        lead2.Sub_DSA__c = false; 
        lead2.Auto_Convert__c = false; 
        //lead2.Project_Picklist__c=''; 
        lead2.Sub_OH_Property_Funds__c = true; 
        system.debug('Second conversion has started: '); 
        insert lead2; 

      
       /* lead2.Project_Picklist__c = proj.Name; 
        
        update lead2;*/ 

        Test.startTest(); 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id =:newLead.Id]; 
        Account acc = [SELECT Id, Sub_DSA__pc, Sub_OH_Property_Funds__pc FROM Account WHERE Id =:convertedLead.ConvertedAccountId]; 
        system.assertEquals(acc.Sub_DSA__pc, true); 
        system.assertEquals(acc.Sub_OH_Property_Funds__pc, true); 
        system.assertEquals(convertedLead.ConvertedOpportunityId, null); 
        Test.stopTest(); 
    }

    /**
    * @author Jimmy Hesketh
    * @date 14/04/2016
    * @description tests that new communities leads can still auto convert through to a person account and opportunity. 
    */ 
    static testMethod void newCommunititiesLeadConversionPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_NEW_COMMUNITIES_RECORDTYPE).Id; 
        newLead.Web_2_Lead__c = false; 
        newLead.Sub_DSA__c = false; 
        newLead.Auto_Convert__c = true; 
        newLead.Project__c = proj.Id; 
        newLead.Status = 'Qualified';  

        insert newLead; 

        Test.startTest(); 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id =:newLead.Id]; 
        system.assert(convertedLead != null);  
        system.assert(String.isNotBlank(convertedLead.ConvertedAccountId)); 
        system.assert(String.isNotBlank(convertedLead.ConvertedOpportunityId)); 
        Test.stopTest(); 
    }

       /**
    * @author Jimmy Hesketh
    * @date 13/04/2016
    * @description 
    */ 
    static testMethod void propertyFundsLeadConversionPositiveTest() {
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_PROPERTY_FUND_RECORDTYPE).Id; 
        newLead.Sub_DSA__c = true; 
        newLead.Web_2_Lead__c = false; 
        newLead.Auto_Convert__c = true; 
        newLead.Status = 'Qualified';  

        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.useDefaultRule = true; 
        newLead.setOptions(dmo); 
        insert newLead; 

        Test.startTest(); 
        Lead convertedLead = [SELECT ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id =:newLead.Id]; 
        system.assert(convertedLead != null);  
        system.assertEquals(convertedLead.ConvertedOpportunityId, null); 
        Test.stopTest(); 
    }

    //jh - test that a list of leads builds a map of opportunities based on the project of the leads & opportunities 
    static testMethod void buildOpportunityListForProjectPositiveTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 
        TestData.createProjects(1); 
        
        TestData.createOpportunities(1, UtilClass.orgRecordTypeMap.get('opportunity_apartments').Id, acc[0].Id); 

        List<Lead> newLeadList = new List<Lead>(); 
        Lead newLead = new Lead(); 
        newLead.FirstName = 'Test first name'; 
        newLead.LastName = 'Test last name'; 
        newLead.Email = 'testemail@test.com'; 
        newLead.Project_Picklist__c = 'Test0'; 
        newLeadList.add(newLead); 

        Map<String, List<Opportunity>> oppList = LeadFramework.buildOpportunityListForProject(newLeadList); 

        system.assert(oppList != null && !oppList.isEmpty()); 
        system.assertEquals(oppList.size(), 1); 
    }

    static testMethod void deduplicateLeadsAgainstAccountsPositiveTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 
        acc[0].PersonEmail = 'testemail@test.com'; 
        update acc; 

        Lead newLead = new Lead(); 
        newLead.FirstName = 'Test first name'; 
        newLead.LastName = 'Test last name'; 
        newLead.Email = 'testemail@test.com'; 

        Test.startTest(); 
        LeadFramework.duplicateAccEmail = new Map<String, Account>(); 
        LeadFramework.deduplicateLeadEmailAgainstAccounts(new List<Lead>{newLead}); 
        Test.stopTest(); 

        system.assertEquals(LeadFramework.duplicateAccEmail.size(), 1); 
    }

    static testMethod void deduplicateLeadsAgainstOpportunitiesTest() {

    }

    static testMethod void leadIsDuplicatePositiveTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 

        Lead newLead = new Lead(); 
        newLead.FirstName = acc[0].FirstName; 
        newLead.LastName = acc[0].LastName; 
        newLead.Email = acc[0].PersonEmail; 

        LeadFramework.deduplicateLeadEmailAgainstAccounts(new List<Lead>{newLead}); 
        Map<String, Account> dupLeads = LeadFramework.duplicateAccEmail; 

        system.assertEquals(dupLeads.size(), 1); 
        Boolean isDup = LeadFramework.leadIsDuplicate(newLead); 
        system.assert(isDup); 
    }

    static testMethod void leadIsDuplicateNegativeTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 

        Lead newLead = new Lead(); 
        newLead.FirstName = acc[0].FirstName; 
        newLead.LastName = acc[0].LastName; 
        newLead.Email = 'thisshouldnotbeadup@test.com'; 

        LeadFramework.deduplicateLeadEmailAgainstAccounts(new List<Lead>{newLead}); 
        Map<String, Account> dupLeads = LeadFramework.duplicateAccEmail; 
        //jh - shouldn't be populated or instantiated
        system.assert(dupLeads.isEmpty()); 
        LeadFramework.duplicateAccEmail = new Map<String, Account>(); 
        Boolean isDup = LeadFramework.leadIsDuplicate(newLead); 
        system.assert(!isDup); 
    }

    static testMethod void leadIsIndividualTest() {
        Lead newLead = new Lead(); 
        newLead.FirstName = 'First Name'; 
        newLead.LastName = 'Last Name'; 
        newLead.Email = 'thisshouldnotbeadup@test.com'; 

        Test.startTest(); 
        Boolean isIndiv = LeadFramework.leadIsIndividual(newLead); 
        system.assert(isIndiv); 
        newLead.ABN__c = '12345'; 
        isIndiv = LeadFramework.leadIsIndividual(newLead); 
        system.assertNotEquals(isIndiv, true); 
        Test.stopTest(); 
    }

    //test where a account exists and the lead should be merged 
    static testMethod void createAccountOnConversionTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 

        Lead newLead = new Lead(); 
        newLead.FirstName = acc[0].FirstName; 
        newLead.LastName = acc[0].LastName; 
        newLead.Email = acc[0].PersonEmail; 

        LeadFramework.deduplicateLeadEmailAgainstAccounts(new List<Lead>{newLead}); 
        Map<String, Account> dupLeads = LeadFramework.duplicateAccEmail; 

        system.assertEquals(dupLeads.size(), 1); 
        Boolean isDup = LeadFramework.leadIsDuplicate(newLead); 
        system.assert(isDup); 

        Database.LeadConvert convertContext = new Database.LeadConvert(); 
        convertContext.setLeadId(newLead.Id); 

        Database.LeadConvert updatedContext = LeadFramework.createAccountOnConversion(true, convertContext, newLead); 
    }

    static testMethod void createOpportunityOnConversionTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 
        TestData.createProjects(1); 
        
        TestData.createOpportunities(1, UtilClass.orgRecordTypeMap.get('lead_apartments').Id, acc[0].Id); 

        List<Lead> newLeadList = new List<Lead>(); 
        Lead newLead = new Lead(); 
        newLead.FirstName = 'Test first name'; 
        newLead.LastName = 'Test last name'; 
        newLead.Email = 'testemail@test.com'; 
        newLead.Project_Picklist__c = 'Test0'; 
        newLeadList.add(newLead); 

        LeadFramework.duplicateAccEmail = new Map<String, Account>(); 
        LeadFramework.duplicateAccEmail.put('testemail@test.com', acc[0]); 
        LeadFramework.existingOppsToUpdate = new List<Opportunity>(); 

        Map<String, List<Opportunity>> oppList = LeadFramework.buildOpportunityListForProject(newLeadList); 
        system.assert(oppList != null && !oppList.isEmpty()); 

        Database.LeadConvert leadContext = new Database.LeadConvert(); 
        leadContext.setLeadId(newLead.Id); 
        leadContext.setConvertedStatus('Qualified');
        leadContext.setOwnerId(UserInfo.getUserId());
        leadContext.setAccountId(acc[0].Id);  
        Test.startTest(); 
        Database.LeadConvert updatedContext = LeadFramework.createOpportunityOnConversion(leadContext, newLead, oppList);

        system.assert(updatedContext.isDoNotCreateOpportunity()); 
        Test.stopTest(); 
    }

    static testMethod void createTaskOnConversionTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 

        Lead newLead = new Lead(); 
        newLead.FirstName = acc[0].FirstName; 
        newLead.LastName = acc[0].LastName; 
        newLead.Email = acc[0].PersonEmail;
        newLead.Web_2_Lead__c = true;  
        newLead.Salutation = 'Mr'; 
        newLead.Enquiry_Method__c = 'Web Form'; 
        newLead.Auto_Convert__c = false; 

        LeadFramework.deduplicateLeadEmailAgainstAccounts(new List<Lead>{newLead}); 
        LeadFramework.taskList = new List<Task>(); 
        Map<String, Account> dupLeads = LeadFramework.duplicateAccEmail; 

        system.assertEquals(dupLeads.size(), 1); 
        Boolean isDup = LeadFramework.leadIsDuplicate(newLead); 
        system.assert(isDup); 

        insert newLead; 

        Database.LeadConvert convertContext = new Database.LeadConvert(); 
        convertContext.setLeadId(newLead.Id); 
        convertContext.setConvertedStatus('Qualified');
        convertContext.setOwnerId(UserInfo.getUserId()); 

        Database.LeadConvert updatedContext = LeadFramework.createAccountOnConversion(true, convertContext, newLead); 
        Database.LeadConvertResult lcr = Database.convertLead(updatedContext); 
        LeadFramework.taskList = new List<Task>(); 


        Test.startTest(); 
        LeadFramework.createTaskOnConversion(true, newLead, lcr, '', false); 
        insert LeadFramework.taskList; 
        Task assignedTask = [SELECT Id, Category__c FROM Task WHERE WhatId = :lcr.getOpportunityId()]; 
        Test.stopTest(); 

        system.assert(assignedTask != null); 
        system.assertEquals(assignedTask.Category__c, 'Web Form'); 
    }
    
    static testMethod void shareOpportunityRecordPositiveTest() {
        TestData.createSuburbs(1); 
        TestData.createAccounts(1); 
        List<Account> acc = TestData.createPersonAccounts(1); 
        TestData.createProjects(1); 
        
        TestData.createOpportunities(1, UtilClass.orgRecordTypeMap.get('lead_apartments').Id, acc[0].Id); 

        Test.startTest(); 
        List<Opportunity> opps = [SELECT Id FROM Opportunity]; 
        User newUserTest = [SELECT Id FROM User limit 1];
        opps[0].OwnerId = newUserTest.Id; 
        update opps; 

        LeadFramework.oppSharesForInsert = new List<OpportunityShare>(); 
        LeadFramework.shareOpportunityRecord(opps[0]); 
        system.assert(LeadFramework.oppSharesForInsert != null && LeadFramework.oppSharesForInsert.size() == 1); 

        Test.stopTest(); 
    }

    static testMethod void getAdminUserIdTest() {
        String adminId = LeadFramework.getAdminUserId();
        //check that a id is returned from the method  
        system.assert(String.isNotBlank(adminId)); 
    }
    
    /**
    * @author       HR
    * @date         24/03/2016
    * @description  Unit test for updateProductStatus 
    */ 
    static testMethod void updateProductStatusTest(){
        Project__c proj = TestData.createProject();
        insert proj;
        
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);
        
        Lead reservationrequestLead = TestData.createLead(proj.Name);
        reservationrequestLead.RecordTypeId = UtilClass.orgRecordTypeMap.get('lead_reservation_request').Id;
        reservationrequestLead.Status = 'Reservation Pending';
        reservationrequestLead.Auto_Convert__c = false;
        reservationrequestLead.Primary_Product__c = apartment[0].Id;
        
        Test.startTest();
            LeadFramework.updateProductStatus(new List<Lead>{reservationrequestLead});
            Product__c apt = [SELECT Id, Internal_Status_Item__c FROM Product__c WHERE ID=: apartment[0].Id LIMIT 1];        
            system.assert(apt.Internal_Status_Item__c=='Reservation Pending');          
            
            reservationrequestLead.Status = 'Reservation Declined';
            LeadFramework.updateProductStatus(new List<Lead>{reservationrequestLead});
            apt = [SELECT Id, Internal_Status_Item__c FROM Product__c WHERE ID=: apartment[0].Id LIMIT 1];        
            system.assert(apt.Internal_Status_Item__c=='Available');            
        Test.stopTest();
    }
    
    /**
    * @author       HR
    * @date         07/04/2016
    * @description  Unit test for updateContractPrice
    */
    static testMethod void updateContractPriceTest(){
        Project__c proj = TestData.createProject();
        insert proj;
        
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);
        List<Product__c> optionNupgrades = TestData.createProductsWithRecordTypes(2, proj.Id, UtilClass.orgRecordTypeMap.get('product__c_upgrade').Id);
        
        Lead reservationrequestLeadWithOptions                      = TestData.createLead(proj.Name);
        reservationrequestLeadWithOptions.RecordTypeId              = UtilClass.orgRecordTypeMap.get('lead_reservation_request').Id;
        reservationrequestLeadWithOptions.Status                    = 'Reservation Pending';
        reservationrequestLeadWithOptions.Auto_Convert__c           = false;
        reservationrequestLeadWithOptions.Primary_Product__c        = apartment[0].Id;
        reservationrequestLeadWithOptions.Upgrade_Option_s_Id__c    = optionNupgrades[0].Id+','+optionNupgrades[1].Id;
        reservationrequestLeadWithOptions.Id                        = TestData.getFakeId(Lead.SObjectType);
        LeadFramework.nPriceTest                                    = apartment[0].List_Price__c;
        
        LeadFramework.updateContractPrice(new List<Lead>{reservationrequestLeadWithOptions});
        system.assert(LeadFramework.leadsMapForTest.get(reservationrequestLeadWithOptions.Id).Contract_Price__c == optionNupgrades[0].List_Price__c+optionNupgrades[0].List_Price__c+apartment[0].List_Price__c);
        
        Lead reservationrequestLeadWithoutOptions                   = TestData.createLead(proj.Name);
        reservationrequestLeadWithoutOptions.RecordTypeId           = UtilClass.orgRecordTypeMap.get('lead_reservation_request').Id;
        reservationrequestLeadWithoutOptions.Status                 = 'Reservation Pending';
        reservationrequestLeadWithoutOptions.Auto_Convert__c        = false;
        reservationrequestLeadWithoutOptions.Primary_Product__c     = apartment[0].Id;
        reservationrequestLeadWithoutOptions.Id                     = TestData.getFakeId(Lead.SObjectType);        
        LeadFramework.nPriceTest                                    = apartment[0].List_Price__c;
        
        LeadFramework.updateContractPrice(new List<Lead>{reservationrequestLeadWithoutOptions});
        system.debug(LeadFramework.leadsMapForTest.get(reservationrequestLeadWithoutOptions.Id).Contract_Price__c == apartment[0].List_Price__c);
    }
    
    static testMethod void submitLeadsForApprovalTest(){
        Project__c proj = TestData.createProject();
        insert proj;
        
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);
        List<Product__c> optionNupgrades = TestData.createProductsWithRecordTypes(2, proj.Id, UtilClass.orgRecordTypeMap.get('product__c_upgrade').Id);
        
        Lead reservationrequestLeadWithOptions                      = TestData.createLead(proj.Name);
        reservationrequestLeadWithOptions.RecordTypeId              = UtilClass.orgRecordTypeMap.get('lead_reservation_request').Id;
        reservationrequestLeadWithOptions.Status                    = 'Reservation Pending';
        reservationrequestLeadWithOptions.Auto_Convert__c           = false;
        reservationrequestLeadWithOptions.Primary_Product__c        = apartment[0].Id;
        reservationrequestLeadWithOptions.Upgrade_Option_s_Id__c    = optionNupgrades[0].Id+','+optionNupgrades[1].Id;
        //reservationrequestLeadWithOptions.Id                      = TestData.getFakeId(Lead.SObjectType);        
        LeadFramework.nPriceTest                                    = apartment[0].List_Price__c;
        
        Instance_Variables__c var = new Instance_Variables__c();
        var.Reservation_Request__c = 'Apartment, Land, Townhouse';
        insert var;
        
        insert reservationrequestLeadWithOptions;
        
        reservationrequestLeadWithOptions = [SELECT CreatedDate FROM Lead WHERE Id=:reservationrequestLeadWithOptions.Id];
        ProcessInstance pi = [SELECT TargetObjectId, CreatedDate FROM ProcessInstance WHERE TargetObjectId = :reservationrequestLeadWithOptions.Id];
        System.assertEquals(reservationrequestLeadWithOptions.CreatedDate.Date(),pi.CreatedDate.Date());
                
    }

    /**
    * @author       HR
    * @date         24/03/2016
    * @description  Unit test for validateOptionsUpgradesforRecordType
    */ 
    static testMethod void validateOptionsUpgradesforRecordTypeTest(){
        //Project__c proj = TestData.createProjects();
        List<Lead> leads = TestData.createLeads(2, null);
        Map<String, RecordType> leadRecordTypes = UtilClass.orgRecordTypeMap;
        
        List<Product__c> products = TestData.createApartmentProducts(5, TestData.createProjects(1)[0].Id);
        products[0].RecordTypeId = UtilClass.orgRecordTypeMap.get('product__c_apartment').Id;
        products[1].RecordTypeId = UtilClass.orgRecordTypeMap.get('product__c_land').Id;
        products[3].RecordTypeId = UtilClass.orgRecordTypeMap.get('product__c_option').Id;
        products[4].RecordTypeId = UtilClass.orgRecordTypeMap.get('product__c_upgrade').Id;
        
        
        leads[0].Upgrade_Option_s_Id__c = products[0].Id+','+products[2].Id;
        leads[1].Upgrade_Option_s_Id__c = products[1].Id+','+products[3].Id;
        
        LeadFramework.validateOptionsUpgradesforRecordType(leads);
    }
    
    /**
    * @author       HR
    * @date         13/03/2016
    * @description  Unit test for updateProductOnDeletedLeads 
    */ 
    static testMethod void updateProductOnDeletedLeadsTest(){
        Instance_Variables__c var = new Instance_Variables__c();
        var.Reservation_Request__c = 'Apartment, Land, Townhouse';
        insert var;
        
        Project__c proj = TestData.createProject();
        insert proj;
        
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);
        
        Lead reservationrequestLead = TestData.createLead(proj.Name);
        reservationrequestLead.RecordTypeId = UtilClass.orgRecordTypeMap.get('lead_reservation_request').Id;
        reservationrequestLead.Status = 'Reservation Pending';
        reservationrequestLead.Auto_Convert__c = false;
        reservationrequestLead.Primary_Product__c = apartment[0].Id;
        
        Test.startTest();
            insert reservationrequestLead;
            //LeadFramework.updateProductStatus(new List<Lead>{reservationrequestLead});
            Product__c apt1 = [SELECT Id, Internal_Status_Item__c FROM Product__c WHERE ID=: apartment[0].Id LIMIT 1];        
            system.assert(apt1.Internal_Status_Item__c=='Reservation Pending');
            
            delete reservationrequestLead;          
            //LeadFramework.updateProductOnDeletedLeads(new List<String>{apartment[0].Id});
            Product__c apt2 = [SELECT Id, Internal_Status_Item__c FROM Product__c WHERE ID=: apartment[0].Id LIMIT 1];        
            system.assert(apt2.Internal_Status_Item__c=='Available');
        Test.stopTest();
    }

    /**
     * @author  JH 
     * @date 21/04/2016 
     * @description Ensure that leads are added to the bad lead queue if something has failed during conversion, this tests that the method 
     * returns the lead with the right owner (bad lead queue) id
     */
    static testMethod void addLeadToBadLeadQueuePositiveTest() {

        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);

        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_APARTMENT_RECORDTYPE).Id; 
        newLead.Sub_DSA__c = true; 
        newLead.Web_2_Lead__c = false; 
        newLead.Console_ID__c = ''; 
        newLead.Web_Form_Source__c = ''; 
        newLead.Auto_Convert__c = true; 
        newLead.Status = 'Open';
        newLead.Primary_Product__c = apartment[0].Id; 
        //jh - this should trip a validation rule for opps from web forms, hereby causing the conversion to fail 
        newLead.Enquiry_Method__c  = 'Web Form'; 
        Test.startTest();
        insert newLead; 
        Test.stopTest(); 
       
        Group badLeadQueue = [SELECT Id FROM Group where Name = 'Bad Leads' and Type = 'Queue' LIMIT 1];
        system.assert(badLeadQueue != null); 

        Lead updatedLead = LeadFramework.addLeadToBadLeadQueue(newLead); 
        system.assertEquals(updatedLead.OwnerId, badLeadQueue.Id); 
    }

      /**
     * @author  JH 
     * @date 27/05/2016 
     * @description If a lead comes in with a project that doesn't exist it should get assigned to the bad lead queue. 
     */
    static testMethod void leadWithoutValidProjectNegativeTest() {

        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);

        Lead newLead = TestData.createLead('Testing Projects'); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_APARTMENT_RECORDTYPE).Id; 
        newLead.Sub_DSA__c = true; 
        newLead.Web_2_Lead__c = false; 
        newLead.Console_ID__c = ''; 
        newLead.Web_Form_Source__c = ''; 
        newLead.Auto_Convert__c = true; 
        newLead.Status = 'Open';
        newLead.Primary_Product__c = apartment[0].Id; 
        //jh - this should trip a validation rule for opps from web forms, hereby causing the conversion to fail 
        newLead.Enquiry_Method__c  = 'Web Form'; 
        Test.startTest();
        insert newLead; 
        Test.stopTest(); 
       
        Group badLeadQueue = [SELECT Id FROM Group where Name = 'Bad Leads' and Type = 'Queue' LIMIT 1];
        system.assert(badLeadQueue != null); 
        Lead updatedLead = [SELECT OwnerId FROM Lead WHERE Id =:newLead.Id limit 1]; 
        system.assertEquals(updatedLead.OwnerId, badLeadQueue.Id); 
    }

     /**
     * @author  JH 
     * @date 26/05/2016 
     * @description Check that the method returns a new note with the correct error message 
     */
    static testMethod void createNoteForBadLeadPositiveTest() {

        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);

        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_APARTMENT_RECORDTYPE).Id; 
        newLead.Sub_DSA__c = true; 
        newLead.Web_2_Lead__c = false; 
        newLead.Console_ID__c = ''; 
        newLead.Web_Form_Source__c = ''; 
        newLead.Auto_Convert__c = true; 
        newLead.Status = 'Open';
        newLead.Primary_Product__c = apartment[0].Id; 
        //jh - this should trip a validation rule for opps from web forms, hereby causing the conversion to fail 
        newLead.Enquiry_Method__c  = 'Web Form'; 
        Test.startTest();
        insert newLead; 
        Test.stopTest(); 
       
        Note badLeadNote = LeadFramework.createNoteForBadLead(newLead.Id, 'This is a really bad error....'); 
        system.assertEquals(badLeadNote.Title, 'Conversion Failed');
        system.assert(badLeadNote.Body.Contains('Convert failed due to the following errors: This is a really bad error'));  
    }

    /**
    * @author  JH 
    * @date 26/05/2016 
    * @description Checks that the campaign member is added to the unsubscribe campaign 
    */
    static testMethod void emailUnsubscribePostiveTest() {

        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);

        Campaign camp = new Campaign(Name='Oliver Hume Master - Email Opt Out', IsActive = true); 
        insert camp; 

        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.Project_Picklist__c = ''; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_APARTMENT_RECORDTYPE).Id; 
        newLead.Sub_DSA__c = true; 
        newLead.Web_2_Lead__c = false; 
        newLead.Console_ID__c = ''; 
        newLead.Web_Form_Source__c = ''; 
        newLead.Auto_Convert__c = false; 
        newLead.Status = 'Open';
        newLead.Primary_Product__c = apartment[0].Id; 
        //jh - this should trip a validation rule for opps from web forms, hereby causing the conversion to fail 
        newLead.Enquiry_Method__c  = 'Web Form'; 
        Test.startTest();
        insert newLead; 
        Test.stopTest(); 
       
        List<Lead> leadList = new List<Lead>();
        leadList.add(newLead); 

        LeadFramework.EmailUnsubscribe(leadList); 
        CampaignMember theCampMember = [SELECT Status, CampaignId FROM CampaignMember WHERE LeadId =:newLead.Id]; 
        system.assertEquals(theCampMember.CampaignId, camp.Id); 
    }

     /**
    * @author  JH 
    * @date 26/05/2016 
    * @description Checks that the campaign member is added to the unsubscribe campaign 
    */
    static testMethod void emailSubscribeBackPostiveTest() {

        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        Project__c proj = TestData.createProjects(1)[0];
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);

        Campaign camp = new Campaign(Name='Oliver Hume Master - Email Opt Out', IsActive = true); 
        insert camp; 

        Lead newLead = TestData.createLead(proj.Name); 
        newLead.Email = 'aemail@gmail.com'; 
        newLead.Project_Picklist__c = ''; 
        newLead.RecordTypeId = recordType.get(LeadFramework.LEAD_APARTMENT_RECORDTYPE).Id; 
        newLead.Sub_DSA__c = true; 
        newLead.Web_2_Lead__c = false; 
        newLead.Console_ID__c = ''; 
        newLead.Web_Form_Source__c = ''; 
        newLead.Auto_Convert__c = false; 
        newLead.Status = 'Open';
        newLead.Primary_Product__c = apartment[0].Id; 
        //jh - this should trip a validation rule for opps from web forms, hereby causing the conversion to fail 
        newLead.Enquiry_Method__c  = 'Web Form'; 
        Test.startTest();
        insert newLead; 
        Test.stopTest(); 
       
        List<Lead> leadList = new List<Lead>();
        leadList.add(newLead); 

        LeadFramework.EmailUnsubscribe(leadList); 
        CampaignMember theCampMember = [SELECT Status, CampaignId FROM CampaignMember WHERE LeadId =:newLead.Id]; 
        system.assertEquals(theCampMember.CampaignId, camp.Id); 

        LeadFramework.EmailSubscribeBack(leadList); 
        //campaign member should no longer exist - method above should remove it 
        try {
            CampaignMember deletedCampMember = [SELECT Status, CampaignId FROM CampaignMember WHERE LeadId =:newLead.Id]; 
            system.assert(false, 'The campaign member should have been removed from the campaign.'); 
        }
        catch(Exception ex) {
            system.assert(true); 
        }
    }

    /**
     * @author  JH 
     * @date 09/05/2016
     * @description Unit test for method that moves attachments on convert from the contact to the opportunity. 
     */
    static testMethod void moveLeadAttachmentsToOppsPositiveTest() {
        TestData.createSuburbs(1); 
        List<Account> accs = TestData.createAccounts(1); 
        List<Contact> testCont = TestData.CreateContacts(accs, 1).get('Contact'); 
        RecordType apartmentOpp = UtilClass.orgRecordTypeMap.get('opportunity_apartments'); 

        List<Opportunity> opp = TestData.createOpportunities(1, apartmentOpp.Id, accs[0].Id); 
        String theString = 'Test String To Blob'; 
        Blob theBlob = Blob.valueOf(theString); 
        Attachment attach = new Attachment(Name = 'Test Attachment', ParentId = testCont[0].Id, Body = theBlob); 
        insert attach; 

        Map<String, String> contactOppIdMap = new Map<String, String>();
        contactOppIdMap.put(testCont[0].Id, opp[0].Id);  


        LeadFramework.moveLeadAttachmentsToOpps(contactOppIdMap); 

        List<Attachment> att = [SELECT Id FROM Attachment WHERE ParentId = :opp[0].Id]; 
        system.assertEquals(att.size(), 1); 
    }

    /**
    * @author       HR
    * @date         19/05/2016
    * @description  Unit test for propertyreservationConvertedOpps
    */
    static testMethod void propertyreservationConvertedOppsTest(){
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
        user1.ProfileId = [Select Id from Profile where name = 'System Administrator'].Id;
        insert user1;

        Project__c proj = TestData.createProject();
        proj.Owner_Assignment__c = user1.Id;
        insert proj;

        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);
        List<Product__c> optionNupgrades = TestData.createProductsWithRecordTypes(2, proj.Id, UtilClass.orgRecordTypeMap.get('product__c_upgrade').Id);

        Price__c price1 = new Price__c(Price__c= 20, Primary_Product__c=apartment[0].Id, Product__c=optionNupgrades[0].Id, Type__c='Upgrade');
        Price__c price2 = new Price__c(Price__c= 20, Primary_Product__c=apartment[0].Id, Product__c=optionNupgrades[1].Id, Type__c='Upgrade');
        List<Price__c> prices = new List<Price__c>();
        prices.add(price1);
        prices.add(price2);
        insert prices;

        List<Account> acc = TestData.createPersonAccounts(1); 
        acc[0].Salutation = 'Mr.'; 
        update acc; 
        Opportunity opp = TestData.createOpportunities(1, UtilClass.orgRecordTypeMap.get('opportunity_apartments').Id, acc[0].Id)[0]; 
        opp.Reservation_Date__c = Date.today(); 
        opp.Primary_Product__c = apartment[0].Id;
        opp.Project__c = proj.Id;
        update opp;

        Map<String, String> opps = new Map<String, String>();
        opps.put(opp.Id, optionNupgrades[0].Id+','+optionNupgrades[0].Id);

        Set<String> optionIds = new Set<String>{optionNupgrades[0].Id, optionNupgrades[1].Id};

        Test.startTest();
        LeadFramework.propertyreservationConvertedOpps(opps, optionIds);
        Test.stopTest();

        Opportunity qryOpp = [SELECT StageName, RecordTypeId, OwnerId, Amount FROM Opportunity WHERE Id=: opp.Id];

        system.assert(qryOpp.StageName      == 'Reservation'); 
        system.assert(qryOpp.RecordTypeId   == UtilClass.orgRecordTypeMap.get('opportunity_portal').Id); 
        system.assert(qryOpp.OwnerId        == user1.Id);

        system.assertEquals(2040.00, qryOpp.Amount);

        Item__c ps = [SELECT Opportunity__c, Product__c, Primary_Product__c, Status__c, Product_Record_Type__c FROM Item__c][0];
        
        system.assert(ps.Opportunity__c     == qryOpp.Id); 
        system.assert(ps.Product__c         == apartment[0].Id); 
        system.assertEquals(ps.Primary_Product__c, apartment[0].Id);
        system.assertEquals(ps.Status__c, 'Reservation'); 
    }

    //jh - perform after delete actions.. 
    static testMethod void performeAfterDeleteActionsTest() {
        Instance_Variables__c var = new Instance_Variables__c();
        var.Reservation_Request__c = 'Apartment, Land, Townhouse';
        insert var;

        Project__c proj = TestData.createProject();
        insert proj;
        
        List<Product__c> apartment = TestData.createApartmentProducts(1, proj.Id);
        Lead reservationrequestLead = TestData.createLead(proj.Name);
        reservationrequestLead.RecordTypeId = UtilClass.orgRecordTypeMap.get('lead_reservation_request').Id;
        reservationrequestLead.Status = 'Reservation Pending';
        reservationrequestLead.Auto_Convert__c = false;
        reservationrequestLead.Primary_Product__c = apartment[0].Id;
        insert reservationrequestLead; 

        Test.startTest(); 
        LeadFramework.performeAfterDeleteActions(new List<Lead>{reservationrequestLead}); 
        Product__c prod = [SELECT Internal_Status_Item__c FROM Product__c WHERE Id =:apartment[0].Id limit 1]; 
        system.assert(prod.Internal_Status_Item__c == 'Available'); 
        Test.stopTest();        
    }

    //jh - merged from the salesfix lead util test. This isn't very good no asserts
    static void InitData(){
        RecordType prjRT = [Select Id From RecordType Where sobjectType = 'Project__c' and DeveloperName = 'Apartments' Limit 1];
        Project__c prj = new Project__c(Name = 'test project',Business_Unit__c='Apartments',RecordTypeId=prjRT.Id, City__c = 'Test', Description__c = 'Sample Description', 
            Region__c = 'Melbourne', Street_Address__c = '12 Test', Zip_Postal_Code__c = 'Victoria', Status__c = 'Planned');             
        insert prj;
        
        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        Account acc = new Account(FirstName = 'test',LastName='account',PersonHasOptedOutOfEmail = true,PersonEmail='test@lead.com',RecordTypeId = objRecordTypeAccount.Id);
        insert acc;
        
        RecordType oppApartmentRT = [Select id from RecordType where sobjectType='Opportunity' and DeveloperName='Apartments' limit 1];
        Opportunity opp = new Opportunity(Name='test opp',AccountId=acc.Id, StageName='New',Project__c=prj.Id,CloseDate = system.today()+1,RecordTypeId = oppApartmentRT.Id);
        insert opp;        
    }
    
    static testMethod void TestLeadConversionWithPE(){   
        InitData(); 
        Test.startTest();
        RecordType objRecordTypeLead = [Select id from RecordType where sobjectType='Lead' and DeveloperName = 'Apartments' limit 1];
        Lead ld = new Lead(FirstName = 'test',LastName='lead',Salutation='Mr',Project_Picklist__c = 'test project',
                           RecordTypeId = objRecordTypeLead.Id,Auto_Convert__c= true,Email='test@lead.com',Enquiry_Source__c='Signage',
                           Enquiry_Method__c = 'Web Form',Skip_Web_Form_Task__c = false,Web_2_Lead__c = true);
        system.debug('Starting salesfix stuff');
        insert ld;   
        Test.stopTest();
    }
}