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
private class manageItemsTests {

    static testMethod void manageItemsTest(){
        //test the manage items / property selection page
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //create a map of product record types
        Map<String, Id> recordTypes = new Map<String, Id>();
        for(RecordType r: [select Id, DeveloperName from RecordType where sObjectType = 'Product__c']){
            recordTypes.put(r.DeveloperName, r.Id);
        }
        
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
 
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        //Bank and Trust Accounts Required for Receipts.
        Bank_Account__c bankAccount = new Bank_Account__c(Name = 'Solicitor Account', BSB_Number__c = '123-123', Bank_NAme__c = 'ANZ', Bank_Account_Number__c = '123123123');
        insert bankAccount;
        Trust_Account__c trustAccount = new Trust_Account__c(Name = 'Trust Account 1', Oliver_Hume_Account__c = ohAccuont.Id, Payment_Method__c = 'Cheque', Cheque_Type__c = 'Printed', Bank_Account__c = bankAccount.Id, Trust_Account_Id__c = 123456);
        insert trustAccount;
        
        //setup some data.
        Account acct = new Account();
        acct.Salutation = 'Mr';
        acct.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        acct.LastName = 'pLastName';
        insert acct;
        
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.VA_Override__c = true;
        project.Owner_Assignment__c = userInfo.getUserId();
        project.Trust_Account__c = trustAccount.Id;
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
        product1.Commencement_Status__c = 'Available';
        product1.List_Price__c = 250000;
        product1.Qty_Available__c = 1;
        product1.Type__c = 'Apartment';
        product1.Project__c = project.Id;
        product1.RecordTypeId = recordTypes.get('Apartment');
        product1.Solicitor__c = acct.Id;
        product1.Solicitors_Bank_Account__c = bankAccount.Id;
        product1.Solicitors_Payment_Method__c = 'EFT';
        product1.Bdr__c = '1';
        product1.Bth__c = '1'; 
        product1.Car_Parks__c = '1'; 
        product1.Description__c = 'Test this'; 
        product1.Features__c = 'Stainless Steel'; 
        product1.Study__c = '0';
        product1.Level__c = '4'; 
        product1.Orientation__c = 'N';
        product1.Viewline__c = 'Sea'; 
        product1.X_End__c = 2; 
        product1.X_Start__c = 3;
        product1.Y_End__c = 2; 
        product1.Y_Start__c = 3;  
        product1.Size__c = 12;    
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
        product2.Solicitor__c = acct.Id;
        product2.Solicitors_Bank_Account__c = bankAccount.Id;
        product2.Solicitors_Payment_Method__c = 'EFT';
        product2.RecordTypeId = recordTypes.get('Apartment');
        product2.Bdr__c = '1'; 
        product2.Bth__c = '1'; 
        product2.Car_Parks__c = '1'; 
        product2.Description__c = 'Test this'; 
        product2.Features__c = 'Stainless Steel'; 
        product2.Study__c = '0';
        product2.Level__c = '4'; 
        product2.Orientation__c = 'N';
        product2.Viewline__c = 'Sea'; 
        product2.X_End__c = 2; 
        product2.X_Start__c = 3;
        product2.Y_End__c = 2; 
        product2.Y_Start__c = 3; 
        product2.Size__c = 12;     
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
        product3.Bdr__c = '1'; 
        product3.Bth__c = '1'; 
        product3.Car_Parks__c = '1'; 
        product3.Description__c = 'Test this'; 
        product3.Features__c = 'Stainless Steel'; 
        product3.Study__c = '0';
        product3.Level__c = '4'; 
        product3.Orientation__c = 'N';
        product3.Viewline__c = 'Sea'; 
        product3.X_End__c = 2; 
        product3.X_Start__c = 3;
        product3.Y_End__c = 2; 
        product3.Y_Start__c = 3; 
        product3.Size__c = 12;      
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
        product4.Bdr__c = '1'; 
        product4.Bth__c = '1'; 
        product4.Car_Parks__c = '1'; 
        product4.Description__c = 'Test this'; 
        product4.Features__c = 'Stainless Steel'; 
        product4.Study__c = '0';
        product4.Level__c = '4'; 
        product4.Orientation__c = 'N';
        product4.Viewline__c = 'Sea'; 
        product4.X_End__c = 2; 
        product4.X_Start__c = 3;
        product4.Y_End__c = 2; 
        product4.Y_Start__c = 3;  
        product4.Size__c = 12;     
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
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppTest';
        opp.stageName = 'New Enquiry';
        opp.closeDate = date.Today();
        opp.Date_of_Enquiry__c = date.Today();
        opp.Enquiry_Method__c = 'Web Form';
        opp.Enquiry_Source__c = 'Web';       
        opp.AccountId = acct.Id;
        opp.Project__c = project.Id;
        insert opp;
    
        test.startTest();
        //Create an instance of the Controller  
        ApexPages.StandardController std = new ApexPages.StandardController(opp);
        manageItemsExtension mie = new manageItemsExtension(std);
        //test the getters/setters
        mie.landDiscount = null;
        string landdiscount = mie.landDiscount;
        mie.landDeposit = null;
        string landDeposit = mie.landDeposit;
        mie.landRebate = null;
        string landRebate = mie.landRebate;
        mie.aptDiscount = null;
        string aptDiscount = mie.aptDiscount;
        mie.aptDeposit = null;
        string aptDeposit = mie.aptDeposit;
        mie.aptRebate = null;
        string aptRebate = mie.aptRebate;
        mie.splitLandDiscount = null;
        string splitLandDiscount = mie.splitLandDiscount;
        mie.splitLandDeposit = null;
        string splitLandDeposit = mie.splitLandDeposit;
        mie.splitLandRebate = null;
        string splitLandRebate = mie.splitLandRebate;
        mie.splitBuildDiscount = null;
        string splitBuildDiscount = mie.splitBuildDiscount;
        mie.splitBuildDeposit = null;
        string splitBuildDeposit = mie.splitBuildDeposit;
        mie.splitBuildRebate = null;
        string splitBuildRebate = mie.splitBuildRebate;
        
        mie.landDiscount = '34';
        landdiscount = mie.landDiscount;
        mie.landDeposit = '34';
        landDeposit = mie.landDeposit;
        mie.landRebate = '34';
        landRebate = mie.landRebate;
        mie.aptDiscount = '34';
        aptDiscount = mie.aptDiscount;
        mie.aptDeposit = '34';
        aptDeposit = mie.aptDeposit;
        mie.aptRebate = '34';
        aptRebate = mie.aptRebate;
        mie.splitLandDiscount = '34';
        splitLandDiscount = mie.splitLandDiscount;
        mie.splitLandDeposit = '34';
        splitLandDeposit = mie.splitLandDeposit;
        mie.splitLandRebate = '34';
        splitLandRebate = mie.splitLandRebate;
        mie.splitBuildDiscount = '34';
        splitBuildDiscount = mie.splitBuildDiscount;
        mie.splitBuildDeposit = '34';
        splitBuildDeposit = mie.splitBuildDeposit;
        mie.splitBuildRebate = '34';
        splitBuildRebate = mie.splitBuildRebate;
        
        //perform some functions
        mie.makeReservation();
        //reservation won't work as there isn't a primary product
        system.assert('Reservation' != mie.opp.StageName && 'Reservation Pending' != mie.opp.StageName);
        //select a type
        mie.productType = 'Apartment';
        mie.typeFilter();
        //select a product
        mie.productId = product1.Id;
        mie.hasTransferred = true; 
        mie.selectProduct();
        system.assertEquals(product1.Id, mie.selectedProduct.Id);
        
        //check that the options and upgrades are there.
        system.assertEquals(1, mie.optionList.size());
        system.assertEquals(1, mie.upgradeList.size());
        //load the options and upgrades
        mie.upgradeList[0].isSelected = true;
        mie.optionList[0].productId = product4.Id;
        mie.optionList[0].findPrice();
        system.assertEquals(125, mie.optionList[0].price);
        
        //make a reservation
        mie.makeReservation();
        //fill in the appropriate reservation fields.
        mie.opp.Reservation_Date__c = date.Today();
        mie.opp.Suburb__c = 'Test Suburb';
        mie.opp.Contract_Signing_Appointment_Date__c = date.Today().addDays(3);
        mie.opp.Appointment_Start_Time__c = '09:30';
        mie.opp.Appointment_End_Time__c = '10:30';
        mie.opp.Purchaser__c = 'Test Purchaser';
        mie.opp.Lot_No__c = '33a';
        //add a varitaion.
        mie.addVac('Variation');
        //check that a new vac has been added
        system.assertEquals(1, mie.vacList.size());
        mie.vacList[0].vacNew.Name = 'Test Variation';
        system.assertEquals('Variation', mie.vacList[0].vac.Type__c = 'Variation');
        //try and save, will error as fields haven't been completed.
        system.assertEquals(true, mie.vacList[0].isEditable);
        mie.vacList[0].saveVac();
        mie.vacList[0].vacNew.Price__c = 12;
        mie.vacList[0].vacNew.Status__c = 'Open';
        mie.vacList[0].vacNew.Description__c = 'Variation Description';
        //commit the record
        mie.vacList[0].saveVac();
        system.assertEquals(false, mie.vacList[0].isEditable);
        mie.vacList[0].editVac();
        system.assertEquals(true, mie.vacList[0].isEditable);
        mie.vacList[0].cancelVac();
        mie.vacList[0].deleteVac();
        system.assertEquals(true, mie.vacList[0].isDeleted);
        //check that there are no items in the list.
        system.assertEquals(0, mie.vacListFiltered.size());
        mie.addVac('Variation');
        //check that a new vac has been added
        system.assertEquals(1, mie.vacListFiltered.size());
        mie.vacList[1].vacNew.Name = 'Test Variation';
        system.assertEquals('Variation', mie.vacList[1].vac.Type__c = 'Variation');
        //try and save, will error as fields haven't been completed.
        system.assertEquals(true, mie.vacList[1].isEditable);
        mie.vacList[1].saveVac();
        mie.vacList[1].vacNew.Price__c = 12;
        mie.vacList[1].vacNew.Status__c = 'Open';
        mie.vacList[1].vacNew.Description__c = 'Variation Description';
        //commit the record
        mie.vacList[1].saveVac();
        
        //try and launch a condition, and then cancel
        mie.addCondition();
        system.assertEquals('Condition', mie.vacList[2].vac.Type__c = 'Condition');
        system.assertEquals(2, mie.vacListFiltered.size());
        //try and save, this will error
        mie.vacList[2].saveVac();
        system.assertEquals(mie.vacList[2].isEditable, true);
        mie.vacList[2].cancelVac();
        
        //test receipts.
        mie.addNewReceipt();
        system.assertEquals(1, mie.newReceipts.size());
        mie.newReceipts[0].receipt.Trust_Account__c = trustAccount.Id;
        //fill in the new recipt and save.
        mie.newReceipts[0].getReceiptTypes();
        mie.newReceipts[0].receipt.Amount__c = 12;
        mie.newReceipts[0].receipt.Customer_Ref__c = '$332';
        //mie.newReceipts[0].receipt.Date_Cleared__c = date.today();
        mie.newReceipts[0].receipt.Date__c = date.today();
        mie.newReceipts[0].receipt.Payment_Method__c = 'EFT';
        mie.newReceipts[0].receipt.Received_From__c = 'From Test';
        mie.newReceipts[0].receipt.Description__c = 'Initial Deposit';
        
        mie.newReceipts[0].recordReceipt();
        system.assertEquals(0, mie.newReceiptsActual.size());
        mie.addNewReceipt();
        system.assertEquals(1, mie.newReceiptsActual.size());
        mie.newReceipts[1].cancel();
        system.assertEquals(0, mie.newReceiptsActual.size());
        system.assertEquals(1, mie.receipts.size());
        
        //try a last save
        /*mie.saveSelections();
        system.assertEquals('Reservation', [select id, StageName from Opportunity where id =:mie.opp.Id].StageName);
        //reload the page.
        mie = new manageItemsExtension(std);
        //transfer the record
        mie.transferRecord();
        system.assertEquals(null, mie.selectedProduct);
        test.stopTest();*/
    }
    
