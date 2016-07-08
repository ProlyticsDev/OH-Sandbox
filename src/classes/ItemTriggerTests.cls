/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class ItemTriggerTests {

    static testMethod void itemTriggerTest(){
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //testing the item trigger.
        //setup some data.
        //create a map of product record types
        Map<String, Id> recordTypes = new Map<String, Id>();
        Map<String, Id> oppRecordTypes = new Map<String, Id>();
        for(RecordType r: [select Id, DeveloperName, sObjectType from RecordType where sObjectType = 'Product__c' OR sObjectType = 'Opportunity']){
            if(r.SobjectType == 'Product__c'){
                recordTypes.put(r.DeveloperName, r.Id);
            }
            else{
                oppRecordTypes.put(r.DeveloperName, r.Id);
            }
        }
        Account acct = new Account();
        acct.Salutation = 'Mr';
        acct.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        acct.LastName = 'pLastName';
        insert acct;
        Bank_Account__c solicitorBank = new Bank_Account__c(Account__c = acct.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
		insert solicitorBank;
    			
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
        
        Product__c[] products = new Product__c[]{};
        Product__c product1 = new Product__c();
        product1.Name = 'Test 101';
        product1.Bdr__c = '2';
        product1.Bth__c = '1';
        product1.Car_Parks__c = '1';
        product1.Contract_Type__c = 'One Part Contract';
        product1.Internal_Status_Item__c = 'Available';
        product1.List_Price__c = 250000;
        product1.Qty_Available__c = 1;
        product1.Type__c = 'Apartment';
        product1.Project__c = project.Id;
        product1.RecordTypeId = recordTypes.get('Apartment');
        product1.Solicitor__c = acct.Id;
        product1.Solicitors_Bank_Account__c = solicitorBank.Id;
        product1.Solicitors_Payment_Method__c = 'EFT';
        product1.Qty_Available__c =1;
        product1.Bdr__c = '1'; 
        product1.Bth__c = '1'; 
        product1.Car_Parks__c = '1'; 
        product1.Description__c = 'Test this'; 
        product1.Features__c = 'Stainless Steel'; 
        product1.Study__c = '0';
        product1.Level__c = '4'; 
        product1.Orientation__c = 'N'; 
        product1.Size__c = 20;
        product1.Viewline__c = 'Sea'; 
        product1.X_End__c = 2; 
        product1.X_Start__c = 3; 
        product1.Y_End__c = 2; 
        product1.Y_Start__c = 3;

        products.add(product1);
     
        
        Product__c product2 = new Product__c();
        product2.Name = 'Test 102';
        product2.Bdr__c = '2';
        product2.Bth__c = '1';
        product2.Car_Parks__c = '1';
        product2.Contract_Type__c = 'Split Contract';
        product2.Internal_Status_Item__c = 'Available';
        product2.List_Price__c = 250000;
        product2.Qty_Available__c = 1;
        product2.Type__c = 'Apartment';
        product2.Project__c = project.Id;
        product1.RecordTypeId = recordTypes.get('Apartment');
        product2.Solicitor__c = acct.Id;
        product2.Solicitors_Bank_Account__c = solicitorBank.Id;
        product2.Solicitors_Payment_Method__c = 'EFT';
        product2.Qty_Available__c =1;
        product2.Bdr__c = '1'; 
        product2.Bth__c = '1'; 
        product2.Car_Parks__c = '1'; 
        product2.Description__c = 'Test this'; 
        product2.Features__c = 'Stainless Steel'; 
        product2.Study__c = '0';
        product2.Level__c = '4'; 
        product2.Orientation__c = 'N'; 
        product2.Size__c = 20;
        product2.Viewline__c = 'Sea'; 
        product2.X_End__c = 2; 
        product2.X_Start__c = 3; 
        product2.Y_End__c = 2; 
        product2.Y_Start__c = 3;
        products.add(product2);
        
        //create an upgrade
        Product__c product3 = new Product__c();
        product3.Name = 'Stone Bench';
        product3.Internal_Status_Item__c = 'Available';
        product3.List_Price__c = 2000;
        product3.Qty_Available__c = 50;
        product3.Type__c = 'Upgrade';
        product3.Project__c = project.Id;
        product3.RecordTypeId = recordTypes.get('Upgrade');
        product3.Qty_Available__c =1;
        product3.Bdr__c = '1'; 
        product3.Bth__c = '1'; 
        product3.Car_Parks__c = '1'; 
        product3.Description__c = 'Test this'; 
        product3.Features__c = 'Stainless Steel'; 
        product3.Study__c = '0';
        product3.Level__c = '4'; 
        product3.Orientation__c = 'N'; 
        product3.Size__c = 20;
        product3.Viewline__c = 'Sea'; 
        product3.X_End__c = 2; 
        product3.X_Start__c = 3; 
        product3.Y_End__c = 2; 
        product3.Y_Start__c = 3;
        products.add(product3);
        
        //create an option
        Product__c product4 = new Product__c();
        product4.Name = 'Blue Paint';
        product4.Internal_Status_Item__c = 'Available';
        product4.List_Price__c = 50;
        product4.Qty_Available__c = 50;
        product4.Type__c = 'Colour Scheme';
        product4.Project__c = project.Id;
        product4.RecordTypeId = recordTypes.get('Option');
        product4.Qty_Available__c =1;
        product4.Bdr__c = '1'; 
        product4.Bth__c = '1'; 
        product4.Car_Parks__c = '1'; 
        product4.Description__c = 'Test this'; 
        product4.Features__c = 'Stainless Steel'; 
        product4.Study__c = '0';
        product4.Level__c = '4'; 
        product4.Orientation__c = 'N'; 
        product4.Size__c = 20;
        product4.Viewline__c = 'Sea'; 
        product4.X_End__c = 2; 
        product4.X_Start__c = 3; 
        product4.Y_End__c = 2; 
        product4.Y_Start__c = 3;
        products.add(product4);
        
        insert products;
        
        //create some price records
        Price__c[] prices = new Price__c[]{};
        
        Price__c price1 = new Price__c();
        price1.Price__c = 100;
        price1.Primary_Product__c = Product1.Id;
        price1.Product__c = Product3.Id;
        prices.add(price1);
        
        Price__c price2 = new Price__c();
        price2.Price__c = 125;
        price2.Primary_Product__c = Product1.Id;
        price2.Product__c = Product4.Id;
        prices.add(price2);
        
        insert prices;
        
        Opportunity[] opps = new Opportunity[]{};
        Opportunity opp = new Opportunity();
        opp.RecordTypeId = oppRecordTypes.get('Apartments');
        opp.Name = 'oppTest1';
        opp.stageName = 'New Enquiry';
        opp.closeDate = date.Today().addDays(5);
        opp.Date_of_Enquiry__c = date.Today();
        opp.Enquiry_Method__c = 'Web Form';
        opp.Enquiry_Source__c = 'Web';       
        opp.AccountId = acct.Id;
        opp.Project__c = project.Id;
        opps.add(opp);
        
        Opportunity opp1 = new Opportunity();
        opp1.RecordTypeId = oppRecordTypes.get('Apartments');
        opp1.Name = 'oppTest2';
        opp1.stageName = 'New Enquiry';
        opp1.closeDate = date.Today();
        opp1.Date_of_Enquiry__c = date.Today();
        opp1.Enquiry_Method__c = 'Web Form';
        opp1.Enquiry_Source__c = 'Web';       
        opp1.AccountId = acct.Id;
        opp1.Project__c = project.Id;
        opps.add(opp1);
        
        insert opps;
        //start test here
        Item__c[] items = new Item__c[]{};
        //create an item record for both opportunities 
        Item__c item1 = new Item__c();
        item1.Opportunity__c = opp.Id;
        item1.Product__c = product1.Id;
        item1.Status__c = 'New Enquiry';
        items.add(item1);
        
        Item__c item2 = new Item__c();
        item2.Opportunity__c = opp1.Id;
        item2.Product__c = product1.Id;
        item2.Status__c = 'New Enquiry';
        items.add(item2);
        insert items;
        
        //reset the utility set for items
        utility.itemIdSet = new Set<String>();
        utility.oppIdSet = new Set<String>();
        test.startTest();
        //update the oppty stage and reservation details
        opp.StageName = 'Reservation';
        opp.Suburb__c = 'Test Suburb';
        opp.Primary_Product__c = product1.Id;
        opp.Reservation_Date__c = date.today();
        opp.Registered_File__c = false;
        opp.Contract_Signing_Appointment_Date__c = date.today().addDays(5);
        opp.Appointment_End_Time__c = '10:00';
        opp.Appointment_Start_Time__c = '09:00';
        opp.Lot_No__c = '33a';
        opp.Full_Deposit_Required__c = 99.00;
        opp.Purchaser__c = 'Test Purchaser';
        update opp;
        //Removed to Prevent Hitting Query Limits
        //end test here
        test.stopTest();
        
    }  
}