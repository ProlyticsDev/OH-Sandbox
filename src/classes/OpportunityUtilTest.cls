/**
* @author JH 
* @date 24/03/2016
* @description Tests new methods added to the opportunity utility 
*/
@isTest
public class OpportunityUtilTest {

    @testSetup static void setupData() {
        TestData.createSuburbs(1); 
    }

    //tests the expected title date in a test with positive data 
    //jh - no pre-existing data factories so have taken some of the methods for the web project  
    static testMethod void expectedTitleDateGreaterThanThreeMonthsPositiveTest() {
        List<Project__c> projs = TestData.createProjects(1); 
        List<Opportunity_Expected_Title_Date__mdt> projectsForRule = [SELECT Id, Label FROM Opportunity_Expected_Title_Date__mdt]; 
        //create a project with a matching name as the configurable settings 
        projs[0].Name = projectsForRule[0].Label; 
        update projs; 

        List<Account> accs = TestData.createAccounts(1); 

        //create some opps for the project with expected title dates 90 days in the future 
        RecordType rTypeId = [SELECT Id FROM RecordType WHERE Name = 'Apartments' AND SobjectType = 'Opportunity' limit 1]; 
        List<Opportunity> newOpps = TestData.createOpportunities(1, rTypeId.Id, accs[0].Id); 
        
        List<Product__c> prods = TestData.createProductsWithRecordTypes(1, projs[0].Id, UtilClass.orgRecordTypeMap.get('product__c_apartment').Id); 
        prods[0].Expected_Titled_Date__c = Date.today() + 91; 
        update prods;

        newOpps[0].Project__c = projs[0].Id; 
        //newOpps[0].Project_Picklist__c = 'Ripley Valley - Providence'; 
        newOpps[0].Primary_Product__c = prods[0].Id; 
        update newOpps; 

        Test.startTest(); 
        List<Opportunity> theOppToUpdate = [SELECT Id, Project__r.Name,Expected_Titled_Date__c FROM Opportunity WHERE Id = :newOpps[0].Id]; 

        //jh new opp shouldn't be set yet 
        system.assert(!newOpps[0].Expected_title_date_3_Months__c); 
        List<Opportunity> updatedOpp = OpportunityUtility.expectedTitleDateGreaterThanThreeMonths(theOppToUpdate); 

        system.assert(updatedOpp[0].Expected_title_date_3_Months__c); 
        Test.stopTest(); 
    }

    static testMethod void expectedTitleDateGreaterThanThreeMonthsNegativeTest() {
        List<Project__c> projs = TestData.createProjects(1); 
        List<Opportunity_Expected_Title_Date__mdt> projectsForRule = [SELECT Id, Label FROM Opportunity_Expected_Title_Date__mdt]; 
        //create a project with a matching name as the configurable settings 
        projs[0].Name = projectsForRule[0].Label; 
        update projs; 

        List<Account> accs = TestData.createAccounts(1); 

        //create some opps for the project with expected title dates 90 days in the future 
        RecordType rTypeId = [SELECT Id FROM RecordType WHERE Name = 'Apartments' AND SobjectType = 'Opportunity' limit 1]; 
        List<Opportunity> newOpps = TestData.createOpportunities(1, rTypeId.Id, accs[0].Id); 
        
        List<Product__c> prods = TestData.createProductsWithRecordTypes(1, projs[0].Id, UtilClass.orgRecordTypeMap.get('product__c_apartment').Id); 
        prods[0].Expected_Titled_Date__c = Date.today() + 20; 
        update prods;

        newOpps[0].Project__c = projs[0].Id; 
        newOpps[0].Project_Picklist__c = 'Ripley Valley - Providence'; 
        newOpps[0].Primary_Product__c = prods[0].Id; 
        update newOpps; 

        Test.startTest(); 
        List<Opportunity> theOppToUpdate = [SELECT Id, Project__r.Name,Expected_Titled_Date__c FROM Opportunity WHERE Id = :newOpps[0].Id]; 

        //jh new opp shouldn't be set yet 
        system.assert(!newOpps[0].Expected_title_date_3_Months__c); 
        OpportunityUtility.expectedTitleDateGreaterThanThreeMonths(theOppToUpdate); 

        Opportunity opp = [SELECT Id, Expected_title_date_3_Months__c FROM Opportunity WHERE Id = :theOppToUpdate[0].Id limit 1]; 
        system.assert(!opp.Expected_title_date_3_Months__c); 
        Test.stopTest(); 
    }

    static testMethod void expectedTitleDateGreaterThanThreeMonthsNegativeDataTest() {
        List<Project__c> projs = TestData.createProjects(1); 
        List<Opportunity_Expected_Title_Date__mdt> projectsForRule = [SELECT Id, Label FROM Opportunity_Expected_Title_Date__mdt]; 
        //create a project with a matching name as the configurable settings 
        projs[0].Name = 'fdsafsdfsdfsafsafsdfs'; 
        update projs; 

        List<Account> accs = TestData.createAccounts(1); 

        //create some opps for the project with expected title dates 90 days in the future 
        RecordType rTypeId = [SELECT Id FROM RecordType WHERE Name = 'Apartments' AND SobjectType = 'Opportunity' limit 1]; 
        List<Opportunity> newOpps = TestData.createOpportunities(1, rTypeId.Id, accs[0].Id); 
        
        List<Product__c> prods = TestData.createProductsWithRecordTypes(1, projs[0].Id, UtilClass.orgRecordTypeMap.get('product__c_apartment').Id); 
        prods[0].Expected_Titled_Date__c = Date.today() + 20; 
        update prods;

        newOpps[0].Project__c = projs[0].Id; 
        newOpps[0].Project_Picklist__c = 'Ripley Valley - Providence'; 
        newOpps[0].Primary_Product__c = prods[0].Id; 
        update newOpps; 

        Test.startTest(); 
        List<Opportunity> theOppToUpdate = [SELECT Id, Project__r.Name,Expected_Titled_Date__c FROM Opportunity WHERE Id = :newOpps[0].Id]; 

        //jh new opp shouldn't be set yet 
        system.assert(!newOpps[0].Expected_title_date_3_Months__c); 
        OpportunityUtility.expectedTitleDateGreaterThanThreeMonths(theOppToUpdate); 

        Opportunity opp = [SELECT Id, Expected_title_date_3_Months__c FROM Opportunity WHERE Id = :theOppToUpdate[0].Id limit 1]; 
        system.assert(!opp.Expected_title_date_3_Months__c); 
        Test.stopTest(); 
    }
}