    static testMethod void manageItemsTestExistingVSA(){
        //test the manage items / property selection page with VSA and existing products
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //create a map of product record types
        Map<String, Id> recordTypes = new Map<String, Id>();
        for(RecordType r: [select Id, DeveloperName from RecordType where sObjectType = 'Product__c']){
            recordTypes.put(r.DeveloperName, r.Id);
        }
        
        
        //Bank and Trust Accounts Required for Receipts.
        Bank_Account__c bankAccount = new Bank_Account__c(Name = 'Solicitor Account', BSB_Number__c = '123-123', Bank_NAme__c = 'ANZ', Bank_Account_Number__c = '123123123');
        insert bankAccount;
        
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        Trust_Account__c trustAccount = new Trust_Account__c(Name = 'Trust Account 1', Oliver_Hume_Account__c = ohAccuont.Id, Payment_Method__c = 'Cheque', Cheque_Type__c = 'Printed', Bank_Account__c = bankAccount.Id, Trust_Account_Id__c = 123456);
        insert trustAccount;
        
        //setup some data.
        Account acct = new Account();
        acct.Salutation = 'Mr';
        acct.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        acct.LastName = 'pLastName';
        insert acct;
        
        
        //No override, we will have a va in place.
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        //project.VA_Override__c = true;
        project.Owner_Assignment__c = userInfo.getUserId();
        project.Trust_Account__c = trustAccount.Id;
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
        product1.Commencement_Status__c = 'Available';
        product1.List_Price__c = 250000;
        product1.Qty_Available__c = 1;
        product1.Type__c = 'Apartment';
        product1.Project__c = project.Id;
        product1.RecordTypeId = recordTypes.get('Apartment');
        product1.Solicitor__c = acct.Id;
        product1.Solicitors_Bank_Account__c = bankAccount.Id;
        product1.Solicitors_Payment_Method__c = 'EFT';
        product1.Bdr__c = '1';
        product1.Bth__c = '1'; 
        product1.Car_Parks__c = '1'; 
        product1.Description__c = 'Test this'; 
        product1.Features__c = 'Stainless Steel'; 
        product1.Study__c = '0';
        product1.Level__c = '4'; 
        product1.Orientation__c = 'N';
        product1.Viewline__c = 'Sea'; 
        product1.X_End__c = 2; 
        product1.X_Start__c = 3;
        product1.Y_End__c = 2; 
        product1.Y_Start__c = 3;  
        product1.Size__c = 12;    
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
        product2.Solicitors_Bank_Account__c = bankAccount.Id;
        product2.Solicitors_Payment_Method__c = 'EFT';
        product2.Bdr__c = '1';
        product2.Bth__c = '1'; 
        product2.Car_Parks__c = '1'; 
        product2.Description__c = 'Test this'; 
        product2.Features__c = 'Stainless Steel'; 
        product2.Study__c = '0';
        product2.Level__c = '4'; 
        product2.Orientation__c = 'N';
        product2.Viewline__c = 'Sea'; 
        product2.X_End__c = 2; 
        product2.X_Start__c = 3;
        product2.Y_End__c = 2; 
        product2.Y_Start__c = 3;  
        product2.Size__c = 12;    
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
        product3.Bdr__c = '1';
        product3.Bth__c = '1'; 
        product3.Car_Parks__c = '1'; 
        product3.Description__c = 'Test this'; 
        product3.Features__c = 'Stainless Steel'; 
        product3.Study__c = '0';
        product3.Level__c = '4'; 
        product3.Orientation__c = 'N';
        product3.Viewline__c = 'Sea'; 
        product3.X_End__c = 2; 
        product3.X_Start__c = 3;
        product3.Y_End__c = 2; 
        product3.Y_Start__c = 3;  
        product3.Size__c = 12;    
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
        product4.Bdr__c = '1';
        product4.Bth__c = '1'; 
        product4.Car_Parks__c = '1'; 
        product4.Description__c = 'Test this'; 
        product4.Features__c = 'Stainless Steel'; 
        product4.Study__c = '0';
        product4.Level__c = '4'; 
        product4.Orientation__c = 'N';
        product4.Viewline__c = 'Sea'; 
        product4.X_End__c = 2; 
        product4.X_Start__c = 3;
        product4.Y_End__c = 2; 
        product4.Y_Start__c = 3;  
        product4.Size__c = 12;    
        products.add(product4);
        
        insert products;
        
        Vendor_Authority__c testVA = new Vendor_Authority__c(Project__c = project.Id, 
                                                             OH_Commission_Percent__c = 3, 
                                                             P1_Payment_Trigger__c = 'Settled', 
                                                             P1_Payment_Percentage__c = 100);
        testVA.General_Start_Date__c = date.today().addDays(-5);
        testVA.General_End_Date__c = date.today().addDays(5);
        insert testVA;
        Product_Assignment__c[] testAssignments = new Product_Assignment__c[]{};
        //create some product assignment records.
        for(Product__c p: products){
            //create test assigments for each product
            testAssignments.add(new Product_Assignment__c(Active__c = true, Product__c = p.Id, Vendor_Authority__c = testVA.Id));
        }
        insert testAssignments;
        //create a vendor sales authority record.
        Id staffRecordType = [select Id from RecordType where sObjectType = 'Account' and DeveloperName = 'Staff_Account' and isPersonType = true limit 1].Id;
        Account salesAccount = new Account(FirstName = 'Test', LastName = 'Staff Account', RecordTypeId = staffRecordType, VSA_Override__c = true);
        
        Vendor_Sales_Authority__c salesVSA = new Vendor_Sales_Authority__c(Account__c = salesAccount.Id, Role__c = 'Sales Consultant', Vendor_Authority__c = testVA.Id, Active__c = true,
                                                                           P1_Payment_Trigger__c = 'Settled', P1_Payment_Percentage__c = 100, Commission_Dollars__c = 1000);
        insert salesVSA;
        
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
        
        Opportunity opp = new Opportunity();
        opp.Name = 'oppTest';
        opp.stageName = 'Reservation';
        opp.closeDate = date.Today();
        opp.Date_of_Enquiry__c = date.Today();
        opp.Enquiry_Method__c = 'Web Form';
        opp.Enquiry_Source__c = 'Web';       
        opp.AccountId = acct.Id;
        opp.Project__c = project.Id;
        opp.Reservation_Date__c = date.Today();
        opp.Contract_Signing_Appointment_Date__c = date.Today().addDays(3);
        opp.Appointment_Start_Time__c = '09:30';
        opp.Appointment_End_Time__c = '10:30';
        opp.Purchaser__c = 'Test Purchaser';
        opp.Lot_No__c = '33a';
        opp.Primary_Product__c = product1.Id;
        opp.Suburb__c = 'Test Suburb';
        opp.Amount = 2000; 
        insert opp;
    
    
        //create a product selection
        Item__c primaryProduct = new Item__c(Opportunity__c = opp.Id, Product__c = product1.Id, Reservation_Date__c = date.today(), Selection_Status__c = 'Active', Status__c = 'Reservation', Price__c = 250000, Product_Record_Type__c = 'Apartment');
        insert primaryProduct;
        test.startTest();
        //Create an instance of the Controller  
        ApexPages.StandardController std = new ApexPages.StandardController(opp);
        manageItemsExtension mie = new manageItemsExtension(std);
        
        
        //try saving
        mie.saveSelections();
        system.assertEquals('Reservation', [select id, StageName from Opportunity where id =:mie.opp.Id].StageName);
        //reload the page.
        mie = new manageItemsExtension(std);
        //transfer the record
        mie.transferRecord();
        system.assertEquals(null, mie.selectedProduct);
        
        mie.exit();
        test.stopTest();
    }

