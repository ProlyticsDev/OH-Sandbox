/*
    Type:       Utilities
    Purpose:
    Used By:    Opportunity Trigger
    ---------------------------------------------------------------
    History:
                v1.0 created -- Ji Zhang 24/09/2012
                v1.01 updated set oppty owner to project Owner_Assignment__c -- Ji Zhang 02/01/2013
                HR - 18/05/2016 - Replace workflows to reduce the SOQL limit errors
*/
public without sharing class OpportunityUtility {

    //SalesFix : Static variable to avoid recursive updates
    private static boolean createPE = true;
    public static boolean CanCreatePE{
        get{
            if(createPE){
                createPE = false;
                return true;
            }
            return createPE;
        }
        set{
            createPE = value;
        }
    }

    public static final Map<String, OppToTaskMapping__c> taskMapping;
    static {
         taskMapping = OppToTaskMapping__c.getAll();
    }

     private static User opptyOwner{
        get{
            if(opptyOwner == null){
                opptyOwner = [select Email from User
                                where Primary_Opportunity_Owner_Apartments__c =: true limit 1];
            }
            return opptyOwner;
        }
        set;
    }

    //SalesFix : helper method to create project assignment based on opportunity fields
    public static Project_Enquiry__c createProjectAssignment(Opportunity opp,Id peId){
        Project_Enquiry__c pa = new Project_Enquiry__c(Id = peId);
        pa.Campaign__c = opp.Originating_Campaign__c;
        pa.Channel_Account__c = opp.Channel_Account__c;
        pa.Enquiry_Method__c = opp.Enquiry_Method__c;
        pa.Enquiry_Source__c = opp.Enquiry_Source__c;
        pa.Enquiry_Source_Other__c = opp.Enquiry_Source_Other__c;
        pa.Lead_Source__c = opp.LeadSource;
        pa.Web_Form_Source__c = opp.Web_Form_Source__c;
        pa.UTM_Campaign__c = opp.UTM_Campaign__c;
        pa.UTM_Content__c = opp.UTM_Content__c;
        pa.UTM_Medium__c = opp.UTM_Medium__c;
        pa.UTM_Source__c = opp.UTM_Source__c;
        pa.UTM_Term__c = opp.UTM_Term__c;
        pa.Product_Interest__c = opp.Lot_No__c;
        pa.Project_Stage__c = opp.Project_Stage__c;
        pa.Property_Connect__c = opp.Property_Connect__c;
        pa.Building_Type__c = opp.Building_Type__c;
        pa.Product_Size__c = opp.Product_Size__c;
        pa.Bdr__c = opp.Bdr__c;
        pa.Bth__c = opp.Bth__c;
        pa.Study__c = opp.Study__c;
        pa.Car__c = opp.Car__c;
        pa.Storeys__c = opp.Storeys__c;
        pa.Rating__c = opp.Rating__c;
        pa.Buyer_Type__c = opp.Buyer_Type__c;
        pa.Buyer_Experience__c = opp.Buyer_Experience__c;
        pa.Purchase_Window__c = opp.Purchase_Window__c;
        pa.Price_Point__c = opp.Price_Point__c;
        pa.Finance__c = opp.Finance__c;
        pa.FIRB__c = opp.FIRB__c;
        pa.Household_Type__c = opp.Household_Type__c;
        pa.Suburb__c = opp.Suburb__c;
        //jh - case 2068
        pa.Purchaser__c = opp.AccountId; 

        return pa;
    }

    public static void updateOppProject(Opportunity[] newOpps){
        //passed insert Opportunities, check that the lookup is populated and add to list to be updated.
        Opportunity[] opps = new Opportunity[]{};
        for(Opportunity o: newOpps){
            if(o.Project_Picklist__c != null){
                opps.add(o);
            }
        }
        if(!opps.isEmpty()){
            //send to the util for updating
            OpportunityUtility.updateOppProjectUtil(opps);
        }
    }

    public static void updateOppProject(Opportunity[] newOpps, Opportunity[] oldOpps){
        //passed updated Opportunities, check that the lookup is populated and has changed, add to list to be updated.
        Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(oldOpps);
        //opps to be passed into util method
        Opportunity[] opps = new Opportunity[]{};
        for(Opportunity o: newOpps){
            if(o.Project_Picklist__c != null && o.Project_Picklist__c != oldMap.get(o.Id).Project_Picklist__c){
                //there is a value and it has changed since the old map version
                opps.add(o);
            }
        }
        if(!opps.isEmpty()){
            OpportunityUtility.updateOppProjectUtil(opps);
        }
    }

    public static void updateOppProjectUtil(Opportunity[] opps){
        //this method will be passed a list of opportunities that need to have the project lookup updated.
        //get a list of potential project names.
        String[] projectNames = new String[]{};
        for(Opportunity o: opps){
            projectNames.add(o.Project_Picklist__c);
        }
        //query for project, and create a map.
        Map<String, Project__c> projectNameMap = new Map<String, Project__c>();
        for(Project__c p: [select Id, Name,RecordTypeId from Project__c where Name in: projectNames]){
            projectNameMap.put(p.Name, p);
        }
        //SalesFix : get appartment record type for Project & Opportunity
        Id oppApartmentRTId;
        Id prjApartmentRTId;
        List<RecordType> rts = [Select Id,SobjectType from RecordType where SobjectType in ('Opportunity','Project__c') and DeveloperName = 'Apartments'];
        if(rts.size() > 0){
            for(RecordType rt : rts){
                if(rt.SobjectType == 'Opportunity')
                    oppApartmentRTId = rt.Id;
                else if(rt.SobjectType == 'Project__c')
                    prjApartmentRTId = rt.Id;

            }
        }
        //now update the opportunities
        for(Opportunity o: opps){
            if(projectNameMap.get(o.Project_Picklist__c) != null){
                //project found in map, so update it here.
                o.Project__c = projectNameMap.get(o.Project_Picklist__c).Id;
                //SalesFix : if the project record type is Apartments set the Opportunity RecordType to Apartments
                if(projectNameMap.get(o.Project_Picklist__c).RecordTypeId == prjApartmentRTId)
                    o.RecordTypeId = oppApartmentRTId;
            }
            else{
                //no project found!
                system.debug('ALERT! No project found for this Project Picklist Value: '+o.Project_Picklist__c);
            }
        }
    }

    //updates the Notify Owner Field on the Opportunity where Web to Lead is set to True.
    public static void setNotifyOwner(Opportunity[] opps){
        for(Opportunity o: opps){
            if(o.Web_2_Lead__c){
                o.Notify_Owner__c = true;
            }
        }
    }

    //HR - Modified the method to check if the map already populated not to run the query again
    static Map<String,String> productRecordTypes = new Map<String,String>();

    public static Map<String, String> getProductRecordTypes(){
        //queries the data base and returns a list of product recordtypes.
        try{
            if(productRecordTypes.isEmpty()){                
                for(RecordType rt: [Select Name, Id From RecordType where sObjectType='Product__c' and isActive=true]){
                     productRecordTypes.put(rt.Name,rt.Id);
                }
            }
            return productRecordTypes;
        }
        catch(exception e){
            return null;
        }
    }

    /*
     * This is a helper method for auto creating default task against a newly created
     * opportunity from the trigger.
     */
    public static void createTaskAfterOppCreation(List<Opportunity> opportunities) {
         if (opportunities == null || opportunities.isEmpty())
             return;

         OppToTaskMapping__c walkInNew = taskMapping.get('Walk-In New');

         if (walkInNew != null) {
             List<Task> newTasks = new List<Task>();

             Set<Id> accountIds = new Set<Id>();
             for (Opportunity opportunity : opportunities) {
                 accountIds.add(opportunity.AccountId);
             }

             Map<Id, Contact> personAccountWithContacts = getPersonalAccountContacts(accountIds);

             for (Opportunity opportunity : opportunities) {
                 //Setting subject, category and type values.

                 String subject = walkInNew.Task_Subject__c;
                 String category = walkInNew.Category__c;
                 String type = walkInNew.Type__c;
                 String project;
                 Date dueDate, activityDate;

                 if (String.isNotBlank(opportunity.Enquiry_Method__c)) {
                     if (opportunity.Enquiry_Method__c == 'Web Form' && opportunity.Web_2_Lead__c) {
                         System.debug('###Skip if lead conversion.');
                         continue; //skip creating task if it is converted lead.
                     } else {
                         OppToTaskMapping__c otherEnquiryMethodMapping = taskMapping.get(opportunity.Enquiry_Method__c);

                         if (otherEnquiryMethodMapping != null) {
                             subject = otherEnquiryMethodMapping.Task_Subject__c;
                             category = otherEnquiryMethodMapping.Category__c;
                             type = otherEnquiryMethodMapping.Type__c;
                         }
                     }
                 }

                 Contact contact = personAccountWithContacts.get(opportunity.AccountId);
                 Id contactId = (contact != null)? contact.Id : null;
                 newTasks.add(new Task(
                     OwnerId           = opportunity.OwnerId,
                     WhatId            = opportunity.Id,
                     WhoId             = contactId,
                     Priority          = 'Normal',
                     Status            = 'Completed',
                     Is_New__c         = true,
                     Subject           = subject,
                     Category__c       = category,
                     Type              = type,
                     Project_Name__c   = opportunity.Project_Picklist__c,
                     ActivityDate      = opportunity.Date_of_Enquiry__c,
                     Activity_Date__c  = opportunity.Date_of_Enquiry__c
                 ));
             }


             if (!newTasks.isEmpty()) {
                 try {
                     insert newTasks;
                 } catch (System.DMLException dml) {
                     for (Integer i = 0; i < dml.getNumDml(); i++)
                         System.debug('### EXCEPTION in task creation after opportunity created: ' + dml.getDmlMessage(i));
                 }
             }
        }
    }

     private static Map<Id, Contact> getPersonalAccountContacts(Set<Id> accIds) {
         Map<Id, Contact> personalAccountContacts = new Map<Id, Contact>();

         for (Account account : [SELECT Id, (select Id from contacts) FROM Account WHERE IsPersonAccount = true AND Id IN: accIds]) {
            if (!personalAccountContacts.containsKey(account.Id))
                personalAccountContacts.put(account.Id, account.Contacts[0]);
         }

         return personalAccountContacts;
     }

    //method taked the bulk of logic originally handled by the accountTrigger to avoid governor limits.  runs async so there may be a delay in sharing config.
    @future
    public static void processAccountShares(Id[] accIDs, Map<Id, Id> oldOwners){
		Opportunity[] oppList = new Opportunity[]{};
		Map<Id, Id> oldAccMap = new Map<Id, Id>();
		AccountShare[] updatedShares = new AccountShare[]{};

		//Return any opportunites associated with these accounts
		Account[] accList = [select id, OwnerId, (select Id, OwnerId from Opportunities) from Account where id in: accIds];
		//Loop through the accList, check to see if the old acc owner still owns an opportunity, if they do, we are going to update there share.
		for(Account a: AccList){
			Id oldUserId = oldOwners.get(a.Id);
		 	//loop through the sub opportunities, if any of them are owned by the old owner, then add them to a list
		 	for(Opportunity o: a.Opportunities){
			 	if(o.OwnerId == oldUserId){
			 		system.debug('Found an opportunity owned by the old owner');
			 		//add the owner to a list
			 		//probably a map of account id and owner id
			 		//an account can only have one (old owner), so make the account the key
			 		oldAccMap.put(a.Id, oldUserId);
			 		break;
			 	}
		 	}
		}
		if(!oldAccMap.isEmpty()){
			//get the share records for the chosen accounts
			for(AccountShare a: [Select UserOrGroupId, RowCause, AccountAccessLevel, OpportunityAccessLevel, Id, ContactAccessLevel, CaseAccessLevel, AccountId From AccountShare where AccountId in: oldAccMap.keyset()]){
				//loop through the share and see if they need updating
				//check the share user in the account map, if they are in there, then they should have at least edit access, so update.
				if(oldAccMap.get(a.AccountId) != null && oldAccMap.get(a.AccountId) == a.UserOrGroupId){
					//modify the permissions if needed, and add to a list for udpate.
					system.debug('Access Level on Account: '+a.AccountAccessLevel);
					if(a.AccountAccessLevel == 'Read'){
						a.AccountAccessLevel = 'Edit';
						updatedShares.add(a);
					}
				}
			}
		}
		update updatedShares;

    }


    public class shareData{
    	public AccountShare[] accountShares;
    	public AccountTeamMember[] accountMembers;

    	public shareData(){
    		//create the default lists
    		accountShares = new AccountShare[]{};
    		accountMembers = new AccountTeamMember[]{};
    	}

    }

    @future
    public static void processBeforeOppShares(string shareJSON){
    	//deserialize the JSON data
    	shareData oppShareData = (shareData)System.JSON.deserialize(shareJSON, shareData.class);
    	Set<Id> adminUsers = new Set<Id>();
    	//get sys admin profile ids
	    for(Profile p: [select Id, (select Id from Users where isActive = true) from Profile where PermissionsModifyAllData = true]){
	    	for(User u: p.Users){
	    		adminUsers.add(u.Id);
	    	}
	    }
    	AccountTeamMember[] newMembers = new AccountTeamMember[]{};
    	AccountShare[] newShares = new AccountShare[]{};
    	//runs without sharing async to try and update the sharing and members
    	system.debug('Opp Member Size for insert: '+oppShareData.accountMembers.size());
    	for(AccountTeamMember a: oppShareData.accountMembers){
    		if(!adminUsers.contains(a.UserId)){
    			newMembers.add(a);
    		}

    	}
    	for(AccountShare a: oppShareData.accountShares){
    		if(!adminUsers.contains(a.UserOrGroupId)){
    			newShares.add(a);
    		}
    	}
    	system.debug('Opp Share Size for insert: '+oppShareData.accountShares.size());
    	try{
	    	upsert newMembers;
			upsert newShares;
    	}
    	catch(exception e){
    		/*
    		String errorString = 'A Sharing Error has occured: \n\n';
    		errorString +='Line: '+e.getLineNumber()+'\n\n';
    		errorString +='Message: '+e.getMessage()+'\n\n';
    		errorString +='Stack Trace: '+e.getStackTraceString()+'\n\n';

    		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
			String[] toAddresses = new String[] {'aa@aprika.com.au'};
			mail.setToAddresses(toAddresses);
			// Specify the subject line for your email address.
			mail.setSubject('Sharing Error Occurred');
			mail.setPlainTextBody(errorString);
			Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
			*/
    	}
    }

    /**
    * @author JH 
    * @date 24/03/2016
    * @description For a list of opportunities checks if they are in the appropriate custom setting. If they are checks if 
    * the expected title date is greater than three months. If it is checks a flag. If it isn't sets the flag to false. 
    */ 
    public static List<Opportunity> expectedTitleDateGreaterThanThreeMonths(List<Opportunity> opps) {


        //query the custom meta data type for all the projects where this rule is applicable 
        List<Opportunity_Expected_Title_Date__mdt> projectsForRule = [SELECT Id, Label FROM Opportunity_Expected_Title_Date__mdt]; 
        if(projectsForRule != null && !projectsForRule.isEmpty()) {
            Set<String> applicableProjects = new Set<String>(); 
            for(Opportunity_Expected_Title_Date__mdt applicableProj :projectsForRule) {
                if(!applicableProjects.contains(applicableProj.Label)) {
                    applicableProjects.add(applicableProj.Label); 
                }
            }

            List<Opportunity> oppsForUpdate = new List<Opportunity>(); 
            //jh - only do the processing if there are records which require this rule 
            if(applicableProjects != null && !applicableProjects.isEmpty()) {
                for(Opportunity theOpp :opps) {
                    if(applicableProjects.contains(theOpp.Project__r.Name)) {
                        //jh - the opp is in a applicable project run the rule 
                        Date expectedTitleDate = theOpp.Expected_Titled_Date__c; 
                        Date today = Date.today(); 
                        if(expectedTitleDate != null) {
                            Integer daysBetween = Date.today().daysBetween(expectedtitleDate);
                            if(daysBetween > 90) {
                                theOpp.Expected_title_date_3_Months__c = true; 
                            }
                            else if(daysBetween < 90) {
                                theOpp.Expected_title_date_3_Months__c = false; 
                            }
                            oppsForUpdate.add(theOpp); 
                        }
                    }
                }

                //jh - if there are opps that need to be updated then perform the update. 
                if(oppsForUpdate != null && !oppsForUpdate.isEmpty()) {
                    return oppsForUpdate; 
                }
            }
        }
        return null; 
    }

    //HR - 18/05/2016 - Replace workflows to reduce the SOQL limit errors
    public static void updateName(List<Opportunity> opps){
        for(Opportunity o : opps){
            o.Name = o.OpportunityName__c;
        }
    }
}