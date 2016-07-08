trigger oppAccountTeamTrigger on Opportunity (before insert, before update, after update) {
    /* Generic Code for Both Before & After Trigger Contexts */
     Map<Id, Map<Id, Id>> userMap = new Map<Id, Map<Id, Id>>();
    Map<Id, Map<Id, AccountShare>> shareMap = new Map<Id, Map<Id, AccountShare>>();
    //Sales Team Map
    Map<Id, Map<Id, AccountTeamMember>> teamShareMap = new Map<Id, Map<Id, AccountTeamMember>>();
    Set<Id> accountIds = new Set<Id>();
    Set<AccountShare> newShares = new Set<AccountShare>();
    Set<AccountShare> deleteShares = new Set<AccountShare>();
    //Sales Team Lists
    Set<AccountTeamMember> newMembers = new Set<AccountTeamMember>();
    Set<AccountTeamMember> deleteMembers = new Set<AccountTeamMember>();
    //Map of Users and the Accounts they should have access to as opportunity owners.
    for(Opportunity o: trigger.new){
        if(utility.oppAccAlreadyProcessed(o.Id)){
            accountIds.add(o.AccountId);
        }
    }
    if(!accountIds.isEmpty()){
        //the user map is a map of all current users that have opportunities for accounts relative to the trigger.
        //for(Opportunity o: [select id, AccountId, OwnerId from Opportunity where AccountId in: accountIds]){}
        for(Opportunity o: trigger.new){
            if(accountIds.contains(o.AccountId)){
                if(userMap.get(o.AccountId) == null){
                    //doesn't exist, so create it
                    userMap.put(o.AccountId, new Map<id, id>());
                }
                //at this point an entry exists in the map for this account, so add the user
                userMap.get(o.AccountId).put(o.OwnerId, o.OwnerId);
            }
        }
         //return the account share records, organise them the same way.
    
        for(AccountShare a: [Select UserOrGroupId, RowCause, AccountAccessLevel, OpportunityAccessLevel, Id, ContactAccessLevel, CaseAccessLevel, AccountId From AccountShare where AccountId in: accountIds]){
            if(shareMap.get(a.AccountId) == null){
                //doesn't exist so create it
                shareMap.put(a.AccountId, new Map<Id, AccountShare>()); 
            }
            //at this point the account exists in the map, so just add the sharing record relevant to the user
            shareMap.get(a.AccountId).put(a.UserOrGroupId, a);
        }
    
         //share map constructed. create the teamShareMap
    
        for(AccountTeamMember a: [select id, AccountAccessLevel, TeamMemberRole, UserId, AccountId from AccountTeamMember where AccountId in: accountIds]){
            if(teamShareMap.get(a.AccountId) == null){
                //doesn't exist so create it
                teamShareMap.put(a.AccountId, new Map<Id, AccountTeamMember>());    
            }
            //at this point the account exists in the map, so just add the sharing record relevant to the user
            teamShareMap.get(a.AccountId).put(a.UserId, a);
        }
    }
    /* End Generic Code  */
    
    if(trigger.isBefore){
        //loop through the opportunities, check to see if there is a sharing rule for that account/user
        for(Opportunity o: trigger.new){
            if(trigger.isInsert ||(trigger.isUpdate && o.OwnerId != trigger.oldMap.get(o.Id).OwnerId)){
                //is a new opportunity or the owner has changed.
                if(teamShareMap.get(o.AccountId) != null){
                    //sharing rules detected for this account...
                    if(teamShareMap.get(o.AccountId).get(o.OwnerId) != null){
                        //there was a matching user already shared on this record... check that they have read/write on the account.
                        if(teamShareMap.get(o.AccountId).get(o.OwnerId).AccountAccessLevel != 'Edit' && teamShareMap.get(o.AccountId).get(o.OwnerId).AccountAccessLevel != 'All'){
                            AccountTeamMember editShare = teamShareMap.get(o.AccountId).get(o.OwnerId);
                            //editShare.AccountAccessLevel = 'Edit';
                            editShare.TeamMemberRole = 'Opportunity Owner';
                            newMembers.add(editShare);
                        }   
                    }
                    else{
                        //there should be a sharing rule, so create one and add it to a list for insert
                        AccountTeamMember newMember = new AccountTeamMember(AccountId = o.AccountId, UserId = o.OwnerId, TeamMemberRole = 'Opportunity Owner');
                        newMembers.add(newMember);
                        system.debug('New Member Added with Edit Access');
                    }
                }
                else{
                    //no sharing rules detected, so add one for the user
                    //there should be a sharing rule, so create one and add it to a list for insert
                    AccountTeamMember newMember = new AccountTeamMember(AccountId = o.AccountId, UserId = o.OwnerId, TeamMemberRole = 'Opportunity Owner');
                    newMembers.add(newMember);
                    system.debug('New Share Member Added with Edit Access');
                }
            }
            /*
            if(trigger.isUpdate && o.OwnerId != trigger.oldMap.get(o.Id).OwnerId){
                //specifically if is is an update, check to see if the old user should still have access to the account record
                if(userMap.get(o.AccountId) != null && userMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) == null){
                    //check to see if thre is a pre-existing sharing record
                    if(teamShareMap.get(o.AccountId) != null && teamShareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) != null){
                        //there is an existing sharing rule
                        //is it automatically created?
                        if(teamShareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId).TeamMemberRole == 'Opportunity Owner'){
                            //is is a manually shared record, so add it to a list for deletion
                            deleteMembers.add(teamShareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId));
                        }
                    }
                }
            }
            */
        }
        
        //loop through the opportunities, check to see if there is a sharing rule for that account/user
        for(Opportunity o: trigger.new){
            if(trigger.isInsert ||(trigger.isUpdate && o.OwnerId != trigger.oldMap.get(o.Id).OwnerId)){
                //is a new opportunity or the owner has changed.
                if(shareMap.get(o.AccountId) != null){
                    //sharing rules detected for this account...
                    if(shareMap.get(o.AccountId).get(o.OwnerId) != null){
                        //there was a matching user already shared on this record... check that they have read/write on the account.
                        if(shareMap.get(o.AccountId).get(o.OwnerId).AccountAccessLevel != 'All' && shareMap.get(o.AccountId).get(o.OwnerId).AccountAccessLevel != 'Edit'){
                            AccountShare editShare = shareMap.get(o.AccountId).get(o.OwnerId);
                            editShare.AccountAccessLevel = 'Edit';
                            newShares.add(editShare);
                        }   
                    }
                    else{
                        //there should be a sharing rule, so create one and add it to a list for insert
                        AccountShare newShare = new AccountShare(AccountId = o.AccountId, UserOrGroupId = o.OwnerId, OpportunityAccessLevel = 'None', AccountAccessLevel = 'Edit', CaseAccessLevel = 'None');
                        newShares.add(newShare);
                        system.debug('New Share Added with Edit Access');
                    }
                }
                else{
                    //no sharing rules detected, so add one for the user
                    //there should be a sharing rule, so create one and add it to a list for insert
                    AccountShare newShare = new AccountShare(AccountId = o.AccountId, UserOrGroupId = o.OwnerId, OpportunityAccessLevel = 'None', AccountAccessLevel = 'Edit', CaseAccessLevel = 'None');
                    newShares.add(newShare);
                    system.debug('New Share Added with Edit Access');
                }
            }
            /*
            if(trigger.isUpdate && o.OwnerId != trigger.oldMap.get(o.Id).OwnerId){
                //specifically if is is an update, check to see if the old user should still have access to the account record
                if(userMap.get(o.AccountId) != null && userMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) == null){
                    //the user isn't in the userMap for that account, so remove their sharing record. (only if it was a manually shared record.)
                    //check to see if thre is a pre-existing sharing record
                    if(shareMap.get(o.AccountId) != null && shareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) != null){
                        //there is an existing sharing rule
                        //is it manually shared?
                        if(shareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId).RowCause == 'Manual'){
                            //is is a manually shared record, so add it to a list for deletion
                            deleteShares.add(shareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId));
                        }
                    }
                }
            }
            */
        }
        try{
            /*
            if(!newShares.isEmpty()){
                AccountShare[] newShareList = new AccountShare[]{};
                newShareList.addAll(newShares);
                upsert newShareList;
            }
            if(!newMembers.isEmpty()){
                //same for account team members
                AccountTeamMember[] newMemberList = new AccountTeamMember[]{};
                newMemberList.addAll(newMembers);
                upsert newMemberList;            
            }
            */
            //as a poc, JSON encode the data and send to the futue method.
            opportunityUtility.shareData shareData = new opportunityUtility.shareData();
            //lists will be init already.
            if(!newShares.isEmpty()){
                shareData.accountShares.addAll(newShares);
            }
            if(!newMembers.isEmpty()){
                //same for account team members
                shareData.accountMembers.addAll(newMembers);
            }
            //encode shareData.
            //Serialise the JSON here and convert to string.
            string shareJSON = JSON.serialize(shareData);
            //pass this to the future method.
            opportunityUtility.processBeforeOppShares(shareJSON);
        }
        catch(exception e){
            system.debug('there were problems updating the sharing... '+ e);
        }
        /* End Account Team Logic */
    }
    if(trigger.isAfter){
        for(Opportunity o: trigger.new){
            if(o.OwnerId != trigger.oldMap.get(o.Id).OwnerId){
                //specifically if is is an update, check to see if the old user should still have access to the account record
                if(userMap.get(o.AccountId) != null && userMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) == null){
                    //check to see if thre is a pre-existing sharing record
                    if(teamShareMap.get(o.AccountId) != null && teamShareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) != null){
                        //there is an existing sharing rule
                        //is it automatically created?
                        if(teamShareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId).TeamMemberRole == 'Opportunity Owner'){
                            //is is a manually shared record, so add it to a list for deletion
                            deleteMembers.add(teamShareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId));
                        }
                    }
                    if(shareMap.get(o.AccountId) != null && shareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId) != null){
                        //there is an existing sharing rule
                        //is it manually shared?
                        if(shareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId).RowCause == 'Manual'){
                            //is is a manually shared record, so add it to a list for deletion
                            deleteShares.add(shareMap.get(o.AccountId).get(trigger.oldMap.get(o.Id).OwnerId));
                        }
                    }
                }
            }
        }
        //Delete Records
        if(!deleteShares.isEmpty()){
            AccountShare[] deleteShareList = new AccountShare[]{};
            deleteShareList.addAll(deleteShares);
            delete deleteShareList;
        }
        if(!deleteMembers.isEmpty()){
            AccountTeamMember[] deleteMemberList = new AccountTeamMember[]{};
            deleteMemberList.addAll(deleteMembers);
            delete deleteMemberList;
        }
    }
}