    /**
     * @author JH 
     * @date 27/05/2016
     * @description Added to test methods which had no code coverage
     */
    static testMethod void removeRecordPostiveTest() {
        //jh - just took this data creation from the other methods 
         OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //create a map of product record types
        Map<String, Id> recordTypes = new Map<String, Id>();
        for(RecordType r: [select Id, DeveloperName from RecordType where sObjectType = 'Product__c']){
            recordTypes.put(r.DeveloperName, r.Id);
        }
        
        
        //Bank and Trust Accounts Required for Receipts.
        Bank_Account__c bankAccount = new Bank_Account__c(Name = 'Solicitor Account', BSB_Number__c = '123-123', Bank_NAme__c = 'ANZ', Bank_Account_Number__c = '123123123');
        insert bankAccount;
        
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        Trust_Account__c trustAccount = new Trust_Account__c(Name = 'Trust Account 1', Oliver_Hume_Account__c = ohAccuont.Id, Payment_Method__c = 'Cheque', Cheque_Type__c = 'Printed', Bank_Account__c = bankAccount.Id, Trust_Account_Id__c = 123456);
        insert trustAccount;
        
        //setup some data.
        Account acct = new Account();
        acct.Salutation = 'Mr';
        acct.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        acct.LastName = 'pLastName';
        insert acct;
        
        
        //No override, we will have a va in place.
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        //project.VA_Override__c = true;
        project.Owner_Assignment__c = userInfo.getUserId();
        project.Trust_Account__c = trustAccount.Id;
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
        product1.Commencement_Status__c = 'Available';
        product1.List_Price__c = 250000;
        product1.Qty_Available__c = 1;
        product1.Type__c = 'Apartment';
        product1.Project__c = project.Id;
        product1.RecordTypeId = recordTypes.get('Apartment');
        product1.Solicitor__c = acct.Id;
        product1.Solicitors_Bank_Account__c = bankAccount.Id;
        product1.Solicitors_Payment_Method__c = 'EFT';
        product1.Bdr__c = '1';
        product1.Bth__c = '1'; 
        product1.Car_Parks__c = '1'; 
        product1.Description__c = 'Test this'; 
        product1.Features__c = 'Stainless Steel'; 
        product1.Study__c = '0';
        product1.Level__c = '4'; 
        product1.Orientation__c = 'N';
        product1.Viewline__c = 'Sea'; 
        product1.X_End__c = 2; 
        product1.X_Start__c = 3;
        product1.Y_End__c = 2; 
        product1.Y_Start__c = 3;  
        product1.Size__c = 12;    
        insert product1; 

         Opportunity opp = new Opportunity();
        opp.Name = 'oppTest';
        opp.stageName = 'Reservation';
        opp.closeDate = date.Today();
        opp.Date_of_Enquiry__c = date.Today();
        opp.Enquiry_Method__c = 'Web Form';
        opp.Enquiry_Source__c = 'Web';       
        opp.AccountId = acct.Id;
        opp.Project__c = project.Id;
        opp.Reservation_Date__c = date.Today();
        opp.Contract_Signing_Appointment_Date__c = date.Today().addDays(3);
        opp.Appointment_Start_Time__c = '09:30';
        opp.Appointment_End_Time__c = '10:30';
        opp.Purchaser__c = 'Test Purchaser';
        opp.Lot_No__c = '33a';
        opp.Primary_Product__c = product1.Id;
        opp.Suburb__c = 'Test Suburb';
        opp.Amount = 2000; 
        insert opp;

         //create a product selection
        Item__c primaryProduct = new Item__c(Opportunity__c = opp.Id, Product__c = product1.Id, Reservation_Date__c = date.today(), 
            Selection_Status__c = 'Active', Status__c = 'Reservation', Price__c = 250000, Product_Record_Type__c = 'Apartment');
        insert primaryProduct;

        Test.startTest(); 
        ApexPages.StandardController controller = new ApexPages.StandardController(opp); 
        ManageItemsExtension manageExt = new ManageItemsExtension(controller);  
        manageExt.productSelectionList = new List<Item__c>{primaryProduct}; 
        manageExt.removeRecord(); 
        system.assert(!manageExt.showResiDetails);
        Test.stopTest(); 
    }

