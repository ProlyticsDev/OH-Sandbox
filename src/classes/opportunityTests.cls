//HR - 26/04/2016 - comment out the below update as another update before any asserts few lines down
//HR - 02/05/2016 - Fix the failing tests by merge the two updates into one as this causing too many SQOL error
@isTest
private class opportunityTests {
    static Map<String, RecordType> recTypes{
        get{
            if(recTypes==null){
                recTypes = new Map<String, RecordType>();
                for(RecordType rt : [SELECT Id, isPersonType, Name, sobjectType 
                                        FROM RecordType 
                                        WHERE sObjectType IN ('Account', 'Receipt__c') 
                                        AND (Name IN ('Oliver Hume Account', 'Receipt') OR (isPersonType=TRUE AND Name='Person Account'))]){
                    if(rt.Name=='Oliver Hume Account')
                        recTypes.put('objRecordTypeOHAccount', rt);
                    if(rt.isPersonType==TRUE)
                        recTypes.put('listRecordType', rt);
                    if(rt.Name=='Receipt')
                        recTypes.put('objRecordTypeReceipt', rt);
                }
            }
            return recTypes;
        }
        set;
    }

    static final RecordType listRecordType = recTypes.get('listRecordType');
    static final Profile listProfiles = [Select Id from Profile where name = 'System Administrator' limit 1];
    static final RecordType objRecordTypeOHAccount = recTypes.get('objRecordTypeOHAccount');
    static final RecordType objRecordTypeReceipt = recTypes.get('objRecordTypeReceipt');    
    //Base Data used for commission testing
    private static Vendor_Authority__c va;
    private static Vendor_Sales_Authority__c vsa;
    private static Product_Assignment__c pa;
    private static Vendor_Sales_Product_Assignment__c vspa;
    private static Product__c testProduct;
    private static Project__c testProject;
    private static Opportunity testOpp;
    private static Opportunity testOppForDelete;
    private static Account salespersonAcc;

