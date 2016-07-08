@isTest
private class adjustmentTriggerTest {

    static list<Adjustment__c> GenerateTestAdjustments(boolean shouldBeSameAmount, boolean shouldGenerateReceipts) 
    {
        list<Adjustment__c> listAdjusments = new list<Adjustment__c>();
        User objCurrentUser = [Select Id From User Where Id = :UserInfo.getUserId()];
        System.runAs ( objCurrentUser ) 
        {
            RecordType objRecordTypeAccount = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
            RecordType objRecordTypeProduct = [Select id from recordtype where sobjecttype = 'Product__c' and name = 'Apartment'];
            RecordType objRecordTypeOHAccount = [Select id from RecordType where Name = 'Oliver Hume Account' and sobjectType='Account' limit 1];
            
            list<Product__c> listProduct = new list<Product__c>();
            
            if(objRecordTypeAccount != null && objRecordTypeProduct != null)
            {
                
                Account objAccount = new Account();
                objAccount.FirstName = 'First Name';
                objAccount.LastName = 'Last Name';
                objAccount.RecordTypeId = objRecordTypeAccount.Id;
                insert objAccount;
                
                Account ohAccuont = new Account();
                ohAccuont.Name = 'Oliver Hume';
                ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
                insert ohAccuont;
                
                Bank_Account__c solicitorBank = new Bank_Account__c(Account__c = objAccount.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
                insert solicitorBank;
                
                Project__c objProject = new Project__c();
                objProject.Name = 'Test Project';
                 objProject.City__c = 'Test'; 
                objProject.Description__c = 'Sample Description'; 
                objProject.Region__c = 'Melbourne'; 
                objProject.Street_Address__c = '12 Test'; 
                objProject.Zip_Postal_Code__c = 'Victoria';    
                objProject.Status__c = 'Planned';
                insert objProject;
                
                for(integer counter = 0; counter < 2; counter++)
                {
                    Product__c objProduct = new Product__c();
                    objProduct.Name = 'Product 00' + counter;
                    objProduct.Project__c = objProject.Id;
                    objProduct.Type__c = 'Apartment';
                    objProduct.RecordTypeId = objRecordTypeProduct.Id;
                    objProduct.Street_Name__c = 'Test Street ' + counter;
                    objProduct.Stage_Number__c = '03';
                    objProduct.Size__c = 200;
                    objProduct.Solicitor__c = objAccount.Id;
                    objProduct.Solicitors_Bank_Account__c = solicitorBank.Id;
                    objProduct.Qty_Available__c =1;
                    objProduct.Solicitors_Payment_Method__c = 'EFT';
                    objProduct.List_Price__c = 2000; 
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
                    listProduct.add(objProduct);
                }
                insert listProduct;
                
                
                Opportunity objOpportunity = new Opportunity();
                objOpportunity.Name = 'Test Opportunity 01';
                objOpportunity.StageName = 'Prospecting';
                objOpportunity.CloseDate = date.today() + 1;
                objOpportunity.Full_Deposit_Required__c = 500;
                objOpportunity.AccountId = objAccount.Id;
                objOpportunity.Primary_Product__c = listProduct[0].Id;
                insert objOpportunity;
                
                Trust_Account__c objTrustAccount = new Trust_Account__c();
                objTrustAccount.Name = 'TestNumberID';
                objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
                insert objTrustAccount;
                
                list<Receipt__c> listReceipts = new list<Receipt__c>();
                if(shouldGenerateReceipts)
                {
                    for(integer counter = 0; counter < 5; counter++)
                    {
                        Receipt__c objReceipt = new Receipt__c();
                        objReceipt.Amount__c = 100;
                        objReceipt.Date__c = date.today();
                        objReceipt.Received_From__c = 'Test Customer 01';
                        objReceipt.Payment_Method__c = 'Credit Card';
                        objReceipt.Type__c = 'Receipt';
                        objReceipt.Description__c = 'Balance of Deposit';
                        objReceipt.Trust_Account__c = objTrustAccount.Id;
                        objReceipt.Opportunity__c = objOpportunity.Id;
                        objReceipt.Product__c = listProduct[0].Id;
                        listReceipts.add(objReceipt);
                    }
                    insert listReceipts;
                }
                
                for(integer counter = 0; counter < 5; counter++)
                {
                    Adjustment__c objAdjustment = new Adjustment__c();
                    objAdjustment.Date__c = date.today();
                    objAdjustment.Opportunity__c = objOpportunity.Id;
                    objAdjustment.Transaction_Description__c = 'Balance of Deposit';
                    objAdjustment.Trust_Account__c = objTrustAccount.Id;
                    objAdjustment.Type__c = 'Credit';
                    objAdjustment.Amount__c = (shouldBeSameAmount ? 100 : 200);
                    objAdjustment.Transaction_Amount__c = 100;
                    objAdjustment.Status__c = 'Unassigned';
                    
                    if(shouldGenerateReceipts)
                    {
                        objAdjustment.Transaction__c = listReceipts[counter].Id;
                    }
                    listAdjusments.add(objAdjustment);
                }
            }
        }
        return listAdjusments;
    }
    
    private static testMethod void CheckSameAmountWithoutTransaction()
    {
        list<Adjustment__c> listAdjustments = adjustmentTriggerTest.GenerateTestAdjustments(true, false);
        insert listAdjustments;
        
        listAdjustments = [Select Id, Status__c, Transaction__c, Resolved_Date__c, Opportunity__c From Adjustment__c Where Id =: listAdjustments];
        for(Adjustment__c objAdjustment : listAdjustments)
        {
            system.assertNotEquals(null, objAdjustment.Transaction__c);
            system.assertEquals(date.today(), objAdjustment.Resolved_Date__c);
            system.assertEquals('Assigned', objAdjustment.Status__c);
        }
        
        list<Receipt__c> listReceipts = [Select Id, Reconciled__c From Receipt__c Where Opportunity__c =: listAdjustments[0].Opportunity__c];
        system.assertEquals(listAdjustments.size(), listReceipts.size());
        for(Receipt__c objReceipt : listReceipts)
        {
            system.assertEquals(true, objReceipt.Reconciled__c);
        }
    }
    
    private static testMethod void CheckLessAmountWithoutTransaction()
    {
        list<Adjustment__c> listAdjustments = adjustmentTriggerTest.GenerateTestAdjustments(false, false);
        insert listAdjustments;
        
        listAdjustments = [Select Id, Status__c, Transaction__c, Resolved_Date__c, Opportunity__c From Adjustment__c Where Id =: listAdjustments];
        for(Adjustment__c objAdjustment : listAdjustments)
        {
            system.assertNotEquals(null, objAdjustment.Transaction__c);
            system.assertEquals(date.today(), objAdjustment.Resolved_Date__c);
            system.assertEquals('Assigned', objAdjustment.Status__c);
        }
        
        list<Receipt__c> listReceipts = [Select Id, Reconciled__c From Receipt__c Where Opportunity__c =: listAdjustments[0].Opportunity__c];
        system.assertEquals(listAdjustments.size(), listReceipts.size());
        for(Receipt__c objReceipt : listReceipts)
        {
            system.assertEquals(true, objReceipt.Reconciled__c);
        }
        
        listAdjustments = [Select Id, Amount__c, Status__c From Adjustment__c Where Opportunity__c =: listAdjustments[0].Opportunity__c and Id Not IN : listAdjustments];
        for(Adjustment__c objAdjustment : listAdjustments)
        {
            system.assertEquals(100, objAdjustment.Amount__c);
            system.assertEquals('Unassigned', objAdjustment.Status__c);
        }
    }
    
    private static testMethod void CheckSameAmountWithTransaction()
    {
        list<Adjustment__c> listAdjustments = adjustmentTriggerTest.GenerateTestAdjustments(true, true);
        insert listAdjustments;
        
        listAdjustments = [Select Id, Status__c, Transaction__c, Resolved_Date__c, Opportunity__c From Adjustment__c Where Id =: listAdjustments];
        for(Adjustment__c objAdjustment : listAdjustments)
        {
            system.assertEquals(date.today(), objAdjustment.Resolved_Date__c);
            system.assertEquals('Assigned', objAdjustment.Status__c);
        }
        
        list<Receipt__c> listReceipts = [Select Id, Reconciled__c From Receipt__c Where Opportunity__c =: listAdjustments[0].Opportunity__c];
        system.assertEquals(listAdjustments.size(), listReceipts.size());
        for(Receipt__c objReceipt : listReceipts)
        {
            system.assertEquals(true, objReceipt.Reconciled__c);
        }
    }
    
    private static testMethod void CheckLessAmountWithTransaction()
    {
        list<Adjustment__c> listAdjustments = adjustmentTriggerTest.GenerateTestAdjustments(false, true);
        insert listAdjustments;
        
        listAdjustments = [Select Id, Status__c, Transaction__c, Resolved_Date__c, Opportunity__c From Adjustment__c Where Id =: listAdjustments];
        for(Adjustment__c objAdjustment : listAdjustments)
        {
            system.assertEquals(date.today(), objAdjustment.Resolved_Date__c);
            system.assertEquals('Assigned', objAdjustment.Status__c);
        }
        
        list<Receipt__c> listReceipts = [Select Id, Reconciled__c From Receipt__c Where Opportunity__c =: listAdjustments[0].Opportunity__c];
        system.assertEquals(listAdjustments.size(), listReceipts.size());
        for(Receipt__c objReceipt : listReceipts)
        {
            system.assertEquals(true, objReceipt.Reconciled__c);
        }
        
        listAdjustments = [Select Id, Amount__c, Status__c From Adjustment__c Where Opportunity__c =: listAdjustments[0].Opportunity__c and Id Not IN : listAdjustments];
        for(Adjustment__c objAdjustment : listAdjustments)
        {
            system.assertEquals(100, objAdjustment.Amount__c);
            system.assertEquals('Unassigned', objAdjustment.Status__c);
        }
    }
    
}