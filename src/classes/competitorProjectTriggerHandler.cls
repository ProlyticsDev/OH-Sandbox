/*
* Author: Jimmy Hesketh
* Summary: Handler class for the competitor project trigger. Performs all trigger business logic. 
* Date: 24/02/2016
*/
public class competitorProjectTriggerHandler {

	//based on the postcode & suburb name populate the relationship to a suburb
	//if the suburb cannot be matched throw a exception 
	public static void updateCompetitorProjectSuburb(List<Competitor_Project__c> competitorProjs) {
		if(competitorProjs != null && !competitorProjs.isEmpty()) {
			//create a map of suburb name & postcode mapping to a id
			List<Suburb__c> suburbs = [SELECT Id, Name, Postcode__c FROM Suburb__c]; 
			Map<String, String> suburbNameIdKeys = new Map<String,String>(); 
			for(Suburb__c theSuburb :suburbs) {
				if(String.isNotBlank(theSuburb.Name)) { 
					suburbNameIdKeys.put(theSuburb.Name, theSuburb.Id);
				} 
			}
			
			//iterate through the list of competitor projects getting the suburb from the map, 
			//if a id matches populate the relationship else throw an error: 
			//1. if there is a suburb name lookup the suburb 
			//2. if there is a suburb & no suburb name stay the same 
			//3. if 
			for(Competitor_Project__c theCompProj :competitorProjs) {
				if(String.isNotBlank(theCompProj.Suburb_Name__c)) {
					String theKey = theCompProj.Suburb_Name__c; 
					if(String.isNotBlank(suburbNameIdKeys.get(theKey))) {
						theCompProj.Suburb__c = suburbNameIdKeys.get(theKey); 
					} 
					else {
						theCompProj.Suburb__c.addError('The suburb name does not match a suburb in Salesforce.'); 
					}
				} 
				else if (String.isBlank(theCompProj.Suburb__c)){
					theCompProj.Suburb__c.addError('The suburb name has not been populated.'); 
				}
			}
		}
	}
}