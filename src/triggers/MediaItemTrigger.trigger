trigger MediaItemTrigger on Media_Item__c (before insert, before update) {
	if(Trigger.isBefore) {
		if(Trigger.isInsert) {
			MediaItemHandler.validateMediaItemRelationships(trigger.new); 
			MediaItemHandler.heroAlreadySelected(trigger.new);
		}

		if(Trigger.isUpdate) {
			MediaItemHandler.validateMediaItemRelationships(trigger.new);
			MediaItemHandler.heroAlreadySelected(trigger.new);
		}
	}
}