@isTest
public class LeadExconTest {

	//setup the data to be used in the tests 
	@testSetup static void setupTestData() {
		TestData.createSuburbs(1); 

		List<Suburb__c> theSuburbs = [SELECT Id, Name, Postcode__c FROM Suburb__c]; 
		theSuburbs[0].Postcode__c = '10'; 
		theSuburbs[0].Name = 'test0';
		update theSuburbs; 
	}

	static testMethod void leadExconTest(){   
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Web Form',
            Enquiry_Method__c = 'Web Form',
            Task_Subject__c = 'Submitted Web Form',
            Category__c = 'Web Form',
            Type__c = 'Web Form Submission'
        );
        insert mapping;
          
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.Owner_Assignment__c = userInfo.getUserId();
        project.City__c = 'Test'; 
        project.Description__c = 'Sample Description'; 
        project.Region__c = 'Melbourne'; 
        project.Street_Address__c = '12 Test'; 
        project.Zip_Postal_Code__c = 'Victoria';    
        project.Status__c = 'Planned';
        insert project;
        system.debug('$$$inserted project:' + project);
        
        Lead lead = new Lead();
        lead.Salutation = 'Mr';
        lead.LastName = 'lname';
        lead.Date_of_Enquiry__c = date.today();
        lead.leadSource = 'D3';
        lead.Enquiry_Method__c = 'Web Form';
        lead.Property_Type__c = 'Apartment';
        //lead.Status = 'Open';
        lead.Auto_Convert__c = true;
        lead.Project_Picklist__c = 'Test Project';
        lead.LeadSource = 'The Age';
        lead.email = 'testa@email.com';
        lead.Search_Campaign__c = false;
        lead.Status = 'Qualified';
        //insert lead;
        
        RecordType rt = [select developerName from RecordType where developerName =: 'Apartments' limit 1];
        system.assertNotEquals(rt,null);
        PageReference pageRef = Page.LeadNew;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('RecordType',rt.id);  
        ApexPages.StandardController sc = new ApexPages.standardController(lead);  
        LeadExCon excon = new LeadExCon(sc); 
        system.assertNotEquals(excon.leadRecord, null);      
        system.assertNotEquals(excon.ownerName, null); 
        excon.leadRecord.Salutation = 'Mr';
        excon.leadRecord.LastName = 'lname';
        excon.leadRecord.Date_of_Enquiry__c = date.today();
        excon.leadRecord.leadSource = 'D3';
        excon.leadRecord.Enquiry_Method__c = 'Web Form';
        excon.leadRecord.Property_Type__c = 'Apartment';
        excon.leadRecord.Auto_Convert__c = true;
        excon.leadRecord.Project_Picklist__c = 'Test Project';
        excon.leadRecord.LeadSource = 'The Age';
        excon.leadRecord.email = 'testB@email.com';
        excon.leadRecord.Search_Campaign__c = false;
        excon.leadRecord.Status = 'Qualified';
        excon.saveLead();
        excon.cancelLead();
        //system.assertNotEquals(LeadUtility.returnOpptyId, null);
    }

    static testMethod void saveNewPositiveTest() {
    	OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Web Form',
            Enquiry_Method__c = 'Web Form',
            Task_Subject__c = 'Submitted Web Form',
            Category__c = 'Web Form',
            Type__c = 'Web Form Submission'
        );
        insert mapping;
          
        List<Project__c> proj = TestData.createProjects(1); 
        Lead lead = TestData.createLead(proj[0].Name); 
        insert lead; 

        Test.startTest(); 
        ApexPages.StandardController stdCont = new ApexPages.StandardController(lead); 
        LeadExcon theExtCont = new LeadExcon(stdCont); 
        theExtCont.leadRecord = lead;
        theExtCont.project = proj[0].Name;  
        theExtCont.enquirySource = 'A test class'; 
        PageReference pageRef = theExtCont.saveNew(); 
        system.assert(pageRef.getUrl().contains('/apex/LeadNew')); 
        Test.stopTest(); 
    }

     static testMethod void getProjectsPositiveTest() {
    	OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Web Form',
            Enquiry_Method__c = 'Web Form',
            Task_Subject__c = 'Submitted Web Form',
            Category__c = 'Web Form',
            Type__c = 'Web Form Submission'
        );
        insert mapping;

        List<Project__c> proj = TestData.createProjects(1); 
        Lead lead = TestData.createLead(proj[0].Name); 
        insert lead; 
     
        Test.startTest(); 
        ApexPages.StandardController stdCont = new ApexPages.StandardController(lead); 
        LeadExcon theExtCont = new LeadExcon(stdCont); 
        theExtCont.projectToEnquiries.put(proj[0].Name, new List<String>{'Apex class'});
        List<SelectOption> options = theExtCont.getProjects(); 
        system.assertEquals(options.size(), 2); 
        Test.stopTest(); 
    }

     static testMethod void getEnquirySourcesPositiveTest() {
    	OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Web Form',
            Enquiry_Method__c = 'Web Form',
            Task_Subject__c = 'Submitted Web Form',
            Category__c = 'Web Form',
            Type__c = 'Web Form Submission'
        );
        insert mapping;

        List<Project__c> proj = TestData.createProjects(1); 
        Lead lead = TestData.createLead(proj[0].Name); 
        insert lead; 
     
        Test.startTest(); 
        ApexPages.StandardController stdCont = new ApexPages.StandardController(lead); 
        LeadExcon theExtCont = new LeadExcon(stdCont); 
        theExtCont.project = proj[0].Name;
         theExtCont.projectToEnquiries.put(proj[0].Name, new List<String>{'Test', 'Apex class'});
        PageReference enquirySources = theExtCont.getEnquirySources(); 
        system.assertEquals(theExtCont.enquiries.size(), 3); 
        Test.stopTest(); 
    }
}