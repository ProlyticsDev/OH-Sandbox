@isTest
private class productAssignmentTriggerTest 
{
    static list<Product_Assignment__c> GenerateTestProductAssignments(boolean isActive) 
    {
        list<Product_Assignment__c> listProductAssignments = new list<Product_Assignment__c>();
        
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs (objCurrentUser) 
        {
            RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
            
            if(objRecordTypeProduct != null)
            {
                
                Account solAccount = new Account(Name = 'Test Solicitor Account');
                insert SolAccount;
                Bank_Account__c solBank = new Bank_Account__c(Name = 'Sol Bank Account', Bank_Account_Number__c = '12345678', BSB_Number__c = '123123', Bank_Name__c = 'Test Bank');
                insert solBank;
                
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
                objProduct.Street_Name__c = 'Test Street';
                objProduct.Stage_Number__c = '03';
                objProduct.Size__c = 200;
                objProduct.Active_VA__c = true;
                objProduct.Solicitor__c = solAccount.Id;
                objProduct.Solicitors_Bank_Account__c = solBank.Id;
                objProduct.Solicitors_Payment_Method__c = 'EFT';
                objProduct.Qty_Available__c =1;
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
                
                Vendor_Authority__c objVendorAuthority = new Vendor_Authority__c(OH_Commission_Percent__c = 3, P1_Payment_Trigger__c = 'Settled', P1_Payment_Percentage__c = 100);
                //objVendorAuthority.Name = 'Test Vendor';
                insert objVendorAuthority;
                
                for(integer counter = 0; counter < 5; counter ++)
                {
                    Product_Assignment__c objProductAssignment = new Product_Assignment__c();
                    objProductAssignment.Vendor_Authority__c = objVendorAuthority.Id;
                    objProductAssignment.Product__c = objProduct.Id;
                    objProductAssignment.Active__c = isActive;
                    listProductAssignments.add(objProductAssignment);
                }
            }
        }
        return listProductAssignments;
    }
    
    static testMethod void TestActiveProductAssignments()
    {
        list<Product_Assignment__c> listProductAssignments = productAssignmentTriggerTest.GenerateTestProductAssignments(true);
        insert listProductAssignments;
        update listProductAssignments;
        
        Product__c objProduct = [Select Id, Active_VA__c From Product__c Limit 1];
        system.assertNotEquals(null, objProduct);
        system.assertEquals(true, objProduct.Active_VA__c);
    }
    
    static testMethod void TestPartialActiveProductAssignments()
    {
        list<Product_Assignment__c> listProductAssignments = productAssignmentTriggerTest.GenerateTestProductAssignments(true);
        insert listProductAssignments;
        
        list<Product_Assignment__c> listUpdateProductAssignments = new list<Product_Assignment__c>();
        for(integer counter = 0; counter < 2; counter++)
        {
            listProductAssignments[counter].Active__c = false;
            listUpdateProductAssignments.add(listProductAssignments[counter]);
        }
        update listUpdateProductAssignments;
        
        Product__c objProduct = [Select Id, Active_VA__c From Product__c Limit 1];
        system.assertNotEquals(null, objProduct);
        system.assertEquals(true, objProduct.Active_VA__c);
    }
    
    static testMethod void TestInActiveProductAssignments()
    {
        list<Product_Assignment__c> listProductAssignments = productAssignmentTriggerTest.GenerateTestProductAssignments(true);
        insert listProductAssignments;
        
        list<Product_Assignment__c> listUpdateProductAssignments = new list<Product_Assignment__c>();
        for(integer counter = 0; counter < listProductAssignments.size(); counter++)
        {
            listProductAssignments[counter].Active__c = false;
            listUpdateProductAssignments.add(listProductAssignments[counter]);
        }
        update listUpdateProductAssignments;
        
        Product__c objProduct = [Select Id, Active_VA__c From Product__c Limit 1];
        system.assertNotEquals(null, objProduct);
        system.assertEquals(false, objProduct.Active_VA__c);
    }
}