//SalesFix : When a Contact/PersonAccount has opted out/In of email, 
//add or remove them to the global email usubscribe campaign
trigger EmailOptOutTrigger on Account (after insert,after update) {

	try{
		
        //get the list of accounts for which the email opt out field changed
        Set<Id> emailOptOutContacts = new Set<Id>();
        Set<Id> emailOptInContacts = new Set<Id>();
        for(Account acc : trigger.new){
            if(!acc.IsPersonAccount) continue;
            
            if((trigger.isInsert && acc.PersonHasOptedOutOfEmail) || 
               (trigger.isUpdate && acc.PersonHasOptedOutOfEmail && !trigger.oldMap.get(acc.Id).PersonHasOptedOutOfEmail)) {
                   emailOptOutContacts.add(acc.PersonContactId);					
               }else if(trigger.isUpdate && !acc.PersonHasOptedOutOfEmail && trigger.oldMap.get(acc.Id).PersonHasOptedOutOfEmail)
                   emailOptInContacts.add(acc.PersonContactId);
        }
        if(!emailOptOutContacts.isEmpty() ||  !emailOptInContacts.isEmpty()){
            List<Campaign> masterCamp = [Select Id From Campaign Where Name = 'Oliver Hume Master - Email Opt Out'];        
            //if the accounts are opted out, add them to the master email unsubscribe campaign if they don't exist already
            if(!emailOptOutContacts.isEmpty()){	
                List<CampaignMember> existingContactMembers = [Select Id,ContactId From CampaignMember Where ContactId in:emailOptOutContacts and CampaignId = :masterCamp[0].Id];
                Map<Id,CampaignMember> existingContactMemberMap = new Map<Id,CampaignMember>();
                for(CampaignMember cm : existingContactMembers){
                    existingContactMemberMap.put(cm.ContactId,cm);
                }
                List<CampaignMember> cmList = new List<CampaignMember>();
                for(Id cId : emailOptOutContacts){
                    CampaignMember cm;
                    if(existingContactMemberMap.containsKey(cId)){
                        cm = existingContactMemberMap.get(cId);
                    }else{
                        cm = new CampaignMember();
                        cm.CampaignId = masterCamp[0].Id;
                        cm.ContactId = cId;                    
                    }
                    cm.Status = 'Unsubscribed';
                    cmList.add(cm);                        
                }            
                if(cmList.size() > 0) upsert cmList;
            }
            //if the contacts are opting back in for email, remove them from the campaign
            if(!emailOptInContacts.isEmpty()){
                List<CampaignMember> cmList = [Select Id from CampaignMember 
                                               Where ContactId in :emailOptInContacts and CampaignId=:masterCamp[0].Id ];
                if(cmList.size() > 0) delete cmList;
            }	
        }
	}catch(Exception ex){
		system.debug('error in contact trigger : ' + ex);
	}
	
}