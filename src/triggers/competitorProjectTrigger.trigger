/*
* Author: J HESKETH
* Date: 26/02/2016
* Summary: Calls handler function to match the competitors suburb data with a suburb that exists in SF and populate the relationship. 
*/ 
trigger competitorProjectTrigger on Competitor_Project__c (before insert, before update) {
	if(trigger.isBefore) {
		if(trigger.isInsert) {
			competitorProjectTriggerHandler.updateCompetitorProjectSuburb(trigger.new); 
		}

		if(trigger.isUpdate) {
			competitorProjectTriggerHandler.updateCompetitorProjectSuburb(trigger.new); 
		}
	}
}