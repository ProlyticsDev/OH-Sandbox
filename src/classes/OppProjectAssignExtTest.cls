@isTest
private class OppProjectAssignExtTest {
	
	@isTest static void TestOppProjectAssignExt() {
		Project__c prj = new Project__c(Name = 'test project',City__c = 'Test', 
        Description__c = 'Sample Description', Region__c = 'Melbourne', Street_Address__c = '12 Test', 
        Zip_Postal_Code__c = 'Victoria', Status__c = 'Planned');
		insert prj;
		
		RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
		Account acc = new Account(FirstName = 'test',LastName='account',PersonHasOptedOutOfEmail = true);
        acc.RecordTypeId = objRecordTypeAccount.Id;
        insert acc;		
        
        RecordType oppApartmentRT = [Select id from RecordType where sobjectType='Opportunity' and DeveloperName='Apartments' limit 1];
		Opportunity opp = new Opportunity(Name='test opp',AccountId=acc.Id, StageName='New',
							CloseDate = system.today()+1,RecordTypeId = oppApartmentRT.Id,Project__c = prj.Id);
		insert opp;
		
		Test.setCurrentPage(Page.ProjectAssignments);
		ApexPages.currentPage().getParameters().put( 'id' , opp.Id);

		OppProjectAssignExt opExt = new OppProjectAssignExt();		
		opExt.Save();
		opExt.Edit();
		opExt.Cancel();
	}
	
}