/**
 * @author  JH 
 * @date 01/06/2016
 * @description To aid in obfuscating data in the sandboxes, this class will take a query & object name + field (records to update, object to update, field to update)
 * in addition a criteria can be set 
 */
global class MassUpdateDataBatch implements Database.Batchable<sObject> {
	
	public String query{get;set;}
	public String fieldName {get;set;}
	public String replaceWith {get;set;}
	
	global MassUpdateDataBatch() {
		
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<SObject> sobjsToUpdate = new List<SObject>(); 
		for(sObject sobj :scope) {
		    String existingEmail = String.valueOf(sobj.get(fieldName));
		    if(String.isNotBlank(existingEmail)) {
	     		String updatedEmail = existingEmail.replace('@', 'test@');
	       		sobj.put(fieldName, updatedEmail); 
	       		sobjsToUpdate.add(sobj); 
		    }
		}
		update sobjsToUpdate; 
	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}