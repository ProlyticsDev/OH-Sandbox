/*
    Type:        Trigger
    Purpose:     

    Used By:     Opportunity Object
    ---------------------------------------------------------------
    History:
      v1.0 created -- Ji Zhang 24/09/2012
      v2.0 created -- Colin Johnson (Aprika Business Solutions) 27/11/2012
      v2.1 created -- Colin Johnson, Aprika - 19/02/13 (Edited to include Budget solution
      v2.2 created -- Colin Johnson, Aprika - 07/03/13 (Edited to include Item Reservation Update and Contract Signing Event creation)
          modified -- HR 15/03/2016, Fix for:
                        SObject row was retrieved via SOQL without querying the requested field: Item__c.Contract_Signing_Appointment_Date__c
                        by added the missing field in the query
                      HR 19/05/2016 Add opp naming method replacing workflows
*/

trigger OpportunityTrigger on Opportunity (before insert, before update, before delete, after insert, after update) {
    
    //CJ Edit
    
    If(trigger.isBefore){
        //Set opp name
        if(!trigger.isDelete)
            OpportunityUtility.updateName(Trigger.new);
    // all logic is in OpportunityUtility class
      if (Trigger.isDelete) {
            List<Receipt__c> receipts = [SELECT Id, Opportunity__c FROM Receipt__c WHERE Reconciled__c = true AND Opportunity__c IN :Trigger.oldMap.keySet()];
            for (Receipt__c r : receipts) {
              Trigger.oldmap.get(r.Opportunity__c).addError('Deleting the Opportunity is not allowed as it contains reconciled receipts');
          }
        }
        
        if(trigger.isInsert){
            opportunityUtility.updateOppProject(trigger.new);
            //project picklist has been updated, send to the associate campaign method.    
            opportunityCampaignUtility.associateCampaign(trigger.new);
            //Ensure the Notify Owner field is set for new Opps where Web to Lead is set.
            //this have been reverted back to the lead tigger.
            //opportunityUtility.setNotifyOwner(trigger.new);
        }   
        if(trigger.isUpdate){         
             Opportunity[] oppList = new Opportunity[]{};
             Opportunity[] oldOppList = new Opportunity[]{};
             Set<Id> prjIds = new Set<Id>();    
             for(Opportunity o: trigger.new){
                if(!utility.oppBeforeAlreadyProcessed(o.Id)){
                    oppList.add(o);
                    oldOppList.add(trigger.oldMap.get(o.Id));
                }
                if(trigger.oldMap.get(o.Id).Project__c != o.Project__c){
                    prjIds.add(o.Project__c);
                }
             }
             if(!oppList.isEmpty()){
                //first update the project names
                opportunityUtility.updateOppProject(oppList, oldOppList);
                //then update the campaign association.
                opportunityCampaignUtility.associateCampaign(oppList, oldOppList);
             }
             //SalesFix : if the project lookup field changes, update the project picklist field as well
             //SalesFix : if the opportunity is either Closed or Won, check the primary project enquiry status and raise error if needed
             Map<Id,Opportunity> oppWithPEs = new Map<Id,Opportunity>([Select Id, (Select Id,Status__c from Project_Enquiries__r where Primary__c = true) from Opportunity where id in : trigger.new]);                    
             Map<Id,Project__c> prjNames = new Map<Id,Project__c>([Select Name from Project__c where Id in: prjIds]);
             for(Opportunity o : trigger.new){
                if(prjNames.containsKey(o.Project__c))
                    o.Project_Picklist__c = prjNames.get(o.Project__c).Name;
                if(oppWithPEs.containsKey(o.Id) && oppWithPEs.get(o.Id).Project_Enquiries__r.size() > 0){    
                    if(o.isWon && !trigger.oldMap.get(o.Id).isWon){
                        for(Project_Enquiry__c pe : oppWithPEs.get(o.Id).Project_Enquiries__r){
                            if(pe.Status__c == 'Disqualified' || pe.Status__c == 'Submit for Disqualification'){
                                system.debug('There is a error? ');
                                o.StageName.addError('The status of the Primary Project Enquiry for this sale must not be Disqualified before you can set the Opportunity to this Closed Won Stage');
                            }        
                        }
                    }   
                    else if(o.isClosed && !trigger.oldMap.get(o.Id).isClosed) {
                        for(Project_Enquiry__c pe : oppWithPEs.get(o.Id).Project_Enquiries__r){
                            if(pe.Status__c == 'Qualifying' || pe.Status__c == 'Interested'){
                                system.debug('There is a error? ');
                                o.StageName.addError('The status of the Primary Project Enquiry for this sale must be Disqualified before you can set the Opportunity to this Closed Lost Stage');
                            }        
                        }
                    }
                }
             }
        }
        //CJ Edit
        //code to maintain the Salesperson on the opportunity.
        if (!Trigger.isDelete) {
            for(Opportunity o: trigger.new){
                if(!o.isWon){
                    //only run code if the opportunity isn't closed
                    if(trigger.isInsert){
                        //it's an insert, so set the saleperson as the running user or owner id
                        if(o.OwnerId != null){
                            //owner id was specified on insert, so use that.
                            o.Salesperson__c = o.OwnerId;
                        }
                        else{
                            //no owner id, so use the running user.
                            o.Salesperson__c = userinfo.getUserId();
                        }
                    }
                    else if(trigger.isUpdate && o.OwnerId != o.Salesperson__c){
                        //it's an update, and the opportunity owner doesn't match the salesperson.
                        o.Salesperson__c = o.OwnerId;
                    }
                }
            }
        }
    }
    //CJ Additions
    //Extended trigger functionality to manage the Stage changes
    //so they update the Item record Status
    if(trigger.isAfter){
        //Create a map between the Record Type Name and Id for easy retrieval
        Map<String,String> productRecordTypes;
        map<id,id> mapOpportunityCampaign = new map<id, id>();
        map<id, id> mapOpportunityPersonAccount = new map<id, id>();
            
        If(trigger.isUpdate){
            //Declare Variables
            //String[] oIds = new String[]{};
            Set<String> oIds = new Set<String>();
            Item__c[] iList = new Item__c[]{};
            Map<Id, Opportunity> pMap = new Map<Id, Opportunity>();
            Product__c[] pList = new Product__c[]{};
            Product__c[] pUpdate = new Product__c[]{};
            //Loop through the Opportunities and add IDs to a list
            For(Opportunity o: trigger.New){
                //we're only interested in opportunities that have changed stage and haven't already been processed.
                if(o.StageName != trigger.oldMap.get(o.Id).StageName && !utility.oppAfterUpdateAlreadyProcessed(o.Id)){
                    //has changed, add to list
                    oids.add(o.Id);
                }
            }

            //HR - 18/04/2016 - IT-Request: 00001455
            For(Opportunity o: trigger.New){
                if(o.Ledger_Balance_Correct__c == o.Full_Deposit_Required__c && o.Current_Stage__c =='Contract + Full Deposit')
                    oids.add(o.Id);
            }

            if(!oids.isEmpty()){
                //try and load the record types
                if(productRecordTypes == null){
                    productRecordTypes = OpportunityUtility.getProductRecordTypes();
                }
                //Loop through the Opportunities in oList and amend the Status of the Item records (if they are not 'Cancelled')
                For(Opportunity o: [SELECT Id, Name, Amount, StageName, Net_Price__c, Full_Deposit_Received_Date__c, (SELECT Id, Name, Product__c, Product__r.RecordTypeId, Status__c FROM Items__r) FROM Opportunity WHERE Id in: oIds]){
                    //Check to see if the StageName has changed
                    If(trigger.newMap.get(o.Id).StageName != trigger.oldMap.get(o.Id).StageName){
                        //Loop through the associated Item records
                        For(Item__c i: o.Items__r){
                           //Check to see if the Item is not 'Cancelled'
                           If(i.Status__c != 'Cancelled'){
                               //Change the Status to equal the StageName of the parent Opportunity
                               i.Status__c = o.StageName;
                               //Add the Item record to the iList to be updated
                               iList.add(i);
                                //If the StageName is being changed to Contract + Full Deposit, set the Actual Sale Price of the Primary Product record
                               If(trigger.newMap.get(o.Id).StageName == 'Contract + Full Deposit' && trigger.oldMap.get(o.Id).StageName != 'Contract + Full Deposit' && (i.Product__r.RecordTypeId == productRecordTypes.get('Apartment') || i.Product__r.RecordTypeId == productRecordTypes.get('Land') || i.Product__r.RecordTypeId == productRecordTypes.get('Urban Village') || i.Product__r.RecordTypeId == productRecordTypes.get('Townhouse'))){
                                   //Add the Product ID to a map for for referencing later
                                   pMap.put(i.Product__c, o);
                               }
                           }
                        }
                    }
                }
                if(!pMap.isEmpty()){
                    //Loop through the pList and update the pUpdate list
                    For(Product__c p: [SELECT Id, Name, Actual_Sale_Price__c, Sale_Date__c FROM Product__c WHERE Id in: pMap.keyset()]){
                        p.Actual_Sale_Price__c = pMap.get(p.Id).Net_Price__c;
                        p.Opportunity__c = pMap.get(p.Id).Id;
                        p.Sale_Date__c = pMap.get(p.Id).Full_Deposit_Received_Date__c;
                        pUpdate.add(p);
                    }
                }
                try{
                    Database.Saveresult[] iListResults = database.update(iList, false);
                    update pUpdate;
                    integer i = 0;
                    for(Database.SaveResult db: iListResults){
                        if(!db.isSuccess()){
                            //add the error message to the parent opportunity
                            for(Database.Error de: db.getErrors()){
                                trigger.newMap.get(iList[i].Opportunity__c).addError(de.getMessage());
                            }
                        }
                        i++;
                    }
                }
                catch(exception e){
                    system.debug('There were some errors during save, everything is rolled back. '+e);
                }
            }
            //SalesFix : everytime the project lookup field on the opportunity changes, sync the fields to project assignment record        
            try{
                if(OpportunityUtility.CanCreatePE){
                    system.debug('salesfix:');
                    Id apartmentRecordTypeId = [Select Id from RecordType where SobjectType = 'Opportunity' and DeveloperName = 'Apartments' Limit 1].Id;
                    List<Project_Enquiry__c> paList = new List<Project_Enquiry__c>();
                    system.debug('Reached this point..'); 
                                        
                    Map<Id,Opportunity> oppWithPEs = new Map<Id,Opportunity>([Select Id, (Select Id,Primary__c,Project__c from Project_Enquiries__r) from Opportunity where id in : trigger.new]);
                    
                    for(Opportunity opp : trigger.new){
                        system.debug('Ok the if condition ' + String.isNotEmpty(opp.Project__c) + 's channel' + opp.Sales_Channel__c != 'Channel'); 

                        if(String.isNotEmpty(opp.Project__c) &&  opp.RecordTypeId == apartmentRecordTypeId &&  
                           opp.Business_Unit__c == 'Apartments' && opp.Sales_Channel__c != 'Channel'){
                               Id peId;
                               if(oppWithPEs.get(opp.Id).Project_Enquiries__r != null && oppWithPEs.get(opp.Id).Project_Enquiries__r.size() > 0){
                                   for(Project_Enquiry__c pe : oppWithPEs.get(opp.Id).Project_Enquiries__r){
                                       if(pe.Project__c == opp.Project__c && pe.Primary__c){
                                           peId = pe.Id; 
                                           break;   
                                       }
                                   }
                               }
                               system.debug('debuginfo ' + peId);
                               if(peId != null){
                                   Project_Enquiry__c pa = OpportunityUtility.createProjectAssignment(opp,peId);
                                   paList.add(pa);
                               }
                           }                        
                    }
                    
                    if(paList.size() > 0) update paList;
                    
                }
            }catch(Exception ex){
                ApexError.AddException(ex);
                system.debug('error in opportunity after update : ' + ex);
            }
      }
        /*
        Version 2.2 Code
        Update the Reservation Date of the Primary Product Item record
        Create an Event for the Contract Signing Appointment
        */
        //Declare Variables
        String[] oiIds = new String[]{}; //List of Opportunity IDs where the Stage is being set to Reserved
        String[] oeuIds = new String[]{}; //List of Opportunity IDs where there is a Contract Signing Date that is being entered for the first time
        Item__c[] iUpdate = new Item__c[]{}; //List of Item records that will be updated
        Event[] eNew = new Event[]{}; //List of Event records that will be created
        Event[] eUpdate = new Event[]{}; //List of Event records that will be updated
        String startHours;
        String startMins;
        String endHours;
        String endMins;
        DateTime startDateTime;
        DateTime endDateTime;
        Time startTime;
        Time endTime;
        Integer durMins;
        Map<Id, Date> resMap = new Map<Id, Date>{};
        Map<Id, Date> conMap = new Map<Id, Date>{};
        Map<Id, DateTime> estartMap = new Map<Id, DateTime>{};
        Map<Id, DateTime> eendMap = new Map<Id, DateTime>{};
        //list to hold new Opportunity Contact Roles
        OpportunityContactRole[] newRoles = new OpportunityContactRole[]{};
        //list to hold Opportunity Contact Roles to be deleted
        OpportunityContactRole[] rolesToBeDeleted = new OpportunityContactRole[]{};
        //list to hold new Campaign Members to be added
        CampaignMember[] campaignMembers = new CampaignMember[]{};
        //Account Team Members to be added
        AccountTeamMember[] accountTeamMembers = new AccountTeamMember[]{};
        //Access rights for Account Team members
        AccountShare[] accountShares = new AccountShare[]{};
        //Marketo User from the User object
        list<User> marketoUser = new list<User>();
        boolean marketoUserSelected = false;
        
        //Loop through the Opportunities being processed to determine whether or not they need to be        //Also return any contact roles here
        for(Opportunity o: [select Id, StageName, Reservation_Date__c, Contract_Signing_Appointment_Date__c, 
                            Appointment_Start_Time__c, Appointment_End_Time__c, Marketo_Project__c, Project_Email_Opt_Out__c, Name, OwnerId, AccountId, 
                            Account.PersonContactId, Account.Name, Project__c, Project__r.Email_Opt_Out_Campaign__c, Auto_Convert__c, 
                            Referring_Builder_Contact__c, Channel_Contact__c, 
                            (select id, ContactId, isPrimary, Role from OpportunityContactRoles) 
                            from Opportunity 
                            where id in: trigger.new]){
            //check to make sure we haven't processed this already.
            if(!utility.oppAlreadyProcessed(o.Id)){
                //If the StageName is being updated to Reservation, add to the oiIds list
                if(o.StageName == 'Reservation' || o.StageName == 'Reservation Pending'){
                    oiIds.add(o.Id);
                    if((trigger.isInsert && o.Reservation_Date__c != null) || (trigger.isUpdate && o.Reservation_Date__c != null && trigger.oldMap.get(o.Id).Reservation_Date__c == null)){
                        resMap.put(o.Id, o.Reservation_Date__c);
                    }
                    if((trigger.isUpdate && o.Contract_Signing_Appointment_Date__c != null && trigger.oldMap.get(o.Id).Contract_Signing_Appointment_Date__c == null)||(trigger.isInsert && o.Contract_Signing_Appointment_Date__c != null)){
                        conMap.put(o.id, o.Contract_Signing_Appointment_Date__c);
                    }
                }
                if(o.Appointment_Start_Time__c != null && o.Appointment_End_Time__c != null && o.Contract_Signing_Appointment_Date__c != null){
                    //Work out the Start Time and Duration of the Event
                    startHours = o.Appointment_Start_Time__c.left(2);
                    startMins = o.Appointment_Start_Time__c.right(2);
                    endHours = o.Appointment_End_Time__c.left(2);
                    endMins = o.Appointment_End_Time__c.right(2);
                    startTime = Time.newInstance(integer.valueOf(startHours), integer.valueOf(startMins), 0, 0);
                    endTime = Time.newInstance(integer.valueOf(endHours), integer.valueOf(endMins), 0, 0);            
                    startDateTime = datetime.newInstance(o.Contract_Signing_Appointment_Date__c, startTime);
                    endDateTime = datetime.newInstance(o.Contract_Signing_Appointment_Date__c, endTime);
                    //only proceed if the times are valid.
                    if(startDateTime >= endDateTime){
                        //o.addError('The Start Time must be before the End Time');
                    }
                    else{
                         //If the Contract Signing Appointment Date is being entered for the first time, add to the oenIds list
                         if((o.StageName == 'Reservation' || o.StageName == 'Reservation Pending') && ((trigger.isUpdate && o.Contract_Signing_Appointment_Date__c != null && trigger.OldMap.get(o.Id).Contract_Signing_Appointment_Date__c == null)|| (trigger.isInsert && o.Contract_Signing_Appointment_Date__c != null))){
                            //Work out the Start Time and Duration of the Event
                            startHours = o.Appointment_Start_Time__c.left(2);
                            startMins = o.Appointment_Start_Time__c.right(2);
                            endHours = o.Appointment_End_Time__c.left(2);
                            endMins = o.Appointment_End_Time__c.right(2);
                            startTime = Time.newInstance(integer.valueOf(startHours), integer.valueOf(startMins), 0, 0);
                            endTime = Time.newInstance(integer.valueOf(endHours), integer.valueOf(endMins), 0, 0);            
                            startDateTime = datetime.newInstance(o.Contract_Signing_Appointment_Date__c, startTime);
                            endDateTime = datetime.newInstance(o.Contract_Signing_Appointment_Date__c, endTime);
                            //Create a new Event & Add to the list for inserting
                            Event e = new Event(Subject='Contract Signing Appointment: ' + o.Name, OwnerId=o.OwnerId, ActivityDate=o.Contract_Signing_Appointment_Date__c, IsReminderSet=TRUE, ReminderDateTime=startDateTime, StartDateTime = startDateTime, EndDateTime = endDateTime, WhatId=o.Id, WhoId = o.Account.PersonContactId, Contract_Signing_Appointment__c = TRUE);
                            eNew.add(e);
                        }
                        //If the Contract Signing Appointment Date is being changed, add to the oeuIds list
                        else if(trigger.isUpdate && o.Contract_Signing_Appointment_Date__c != null && trigger.OldMap.get(o.Id).Contract_Signing_Appointment_Date__c != null && ((trigger.OldMap.get(o.Id).Contract_Signing_Appointment_Date__c != o.Contract_Signing_Appointment_Date__c) || (trigger.OldMap.get(o.Id).Appointment_Start_Time__c != o.Appointment_Start_Time__c) || (trigger.OldMap.get(o.Id).Appointment_End_Time__c != o.Appointment_End_Time__c))){
                            //Work out the Start Time and Duration of the Event
                            startHours = o.Appointment_Start_Time__c.left(2);
                            startMins = o.Appointment_Start_Time__c.right(2);
                            endHours = o.Appointment_End_Time__c.left(2);
                            endMins = o.Appointment_End_Time__c.right(2);
                            startTime = Time.newInstance(integer.valueOf(startHours), integer.valueOf(startMins), 0, 0);
                            endTime = Time.newInstance(integer.valueOf(endHours), integer.valueOf(endMins), 0, 0);            
                            startDateTime = datetime.newInstance(o.Contract_Signing_Appointment_Date__c, startTime);
                            endDateTime = datetime.newInstance(o.Contract_Signing_Appointment_Date__c, endTime);
                            //If the old date is in the past, create a new Event
                            if(trigger.oldMap.get(o.Id).Contract_Signing_Appointment_Date__c != null && trigger.oldMap.get(o.Id).Contract_Signing_Appointment_Date__c < date.today()){
                                //Create a new Event & Add to the list for inserting
                                Event e = new Event(Subject='Contract Signing Appointment: ' + o.Name, OwnerId=o.OwnerId, ActivityDate=o.Contract_Signing_Appointment_Date__c, IsReminderSet=TRUE, ReminderDateTime=startDateTime, StartDateTime = startDateTime, EndDateTime = endDateTime, WhatId=o.Id, WhoId=o.Account.PersonContactId, Contract_Signing_Appointment__c = TRUE);
                                eNew.add(e);            
                            }
                            //If the old date is in the future, find the Event and update it
                            else if(trigger.oldMap.get(o.Id).Contract_Signing_Appointment_Date__c != null && trigger.oldMap.get(o.Id).Contract_Signing_Appointment_Date__c >= date.today()){
                                //Add the Opportunity ID to the oeuIds list  //Add the Id, StartDateTime and EndDateTime to a Map
                                oeuIds.add(o.Id);
                                estartMap.put(o.Id, startDateTime);
                                eendMap.put(o.Id, endDateTime);
                            }
                        }   
                    }
                }
                //now query opportunities and any contact roles.
                //for(Opportunity o: [select Id, Account.PersonContactId, 
                                   // (select Id, isPrimary, Role, ContactId from OpportunityContactRoles) 
                                   // from Opportunity where id = :o.id]){
                    //if it's a person account, then continue to try and update the primary contact role.
                if(o.Account.PersonContactId != null){
                     //Are there any contact roles? 
                    if(o.OpportunityContactRoles.isEmpty()){
                        //there are no contact roles, so create one for the person contact id
                        OpportunityContactRole newRole = new OpportunityContactRole();
                        newRole.IsPrimary = true;
                        newRole.ContactId = o.Account.PersonContactId;
                        newRole.OpportunityId = o.Id;
                        //the new role should be Customer
                        newRole.Role = 'Customer';
                        //add the new role to a list for insert.
                        newRoles.add(newRole);
                    }
                    else{
                        //there are some contact roles, check to see if any of them are the person contact.
                        boolean isContactRole = false;
                        for(OpportunityContactRole ocr: o.OpportunityContactRoles){
                            if(ocr.ContactId == o.Account.PersonContactId){
                                //there is a contact role, are they primary?
                                isContactRole = true;
                                if(!ocr.isPrimary){
                                    //not primary, change to primary and add them to the list for upsert.
                                    ocr.isPrimary = true;
                                    ocr.Role = 'Customer';
                                    newRoles.add(ocr);
                                }
                                //don't need to loop anymore, found what we were looking for
                                break;
                            }
                        }
                        //if isContact role still is false, then generate a new contact role for the person contact id and make it primary.
                        if(!isContactRole){
                            OpportunityContactRole newRole = new OpportunityContactRole();
                            newRole.IsPrimary = true;
                            newRole.ContactId = o.Account.PersonContactId;
                            newRole.OpportunityId = o.Id;
                            //the new role should be Customer
                            newRole.Role = 'Customer';
                            //add the new role to a list for insert.
                            newRoles.add(newRole);
                        }
                    }
                }
               // }
                
                boolean hasReferringRoleChanged = false;
                if(o.Referring_Builder_Contact__c != null && o.Referring_Builder_Contact__c != o.Account.PersonContactId)
                {
                    OpportunityContactRole newRole = new OpportunityContactRole();
                    newRole.ContactId = o.Referring_Builder_Contact__c;
                    newRole.OpportunityId = o.Id;
                    //add a Referring Builder role
                    newRole.Role = 'Referring Builder';
                    if(trigger.isInsert ||( trigger.isUpdate && trigger.oldMap.get(o.id).Referring_Builder_Contact__c != o.Referring_Builder_Contact__c))
                    {
                        //add the new role to a list for insert.
                        newRoles.add(newRole);
                        hasReferringRoleChanged = true;
                    }
                }
                else
                {
                    hasReferringRoleChanged = true;
                }
                
                boolean hasChannelRoleChanged = false;
                if(o.Channel_Contact__c != null && o.Channel_Contact__c != o.Account.PersonContactId)
                {
                    OpportunityContactRole newRole = new OpportunityContactRole();
                    newRole.ContactId = o.Channel_Contact__c;
                    newRole.OpportunityId = o.Id;
                    //add a Referring Channel role
                    newRole.Role = 'Referring Channel';
                    if(trigger.isInsert || (trigger.isUpdate && trigger.oldMap.get(o.id).Channel_Contact__c != o.Channel_Contact__c))
                    {
                        system.debug('Adding Channel Contact');
                        //add the new role to a list for insert.
                        newRoles.add(newRole);
                        hasChannelRoleChanged = true;
                    }
                }
                else
                {
                    hasChannelRoleChanged = true;
                }
                
                for(OpportunityContactRole ocr : o.OpportunityContactRoles)
                {
                    if(hasReferringRoleChanged && ocr.Role == 'Referring Builder')
                    {
                        system.debug('Referring builder role added to the delete list');
                        rolesToBeDeleted.add(ocr);
                    }
                    if(hasChannelRoleChanged && ocr.Role == 'Referring Channel')
                    {
                        system.debug('Referring channel role added to the delete list');
                        rolesToBeDeleted.add(ocr);
                    }
                }
            
                //Create maps of Campaigns and Person Accounts linked to Opportunities via Projects and Accounts respectively
                if(o.Project_Email_Opt_Out__c == true && o.Account.PersonContactId != null && o.Project__r.Email_Opt_Out_Campaign__c != null)
                {
                    mapOpportunityCampaign.put(o.id, o.Project__r.Email_Opt_Out_Campaign__c);
                    mapOpportunityPersonAccount.put(o.id, o.Account.PersonContactId);
                }
                
                if(o.Marketo_Project__c == true)
                {
                    if(!marketoUserSelected)
                    {
                        if(marketoUser.isEmpty()){
                            marketoUser = new list<User>([SELECT ID FROM USER WHERE USERNAME = 'marketo@oliverhume.com.au' or USERNAME = 'test-marketo@oliverhume.com.au' order by USERNAME]);
                            marketoUserSelected = true;
                        }
                    }
                    if(marketoUser.size() > 0)
                    {
                        AccountTeamMember accountTM = new AccountTeamMember();
                        accountTM.AccountId = o.AccountId;
                        accountTM.TeamMemberRole = 'Marketo';
                        accountTM.UserId = marketoUser[0].id;
                        accountTeamMembers.add(accountTM);
                        
                        AccountShare objAccountShare = new AccountShare();
                        objAccountShare.AccountAccessLevel = 'Edit';
                        objAccountShare.OpportunityAccessLevel = 'Edit';
                        objAccountShare.AccountId = o.AccountId;
                        objAccountShare.UserOrGroupId = marketoUser[0].id;
                        if(objAccountShare.UserOrGroupId != o.OwnerId)
                        {
                            accountShares.add(objAccountShare);
                        }
                    }
                }
                /*
                if(trigger.isInsert)
                {
                    if(o.Referring_Builder_Contact__c != null && o.Referring_Builder_Contact__c != o.Account.PersonContactId)
                    {
                        OpportunityContactRole newRole = new OpportunityContactRole();
                        newRole.ContactId = o.Referring_Builder_Contact__c;
                        newRole.OpportunityId = o.Id;
                        //add a Referring Builder role
                        newRole.Role = 'Referring Builder';
                        newRoles.add(newRole);
                    }
                    
                    if(o.Channel_Contact__c != null && o.Channel_Contact__c != o.Account.PersonContactId)
                    {
                        OpportunityContactRole newRole = new OpportunityContactRole();
                        newRole.ContactId = o.Channel_Contact__c;
                        newRole.OpportunityId = o.Id;
                        //add a Referring Channel role
                        newRole.Role = 'Referring Channel';
                        newRoles.add(newRole);
                    }
                }
                */
            }
        }
        
        if(mapOpportunityCampaign.size() > 0)
        {
            //Get a list of campaign members already present for same campaign and contact
            list<CampaignMember> listCampaignMembers = new list<CampaignMember>([
                SELECT Id, CampaignId, ContactId
                FROM CampaignMember
                WHERE CampaignId IN : mapOpportunityCampaign.values()
                    AND ContactId IN : mapOpportunityPersonAccount.values()]);
            
            boolean isPresent = false;
            for(id opportunityId : mapOpportunityCampaign.keySet())
            {
                isPresent = false;
                for(CampaignMember objCampaignMember : listCampaignMembers)
                {
                    if(objCampaignMember.CampaignId == mapOpportunityCampaign.get(opportunityId) && objCampaignMember.ContactId == mapOpportunityPersonAccount.get(opportunityId))
                    {
                        isPresent = true;
                    }
                }
                
                //Where the Opportunity Field ‘Project Email Opt-Out’ is marked as TRUE, add the related
                //Person Account as a Campaign Member with Member Status = ‘Unsubscribed’ to the 
                //campaign referenced on the Opportunity related Project field ‘Email Opt-Out Campaign’
                if(!isPresent)
                {
                    CampaignMember objCampaignMember = new CampaignMember();
                    objCampaignMember.CampaignId = mapOpportunityCampaign.get(opportunityId);
                    objCampaignMember.ContactId = mapOpportunityPersonAccount.get(opportunityId);
                    objCampaignMember.Status = 'Unsubscribed';
                    campaignMembers.add(objCampaignMember);
                }
            }
        }
        
        if(!oiIds.isEmpty()){
            //try and load the record types
            if(productRecordTypes == null){
                productRecordTypes = OpportunityUtility.getProductRecordTypes();
            }
            //Pull out all Items that need updating
            //HR - Fix by adding the missing field Contract_Signing_Appointment_Date__c in the query 
            Item__c[] iList = [SELECT Id, Opportunity__c, Reservation_Date__c, Product__c, Product__r.RecordTypeId, Status__c, Contract_Signing_Appointment_Date__c FROM Item__c WHERE Opportunity__c in: oiIds AND Status__c != 'Cancelled'];
            //Process the list of Items in iList
            for(Item__c i: iList){
                //Check the Record Type of the Product to make sure it's a Primary Product
                if(i.Product__r.RecordTypeId == productRecordTypes.get('Apartment') || i.Product__r.RecordTypeId == productRecordTypes.get('Land') || i.Product__r.RecordTypeId == productRecordTypes.get('Urban Village') || i.Product__r.RecordTypeId == productRecordTypes.get('Townhouse')){
                    //Update the Reservation Date
                    boolean isChanged = false;
                    if(resMap.get(i.Opportunity__c) != null && resMap.get(i.Opportunity__c) != i.Reservation_Date__c){
                        i.Reservation_Date__c = resMap.get(i.Opportunity__c);
                        //the record has changed.
                        ischanged = true;
                    }
                    if(conMap.get(i.Opportunity__c) != null && conMap.get(i.Opportunity__c) != i.Contract_Signing_Appointment_Date__c){
                        i.Contract_Signing_Appointment_Date__c = conMap.get(i.Opportunity__c);
                        system.debug('Update Contract Signing Apt Date');
                        //the record has changed
                        ischanged = true;
                    }
                    //Add to the list for updating, only if we have a change on the record
                    if(isChanged){
                        iUpdate.add(i);
                    }
                }
            }
        }
        
        if(!oeuIds.isEmpty()){
            //Pull out all Events that need updating
            Event[] eList = [SELECT Id, Subject, ActivityDate, ReminderDateTime, StartDateTime, EndDateTime, WhatId, WhoId, Contract_Signing_Appointment__c FROM Event WHERE WhatId in: oeuIds AND Contract_Signing_Appointment__c = TRUE];
            //Process the list of Events in eList
            for(Event e: eList){
                //Update the Event fields with the relevant record in the map created earlier / Add the Event to the list for updating
                e.ReminderDateTime = estartMap.get(e.WhatId);
                e.StartDateTime = estartMap.get(e.WhatId);
                e.EndDateTime = eendMap.get(e.WhatId);
                eUpdate.add(e);
            }
        }
        
        System.debug('### rolesToBeDeleted: ' + rolesToBeDeleted);
        //Update Item records
        delete rolesToBeDeleted;
        update iUpdate;
        insert eNew;
        update eUpdate;
        //insert Opportunity Contact Roles
        upsert newRoles;
        insert campaignMembers;
        insert accountTeamMembers;
        insert accountShares;
    }

    // Commission generation and other checks - Lacey 29/05/14
    if(trigger.isAfter && trigger.isUpdate)
    {
        List<Id> commissionRequired = new List<Id>();
        List<Id> conditionCheckRequired = new List<Id>();
        List<Product__c> productsToUpdate = new List<Product__c>();
        Map<Id, Integer> productToTerms = new Map<Id, Integer>();
        Map<Id, Date> productToExpectedSettlementDate = new Map<Id, Date>(); // Richard Clarke 2015-11-19 push expected settlement date to primary product on closed-won or change

        // Work out which opportunities need processing
        for(Opportunity o : trigger.new)
        {
            //check to make sure we haven't already processed this record.
            if(!utility.commOppAlreadyProcessed(o.Id))
            {
                if(o.Registered_File__c && !trigger.oldMap.Get(o.Id).Registered_File__c)
                {
                    commissionRequired.add(o.Id);
                }
    
                if(o.StageName == 'Unconditional Contract' && trigger.oldMap.get(o.Id).StageName != 'Unconditional Contract')
                {
                    conditionCheckRequired.add(o.Id);
                }
                //changed to fire if either field is changed.  (isWon must be changed from false to true)
                if(o.IsWon && (!trigger.oldMap.get(o.Id).isWon || o.Settlement_Terms_Days__c != trigger.oldMap.get(o.Id).Settlement_Terms_Days__c))
                {
                    productToTerms.put(o.Primary_Product__c, (Integer)o.Settlement_Terms_Days__c);
                }
                // Richard Clarke 2015-11-19 push expected settlement date to primary product on closed-won or change
                if(o.IsWon && (!trigger.oldMap.get(o.Id).isWon || o.Expected_Settlement_Date__c != trigger.oldMap.get(o.Id).Expected_Settlement_Date__c))
                {
                    productToExpectedSettlementDate.put(o.Primary_Product__c, (Date)o.Expected_Settlement_Date__c);
                }
            }
        }

        // Do commission
        /*
        try
        {
            //limit the async request by checking that commissionRequired has values
            if(!commissionRequired.isEmpty())
            {
                commissionGeneration.debugOutput = true;
                commissionGeneration.GenerateCommissionForOpportunities(commissionRequired);
            }
            
        }
        catch (Exception e)
        {
            System.debug('There was an exception generating commission for the opportunities modified: ' + e.getMessage());
        }
        */

        // Condition checking for 'Unconditional Contract' oppties
        //save a query and check that there are values in conditionCheckRequired
        if(!conditionCheckRequired.isEmpty())
        {
            for(Variation_Condition__c vc : [select Id, Opportunity__c from Variation_Condition__c
                                                where (Status__c = 'Open' or Status__c = 'Overdue') and Type__c = 'Condition' and Opportunity__c in : conditionCheckRequired])
            {
                trigger.newMap.get(vc.Opportunity__c).addError('This Opportunity cannot be set to Unconditional Contract as there are open or overdue Conditions.');
            }
        }

        // Settlement term updates for primary products
        //check to make sure productToTerms contains values to save a query
        if(!productToTerms.isEmpty() || !productToExpectedSettlementDate.isEmpty())
        {
            // Richard Clarke 2015-11-19 push expected settlement date to primary product on closed-won or change
            for(Product__c p : [select Id, Settlement_Terms_Days__c, Expected_Settlement_Date__c from Product__c where Id in : productToTerms.keyset() or Id in : productToExpectedSettlementDate.keyset()])
            {
                if ( productToTerms.containsKey(p.Id)) {
                    p.Settlement_Terms_Days__c = productToTerms.get(p.Id);
                }
                if ( productToExpectedSettlementDate.containsKey(p.Id)) {
                    p.Expected_Settlement_Date__c = productToExpectedSettlementDate.get(p.Id);
                }
                productsToUpdate.add(p);
            }
    
            update productsToUpdate;
        }
    }
}