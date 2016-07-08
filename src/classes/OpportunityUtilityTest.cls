/**
* @auther		HR
* @date 		06/05/2016
* @description	Code coverage for the opportunityutility class
**/


//TODO: IF THE TEST PASSES NEED TO UPDATE THE DATA AND ADD ASSERT
@isTest
private class OpportunityUtilityTest {
	
	@isTest static void createProjectAssignmentTest() {
		RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
		RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
		//RecordType objRecordTypeOpportunity = [Select id from RecordType where sobjectType='Opportunity' and developername='Channel_Account' limit 1];

		Account objAccount = new Account();
        objAccount.FirstName = 'First Name';
        objAccount.LastName = 'Last Name';
        objAccount.RecordTypeId = objRecordTypeAccount.Id;
        insert objAccount;

	Project__c objProject = new Project__c();
        objProject.Name = 'Test Project';
        objProject.City__c = 'Test'; 
        objProject.Description__c = 'Sample Description'; 
        objProject.Region__c = 'Melbourne'; 
        objProject.Street_Address__c = '12 Test'; 
        objProject.Zip_Postal_Code__c = 'Victoria';    
        objProject.Status__c = 'Planned';
        insert objProject;

	Product__c objProduct = new Product__c();
        objProduct.Name = 'Product 00';
        objProduct.Project__c = objProject.Id;
        objProduct.Type__c = 'Apartment';
        objProduct.RecordTypeId = objRecordTypeProduct.Id;
        objProduct.Street_Name__c = 'Test Street ';
        objProduct.Stage_Number__c = '333';
        objProduct.Size__c = 200;      
        objProduct.Qty_Available__c = 1;
         objProduct.Bdr__c = '1';
        objProduct.Bth__c = '1'; 
        objProduct.Car_Parks__c = '1'; 
        objProduct.Description__c = 'Test this'; 
        objProduct.Features__c = 'Stainless Steel'; 
        objProduct.Study__c = '0';
        objProduct.Level__c = '4'; 
        objProduct.Orientation__c = 'N';
        objProduct.Viewline__c = 'Sea'; 
        objProduct.X_End__c = 2; 
        objProduct.X_Start__c = 3;
        objProduct.Y_End__c = 2; 
        objProduct.Y_Start__c = 3; 
        objProduct.List_Price__c = 2000;      
        
        insert objProduct;

	Project_Enquiry__c pe_old = new Project_Enquiry__c(Project__c=objProject.Id);
	insert pe_old;

		Opportunity objOpportunity = new Opportunity();
        objOpportunity.Name = 'Test Opportunity 01';
        objOpportunity.StageName = 'Prospecting';
        objOpportunity.CloseDate = date.today() + 1;
        objOpportunity.Full_Deposit_Required__c = 500;
        objOpportunity.AccountId = objAccount.Id;
        //objOpportunity.RecordTypeId = objRecordTypeOpportunity.Id;
        insert objOpportunity;

		Project_Enquiry__c pe_new = OpportunityUtility.createProjectAssignment(objOpportunity, null);
	}
	
}