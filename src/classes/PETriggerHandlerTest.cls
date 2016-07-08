//SalesFix : Test Class to Cover Project Enquiry Trigger and its handler class.
@isTest
public class PETriggerHandlerTest {

    @testSetup
    public static void InitData(){
    	RecordType prjRT = [Select Id From RecordType Where sobjectType = 'Project__c' and DeveloperName = 'Apartments' Limit 1];
		Project__c prj = new Project__c(Name = 'test project',Business_Unit__c='Apartments',RecordTypeId=prjRT.Id, City__c = 'Test', 
        Description__c = 'Sample Description', Region__c = 'Melbourne', Street_Address__c = '12 Test', 
        Zip_Postal_Code__c = 'Victoria', Status__c = 'Planned');
		insert prj;

        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        Account acc = new Account(FirstName = 'test',LastName='account',PersonHasOptedOutOfEmail = true,PersonEmail='test@lead.com',RecordTypeId = objRecordTypeAccount.Id);
        insert acc;

        RecordType oppApartmentRT = [Select id from RecordType where sobjectType='Opportunity' and DeveloperName='Apartments' limit 1];
		Opportunity opp = new Opportunity(Name='test opp',AccountId=acc.Id, StageName='New',Project__c=prj.Id,CloseDate = system.today()+1,RecordTypeId = oppApartmentRT.Id);
		insert opp;

		TestData.createSuburbs(1); 
    }

	public testMethod static void TestPATrigger() {

		RecordType prjRT = [Select Id From RecordType Where sobjectType = 'Project__c' and DeveloperName = 'Apartments' Limit 1];
		List<Project__c> prjsData = TestData.createProjects(2); 
		Project__c prj = prjsData[0]; 
		Project__c newPrj = prjsData[1]; 

		Account acc = [Select Id from Account where isPersonAccount = true and FirstName = 'test' and LastName='account' limit 1];
		Opportunity opp = [Select Id from Opportunity where AccountId =: acc.Id limit 1];

		Campaign c = new Campaign(Name = 'test campaign');
		insert c;

		Project_Enquiry__c pa1 = new Project_Enquiry__c(Opportunity__c = opp.Id,Project__c=prj.Id,Primary__c = true);
		insert pa1;

		pa1.Status__c = 'Submit for Disqualification';
		pa1.Reason__c = 'Financial';
		pa1.Disqualified_Reason_Detail__c = 'Price Point';
		pa1.Manager_Approval__c = true;
		update pa1;

        List<Project_Enquiry__c> paList = [Select Id From Project_Enquiry__c Where Opportunity__c=:opp.Id and Primary__c = true];
		system.assertEquals(1,paList.size());

		pa1.Status__c = 'Disqualified';
		pa1.Reason__c = 'Financial';
		pa1.Disqualified_Reason_Detail__c = 'Price Point';
		pa1.Manager_Approval__c = true;
		update pa1;

        Test.startTest();
        Project_Enquiry__c pa2 = new Project_Enquiry__c(Opportunity__c = opp.Id,Campaign__c=c.Id,
                                                        Project__c=newPrj.Id,Primary__c = true);
		insert pa2;

        opp.Project__c = newPrj.Id;
        update opp;

		paList = [Select Id From Project_Enquiry__c Where Opportunity__c=:opp.Id];
		//JH - TODO 
		//system.assertEquals(2,paList.size());

        Test.stopTest();

	}

	//jh test that the campaign no of project enquiries gets updated properly.. 
	static testMethod void noOfProjectEnquiriesUpdatedPositiveTest() {
		RecordType prjRT = [Select Id From RecordType Where sobjectType = 'Project__c' and DeveloperName = 'Apartments' Limit 1];
		//Project__c prj = new Project__c(Name = 'test project');
		Project__c newPrj = TestData.createProjects(1)[0]; 

		Account acc = [Select Id from Account where isPersonAccount = true and FirstName = 'test' and LastName='account' limit 1];
		Opportunity opp = [Select Id from Opportunity where AccountId =: acc.Id limit 1];

		Campaign c = new Campaign(Name = 'test campaign');
		insert c;

		Project_Enquiry__c pa1 = new Project_Enquiry__c(Opportunity__c = opp.Id,Project__c=newPrj.Id,Primary__c = true, Campaign__c=c.Id);
		insert pa1;

		Test.startTest(); 
		Campaign updatedCamp = [SELECT Id, No_Of_Project_Enquiries__c FROM Campaign WHERE Id = :c.Id limit 1]; 
		system.assertEquals(updatedCamp.No_Of_Project_Enquiries__c, 1); 

		pa1.Campaign__c = null; 
		update pa1;

		Campaign updatedCamp2 = [SELECT Id, No_Of_Project_Enquiries__c FROM Campaign WHERE Id = :c.Id limit 1]; 
		system.assertEquals(updatedCamp2.No_Of_Project_Enquiries__c, 0); 

		system.debug('Scenario 3..'); 
		pa1.Campaign__c = c.Id; 
		update pa1; 

		Campaign updatedCamp3 = [SELECT Id, No_Of_Project_Enquiries__c FROM Campaign WHERE Id = :c.Id limit 1]; 
		system.assertEquals(updatedCamp3.No_Of_Project_Enquiries__c, 1); 

		delete pa1; 
		Campaign updatedCamp4 = [SELECT Id, No_Of_Project_Enquiries__c FROM Campaign WHERE Id = :c.Id limit 1]; 
		system.assertEquals(updatedCamp4.No_Of_Project_Enquiries__c, 0); 

		Test.stopTest(); 
	}


}