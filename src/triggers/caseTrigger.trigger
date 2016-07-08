/* HISTORY
	
	2016-03-30 Richard Clarke (RC) created to add support to prepopulate Case.Contact and Case.User__c
	
*/
trigger caseTrigger on Case (after insert) {
    if ( trigger.isInsert && trigger.isAfter ) {
    	// RC when inserting new cases pre-populate Contact and User__c if IT Request record type
    	caseUtilities.PopulateContactAndUser( trigger.new );
    }
}