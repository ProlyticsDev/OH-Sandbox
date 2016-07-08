trigger itemTrigger on Item__c (After Insert, After Update) {

/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 5 March 2013
Trigger Purpose: When the Internal Status of a Product is set to Unavailable, check to see if there are any other 
Opportunities that have an ‘interest’ (Stage values of New Enquiry; Contacted; Qualified; Appointment) in the same Product. 
If there are any, send a Task notification to the Opportunity Owner advising that the Product is no longer available.
*/

    //Declare Variables
    String[] pIds = new String[]{};
    Task[] tNew = new Task[]{};
	
	//do an initial check to make sure there are records to process.
	Item__c[] itemsToProcess = new Item__c[]{};
	for(Item__c i: trigger.new){
		if(!utility.itemAlreadyProcessed(i.Id)){
		 itemsToProcess.add(i);
		}
	}
	//only continue if there are items to process
	if(!itemsToProcess.isEmpty()){
		For(Item__c i: [SELECT Id, Status__c, Product__c, Product__r.RecordTypeId, Product__r.RecordType.Name FROM Item__c WHERE Id in: trigger.new]){
	        //If this Item Status is not equal to New Enquiry, Contacted, Qualified or Appointment
	        if(trigger.IsInsert){
	            if((i.Product__r.RecordType.Name == 'Apartment' || i.Product__r.RecordType.Name == 'Land' || i.Product__r.RecordType.Name == 'Urban Village' || i.Product__r.RecordType.Name == 'Townhouse') && (i.Status__c == 'Reservation Pending' ||  i.Status__c == 'Reservation')){
	                //Add the product ID to the list for referencing
	                pIds.add(i.Product__c);
	            }
	          
	        }
	        else{
	            if((i.Product__r.RecordType.Name == 'Apartment' || i.Product__r.RecordType.Name == 'Land' || i.Product__r.RecordType.Name == 'Urban Village' || i.Product__r.RecordType.Name == 'Townhouse') && ((trigger.OldMap.get(i.Id).Status__c != 'Reservation Pending' && i.Status__c == 'Reservation Pending') || ((trigger.OldMap.get(i.Id).Status__c != 'Reservation Pending' && trigger.OldMap.get(i.Id).Status__c != 'Reservation') &&  i.Status__c == 'Reservation'))){
	                //Add the product ID to the list for referencing
	                pIds.add(i.Product__c);
	            }
	        }
	    }
	    //Build a list of all Item records where Item.Product__c is in list of Ids{
	    if(!pIds.isEmpty()){
	    	Item__c[] iList = [SELECT Id, Name, Product__c, Opportunity__r.StageName, Opportunity__r.AccountId, Opportunity__r.OwnerId, Opportunity__r.Account.PersonContactId FROM Item__c WHERE Product__c in: pIds];
		    for(Item__c i: iList){
		        //If Oppty.Stage = New Enquiry, Contacted, Qualified, Appointment
		        if(i.Opportunity__r.StageName == 'New Enquiry' || i.Opportunity__r.StageName == 'Contacted' || i.Opportunity__r.StageName == 'Qualified' || i.Opportunity__r.StageName == 'Appointment'){
		            //Create a Task for the Oppty.Owner advising the Product is no longer available
		                //Notify Assignee = TRUE
		                //WhatId = Oppty.Id
		                //WhoId = Contact
		            Task t = new Task(Subject = 'Notification: Product is no longer available', OwnerId = i.Opportunity__r.OwnerId, Status = 'In Progress', reminderDateTime = system.now(), IsReminderSet = TRUE, Description = 'You have a client who has registered interest in a product that is no longer available.\n\nPlease contact the client to discuss alternative options.', WhatId = i.Opportunity__c, WhoId = i.Opportunity__r.Account.PersonContactId, ActivityDate = date.today());    
		            tNew.add(t);
		        }
		    }
	    }
	    if(tNew.size() > 0){
	        Database.DMLOptions dlo = new Database.DMLOptions();
	        dlo.EmailHeader.triggerUserEmail = true;
	        database.insert (tNew, dlo); //Insert new Task records and send notification emails
	    }
	}
}