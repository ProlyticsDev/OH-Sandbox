/*
    Type:       Utilities
    Purpose:    
    Used By:    Opportunity Trigger
    ---------------------------------------------------------------
    History:
                v1.0 created -- Ji Zhang 24/09/2012
                v1.01 a)modified create task regardless isweb2lead 
                      b)add extra lead fields
                      c)if web2lead and new oppty, set oppty owner to project Owner_Assignment__c
                      -- Ji Zhang 20/11/2012
                v1.02 a)only create task when it is isweb2lead (reverse back to v1.0 from v1.01)
                v1.03 test method fix Id opptyOwnerId = (projectIdMap.get(o.Project_Picklist__c)).Owner_Assignment__c; -- Ji Zhang 02/01/2013
                v1.04 add manual sharing rule for the opportunity if it is existing opportunity but differrent owner 
                      add return OpptyId for vf retURL (from vf there is only 1 lead, so there is just 1 opptyId)-- Ji Zhang 04/01/2013
                v1.05 leadProjectSet add project even without a valided email -- Ji Zhang 14/01/2013
                v1.06 fix if it is existing opp, the return url is null -- Ji Zhang 16/01/2013
                v1.07 check notify original owner check box when the opportunity is dulplicated and the creater is not 
                      currenty opportunity owner.
*/
public without sharing class LeadUtility {
     /*
        // commented our from v1.01, now the owner is from the project object -> Owner_Assignment__c (lookup field)
        private static User opptyOwner{
        get{
            if(opptyOwner == null){
                opptyOwner = [select Email from User 
                                where Primary_Opportunity_Owner_Apartments__c =: true limit 1];
            }
            return opptyOwner;
        }
        set;
    }*/  

    //SalesFix : variables used to link Campaign to project enquiry object during lead conversion    
  /*  private static Map<String, Map<String, Campaign[]>> childCampaignMap;
    private static Map<String, Map<String, Campaign>> parentCampaignMap;

    
    public static Id returnOpptyId{get;set;} 
    //SalesFix : When a lead has opted out of email, add them to the global email usubscribe campaign
    public static void EmailUnsubscribe(List<Lead> leadList){
        List<Campaign> masterCamp = [Select Id From Campaign Where Name = 'Oliver Hume Master - Email Opt Out'];        
        if(masterCamp.size() > 0){
            List<CampaignMember> existingLeadMembers = [Select Id,LeadId From CampaignMember Where LeadId in:leadList and CampaignId = :masterCamp[0].Id];
            Map<Id,CampaignMember> existingLeadMemberMap = new Map<Id,CampaignMember>();
            for(CampaignMember cm : existingLeadMembers){
                existingLeadMemberMap.put(cm.LeadId,cm);
            }
            List<CampaignMember> cmList = new List<CampaignMember>();
            for(Lead l : leadList){
                CampaignMember cm;
                if(existingLeadMemberMap.containsKey(l.Id)){
                    cm = existingLeadMemberMap.get(l.Id);
                }else{
                    cm = new CampaignMember();
                    cm.CampaignId = masterCamp[0].Id;
                    cm.LeadId = l.Id;                    
                }
                cm.Status = 'Unsubscribed';
                cmList.add(cm);                        
            }            
            if(cmList.size() > 0) upsert cmList;
        }
    }
    //SalesFix : when a lead has opted back for email, remove them from the unsubscribe campaign if exist
    public static void EmailSubscribeBack(List<Lead> leadList){
        List<Campaign> masterCamp = [Select Id From Campaign Where Name = 'Oliver Hume Master - Email Opt Out'];
        if(masterCamp.size() > 0){
            List<CampaignMember> cmList = [Select Id from CampaignMember 
                                        Where LeadId in :leadList and CampaignId=:masterCamp[0].Id ];
            if(cmList.size() > 0) delete cmList;
        }
    }

    public static void convertLeads(List<Lead> leadList){
        system.debug('$$$converLeads method!');
        Set<String> leadEmailSet = new Set<String>();
        Set<String> leadProjectSet = new Set<String>();
        Set<String> enquirySet = new Set<String>();        
        
        //Obtain the Oliver Hume User Record to reference the ID
        Profile adminProfile; 
        User adminUser;
        try{
            adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            adminUser = [SELECT Id, FirstName, LastName from User WHERE FirstName = 'Oliver' AND LastName = 'Hume' AND ProfileId =:adminProfile.Id LIMIT 1];            
        }
        catch(exception e){
            //couldn't locate the admin user, so just use the running user
            adminUser = [select id from User where Id =: userInfo.getUserId()];
        }
        //SalesFix : get appartment record type ids for Lead, Opportunity, Project objects
        Id apartmentRecordTypeId;
        Id oppApartmentRTId;
        Id prjApartmentRTId;
        List<RecordType> rts = [Select Id,SobjectType from RecordType where SobjectType in ('Lead','Opportunity','Project__c') and DeveloperName = 'Apartments'];
        if(rts.size() > 0){
            for(RecordType rt : rts){
                if(rt.SobjectType == 'Lead')
                    apartmentRecordTypeId = rt.Id;
                else if(rt.SobjectType == 'Opportunity') 
                    oppApartmentRTId = rt.Id;
                else if(rt.SobjectType == 'Project__c') 
                    prjApartmentRTId = rt.Id;
                    
            }                
        }
        
        // v1.04 create sharing list
        List<OpportunityShare> oppShareList = new List<OpportunityShare>();
         
        for(Lead l : leadList){
            system.debug('The lead owner is: '+l.ownerId);
            if(l.Email != '' && l.Email != null){
                leadEmailSet.add(l.Email);   
            }
            // v1.05 change
            // project name
            leadProjectSet.add(l.Project_Picklist__c);
            if(l.Enquiry_Source__c != null){
                enquirySet.add(l.Enquiry_Source__c);
            }
        }
        
        // only do the logic if any lead matches 
        //if(!leadEmailSet.isEmpty()){
        system.debug('$$$has email!');
        // find all personal accounts that in lead email set
        List<Account> pAcctList = new List<Account>();
        pAcctList = [select PersonEmail, LastModifiedDate from Account 
                       where IsPersonAccount =: true
                       and PersonEmail in: leadEmailSet
                       order by LastModifiedDate desc];
                       
        // key is personal email, list account -> all accounts have same email
        Map<String, List<Account>> pAcctMap = new Map<String, List<Account>>();
        
        system.debug('$$$pAcctList.isEmpty:' + pAcctList.isEmpty());
        if(!pAcctList.isEmpty()){
            for(Account a : pAcctList){
                List<Account> tempList = new List<Account>();
                if(pAcctMap.containsKey(a.PersonEmail)){
                    tempList = pAcctMap.get(a.PersonEmail);
                }
                tempList.add(a);
                pAcctMap.put(a.PersonEmail, tempList);
            }
        }              
        //To do: project set
        List<Project__c> projectList = new List<Project__c>();
        projectList = [select id, Name,RecordTypeId,Owner_Assignment__c,Business_Unit__c from Project__c where Name in: leadProjectSet];
        
        Map<String, Project__c> projectIdMap = new Map<String, Project__c>();
        for(Project__c p : projectList){
            projectIdMap.put(p.Name, p);
        }
            
        // find all open opportunities that in lead project set
        // and is open
        List<Opportunity> opptyList = new List<Opportunity>();
        opptyList = [select Name, OwnerId, Project__c, Project__r.Name, 
                     LastModifiedDate, Owner.Email, AccountId, Notify_Owner__c
                     from Opportunity
                     where Project__r.Name in: leadProjectSet 
                     and IsClosed =: false
                     and AccountId != null
                     order by LastModifiedDate desc];
        //SalesFix : change in opportunity matching logic  
        //get the most recent open opporuntiy instead of the opportunituy with the same project
        List<Opportunity> aptOpptyList = new List<Opportunity>();
        aptOpptyList = [select Name, OwnerId, Project__c, Project__r.Name,
                     LastModifiedDate, Owner.Email, AccountId, Account.PersonEmail, Notify_Owner__c,
                     (Select Id from Project_Enquiries__r)
                     from Opportunity
                     where IsClosed =: false 
                     and StageName != 'Reservation'
                     and AccountId in: pAcctList
                     and RecordTypeId =: oppApartmentRTId
                     and Business_Unit__c = 'Apartments'
                     and Sales_Channel__c != 'Channel'
                     order by Account.PersonEmail,CreatedDate desc];        
        // key is preoject id(change to project name), value is the most recently updated opportunity
        // with the same project id
        Map<String, List<Opportunity>> opptyMap = new Map<String, List<Opportunity>>();
        system.debug('$$$opptyList.isEmpty:' + opptyList.isEmpty());

        if(!opptyList.isEmpty()){
            for(Opportunity o : opptyList){
                List<Opportunity> oppList = new List<Opportunity>();
                // only put the first one as it has the most recent last modified date
                if(!opptyMap.containsKey(o.Project__r.Name)){
                    oppList.add(o);
                }else{
                    oppList = opptyMap.get(o.Project__r.Name);
                    oppList.add(o);
                }
                opptyMap.put(o.Project__r.Name, oppList);
            }
        }
        //SalesFix : Create a map of Email and the latest opp from the matched account
        Map<String, Opportunity> aptOpptyMap = new Map<String, Opportunity>();
        if(!aptOpptyList.isEmpty()){
            for(Opportunity o : aptOpptyList){
                if(!aptOpptyMap.containsKey(o.Account.PersonEmail))
                    aptOpptyMap.put(o.Account.PersonEmail, o);
            }
        }
        //SalesFix : identify the matching campaign based on project name and enquire source using the same logic from opportunity utitlity campaign association
        childCampaignMap = new Map<String, Map<String, Campaign[]>>();
        parentCampaignMap = new Map<String, Map<String, Campaign>>();
        String camQuery = 'select Id, Name, ParentId, Channels__c, StartDate, EndDate, Project__c, Project__r.Name from Campaign where isActive = true and Project__r.Name in: leadProjectSet ';
        if(!enquirySet.isEmpty()){
            camQuery += 'and Channels__c includes (';
            for(String s: enquirySet){
                camQuery += '\''+s+'\',';
            }
            camQuery = camQuery.removeEnd(',');
            camQuery += ') ';
        }
        camQuery += 'order by StartDate, createdDate asc';
       //camQuery += ') order by StartDate, createdDate asc';
        System.debug(camQuery);
        Campaign[] allCams = database.query(camQuery);
        buildCampaignMaps(allCams);

        // get appartment primary owner
        
        //OpportunityUtility.UpdateOppCampaign(emptyOppList, trigger.new); 
        //public static void UpdateOppCampaign(List<Opportunity> oldOppList, List<Opportunity> newOppList)
        // do update oppty owner id for new contact
        // do update oppty owner id for new oppty
        Set<Id> updateOpptySet = new Set<Id>();
        Set<Id> updateAccSet = new Set<Id>();
        List<Task> taskList = new List<Task>();
        List<Opportunity> updateExistingOpptyList = new List<Opportunity>();
        List<Project_Enquiry__c> paList = new List<Project_Enquiry__c>();

        //Map to Track the owners of New Opportunities based on lead ownership
        Map<Id, Id> oppOwnerMap = new Map<Id, Id>(); 
         
        for(lead l : leadList){
                // check if the contact exists by using email matching
            Boolean existingContact = false;
            Id acctId = null;
            Boolean existingOppty = false;
            Id opptyId = null;
            String sendEmail= null;
            
            //l.Project__c = projectIdMap.get(l.Project_Picklist__c).id;
            
            // found existing contact
            if(pAcctMap.containsKey(l.Email)){
                acctId = (pAcctMap.get(l.Email))[0].Id;
                existingContact = true;
            }
            system.debug('$$$acctId' + acctId);

            //SalesFix : use the new logic only for apartment opps & retain the old logic for non apartment records
            if(l.RecordTypeId == apartmentRecordTypeId && projectIdMap.containsKey(l.Project_Picklist__c) 
                && projectIdMap.get(l.Project_Picklist__c).RecordTypeId == prjApartmentRTId 
                && projectIdMap.get(l.Project_Picklist__c).Business_Unit__c == 'Apartments'
                && String.isEmpty(l.Channel_Account__c) && aptOpptyMap.containsKey(l.Email)){ 
                Opportunity o =  aptOpptyMap.get(l.Email);
                if(o.AccountId == acctId){
                    opptyId = o.Id;
                    existingOppty = true;
                    sendEmail = l.Owner.Email;
                    Opportunity op = o;
                    if(op.OwnerId != userInfo.getUserId()){
                        op.Notify_Original_Owner__c = true; 
                    }
                    updateExistingOpptyList.add(op);
                    returnOpptyId = opptyId;
                    if(o.OwnerId != userInfo.getUserId()){
                        OpportunityShare oppShare = new OpportunityShare();
                        oppShare.OpportunityId = opptyId;
                        oppShare.OpportunityAccessLevel = 'Read';
                        oppShare.UserOrGroupId = userInfo.getUserId();
                        oppShareList.add(oppShare);
                    } 
                }
            }
            else if(opptyMap.containsKey(l.Project_Picklist__c)){
                // list of all oppty with same project name
                List<Opportunity> olist = opptyMap.get(l.Project_Picklist__c);
                for(Opportunity o : olist){
                    system.debug('$$$o.AccountId' + o.AccountId);
                    // found existing oppty - same account and same project -- confirmed with david 
                    if(o.AccountId == acctId){
                        system.debug('$$$found matching accid' + o.AccountId);
                        opptyId = o.Id;
                        existingOppty = true;
                        sendEmail = l.Owner.Email;
                        Opportunity op = o;
                        //v1.07 start
                        //op.Notify_Owner__c = true;
                        //not same person then notify original owner
                        if(op.OwnerId != userInfo.getUserId()){
                            op.Notify_Original_Owner__c = true; 
                        }
                        //end 
                        updateExistingOpptyList.add(op);
                        //v1.06 
                        returnOpptyId = opptyId;
                        // v1.04 sharing rule
                        // only add to sharing list if the current oppty owner is not same as current login
                        system.debug('$$$opp owner id:' + o.OwnerId);
                        system.debug('$$$currrent user id:' + userInfo.getUserId());
                        if(o.OwnerId != userInfo.getUserId()){
                            // create sharing rule -- manual sharing
                            OpportunityShare oppShare = new OpportunityShare();
                            oppShare.OpportunityId = opptyId;
                            oppShare.OpportunityAccessLevel = 'Read';
                            oppShare.UserOrGroupId = userInfo.getUserId();
                            //oppShare.RowCause = 'Manual';
                            oppShareList.add(oppShare);
                            system.debug('$$$sharing details:' + oppShare);
                        } 
                    }
                }
            }

            system.debug('$$$existingContact:' + existingContact);
            system.debug('$$$existingOppty:' + existingOppty);
            Boolean isWebToLead = l.Web_2_Lead__c;
            String firstName = l.FirstName != null ? l.FirstName : '';
            String lastName = l.LastName != null ? l.LastName : '';
            String phone = l.Phone != null ? l.Phone : '';
            String email = l.Email != null ? l.Email : '';
            String comments = l.Comments__c != null ? l.Comments__c : '';
            String leadSource = l.LeadSource;
            String leadEnquirySource = l.Enquiry_Source__c;
            String leadWebFormSource = l.Web_Form_Source__c != null ? l.Web_Form_Source__c : '';
            String propertyType = l.Property_Type__c;
            String pricePoint = l.Price_Point__c;
            String buyerType = l.Buyer_Type__c;
            String purchaseWindow = l.Purchase_Window__c;
            String suburb = l.Suburb__c;
            //if(existingContact && existingOppty){
            Database.LeadConvertResult lcr = convertOneLead(l, acctId, opptyId, existingContact, existingOppty, sendEmail);         
            //}
            // v1.06 
            if(!existingOppty)
                returnOpptyId = lcr.getOpportunityId();
            
            system.debug('$$$$existingContact:' + existingContact);
            system.debug('$$$$existingOppty:' + existingOppty);
           
            //--- add for fix start ---
            if(!existingContact || !existingOppty){
                updateOpptySet.add(lcr.getOpportunityId());
                updateAccSet.add(lcr.getAccountId());
                //here we also want to track the original lead owner against the opportunity
                oppOwnerMap.put(lcr.getOpportunityId(), l.OwnerId);
            }
            //--- add for fix end ---

            //SalesFix : Create a project assignment mapping the current project enquired to the opportunity            
            if(l.RecordTypeId == apartmentRecordTypeId && projectIdMap.containsKey(l.Project_Picklist__c) 
                && projectIdMap.get(l.Project_Picklist__c).RecordTypeId == prjApartmentRTId 
                && projectIdMap.get(l.Project_Picklist__c).Business_Unit__c == 'Apartments'
                && String.isEmpty(l.Channel_Account__c)){
                Id paAccntId = existingContact ? acctId : lcr.getAccountId();
                Id paPrjId = projectIdMap.get(l.Project_Picklist__c).Id;   
                Id paCampId = getCampaignId(l);
                Id paOppId = existingOppty ? opptyId : returnOpptyId;    
                Boolean isPrimary = true;
                if(existingOppty){
                    Opportunity opp = aptOpptyMap.get(l.Email);
                    if(opp != null && opp.Project_Enquiries__r != null && opp.Project_Enquiries__r.size() > 0) 
                        isPrimary = false;    
                }    
                Project_Enquiry__c pa = createProjectAssignment(paAccntId,paPrjId,paCampId,paOppId,l,isPrimary);
                paList.add(pa);   
            }
            
            system.debug('$$$$updateOpptySet:' +  updateOpptySet);
            // for creating task only create task when
            // enquiry method = web form
            // added by PE: 3rd Oct 2012 - checks Web 2 Lead 
            //SalesFix : added second condition to check the field Skip Web Form Task
            if(l.Enquiry_Method__c == 'Web Form' && !l.Skip_Web_Form_Task__c){
                if(isWebToLead){ //-- v1.01 commented out // reversed back v1.02
                    Task taskRec = new Task();
                    taskRec.Subject = 'Submitted Web Form';
                    taskRec.Category__c = 'Web Form';
                    taskRec.Type = 'Web Form';
                    taskRec.Priority  = 'Normal';
                    taskRec.Is_New__c = true;
                    taskRec.Status = 'Completed';
                    taskRec.WhoId = lcr.getContactId();
                    if(!existingOppty){
                        taskRec.WhatId = lcr.getOpportunityId();
                    }else{
                        taskRec.WhatId = opptyId;
                    }
                    taskRec.Project_Name__c = l.Project_Picklist__c;
                    system.debug('debuginfo : ' + taskRec.Project_Name__c);
                    taskRec.Description = 'First Name: ' + firstName + '\n' 
                                         +'Last Name: ' + lastName + '\n' 
                                         +'Phone: ' + phone + '\n'
                                         +'Email: ' + email + '\n'
                                         +'Lead Source: ' + leadSource + '\n'
                                         +'Enquiry Source: ' + leadEnquirySource + '\n'
                                         +'Lead Web Form Source: ' + leadWebFormSource + '\n'
                                         +'Suburb: ' + Suburb + '\n'
                                         +'Property Type: ' + propertyType + '\n'
                                         +'Price Point: ' + pricePoint + '\n' 
                                         +'Buyer Type: ' + buyerType + '\n'
                                         +'Purchase Window: ' + purchaseWindow + '\n'
                                         +'Comments: ' + comments;
                    taskRec.ActivityDate = date.today();
                    taskRec.Activity_Date__c = date.today();
                    taskList.add(taskRec);
                }
            }
        }
        
        //update all existing opp -- for set notify owner to trigger workflow
        if(!updateExistingOpptyList.isEmpty()){
            update updateExistingOpptyList;
        }
        //SalesFix : insert the new project assignment records
        if(!paList.isEmpty()) insert paList;

        // calling opptunityUtility to update oppty
        // set oppty owner Id
        List<Opportunity> newOpptyList = new List<Opportunity>();
        newOpptyList = [Select OwnerId, AccountId, LeadSource, Project__c, Project_Picklist__c, 
                        Web_2_Lead__c, Notify_Owner__c, RecordTypeId,Business_Unit__c
                        From opportunity Where Id in: updateOpptySet];
        List<Opportunity> updateOpptyList = new List<Opportunity>();     
        //set account owner id
        List<Account> newAccList = new List<Account>();
        newAccList = [select OwnerId from Account where Id in: updateAccSet];
        List<Account> updateAccList = new List<Account>();
        
        //for each new account, update the owner to sys admin user
       
        for(Account a: newAccList){
            a.OwnerId = adminUser.Id;
            updateAccList.add(a);
        }
        //update the accounts here
        update updateAccList;
        //if(opptyList.isEmpty()){
            for(Opportunity o : newOpptyList){
                //SalesFix : skip the opportunity owner assignment for Apartments - its handled in process builder now
                if(o.RecordTypeId == oppApartmentRTId && o.Business_Unit__c == 'Apartments')
                    continue;
                
                system.debug('$$$webtolead:' + o.web_2_lead__c);
                if(o.Web_2_Lead__c){
                    Id opptyOwnerId = (projectIdMap.get(o.Project_Picklist__c)).Owner_Assignment__c;
                    o.ownerId = opptyOwnerId;
                    o.Notify_Owner__c = true;
                }else{
                    system.debug('$$$set login id');
                    /* CW Changed to reference original lead owner, not logged in user*/
                    //o.ownerId = UserInfo.getUserId();
                    //set as lead owner, not current logged in user
                    //Has to be done here as the convert process sets the owner as the context user due to privacy settings
                    /* Commented Out Because this is Being Set on Convert. */
    /*                o.ownerId = oppOwnerMap.get(o.Id);
                }
                updateOpptyList.add(o);
            }
            system.debug('$$$updateOpptyList' + updateOpptyList);
            //system.debug('$$$calling oppty utility');
            //List<Opportunity> emptyOppList = new List<Opportunity>();
            //OpportunityUtility.UpdateOppCampaign(emptyOppList, updateOpptyList);
            if(!updateOpptyList.isEmpty()){
                update updateOpptyList; 
            }
        //}   
        
        if(!taskList.isEmpty()){
            try{
                system.debug('$$$lead create task:' + taskList);
                insert taskList;
            }catch(Exception e){
                system.debug(e);    
            }
        } 
        
        //v1.04 insert all sharing rule records
        if(!oppShareList.isEmpty()){
            system.debug('$$$creating sharing!!');
            try{
                Database.SaveResult[] oppShareInsertResult = Database.insert(oppShareList,false);
                for(Database.SaveResult sr:oppShareInsertResult){
                   if(!sr.isSuccess())
                      Database.Error err = sr.getErrors()[0];
                }
            }catch(Exception e){
                system.debug(e);    
            }
        }  
    }
    //}

    //SalesFix : helper method to build the parent and child campaing maps to link to project enquiry
    private static void buildCampaignMaps(List<Campaign> allCams){        
        for(Campaign c: allCams){
            if(c.ParentId != null){
                if(childCampaignMap.get(c.Project__r.Name) == null){
                    childCampaignMap.put(c.Project__r.Name, new Map<String, Campaign[]>());
                }
                if(String.isNotBlank(c.Channels__c)) {
                    for(String s: c.Channels__c.split(';')){
                        if(childCampaignMap.get(c.Project__r.Name).get(s) == null){
                            childCampaignMap.get(c.Project__r.Name).put(s, new Campaign[]{});
                        }
                        childCampaignMap.get(c.Project__r.Name).get(s).add(c);
                    }   
                }
            }
            else{
                if(parentCampaignMap.get(c.Project__r.Name) == null){
                    parentCampaignMap.put(c.Project__r.Name, new Map<String, Campaign>());  
                }
                if(String.isNotBlank(c.Channels__c)) {
                    for(String s: c.Channels__c.split(';')){
                        parentCampaignMap.get(c.Project__r.Name).put(s, c);
                    }
                }
            }
        }
    }
    //SalesFix : helper method get the matching campaign id based on project name and enquiry source
    private static Id getCampaignId(Lead l){
        Id paCampId;
        if(childCampaignMap.get(l.Project_Picklist__c) != null && childCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c) != null){
            Campaign[] sourceCampaigns = childCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c);
            Campaign[] newChildCampaigns = new Campaign[]{};
            boolean hasFound = false;
            for(Campaign c: sourceCampaigns){
                Date enqDate = Date.today();
                for(Integer i = 0; i <8; i++){
                    if(c.StartDate<= enqDate && c.EndDate >= enqDate){
                        paCampId = c.Id;
                        hasFound = true;
                        break;  
                    }
                    else{
                        enqDate = enqDate.addDays(-7);
                    }
                }
            }
            if(!hasFound){
                Campaign lastCampaign = sourceCampaigns[sourceCampaigns.size()-1];
                paCampId = lastCampaign.Id;
            }
        }
        else{
            if(parentCampaignMap.get(l.Project_Picklist__c) != null && parentCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c) != null){
                Campaign matchingParentCampaign = parentCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c);
                paCampId = matchingParentCampaign.Id;
            }
        }
        return paCampId;
    }
    //SalesFix : helper method to create project assignment record
    private static Project_Enquiry__c createProjectAssignment(Id paAccntId,Id paPrjId,Id paCampId,Id paOppId, Lead l, Boolean isPrimary){
        Project_Enquiry__c pa = new Project_Enquiry__c();
        pa.Project__c = paPrjId;
        pa.Opportunity__c =  paOppId;
        pa.Campaign__c = paCampId;
        pa.Primary__c = isPrimary;
        pa.Status__c = 'Interested';
        pa.Client_Enquiry__c = true;
        pa.Property_Connect__c = l.Property_Connect__c;
        pa.Enquiry_Method__c = l.Enquiry_Method__c;
        pa.Enquiry_Source__c = l.Enquiry_Source__c;
        pa.Enquiry_Source_Other__c = l.Enquiry_Source_Other__c;
        pa.Lead_Source__c = l.LeadSource;
        pa.Web_Form_Source__c = l.Web_Form_Source__c;
        pa.Channel_Account__c = l.Channel_Account__c;
        pa.UTM_Campaign__c = l.UTM_Campaign__c;
        pa.UTM_Content__c = l.UTM_Content__c;
        pa.UTM_Medium__c = l.UTM_Medium__c;
        pa.UTM_Source__c = l.UTM_Source__c;
        pa.UTM_Term__c = l.UTM_Term__c;
        pa.Product_Interest__c = l.Product_Interest__c;
        pa.Project_Stage__c = l.Project_Stage__c;
        
        pa.Building_Type__c = l.Building_Type__c;
        pa.Product_Size__c = l.Product_Size__c;
        pa.Bdr__c = l.Bdr__c;
        pa.Bth__c = l.Bth__c;
        pa.Study__c = l.Study__c;
        pa.Car__c = l.Car__c;
        pa.Storeys__c = l.Storeys__c;
        pa.Rating__c = l.Rating__c;
        pa.Buyer_Type__c = l.Buyer_Type__c;
        pa.Buyer_Experience__c = l.Buyer_Experience__c;
        pa.Purchase_Window__c = l.Purchase_Window__c;
        pa.Price_Point__c = l.Price_Point__c;
        pa.Finance__c = l.Finance__c;
        pa.FIRB__c = l.FIRB__c;
        pa.Household_Type__c = l.Household_Type__c;
        pa.Suburb__c = l.Suburb__c;
        //jh - case 2068 
        pa.Purchaser__c = paAccntId; 
        
        return pa;
    }

    private static Database.LeadConvertResult convertOneLead(Lead leadRec, Id acctId, Id opptyId, Boolean existingContact, Boolean existingOppty, String sendEmail){
        system.debug('$$$do convert lead');
        /*
        //locate the admin user
        Profile adminProfile; 
        User adminUser;
        try{
            adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            adminUser = [SELECT Id, FirstName, LastName from User WHERE FirstName = 'Oliver' AND LastName = 'Hume' AND ProfileId =:adminProfile.Id LIMIT 1];
        }
        catch(exception e){
            //couldn't locate the admin user, so just use the running user
            adminUser = [select id from User where Id =: userInfo.getUserId()];
        }
        */
        //try setting the lead owner as well.
        //leadRec.ownerId = adminUser.Id;
        
   /*     Database.Leadconvert lc = new Database.Leadconvert();
        lc.setLeadId(leadRec.Id);
        lc.setConvertedStatus('Qualified');
        //try and set the owner of the converted records, this can't affect the orginal lead owner.
        //lc.setOwnerId(adminUser.Id);
        lc.setOwnerId(leadRec.OwnerId);
        // case 1: existing contact, existing opportunity
        // case 2: existing contact, new opportunity
        // case 3: new contact, always new opportunity
        if(existingContact){
            lc.setAccountId(acctId);
        } 
        
        if(existingOppty && existingContact){
            lc.setDoNotCreateOpportunity(true); 
            // To Do: send email
            if(sendEmail != null && sendEmail != ''){
                // To Do: send email
            } 
        }
        if(!existingOppty){
            // set oppty name
            String d = String.valueOf(leadRec.Date_of_Enquiry__c);
            d = d.subString(8,10) + '-' + d.subString(5,7) + '-' + d.subString(0,4);
            //d = d.subString(0,d.length()-9);
            lc.setOpportunityName(leadRec.LastName + ' - ' + leadRec.Project_Picklist__c + ' - ' + d);
        }
        //lc.setDoNotCreateOpportunity(true); 
        system.debug('existingContact:' + existingContact);
        system.debug('existingOppty:' + existingOppty);
        Database.LeadConvertResult lcr = Database.convertLead(lc);
        system.debug('$$$convert status:' + lcr.isSuccess());
        return lcr;
    }
    
    static testMethod void leadUtilityTest(){
        Test.startTest();
        List<OppToTaskMapping__c> mappings = new  List<OppToTaskMapping__c>{
            new OppToTaskMapping__c(
                Name = 'Walk-In New',
                Enquiry_Method__c = 'Walk-In',
                Task_Subject__c = 'Walk-In Enquiry',
                Category__c = 'Walk In - New',
                Type__c = 'Walk-In'
            ), 
            new OppToTaskMapping__c(
                Name = 'Web Form',
                Enquiry_Method__c = 'Web Form',
                Task_Subject__c = 'Submitted Web Form',
                Category__c = 'Web Form',
                Type__c = 'Web Form Submission'
            )
        };
        insert mappings;
        
        Account acct = new Account();
        acct.Salutation = 'Mr';
        acct.firstName = 'pFirstName';
        //acct.IsPersonAccount = true;
        acct.LastName = 'pLastName';
        acct.PersonEmail = 'a@a.com';
        insert acct;
        
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.Owner_Assignment__c = userInfo.getUserId();
        insert project;
        system.debug('$$$inserted project:' + project);
        
        Project__c project1 = new Project__c();
        project.Name = 'Test Project1';
        project.Owner_Assignment__c = userInfo.getUserId();
        insert project1;
        
        Campaign pCampaign = new Campaign();
        pCampaign.Name = 'Parent Campaign';
        pCampaign.IsActive = true;
        pCampaign.StartDate = date.today();
        pCampaign.EndDate = date.today().addDays(30);
        pCampaign.Project__c = project.Id;
        pCampaign.Channel__c = 'The Age';
        pCampaign.Channels__c = 'The Age; The Sun Herald';
        insert pCampaign;
        
        Campaign chCampaign = new Campaign();
        chCampaign.Name = 'Parent Campaign';
        chCampaign.IsActive = true;
        chCampaign.StartDate = date.today();
        chCampaign.EndDate = date.today().addDays(30);
        chCampaign.Project__c = project.Id;
        chCampaign.Channel__c = 'Web';
        chCampaign.Channels__c = 'Web';
        chCampaign.ParentId = pCampaign.Id;
        insert chCampaign;
        
        
        List<Lead> leadList = new List<Lead>();
        
        // case 1: no match contact
        Lead lead = new Lead();
        lead.Salutation = 'Mr';
        lead.LastName = 'lname';
        lead.Date_of_Enquiry__c = date.today();
        lead.leadSource = 'D3';
        lead.Enquiry_Method__c = 'Web Form';
        lead.Property_Type__c = 'Apartment';
        //lead.Status = 'Open';
        lead.Auto_Convert__c = false; //true;
        lead.Project_Picklist__c = 'Test Project';
        lead.LeadSource = 'The Age';
        lead.email = 'test@email.com';
        lead.Search_Campaign__c = false;
        lead.Status = 'Qualified';
        leadList.add(lead);     
        /*
        // case 2: match contact
        lead = new Lead();
        lead.Salutation = 'Mr';
        lead.LastName = 'lname';
        lead.Date_of_Enquiry__c = date.today();
        lead.leadSource = 'D3';
        lead.Enquiry_Method__c = 'Web Form';
        lead.Property_Type__c = 'Apartment';
        //lead.Status = 'Open';
        lead.Email = 'a@a.com';
        lead.Auto_Convert__c = true;
        lead.Web_2_Lead__c = true;
        lead.Project_Picklist__c = 'Test Project';
        lead.LeadSource = 'Web';
        lead.phone = '123';
        lead.Search_Campaign__c = false;
        lead.Status = 'Qualified';
        leadList.add(lead);  
        /*
        for(Integer i = 0; i < 1; i++){
            Lead lead = new Lead();
            lead.Salutation = 'Mr' + i;
            lead.LastName = 'lname' + i;
            lead.Date_of_Enquiry__c = date.today();
            lead.leadSource = 'The Age';
            lead.Enquiry_Method__c = 'Web Form';
            lead.Property_Type__c = 'Apartment';
            //lead.Status = 'Open';
            lead.Email = i + 'a@a.com';
            lead.Auto_Convert__c = true;
            lead.Web_2_Lead__c = true;
            lead.Project_Picklist__c = 'Test Project';
            lead.LeadSource = 'Web';
            lead.phone = '123';
            lead.Search_Campaign__c = false;
            lead.Status = 'Qualified';
            leadList.add(lead);  
        }
        insert leadList;
        Test.stopTest();
    }*/
   
}