trigger EmailOptOutContactTrigger on Contact (after insert,after update) {

    	try{
		List<Campaign> masterCamp = [Select Id From Campaign Where Name = 'Oliver Hume Master - Email Opt Out'];        
		if(!masterCamp.isEmpty()){
			//get the list of contacts for which the email opt out field changed
			Set<Id> emailOptOutContacts = new Set<Id>();
			Set<Id> emailOptInContacts = new Set<Id>();
			for(Contact con : trigger.new){
				//if(!acc.IsPersonAccount) continue;
                if (con.IsPersonAccount) continue;

				if((trigger.isInsert && con.HasOptedOutOfEmail) || 
					(trigger.isUpdate && con.HasOptedOutOfEmail && !trigger.oldMap.get(con.Id).HasOptedOutOfEmail)) {
					emailOptOutContacts.add(con.Id);					
				}else if(trigger.isUpdate && !con.HasOptedOutOfEmail && trigger.oldMap.get(con.Id).HasOptedOutOfEmail)
					emailOptInContacts.add(con.Id);
			}
			//if the contacts are opted out, add them to the master email unsubscribe campaign if they don't exist already
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