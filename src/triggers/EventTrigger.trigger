trigger EventTrigger on Event (after insert,after update) {

	Set<Id> oppIds = new Set<Id>();

	for(Event ev : trigger.new){
		if(trigger.isInsert || (trigger.isUpdate && ev.StartDateTime != trigger.oldMap.get(ev.Id).StartDateTime)){
			if(ev.Type == 'Inside Sales Appointment' && String.valueOf(ev.WhatId).startsWith('006')){
				oppIds.add(ev.WhatId);			
			}
		}
	}

	DateTime dt = DateTime.now();

	List<Opportunity> opps = [Select Id,Next_Appointment_Date__c,AccountId, 
								(Select StartDateTime from Events where Type = 'Inside Sales Appointment' and StartDateTime >: dt Order By StartDateTime asc limit 1) 
								from Opportunity where Id in : oppIds];

	List<Account> accList = new List<Account>();
	for(Opportunity opp : opps){	
		if(opp.Events != null && opp.Events.size() == 1){
			opp.Next_Appointment_Date__c = opp.Events[0].StartDateTime.date();			
			Account acc = new Account(Id = opp.AccountId);
			acc.Next_Appointment_Date__c = opp.Events[0].StartDateTime.date();	
			accList.add(acc);		
		}
	}
	update opps;		

	if(accList.size() > 0)
		update accList;
}