    @IsTest
    public static void setupBaseData(){

        Account acct = new Account
        (
            Name = 'Test Account'
        );

        Account OHAcct = new Account
        (
            Name = 'Oliver Hume'
            //OH_Account__c = true
        );
        Account solAccount = new Account(Name = 'Test Solicitor Account');
        
        Id staffId = [select Id from RecordType where sObjectType = 'Account' and isPersonType = true and DeveloperName = 'Staff_Account' limit 1].Id;
        //Need a Salesperson Account
        salespersonAcc = new Account
        (
            FirstName = 'A',
            LastName = 'User',
            RecordTypeId = staffId,
            Commission_Structure__c = 'OHNC VIC - Retainer'
        );
        
        Account ohAccuont = new Account();
        ohAccuont.Name = 'Oliver Hume';
        ohAccuont.RecordTypeId = objRecordTypeOHAccount.Id;
        //insert ohAccuont;
        
        insert new List<Account>{acct, OHAcct, SolAccount, salespersonAcc, ohAccuont};
        
        Bank_Account__c solBank = new Bank_Account__c(Name = 'Sol Bank Account', Bank_Account_Number__c = '12345678', BSB_Number__c = '123123', Bank_Name__c = 'Test Bank');
        insert solBank;
        
        testProject = new Project__c
        (
            Name = 'Test Project',
            OH_Account__c = OHAcct.Id,
            City__c = 'Test', 
            Description__c = 'Sample Description', 
            Region__c = 'Melbourne', 
            Street_Address__c = '12 Test', 
            Zip_Postal_Code__c = 'Victoria',
            Status__c = 'Planned'
        );

        insert testProject;

        System.Assert(testProject.Id != null, 'Project was not created successfully.');

        va = new Vendor_Authority__c
        (
            OH_Build_Lockup_Dollars__c = 10,
            OH_Build_Lockup_Percent__c = 10,
            OH_Cancellation_Dollars__c = 20,
            OH_Cancellation_Percent__c = 20,
            OH_Commission_Dollars__c = 30,
            OH_Commission_Percent__c = 30,
            OH_Construction_Commenced_Dollars__c = 40,
            OH_Construction_Commenced_Percent__c = 40,
            OH_Settled_Dollars__c = 50,
            OH_Settled_Percent__c = 50,
            OH_Unconditional_Dollars__c = 60,
            OH_Unconditional_Percent__c = 60,
            Channel_Build_Lockup_Dollars__c = 10,
            Channel_Build_Lockup_Percent__c = 10,
            Channel_Cancellation_Dollars__c = 20,
            Channel_Cancellation_Percent__c = 20,
            Channel_Commission_Dollars__c = 30,
            Channel_Commission_Percent__c = 30,
            Channel_Construction_Commenced_Dollars__c = 40,
            Channel_Construction_Commenced_Percent__c = 40,
            Channel_Settled_Dollars__c = 50,
            Channel_Settled_Percent__c = 50,
            Channel_Unconditional_Dollars__c = 60,
            Channel_Unconditional_Percent__c = 60,
            Project__c = testProject.Id,
            Status__c = 'Approved',
            Approval_PD__c = true,
            Approval_GM_SA__c = true,
            Admin_Fee__c = 5,
            Commission_Based_On__c = 'Margin Scheme Price',
            P1_Payment_Trigger__c = 'Settled',
            P1_Payment_Percentage__c = 100
        );

        insert va;

        testProduct = new Product__c
        (
            Name = 'Test Apartments',
            Project__c = testProject.Id,
            Solicitor__c = solAccount.Id,
            Solicitors_Bank_Account__c = solBank.Id,
            Solicitors_Payment_Method__c = 'EFT',
            Qty_Available__c =1, 
            Bdr__c = '1',
            Bth__c = '1', 
            Car_Parks__c = '1', 
            Description__c = 'Test this', 
            Features__c = 'Stainless Steel', 
            Study__c = '0',
            Level__c = '4', 
            Orientation__c = 'N',
            Viewline__c = 'Sea', 
            X_End__c = 2, 
            X_Start__c = 3,
            Y_End__c = 2, 
            Y_Start__c = 3, 
            Size__c = 12,
            List_Price__c = 2000      
        );

        insert testProduct;

        pa = new Product_Assignment__c
        (
            Vendor_Authority__c = va.Id,
            Product__c = testProduct.Id,
            Active__c = false, 
            OH_Build_Lockup_Dollars__c = 5,
            OH_Build_Lockup_Percent__c = 5,
            OH_Cancellation_Dollars__c = 10,
            OH_Cancellation_Percent__c = 10,
            OH_Commission_Dollars__c = 15,
            OH_Commission_Percent__c = 15,
            OH_Construction_Commenced_Dollars__c = 20,
            OH_Construction_Commenced_Percent__c = 20,
            OH_Settled_Dollars__c = 25,
            OH_Settled_Percent__c = 25,
            OH_Unconditional_Dollars__c = 0,
            OH_Unconditional_Percent__c = 0,
            Channel_Build_Lockup_Dollars__c = 10,
            Channel_Build_Lockup_Percent__c = 10,
            Channel_Cancellation_Dollars__c = 20,
            Channel_Cancellation_Percent__c = 20,
            Channel_Commission_Dollars__c = 30,
            Channel_Commission_Percent__c = 30,
            Channel_Construction_Commenced_Dollars__c = 40,
            Channel_Construction_Commenced_Percent__c = 40,
            Channel_Settled_Dollars__c = 50,
            Channel_Settled_Percent__c = 50,
            Channel_Unconditional_Dollars__c = 60,
            Channel_Unconditional_Percent__c = 60
        );

        insert pa;

        testOppForDelete = new Opportunity(
            Name = 'Test Oppty',
            AccountId = acct.Id,
            Project__c = testProject.Id,
            Primary_Product__c = testProduct.Id,
            StageName = 'Settled',
            CloseDate = System.today(),
            Actual_Settlement_Date__c = System.today(),
            Purchaser__c = 'Michael Knight',
            Margin_Scheme_Price__c = 100.00,
            Date_of_Enquiry__c = date.today(),
            Enquiry_Method__c = 'Web Form',
            Enquiry_Source__c = 'Web'
        );
        
        //insert testOppForDelete;        
        
        testOpp = new Opportunity(
            Name = 'Test Oppty',
            AccountId = acct.Id,
            Project__c = testProject.Id,
            Primary_Product__c = testProduct.Id,
            StageName = 'Settled',
            CloseDate = System.today(),
            Actual_Settlement_Date__c = System.today(),
            Purchaser__c = 'Michael Knight',
            Margin_Scheme_Price__c = 100.00,
            Date_of_Enquiry__c = date.today(),
            Enquiry_Method__c = 'Web Form',
            Enquiry_Source__c = 'Web'
        );

        //insert testOpp;

        insert new List<Opportunity>{testOpp, testOppForDelete};

        //reset the recursion test
        utility.commOppIdSet = new Set<String>();
        
        Commission__c comm = new Commission__c
        (
            Opportunity__c = testOpp.Id, 
            Account__c = salespersonAcc.Id,
            Type__c = 'Commission Generated',
            Payment_Type__c = 'P1',
            Status__c = 'Pending',
            Category__c = 'Staff',
            Role__c = 'Sales Consultant',
            Payment_Stage__c = 'Unconditional Contract',
            Amount__c = 10000,
            Vendor_Authority__c = va.id
        );

        insert comm;
        
        
        
        Trust_Account__c objTrustAccount = new Trust_Account__c();
        objTrustAccount.Name = 'TestNumberID';
        objTrustAccount.Oliver_Hume_Account__c = ohAccuont.Id;
        insert objTrustAccount;
        

        
        Receipt__c objReceipt = new Receipt__c();
        objReceipt.RecordTypeId = objRecordTypeReceipt.Id;
        objReceipt.Amount__c = 10000;
        objReceipt.Date__c = date.today();
        objReceipt.Received_From__c = 'Test Customer 01';
        objReceipt.Payment_Method__c = 'Credit Card';
        objReceipt.Description__c = 'Initial Deposit';
        objReceipt.Trust_Account__c = objTrustAccount.Id;
        objReceipt.Opportunity__c = testOppForDelete.Id;
        objReceipt.Product__c = testProduct.Id;
        objReceipt.Manager_Override__c = true;
        objReceipt.Reconciled__c = true;
        objReceipt.Date_Reconciled__c = Date.today();
        
        insert objReceipt;

    }
    
