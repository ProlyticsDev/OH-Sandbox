trigger documentTrigger on Document__c (after insert, after update) 
{
	if(trigger.isAfter)
	{
		list<Task> listTasksToBeInserted = new list<Task>();
		if(trigger.isInsert || trigger.isUpdate)
		{
			map<Id, Document__c> mapDocuments = new map<Id, Document__c>();
			
			for(Document__c objDocument : trigger.new)
			{
				if((objDocument.Type__c == 'Police Check' || objDocument.Type__c == 'Agent’s Rep Licence' || 
					objDocument.Type__c == 'Commission Agreement' || objDocument.Type__c == 'Eligibility Declaration' || 
					objDocument.Type__c == 'Agent Rep Authority' || objDocument.Type__c == 'MGS Profile') &&
					objDocument.Project__c != null && objDocument.Validated__c == false)
				{
					mapDocuments.put(objDocument.Id, objDocument);
				}
			}
			
			for(Document__c objDocument : [
				Select Id,
					Staff_Member__c, Staff_Member__r.Id, Staff_Member__r.Name,
					Project__c, Project__r.Sales_Manager__c
				From Document__c 
				Where Id =: mapDocuments.keySet()])
			{
				Task objTask = new Task();
			    objTask.Subject ='HR Document Validation';
			    objTask.ActivityDate = date.today();
			    objTask.Description = 'Hi, ' + objDocument.Staff_Member__r.Name + ' has submitted a new HR Document that requires validation. Please review the document and update the Validation field to TRUE. Thanks, Sys Admin';
			    objTask.WhatId = objDocument.Staff_Member__r.Id;
			    objTask.OwnerId = objDocument.Project__r.Sales_Manager__c;
			    if(objDocument.Project__r.Sales_Manager__c != null)
			    {
			    	listTasksToBeInserted.add(objTask);
			    }
			    else
			    {
			    	mapDocuments.get(objDocument.id).addError('Sales Manager for the Project cannot be empty. Unable to create task for Project Sales Manager.');
			    }
			}
		}
		
		try
		{
			insert listTasksToBeInserted;
		}
		catch(DmlException ex)
		{
			throw new ohHelper.ApplicationException(ex.getMessage());
		}
		catch(Exception ex)
		{
			throw new ohHelper.ApplicationException(ex.getMessage());
		}
	}
}