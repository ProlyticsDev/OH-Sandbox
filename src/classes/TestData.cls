/**
 * @author		HR
 * @date		15/02/2016
 * @description	Test data to be used in the test classes
**/
@isTest
public with sharing class TestData {
	
	public static Map<String, List<Account>> createBusinessAccount(Integer numAccts){
		if(!Test.isRunningTest()){
			throw new TestDataException('Use only in test classes'); 
			return null;
		} 
		
		List<Account> accts = new List<Account>();
		
		for(Integer i=0; i<numAccts; i++){
			Account acc = new Account();
			acc.name	=	'TestAccount'+i;
			accts.add(acc);
		}
		
		insert accts;
		
		return new Map<String, List<Account>>{'Account' => accts};
	}
	
	public static Map<String, List<Contact>> CreateContacts(List<Account> accts, Integer numContactsPerAccount){
		if(!Test.isRunningTest()){
			throw new TestDataException('Use only in test classes'); 
			return null;
		}
		
		List<Contact> cons = new List<Contact>();
		
		for(Account acc : accts){
			for(Integer i=0; i<numContactsPerAccount; i++){
				Contact con		= 	new Contact();
				con.AccountId 	= 	acc.Id;
				con.LastName	=	'TestCon'+i;
				con.Email		=	'email'+i+'@test.com.au';
				cons.add(con);
			}
		}
		insert cons;

		return new Map<String, List<Contact>>{'Contact' => cons};
	}

	public static List<Project__c> createProjects(Integer numRec) {
		List<Project__c> projects = new List<Project__c>(); 
		for(Integer i=0; i < numRec; i++) {
			Project__c proj = new Project__c(); 
			proj.Name = 'Test' +i; 
			proj.Business_Unit__c = 'Apartments'; 
			proj.Project_Prefix__c = 'T' + i; 
			proj.Suburb__c = [SELECT Id FROM Suburb__c limit 1].Id; 
			proj.Owner_Assignment__c = UserInfo.getUserId(); 
			proj.Marketing_Notifications__c = UserInfo.getUserId(); 
			proj.Project_Manager__c = UserInfo.getUserId(); 
			proj.Project_Director__c = 'TEST DIRECTOR'; 
			proj.Solicitor__c = createAccounts(1)[0].Id; 
			proj.Trust_Account__c = createTrustAccounts(1)[0].Id; 
			proj.OH_Account__c = createAccounts(1)[0].Id; 
			proj.Commencement_Year__c = String.valueOf(system.now().year()); 
			proj.City__c = 'Test'; 
            proj.Description__c = 'Sample Description'; 
            proj.Region__c = 'Melbourne'; 
            proj.Street_Address__c = '12 Test'; 
            proj.Zip_Postal_Code__c = 'Victoria';    
            proj.Status__c = 'Planned';

			projects.add(proj); 
		}
		insert projects; 
		return projects; 
	}

	public static List<Lead> createLeads(Integer numRec, String projId) {
		List<Lead> leads = new List<Lead>(); 
		for(Integer i=0; i < numRec; i++) {
			Lead newLead = new Lead(); 
			newLead.FirstName = 'Test' + i; 
			newLead.LastName = 'Last' + i; 
			newLead.Email = 'newLead@test.com'; 
			newLead.Street = 'test' + i; 
			newLead.Project__c = projId; 
			newLead.Salutation = 'Mr';

			leads.add(newLead); 
		}

		insert leads; 
		return leads; 
	}

	public static List<Product__c> createApartmentProducts(Integer numRec, String projId) {
		List<Product__c> products = new List<Product__c>(); 
		for(Integer i=0; i < numRec; i++) {
			Product__c prod = new Product__c(); 
			prod.Name = 'Product' + i; 
			prod.Project__c = projId; 
			prod.RecordTypeId = UtilClass.orgRecordTypeMap.get('product__c_apartment').Id;
			prod.Type__c = 'Apartment';
			prod.Console_Reference__c = '00' + i; 
			prod.Qty_Available__c = 1; 
			prod.List_Price__c = 1000;
			prod.Bdr__c = '1'; 
			prod.Bth__c = '1'; 
			prod.Orientation__c = 'N'; 
			prod.Features__c = 'Stainless Steel'; 
			prod.Description__c = 'Test record to be created.';
			prod.Level__c = '2'; 
			prod.List_Price__c = 2000; 
			prod.Size__c = 20; 
			prod.Study__c = '1'; 
			prod.Type__c = 'Test'; 
			prod.Viewline__c = 'Sea'; 
			prod.Car_Parks__c = '2'; 
			prod.X_End__c = 2; 
			prod.X_Start__c = 3; 
			prod.Y_End__c = 2; 
			prod.Y_Start__c = 3; 
			prod.Internal_Status__c = 'Available'; 

			products.add(prod);  
		}

		insert products; 
		return products; 
	}
	
	public static List<Product__c> createProductsWithRecordTypes(Integer numRec, String projId, String recTypeId) {
		List<Product__c> products = new List<Product__c>(); 
		for(Integer i=0; i < numRec; i++) {
			Product__c prod = new Product__c(); 
			prod.Name = 'optionsupgrades' + i; 
			prod.Project__c = projId; 
			prod.RecordTypeId = recTypeId;			
			prod.Console_Reference__c = '100' + i; 
			prod.Qty_Available__c = 1; 
			prod.List_Price__c = 0;
			prod.Size__c = 20; 
			prod.Internal_Status__c = 'Available'; 
			prod.Study__c = '1'; 
			prod.Type__c = 'Test'; 
			prod.Viewline__c = 'Sea'; 
			prod.Car_Parks__c = '2'; 
			prod.Bdr__c = '1'; 
			prod.Bth__c = '1'; 
			prod.Orientation__c = 'N'; 
			prod.Features__c = 'Stainless Steel'; 
			prod.Description__c = 'This is a sample desc'; 
			prod.Level__c = '1'; 

			products.add(prod);  
		}

		insert products; 
		return products; 
	}

	public static List<Suburb__c> createSuburbs(Integer numRec) {
		List<Suburb__c> suburbs = new List<Suburb__c>(); 
		for(Integer i=0; i < numRec; i++) {
			Suburb__c sub = new Suburb__c(); 
			sub.Name = 'Test' + i; 
			//sub.Employment__c = 'Test option ' + i; 
			sub.Postcode__c = '2011'; 
			//sub.Suburb_Brief_Description__c = 'Brief description for test ' + i; 
			//sub.Suburb_Detailed_Description__c = 'Long description for test ' +i ;  

			suburbs.add(sub); 
		}
		insert suburbs; 
		return suburbs;  
	}

	public static List<Account> createAccounts(Integer numRec) {
		List<Account> accts = new List<Account>();
		
		for(Integer i=0; i < numRec; i++){
			Account acc = new Account();
			acc.name	=	'TestAccount'+i;
			accts.add(acc);
		}
		
		insert accts;
		return accts; 
	}

	public static List<Account> createOliverHumeAccounts(Integer numRec) { 
		List<Account> trustAccs = new List<Account>();
		RecordType rType = [SELECT Id 
							FROM RecordType 
							WHERE Name = 'Oliver Hume Account' 
							AND SobjectType = 'Account' 
							limit 1]; 

		for(Integer i=0; i < numRec; i++) {
			Account acc = new Account();
			acc.name	=	'StaffTestAccount'+i;
			acc.RecordTypeId = rType.Id; 
			trustAccs.add(acc);
		}
		
		insert trustAccs;
		return trustAccs; 
	}

	public static List<Trust_Account__c> createTrustAccounts(Integer numRec) {
		List<Trust_Account__c> trustAccs = new List<Trust_Account__c>();
		
		for(Integer i=0; i < numRec; i++){
			Trust_Account__c trustAcc = new Trust_Account__c();
			trustAcc.name	=	'TestAccount'+i;
			trustAcc.Oliver_Hume_Account__c = createOliverHumeAccounts(1)[0].Id; 
			trustAccs.add(trustAcc);
		}
		
		insert trustAccs;
		return trustAccs; 
	}

	public static List<Account> createPersonAccounts(Integer numRec) {
		List<Account> personAccs = new List<Account>(); 

		for(Integer i = 0; i < numRec; i++) {
			Account personAcc = new Account(); 
			personAcc.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_personaccount').Id;
			personAcc.FirstName = 'FirstName'+i; 
			personAcc.LastName = 'LastName' + i; 
			personAcc.PersonEmail = 'test@test.com'+i; 
			personAccs.add(personAcc);  
		}

		insert personAccs; 
		return personAccs;
	}

	public static List<Competitor_Project__c> createCompetitorProjects(Integer numRec) {
		List<Competitor_Project__c> competitorProjects = new List<Competitor_Project__c>(); 
		for(Integer i=0; i < numRec; i++){
			Competitor_Project__c compProj = new Competitor_Project__c();
			compProj.name	=	'CompetitorProject'+i;
			compProj.Postcode__c = '1' + i; 
			compProj.Suburb_Name__c = 'test'+i; 
			competitorProjects.add(compProj);
		}

		insert competitorProjects; 
		return competitorProjects; 
	}

	public static List<Media_Item__c> createMediaItems(Integer numRec, Boolean isProject, String relatedId, Boolean isHero) {
		List<Media_Item__c> mediaItems = new List<Media_Item__c>(); 
		for(Integer i=0; i < numRec; i++) {
			Media_Item__c medItem = new Media_Item__c(); 
			medItem.Name = 'Test' + i; 
			medItem.CDN_URL__c = 'www.test.com'; 
			medItem.CDN_Thumbnail_URL__c = 'www.sample.com'; 
			medItem.Hero__c = isHero;
			medItem.File_Category__c = 'Marketing Materials'; 
			medItem.File_Type__c = 'Project Images'; 
			if(isProject) {
				medItem.Project__c = relatedId; 
			}
			else {
				medItem.Product__c = relatedId; 
			}

			mediaItems.add(medItem); 
		}

		insert mediaItems; 
		return mediaItems; 
	}

	public static List<Opportunity> createOpportunities(Integer numRec, String recordTypeId, String accId) {
		List<Opportunity> opportunities = new List<Opportunity>(); 
		for(Integer i=0; i < numRec; i++) {
			Opportunity opp = new Opportunity(); 
			opp.Name = 'Test' + i; 
			opp.StageName = 'In Progress'; 
			opp.Next_Step_Comments__c = 'Test' + i; 
			opp.CloseDate = Date.today() + 3;
			opp.Date_of_Enquiry__c = Date.today();  
			opp.Project_Picklist__c = 'Test'+i; 
			opp.Enquiry_Method__c = 'Phone'; 
			opp.Rating__c = 'Hot'; 
			opp.AccountId = accId; 

			opportunities.add(opp); 
		}

		insert opportunities; 
		return opportunities; 
	}
	
    public static Lead createLead(String proj){
    	return new Lead(
                LastName				=	'lastname', 
                Salutation				=	'Mr', 
                FirstName				=	'firstname', 
                Email					=	'test@oh.com.au', 
                MobilePhone				=	'0437402809', 
                Project_Picklist__c		=	proj, 
                Enquiry_Method__c		=	'Web Form', 
                Originating_Source__c	=	'Channel', 
                Web_2_Lead__c 			= 	true, 
                Buyer_Type__c			=	'Investor', 
                Purchase_Window__c		=	'Timeframe to purchase', 
                Enquiry_Source__c		=	'GO Portal', 
                PostalCode				=	'3000', 
                Price_Point__c			=	'$300k‐$399k', 
                Bdr__c					=	'1'    	
    	);
    }
    
    public static Project__c createProject(){
    	return new Project__c(
    			Name				=	'TestProject',
    			Owner_Assignment__c	=	UserInfo.getUserId(),
    			City__c = 'Test', 
	            Description__c = 'Sample Description', 
	            Region__c = 'Melbourne', 
	            Street_Address__c = '12 Test', 
	            Zip_Postal_Code__c = 'Victoria',
	            Status__c = 'Planned'
    	);
    }
    
    static Integer s_num=1;
    public static String getFakeId(Schema.SObjectType sot){    	
        String result = String.valueOf(s_num++);
        return sot.getDescribe().getKeyPrefix()+'0'.repeat(12-result.length())+result;
    }
	
    public static OppToTaskMapping__c createMapping() {
    	OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Web Form',
            Enquiry_Method__c = 'Web Form',
            Task_Subject__c = 'Submitted Web Form',
            Category__c = 'Web Form',
            Type__c = 'Web Form Submission'
        );
        
        return mapping; 
    }

    public static List<Product__c> createProducts(Integer numRec, String projId) {
		List<Product__c> products = new List<Product__c>(); 
		for(Integer i=0; i < numRec; i++) {
			Product__c prod = new Product__c(); 
			prod.Name = 'Product' + i; 
			prod.Project__c = projId; 
			prod.Type__c = 'Apartment';
			prod.Console_Reference__c = '00' + i; 
			prod.Qty_Available__c = 1; 

			products.add(prod);  
		}

		insert products; 
		return products; 
	}

    // Creates a Test User with a given Profile
	public static User createTestAdminUser(String firstName,String lastName,String email,String userName) {
    	return new User(
	        FirstName = firstName,
	        LastName = lastName,
	        Email = email,
	        Username = userName,
	        ProfileId = UserInfo.getProfileId(),
	        Alias = lastName.substring(0,5),
	        CommunityNickname = lastName.substring(0,5),
	        TimeZoneSidKey = 'America/Los_Angeles', 
	        LocaleSidKey='en_US', 
	        EmailEncodingKey='UTF-8', 
	        LanguageLocaleKey='en_US'
    	);
	}	
	public class TestDataException extends Exception{} 
}