    static testMethod void deleteOppTest() {
        try {
            setupBaseData();
            delete testOppForDelete;
        } catch (Exception e) {
            if (e.getMessage().contains('Deleting the Opportunity is not allowed as it contains reconciled receipts')) {
              System.assert(true);
          }
        }
        
    }
    
    
    static testMethod void oppCamUtilTest(){
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //Create 2 Projects
        Project__c[] projects = new Project__c[]{};
        Project__c p1 = new Project__c(Name = 'Test Project 1', 
                                       Marketing_Notifications__c = userInfo.getUserId(), 
                                       City__c = 'Test', 
                                       Description__c = 'Sample Description', 
                                       Region__c = 'Melbourne', 
                                       Street_Address__c = '12 Test', 
                                       Zip_Postal_Code__c = 'Victoria',
                                       Status__c = 'Planned'
                                       );
        Project__c p2 = new Project__c(Name = 'Test Project 2', 
                                       Marketing_Notifications__c = userInfo.getUserId(),
                                       City__c = 'Test', 
                                       Description__c = 'Sample Description', 
                                       Region__c = 'Melbourne', 
                                       Street_Address__c = '12 Test', 
                                       Zip_Postal_Code__c = 'Victoria',
                                       Status__c = 'Planned');
        projects.add(p1);
        projects.add(p2);
        insert projects;
        Campaign[] cams = new Campaign[]{};
        //Create 1 parent Campaign
        Campaign parentCampaign = new Campaign(Name = 'Parent Campaign', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', isActive = true);
        insert parentCampaign;
        //create 1 child campaign
        Campaign childCampaign = new Campaign(Name = 'Child Campaign', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', ParentId = parentCampaign.Id, isActive = true);
        insert childCampaign;
        //create some sample opportunities to test campaign assignment.
        Account acc1 = new Account(Name = 'Account 1');
        insert acc1;
        //Match Existing Child Opportunity
        Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
        //Match Existing Child Opportunity withing 8 week timeframe.
        Opportunity opp2 = new Opportunity(Name = 'Test Opp2', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today().addDays(+14), Enquiry_Source__c = 'Channel2', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
        //Match Parent Campaign, but not within timeframe
        Opportunity opp3 = new Opportunity(Name = 'Test Opp3', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today().addDays(+98), Enquiry_Source__c = 'Channel2', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
        //No Match to any Campaign
        Opportunity opp4 = new Opportunity(Name = 'Test Opp4', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel3', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 2');
        Opportunity[] opps = new Opportunity[]{opp1, opp2, opp3, opp4};
        insert opps;
        
        //run some tests
        test.startTest();
            //send opps to the class for processing
            opportunityCampaignUtility.associateCampaignGeneric(opps);
        test.stopTest();
        
        //query for newly created campaigns
        //SalesFix : Change Request from Carrie Hallman - no need to create any new campaigns
        /*
        Date newChildDate = date.today().addDays(+98);
        String newChildName = p1.Name+' - '+ opp3.Enquiry_Source__c+' - '+newChildDate.year()+'-'+newChildDate.month();
        system.debug('Searching for Campaign with Name: '+newChildName);
        Campaign newChild = [select Id, ParentId from Campaign where ParentId =: parentCampaign.Id and Name =:newChildName limit 1];
        String newParentName = p2.Name+' - '+opp4.Enquiry_Source__c;
        Campaign newParent = [select Id from Campaign where ParentId = null and Project__c =: p2.Id and Name =: newParentName limit 1];
        Date newChildNewParentDate = date.today();
        String newChildNewParentName = p2.Name+' - '+opp4.Enquiry_Source__c+' - '+newChildNewParentDate.year()+'-'+newChildNewParentDate.month();
        Campaign newChildNewParent = [select Id, ParentId from Campaign where ParentId != null and Project__c =: p2.Id and Name =: newChildNewParentName limit 1];
        
        for(Opportunity o: [select Id, Name, Originating_Campaign__c, Originating_Campaign__r.Name, Originating_Campaign__r.ParentId from Opportunity where Id in: opps]){
            if(o.Name == 'Test Opp1'){
                //should have matched to childCampaign
                system.assertEquals(o.Originating_Campaign__c, childCampaign.Id);
            }
            if(o.Name == 'Test Opp2'){
                //should have matched to childCampaign
                system.assertEquals(childCampaign.Name, o.Originating_Campaign__r.Name);
            }
            if(o.Name == 'Test Opp3'){
                //should have matched to childCampaign
                system.assertEquals(newChild.Id, o.Originating_Campaign__c);
                //should have matched to existing parent campaign
                system.assertEquals(parentCampaign.Id, newChild.ParentId);
            }
            if(o.Name == 'Test Opp4'){
                //should have matched to childCampaign
                
                system.assertEquals(newChildNewParent.Id, o.Originating_Campaign__c);
                system.assertEquals(newParent.Id, o.Originating_Campaign__r.ParentId);
            }
        }

        */
    }
    
    static testmethod void TestMarketoCustomisations()
    {
        Test.startTest();
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //RecordType listRecordType = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        //Profile listProfiles = [Select Id from Profile where name = 'System Administrator' limit 1];
        if(listRecordType != null && listProfiles != null)
        {
            User user1 = new User();
            user1.Username= 'test-marketo@oliverhume.com.au';
            user1.Email = 'test-marketo@oliverhume.com.au';
            user1.Lastname = 'mike';
            user1.Firstname = 'white';
            user1.Alias = 'mwhite';
            user1.CommunityNickname = 'mwhite01';
            user1.TimeZoneSidKey = 'GMT';
            user1.LocaleSidKey = 'en_US';
            user1.EmailEncodingKey = 'ISO-8859-1';
            user1.LanguageLocaleKey = 'en_US';
            user1.ProfileId = listProfiles.id;
            insert user1;
            
            Account acc1 = new Account(FirstName = 'Account 1', LastName = 'Account 1', RecordTypeId = listRecordType.id, Salutation='Mr');
            insert acc1;
            
            Account acc2 = new Account(FirstName = 'Account 2', LastName = 'Account 2', RecordTypeId = listRecordType.id, Salutation='Mr');
            insert acc2;
            
            /*
            Account account1 = [Select PersonContactId, Id from Account where Id =: acc1.id];
            Account account2 = [Select PersonContactId, Id from Account where id =: acc2.id];
            
            system.assertNotEquals(account1,null);
            system.assertNotEquals(account1.PersonContactId,null);
            */
            List<Id> ids = new List<Id>{acc1.id, acc2.id};
            Map<Id, Account> accountMap = new Map<Id, Account>([SELECT Id, PersonContactId from Account where Id IN : ids]);
            Account account1 = accountMap.get(acc1.id);
            Account account2 = accountMap.get(acc2.id);
            
            system.assertNotEquals(account1,null);
            system.assertNotEquals(account1.PersonContactId,null);
            
            Campaign campaign1 = new Campaign(Name = 'Campaign 1', StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', isActive = true);
            insert campaign1;
            
            Project__c[] projects = new Project__c[]{};
            Project__c p1 = new Project__c(Name = 'Test Project 1', 
                                           Marketing_Notifications__c = userInfo.getUserId(), 
                                           Email_Opt_Out_Campaign__c = campaign1.id, 
                                           Marketo_Project__c = true,
                                           City__c = 'Test', 
                                           Description__c = 'Sample Description', 
                                           Region__c = 'Melbourne', 
                                           Street_Address__c = '12 Test', 
                                           Zip_Postal_Code__c = 'Victoria',
                                           Status__c = 'Planned'
                                           );
            Project__c p2 = new Project__c(Name = 'Test Project 2', 
                                           Marketing_Notifications__c = userInfo.getUserId(),
                                           City__c = 'Test', 
                                           Description__c = 'Sample Description', 
                                           Region__c = 'Melbourne', 
                                           Street_Address__c = '12 Test', 
                                           Zip_Postal_Code__c = 'Victoria',
                                           Status__c = 'Planned'
                                           );
            projects.add(p1);
            projects.add(p2);
            insert projects;
            
            Bank_Account__c solicitorBank = new Bank_Account__c(Account__c = account1.Id, Name = '1231234', BSB_Number__c = '123 123', Bank_Name__c = 'Test Bank');
            insert solicitorBank;
            
            Map<String, Id> recordTypes = new Map<String, Id>();
            for(RecordType r: [select Id, DeveloperName, sObjectType from RecordType where sObjectType = 'Product__c' OR sObjectType = 'Opportunity']){
                if(r.SobjectType == 'Product__c'){
                    recordTypes.put(r.DeveloperName, r.Id);
                }
            }
            Product__c product1 = new Product__c();
            product1.Name = 'Test 101';
            product1.Contract_Type__c = 'One Part Contract';
            product1.Internal_Status_Item__c = 'Available';
            product1.List_Price__c = 250000;
            product1.Qty_Available__c = 1;
            product1.Type__c = 'Apartment';
            product1.Project__c = p1.Id;
            product1.RecordTypeId = recordTypes.get('Apartment');
            product1.Solicitor__c = account1.Id;
            product1.Solicitors_Bank_Account__c = solicitorBank.Id;
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
            product1.Y_Start__c = 3 ;  
            product1.Size__c = 12; 
            insert product1;
            
            Campaign campaign2 = new Campaign(Name = 'Campaign 2', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', isActive = true);
            insert campaign2;
            
            //create some sample opportunities to test campaign assignment.
            Opportunity opp1 = new Opportunity(Name = 'Test Opp1', 
                Project__c = p1.id, 
                Project_Email_Opt_Out__c = true,
                Referring_Builder_Contact__c = account2.PersonContactId, 
                Channel_Contact__c = account2.PersonContactId,
                Contract_Signing_Appointment_Date__c = date.today() - 2,
                StageName = 'New Enquiry', 
                CloseDate = date.today(), 
                AccountID = account1.Id,
                Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', Project_Picklist__c = 'Test Project 1');
            
            Opportunity opp2 = new Opportunity(Name = 'Test Opp2', StageName = 'Contract + Full Deposit', Full_Deposit_Received_Date__c = date.today(), Contract_Signing_Appointment_Date__c = date.today() - 2, CloseDate = date.today(), Date_of_Enquiry__c = date.today().addDays(+14), Enquiry_Source__c = 'Channel2', AccountID = account1.Id, Project_Picklist__c = 'Test Project 1', Purchaser_Signed_Date__c = date.today());
            
            Opportunity[] opps = new Opportunity[]{opp1, opp2};
            insert opps;
            
            System.debug('### opps: ' + opps);
            List<OpportunityContactRole> listOCR = new List<OpportunityContactRole>();
            List<OpportunityContactRole> primaryRoles = new List<OpportunityContactRole>();
            for (OpportunityContactRole cRole : [SELECT ID, ContactId, Role, isPrimary FROM OpportunityContactRole WHERE OpportunityId =: opp1.id]) {
                if (cRole.Role == 'Referring Builder' || cRole.Role == 'Referring Channel')
                    listOCR.add(cRole);
                if (cRole.isPrimary)
                    primaryRoles.add(cRole);
            }
            
            //list<OpportunityContactRole> listOCR = new list<OpportunityContactRole>([SELECT ID, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId =: opp1.id and Role in ('Referring Builder','Referring Channel')]);
            //system.assertEquals(2, listOCR.size());
            if(listOCR.size() > 0)
            {
                system.assertEquals(listOCR[0].ContactId, account2.PersonContactId);
            }
            
            string primaryRole = '';
            for(OpportunityContactRole ocr : primaryRoles) //[Select Role from OpportunityContactRole Where OpportunityId =: opp1.id and isPrimary = true])
            {
                primaryRole = ocr.Role;
            }
            system.assertEquals('Customer', primaryRole);
            
            string memberStatus = '';
            for(CampaignMember cm : [Select Status from CampaignMember where CampaignId =: campaign1.id and ContactId =: account1.PersonContactId])
            {
                memberStatus = cm.Status;
            }
            //system.assertEquals('Unsubscribed', memberStatus);
            
            boolean isMarketoUserInserted = false;
            for(AccountTeamMember act : [Select TeamMemberRole, UserId from AccountTeamMember where AccountId =: account1.id])
            {
                if(act.TeamMemberRole == 'Marketo')
                {
                    isMarketoUserInserted = true;
                }
            }
            //system.assertEquals(true, isMarketoUserInserted);


            opp1.Contract_Signing_Appointment_Date__c = date.today() - 1;
            opp1.Primary_Product__c = product1.Id;
            opp1.StageName = 'Reservation';
            opp1.Reservation_Date__c = date.today() - 1;
            opp1.Suburb__c = 'Test Suburb';
            //HR - 26/04/2016 - comment out the below update as another update before any asserts few lines down
            //update opp1;
            
            opp1.Referring_Builder_Contact__c = null;
            opp1.Channel_Contact__c = null;
            //HR - 02/05/2016 - merge the two updates into one as this causing too many SQOL error
            //update opp1;
            
            listOCR = new list<OpportunityContactRole>([SELECT ID, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId =: opp1.id and Role in ('Referring Builder','Referring Channel')]);
            //system.assertEquals(0, listOCR.size());
            
            //opp2.StageName = 'Qualified';
            opp2.Contract_Signing_Appointment_Date__c = date.today() - 1;
            //HR - 02/05/2016 - merge the two updates into one as this causing too many SQOL error
            //update opp2;
            update new List<Opportunity>{opp1, opp2};
            
            listOCR = new list<OpportunityContactRole>([SELECT ID, ContactId, Role FROM OpportunityContactRole WHERE OpportunityId =: opp1.id and Role in ('Referring Builder','Referring Channel')]);
            //system.assertEquals(2, listOCR.size());

          
        }
         test.stopTest();
    }

    static testmethod void TestContactRoleAssignment(){
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //RecordType listRecordType = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        
            Account acc1 = new Account(FirstName = 'Account 1', LastName = 'Account 1', RecordTypeId = listRecordType.id);
            insert acc1;
            
            Account acc2 = new Account(FirstName = 'Account 2', LastName = 'Account 2');
            insert acc2;
            
            acc1 = [Select PersonContactId, Id from Account where Id =: acc1.id];
            acc2 = [Select PersonContactId, Id from Account where id =: acc2.id];
            
            system.assertNotEquals(acc1,null);
            system.assertNotEquals(acc1.PersonContactId,null);
            
            Project__c[] projects = new Project__c[]{};
            Project__c p1 = new Project__c(Name = 'Test Project 1', 
                                           Marketing_Notifications__c = userInfo.getUserId(),
                                           City__c = 'Test', 
                                           Description__c = 'Sample Description', 
                                           Region__c = 'Melbourne', 
                                           Street_Address__c = '12 Test', 
                                           Zip_Postal_Code__c = 'Victoria',
                                           Status__c = 'Planned'
                                           );
            projects.add(p1);
            insert projects;
            
            
            Opportunity[] opps = new Opportunity[]{};
            //create a number of opportunities
            for(Integer i = 0; i<20; i++){
                //create some sample opportunities to test campaign assignment.
                Opportunity opp1 = new Opportunity(Name = 'Test Opp1', 
                Project__c = p1.id, 
                Project_Email_Opt_Out__c = true,
                //Referring_Builder_Contact__c = account2.PersonContactId, 
                //Channel_Contact__c = account2.PersonContactId,
                Contract_Signing_Appointment_Date__c = date.today() - 2,
                StageName = 'New Enquiry', 
                CloseDate = date.today(), 
                AccountID = acc1.Id,
                Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', Project_Picklist__c = 'Test Project 1');
                opps.add(opp1);
            }
            insert opps;
            test.startTest();
            utility.oppIdSet = new set<String>();
            Id[] oppIds = new Id[]{};
            for(Opportunity o: opps){
                oppIds.add(o.Id);
            }
            system.assertEquals(opps.size(), 20);
            system.assertEquals(20,[select Count() from OpportunityContactRole where OpportunityId in: oppIds]);
            for(OpportunityContactRole o: [select Id, Role, ContactId, isPrimary from OpportunityContactRole where OpportunityId in: oppIds]){
                system.assertEquals(o.Role, 'Customer');
                system.assertEquals(true, o.isPrimary);
            }
            //now update the referring builder
            for(Opportunity o: opps){
                o.Referring_Builder_Contact__c = acc2.PersonContactId;
            }
            update opps;
            
            //assert the referring builder got updated ok
            system.assertEquals(40,[select Count() from OpportunityContactRole where OpportunityId in: oppIds]);
            
            
            OpportunityContactRole[] ocrs = [select Id, Role from OpportunityContactRole where OpportunityId in: oppIds and Role = 'Referring Builder' and contactId !=: acc1.personContactId];
            
            system.assertEquals(ocrs.size(), 20);
            
            test.stopTest();
    }
    
    static testmethod void createTaskAfterOppCreationTest() {
        Test.startTest();
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In New',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry',
            Category__c = 'Walk In - New',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //RecordType listRecordType = [Select id from RecordType where isPersonType = true and sobjectType='account' limit 1];
        //Profile listProfiles = [Select Id from Profile where name = 'System Administrator' limit 1];
        if(listRecordType != null && listProfiles != null)
        {
             //Create 2 Projects
            Project__c[] projects = new Project__c[]{};
            Project__c p1 = new Project__c(Name = 'Test Project 1', 
                                           Marketing_Notifications__c = userInfo.getUserId(),
                                           City__c = 'Test', 
                                           Description__c = 'Sample Description', 
                                           Region__c = 'Melbourne', 
                                           Street_Address__c = '12 Test', 
                                           Zip_Postal_Code__c = 'Victoria',
                                           Status__c = 'Planned'
                                           );
            projects.add(p1);
            insert projects;
            
            Campaign[] cams = new Campaign[]{};
            //Create 1 parent Campaign
            Campaign parentCampaign = new Campaign(Name = 'Parent Campaign', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', isActive = true);
            insert parentCampaign;
            //create 1 child campaign
            Campaign childCampaign = new Campaign(Name = 'Child Campaign', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', ParentId = parentCampaign.Id, isActive = true);
            insert childCampaign;
            //create some sample opportunities to test campaign assignment.
            Account acc1 = new Account(Name = 'Account 1');
            insert acc1;
            Account acc2 = new Account(FirstName = 'Account 2', LastName = 'Account 2', RecordTypeId = listRecordType.id);
            insert acc2;
            
            Account account2 = [Select PersonContactId, Id from Account where id =: acc2.id];
           
            
            //Match Existing Child Opportunity
            //Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
            //create some sample opportunities to test campaign assignment.
                Opportunity opp1 = new Opportunity(Name = 'Test Opp1', 
                    Project__c = p1.id, 
                    Project_Email_Opt_Out__c = true,
                    Referring_Builder_Contact__c = account2.PersonContactId, 
                    Channel_Contact__c = account2.PersonContactId,
                    Contract_Signing_Appointment_Date__c = date.today() - 2,
                    StageName = 'New Enquiry', 
                    CloseDate = date.today(), 
                    AccountID = acc1.Id,
                   Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', Project_Picklist__c = 'Test Project 1');
            insert opp1;
            
            List<Task> tasks = [Select Id, WhatId, WhoId FROM Task WHERE WhatId =: opp1.Id];
            
            Test.stopTest();
            System.assert(tasks.size() >= 1, 'Task should be auto created for this opportunity.');
            System.assertEquals(tasks[0].WhatId, opp1.Id, 'Task should belongs to this opportunity.');
        }
    } 
    
     static testmethod void commissionTriggerGenerationTest() {
         //Create some data
        setupBaseData();
        //run the test, we are only checking that the commission part of the trigger has fired, not the entire comms generation logic
        test.startTest();
        //testOpp.Registered_File__c = true;
        testOpp.GM_OK_to_Register__c = true;
        //testOpp.Registered_File_Date__c = date.today();
        testOpp.Salesperson_pa__c = salespersonAcc.Id;
        update testOpp;
        test.stopTest();
    }
    
    // Richard Clarke 2015-11-19 push expected settlement date to primary product on closed-won or change
    static testmethod void opportunityTriggerExpectedSettlementDateTest() {
         //Create some data
        setupBaseData();
        //start the test
        test.startTest();
        testOpp.Settlement_Terms_Days__c = 60;
        testOpp.Settlement_Ext_Days__c = 14; // simulating a 14 day manual extension to settlement
        testOpp.Settlement_From__c = 'Contract Signing';
        testOpp.Forecast_Unconditional_Date__c = date.today();
        testOpp.Vendor_Signed_Date__c = date.today();
        update testOpp;
        test.stopTest();
    }

    static testmethod void conditionValidationTest(){
        //Create some data
        setupBaseData();
        
        //create some conditions
        Variation_Condition__c[] conditionList = new Variation_Condition__c[]{};
        for(Integer i = 0; i < 10; i++){
            conditionList.add(new Variation_Condition__c(Name = 'Condition '+i, Initial_Expiry_Date__c = date.today().addDays(5-i), Type__c = 'Condition', Status__c = i<5?'Open':'Satisfied', Opportunity__c = testOpp.Id));
        }
        insert conditionList;
        test.startTest();
        //update the opportunity
        testOpp.StageName = 'Unconditional Contract';
        try{
            update testOpp;
        }
        catch(dmlException d){
            system.debug('There was a problem updating the opportunity.'+ d.getMessage());
            system.assertEquals('Update failed. First exception on row 0 with id '+testOpp.Id+'; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, This Opportunity cannot be set to Unconditional Contract as there are open or overdue Conditions.: []', d.getMessage());
        }
        test.stopTest();
    }
    
    static testmethod void synergyTest(){
        //create a synergy opportunity, but forget to add a project.
        //Create 2 Projects
        Project__c[] projects = new Project__c[]{};
        Project__c p1 = new Project__c(Name = 'Test Project 1',
                                       City__c = 'Test', 
                                       Description__c = 'Sample Description', 
                                       Region__c = 'Melbourne', 
                                       Street_Address__c = '12 Test', 
                                       Zip_Postal_Code__c = 'Victoria',
                                       Status__c = 'Planned'
                                      );
        Project__c p2 = new Project__c(Name = 'Test Project 2',
                                       City__c = 'Test', 
                                       Description__c = 'Sample Description', 
                                       Region__c = 'Melbourne', 
                                       Street_Address__c = '12 Test', 
                                       Zip_Postal_Code__c = 'Victoria',
                                       Status__c = 'Planned'
                                        );
        projects.add(p1);
        projects.add(p2);
        insert projects;
        //create some sample opportunities to test campaign assignment.
        Account acc1 = new Account(Name = 'Account 1');
        insert acc1;
        //get the synergy record type
        Id synergyTypeId = [select Id from RecordType where sObjectType = 'Opportunity' and DeveloperName = 'Synergy' limit 1].Id;
        //Match Existing Child Opportunity
        Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, RecordTypeId = synergyTypeId);
        Opportunity[] opps = new Opportunity[]{opp1};
        insert opps;
        //update opp1 to make sure that the project isn't populated.
        opp1 = [select Id, Project__c from Opportunity where Id =: opp1.Id];
        system.assertEquals(null, opp1.Project__c);
        
        //run some tests
        test.startTest();
        //update the project (lookup only)
            opp1.Project_Picklist__c = 'Test Project 1';
            system.debug('updating opp1 here...');
            utility.oppBeforeIdSet.remove(opp1.Id);
            update opp1;
        test.stopTest();
        opp1 = [select Id, Project__c from Opportunity where Id =: opp1.Id];
        system.assertEquals(p1.Id, opp1.Project__c);
    
    }
    
    static testMethod void testCancellationCommissionsStatusUpdate(){
        //create some data.
        setupBaseData();

        //update opportunity stage to 'Reservation Cancelled'
        //Opportunity opp = [Select Id, StageName FROM Opportunity
        //                   WHERE Primary_Product__r.Name = 'Test Apartments'
        //                   LIMIT 1];
        testOpp.StageName = 'Reservation Cancelled';
        testOpp.Consultant_Objection__c = 'Price Point';
        testOpp.Future_Stages__c = 'NO';
        update testOpp;

        //confirm commissions updated to 'Void - Cancellation'    
        LIST<Commission__c> comms = [Select Id, Status__c FROM Commission__c 
                                     WHERE Opportunity__c = :testOpp.Id];        

        System.Assert(!comms.isEmpty());
        for (Commission__c c : comms) {
            System.AssertEquals('Void - Cancellation', c.Status__c);
        }
    }
    
    static testMethod void testCancellationCommissionsStatusUpdate2(){
        //create some data.
        setupBaseData();

        //update Commission_Paid_on_Cancellations checkbox to true
        va.Commission_Paid_on_Cancellations__c = true;
        update va;
        
        //update opportunity stage to 'Reservation Cancelled'
        testOpp.StageName = 'Reservation Cancelled';
        testOpp.Consultant_Objection__c = 'Price Point';
        testOpp.Future_Stages__c = 'NO';
        update testOpp;

        //confirm commissions updated to 'Cancelled - Payable'    
        LIST<Commission__c> comms = [Select Id, Status__c FROM Commission__c 
                                     WHERE Opportunity__c = :testOpp.Id];        

        System.Assert(!comms.isEmpty());
        for (Commission__c c : comms) {
            System.AssertEquals('Cancelled - Payable', c.Status__c);
        }
    }  

    //jh - check that a primary customer role gets created
    static testMethod void createPrimaryCustomerRole() {
        List<Suburb__c> subs = TestData.createSuburbs(2);
        Map<String,RecordType> recordType = UtilClass.orgRecordTypeMap;
        List<Project__c> projs = TestData.createProjects(2);
        Project__c proj = projs[0]; 
        proj.RecordTypeId = UtilClass.orgRecordTypeMap.get('project__c_apartments').Id;
        update proj;
        Lead newLead = TestData.createLead(proj.Name); 
        newLead.RecordTypeId = recordType.get('lead_apartments').Id; 
        newLead.Auto_Convert__c = false; 
        newLead.Project_Picklist__c = proj.Name; 
        newLead.Enquiry_Source__c = 'Not GO Portal'; 
        insert newLead; 


        Lead theLead = [SELECT ConvertedOpportunityId FROM Lead WHERE Id = :newLead.Id limit 1];
        //jh trigger should have fired & created a primary customer role on the opp 
        List<OpportunityContactRole> oppContactRoles = [SELECT Id, IsPrimary, Role 
                                                        FROM OpportunityContactRole 
                                                        WHERE OpportunityId = :theLead.ConvertedOpportunityId]; 
        system.debug('The contact roles that are created in a insert operation: ' + oppContactRoles); 
        Boolean hasPrimaryOppRole = false; 
        for(OpportunityContactRole oppRole :oppContactRoles) {
            if(oppRole.IsPrimary && oppRole.Role == 'Customer') {
                hasPrimaryOppRole = true; 
            }
        }

        system.assertEquals(hasPrimaryOppRole, true); 
    }


    // JH CRON expression: midnight on March 15.
    // Because this is a test, job executes
    // immediately after Test.stopTest().
    public static String CRON_EXP = '0 0 0 15 3 ? 2022';


    //jh - test the opportunity schedulable class
    /**
    * @author JH 
    * @date 01/07/2016
    * @description JH - unit test the schedulable batch class for opportunities 
    */ 
    static testMethod void opportunityScheduledBatchPostiveTest() {
        List<Account> accs = TestData.createAccounts(1); 
        Opportunity newOpp = TestData.createOpportunities(1, UtilClass.orgRecordTypeMap.get('opportunity_apartments').Id, accs[0].Id)[0]; 

        //JH - starts the job - batch runs on stopTest() 
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('Test Job', CRON_EXP, new OpportunitySchedule());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run
        System.assertEquals('2022-03-15 00:00:00',
            String.valueOf(ct.NextFireTime));
        // Verify the scheduled job hasn't run yet.
        Test.stopTest();
    }  

     //jh - test the opportunity schedulable class
    /**
    * @author JH 
    * @date 01/07/2016
    * @description JH - unit test the schedulable batch class for opportunities 
    */ 
    static testMethod void nextAppointmentBatchPostiveTest() {
        List<Account> accs = TestData.createAccounts(1); 
        Opportunity newOpp = TestData.createOpportunities(1, UtilClass.orgRecordTypeMap.get('opportunity_apartments').Id, accs[0].Id)[0]; 

        Event testEvent = new Event(Type = 'Inside Sales Appointment', WhatId=newOpp.Id, StartDateTime=Date.today()+5, 
            Subject='Inside Sales Appointment', DurationInMinutes=200, Location='Oliver Hume', Appointment_Type__c = 'Property', 
            Appointment_Status__c = 'Appointment Set', Location_Type__c = 'OH Onsite'); 
        insert testEvent; 

        //JH - starts the job - batch runs on stopTest() 
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('Test Job', CRON_EXP, new NextAppointmentBatchSchedule());
        // Get the information from the CronTrigger API object
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
        // Verify the expressions are the same
        System.assertEquals(CRON_EXP, ct.CronExpression); 
        // Verify the job has not run
        System.assertEquals(0, ct.TimesTriggered); 
        // Verify the next time the job will run
        System.assertEquals('2022-03-15 00:00:00',
            String.valueOf(ct.NextFireTime));
        // Verify the scheduled job hasn't run yet.
        Test.stopTest();

        //jh - check that next appointment date 
    }  
}