       /**
     * @author JH 
     * @date 27/05/2016
     * @description Added to test methods which had no code coverage
     */
    static testMethod void saveSelectedPostiveTest() {
        //jh - just took this data creation from the other methods 
         OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //create a map of product record types
        Map<String, Id> recordTypes = new Map<String, Id>();
        for(RecordType r: [select Id, DeveloperName from RecordType where sObjectType = 'Product__c']){
            recordTypes.put(r.DeveloperName, r.Id);
        }
        
        
        //Bank and Trust Accounts Required for Receipts.
        Bank_Account__c bankAccount = new Bank_Account__c(Name = 'Solicitor Account', BSB_Number__c = '123-123', Bank_NAme__c = 'ANZ', Bank_Account_Number__c = '123123123');
        insert bankAccount;
        
        RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        insert ohAccuont;
        
        Trust_Account__c trustAccount = new Trust_Account__c(Name = 'Trust Account 1', Oliver_Hume_Account__c = ohAccuont.Id, Payment_Method__c = 'Cheque', Cheque_Type__c = 'Printed', Bank_Account__c = bankAccount.Id, Trust_Account_Id__c = 123456);
        insert trustAccount;
        
        //setup some data.
        Account acct = new Account();
        acct.Salutation = 'Mr';
        acct.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        acct.LastName = 'pLastName';
        insert acct;
        
        
        //No override, we will have a va in place.
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        //project.VA_Override__c = true;
        project.Owner_Assignment__c = userInfo.getUserId();
        project.Trust_Account__c = trustAccount.Id;
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
        product1.Commencement_Status__c = 'Available';
        product1.List_Price__c = 250000;
        product1.Qty_Available__c = 1;
        product1.Type__c = 'Apartment';
        product1.Project__c = project.Id;
        product1.RecordTypeId = recordTypes.get('Apartment');
        product1.Solicitor__c = acct.Id;
        product1.Solicitors_Bank_Account__c = bankAccount.Id;
        product1.Solicitors_Payment_Method__c = 'EFT';
        product1.Bdr__c = '1';
        product1.Bth__c = '1'; 
        product1.Car_Parks__c = '1'; 
        product1.Description__c = 'Test this'; 
        product1.Features__c = 'Stainless Steel'; 
        product1.Study__c = '0';
        product1.Level__c = '4'; 
        product1.Orientation__c = 'N';
        product1.Viewline__c = 'Sea'; 
        product1.X_End__c = 2; 
        product1.X_Start__c = 3;
        product1.Y_End__c = 2; 
        product1.Y_Start__c = 3;  
        product1.Size__c = 12;    
        insert product1; 

         Opportunity opp = new Opportunity();
        opp.Name = 'oppTest';
        opp.stageName = 'Reservation';
        opp.closeDate = date.Today();
        opp.Date_of_Enquiry__c = date.Today();
        opp.Enquiry_Method__c = 'Web Form';
        opp.Enquiry_Source__c = 'Web';       
        opp.AccountId = acct.Id;
        opp.Project__c = project.Id;
        opp.Reservation_Date__c = date.Today();
        opp.Contract_Signing_Appointment_Date__c = date.Today().addDays(3);
        opp.Appointment_Start_Time__c = '09:30';
        opp.Appointment_End_Time__c = '10:30';
        opp.Purchaser__c = 'Test Purchaser';
        opp.Lot_No__c = '33a';
        opp.Primary_Product__c = product1.Id;
        opp.Suburb__c = 'Test Suburb';
        opp.Amount = 2000; 
        insert opp;

         //create a product selection
        Item__c primaryProduct = new Item__c(Opportunity__c = opp.Id, Product__c = product1.Id, Reservation_Date__c = date.today(), 
            Selection_Status__c = 'Active', Status__c = 'Reservation', Price__c = 250000, Product_Record_Type__c = 'Apartment');
        insert primaryProduct;

        Test.startTest(); 
        ApexPages.StandardController controller = new ApexPages.StandardController(opp); 
        ManageItemsExtension manageExt = new ManageItemsExtension(controller);  
        manageExt.productSelectionList = new List<Item__c>{primaryProduct}; 
        manageExt.hasTransferred = true; 
        manageExt.selectedProduct = product1; 
        PageReference pageRef = manageExt.saveSelections(); 
        system.assertEquals(pageRef.getUrl(), '/' + opp.Id);
        manageItemsExtension.Addition[] addTest = manageExt.combinedAdditions; 
        system.assertNotEquals(addTest, null); 

        ManageItemsExtension.Addition add = new ManageItemsExtension.Addition(200, 'test'); 
        manageExt.addVariation(); 
        system.assertEquals(add.addPrice, 200); 
        system.assertEquals(add.addName, 'test'); 
        Test.stopTest(); 
    }
}