trigger accountTrigger on Account (after update) {

	
	//Vars
	Id[] accIds = new Id[]{};
	Account[] accList = new Account[]{};
	Opportunity[] oppList = new Opportunity[]{};
	Map<Id, Id> oldAccMap = new Map<Id, Id>();
	AccountShare[] updatedShares = new AccountShare[]{};
	
	//used to maintain the account share
	//build a list of accounts where the owner has changed.
	for(Account a: trigger.new){
		if(a.OwnerId != trigger.oldMap.get(a.Id).ownerId && !utility.accAlreadyProcessed(a.Id)){
			//the owners have changed, so add the new record to a list
			system.debug('Account Owners Have Changed!');
			accIds.add(a.Id);
		}
	} 
	
	//Return any opportunites associated with these accounts
	if(!accIds.isEmpty()){
		accList = [select id, OwnerId, (select Id, OwnerId from Opportunities) from Account where id in: accIds];
	}
	
	//Loop through the accList, check to see if the old acc owner still owns an opportunity, if they do, we are going to update there share.	
	for(Account a: AccList){
		Id oldUserId = trigger.oldMap.get(a.Id).OwnerId;
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