@isTest
public class LeadUtilityTest {

    /*  @testSetup public static void InitData(){
        RecordType prjRT = [Select Id From RecordType Where sobjectType = 'Project__c' and DeveloperName = 'Apartments' Limit 1];
        Project__c prj = new Project__c(Name = 'test project',Business_Unit__c='Apartments',RecordTypeId=prjRT.Id,City__c = 'Test', Description__c = 'Sample Description', 
                Region__c = 'Melbourne', Street_Address__c = '12 Test', Zip_Postal_Code__c = 'Victoria', Status__c = 'Planned');                
        insert prj;
        
        RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        Account acc = new Account(FirstName = 'test',LastName='account',PersonHasOptedOutOfEmail = true,PersonEmail='test@lead.com',RecordTypeId = objRecordTypeAccount.Id);
        insert acc;
        
        RecordType oppApartmentRT = [Select id from RecordType where sobjectType='Opportunity' and DeveloperName='Apartments' limit 1];
		Opportunity opp = new Opportunity(Name='test opp',AccountId=acc.Id, StageName='New',Project__c=prj.Id,CloseDate = system.today()+1,RecordTypeId = oppApartmentRT.Id);
		insert opp;     

        Campaign camp = new Campaign(Name = 'Test', Project__c = prj.Id, IsActive = true); 
        insert camp;    
    }
    
    @isTest public static void TestLeadConversionWithPE(){   
        Test.startTest();
        RecordType objRecordTypeLead = [Select id from RecordType where sobjectType='Lead' and DeveloperName = 'Apartments' limit 1];
        Lead ld = new Lead(FirstName = 'test',LastName='lead',Salutation='Mr',Project_Picklist__c = 'test project',
                           RecordTypeId = objRecordTypeLead.Id,Auto_Convert__c= true,Email='test@lead.com',Enquiry_Source__c='Signage',
                           Enquiry_Method__c = 'Web Form',Skip_Web_Form_Task__c = false,Web_2_Lead__c = true);
        insert ld;   
        Test.stopTest();
    }

    //jh - fix for a bug found in prod 
  static testMethod void leadConversionCampaignChannelBlank() {
        Test.startTest(); 
        RecordType objRecordTypeLead = [Select id from RecordType where sobjectType='Lead' and DeveloperName = 'Apartments' limit 1];
        Lead ld = new Lead(FirstName = 'test',LastName='lead',Salutation='Mr',Project_Picklist__c = 'test project',
                           RecordTypeId = objRecordTypeLead.Id,Auto_Convert__c= true,Email='test@lead.com',
                           Enquiry_Method__c = 'Web Form',Skip_Web_Form_Task__c = false,Web_2_Lead__c = true);
        try {
            insert ld;   
        }
        catch(NullPointerException nullEx) {
            Campaign theCamp = [SELECT Channels__c FROM Campaign limit 1]; 
            system.assertEquals(theCamp.Channels__c, null); 
        }
        Test.stopTest(); 
    }*/
    
}