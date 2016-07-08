/* HISTORY
	
	2016-03-30 Richard Clarke (RC) created class to add support to prepopulate Case.Contact and Case.User__c
	- if Case.SuppliedEmail is set (from email to case or web to case) this is used to catch to OH Contacts and Users
	- if not then the CreatedBy.Email is used for matching
	- only active users are matched
	- only contacts visible to the creating user are matched as the private security model means not all contacts are visible
	
*/
public with sharing class caseUtilities {

	// RC after inserting new cases populate Contact and User__c if IT Request record type
	public static void PopulateContactAndUser( List<Case> insertedCases ) {
		
		// RC Get IT Request record type
		ID ITRequestRecordTypeId = [SELECT Id FROM RecordType WHERE sObjectType='Case' AND DeveloperName='IT_Request' LIMIT 1].Id;
		system.assertNotEquals(null,ITRequestRecordTypeId);
//system.debug('***RC*** Retrieved ITRequestRecordTypeId=' + ITRequestRecordTypeId);

        // RC get list of IT Request IDs which have been inserted
        Set<ID> CaseIDs = new Set<ID>();
		for ( Case c : insertedCases ) {
			if ( c.RecordTypeId == ITRequestRecordTypeId) {
                if ( !CaseIDs.contains(c.Id) ) {
                	CaseIDs.add(c.Id);
                }
            }
        }

        // RC retrieve cases with data to support the contact and user linkage process
   	    List<Case> ITRequestCases = [select Id, ContactID, Contact.Email, CreatedById, CreatedBy.Email, SuppliedEmail, User__c from Case where Id in :CaseIDs];
//system.assertEquals(CaseIDs.size(),ITRequestCases.size());
        
		// RC Generate maps/sets of creator user ids and supplied emails from any IT Request being added
		Map<string,Id> CreatorEmailsToId = new Map<String,Id>();
		Map<Id,string> CreatorIdToEmails = new Map<Id,String>();
		Set<string> SuppliedEmails = new Set<String>();
		for ( Case c : ITRequestCases ) {
			if ( !CreatorEmailsToId.keyset().contains(c.CreatedBy.Email)) {
				CreatorEmailsToId.put(c.CreatedBy.Email,c.CreatedById);
				CreatorIdToEmails.put(c.CreatedById,c.CreatedBy.Email);
//system.debug('***RC*** Added CreatorEmailsToId c.CreatedBy.Email=' + c.CreatedBy.Email + ' c.CreatedById=' + c.CreatedById + ' from Case.Id=' + c.Id);
			}
			if ( c.SuppliedEmail != null ) {
				if ( !SuppliedEmails.contains(c.SuppliedEmail)) {
					SuppliedEmails.add(c.SuppliedEmail);
//system.debug('***RC*** Added SuppliedEmail=' + c.SuppliedEmail + ' from Case.Id=' + c.Id);
				}
			}
		}
		
		// RC Get map of contacts under the OH business account which have emails matching the creator email or the supplied email
		Map<string,Id> ContactEmailsToId = new Map<string,Id>();
system.debug('***RC*** Looking for OH contacts matching ' + CreatorEmailsToId.size() + ' CreatorEmails');
		for ( Contact c: [Select Id, Email, Business_Account__r.Name from Contact where Business_Account__r.Name = 'Oliver Hume Real Estate' and (Email in :CreatorEmailsToId.keyset() OR Email in :SuppliedEmails)]) {
			if ( !ContactEmailsToId.keyset().contains(c.Email)) {
				ContactEmailsToId.put(c.Email,c.Id);
system.debug('***RC*** Added ContactEmailsToId=' + c.Email + ' to Contact.Id=' + c.Id);
			}
		}

        // RC Get map of active users which have emails matching the supplied email or creator email
		Map<string,Id> UserEmailsToId = new Map<string,Id>();
		for ( User u: [Select Id, Email from User where IsActive = true and ( Email in :CreatorEmailsToId.keyset() OR Email in :SuppliedEmails)]) {
			if ( !UserEmailsToId.keyset().contains(u.Email)) {
				UserEmailsToId.put(u.Email,u.Id);
//system.debug('***RC*** Added UserEmailsToId=' + u.Email + ' to User.Id=' + u.Id);
			}
		}
		
		// RC Iterate through inserted cases populating Contact and User__c if not set and a match can be found
        List<Case> ITRequestCasesToUpdate = new List<Case>();
        Boolean updateCase;
		for ( Case c : ITRequestCases ) {
            updateCase = false;
			// RC Set the case Contact if not already set
			if ( c.ContactId == null ) {
				// RC Try and populate case Contact lookup based on SuppliedEmail if known as a priority
				if ( c.SuppliedEmail != null ) {
					if ( ContactEmailsToId.keyset().contains(c.SuppliedEmail)) {
						c.ContactId = ContactEmailsToId.get(c.SuppliedEmail);
                        updateCase = true;
//system.debug('***RC*** Set Case.Contact=' + c.ContactId + ' based on Case.SuppliedEmail' );
					}
				} else {
					// RC No SuppliedEmail so set Contact lookup matching the creator's email
					if ( ContactEmailsToId.keyset().contains(c.CreatedBy.Email)) {
						c.ContactId = ContactEmailsToId.get(c.CreatedBy.Email);
                        updateCase = true;
//system.debug('***RC*** Set Case.Contact=' + c.ContactId + ' based on Case.CreatedBy.Email' );
					}
				}
            }

			// RC Set the case User if not already set
			if ( c.User__c == null ) {
				// RC Try and populate case User lookup based on SuppliedEmail if known as a priority
				if ( c.SuppliedEmail != null ) {
					if ( UserEmailsToId.keyset().contains(c.SuppliedEmail)) {
						c.User__c = UserEmailsToId.get(c.SuppliedEmail);
                        updateCase = true;
//system.debug('***RC*** Set Case.User__c=' + c.User__c + ' based on Case.SuppliedEmail' );
					}
				} else {
					// RC No SuppliedEmail so set to the creator
					c.User__c = c.CreatedById;
                       updateCase = true;
//system.debug('***RC*** Set Case.User__c=' + c.User__c + ' based on Case.CreatedById' );
				}
			}
        	if ( updateCase ) {
				ITRequestCasesToUpdate.add(c);
            }
        }
        if ( ITRequestCasesToUpdate.size() > 0) {
            update ITRequestCasesToUpdate;
//system.debug('***RC*** Updated ITRequestCasesToUpdate.size()=' + ITRequestCasesToUpdate.size() );
        }
	}
}