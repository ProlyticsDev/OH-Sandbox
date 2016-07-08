trigger ProjectTranslationTrigger on Project_Translation__c (before insert, before update) {
	if(trigger.isBefore) {
		if(trigger.isInsert) {
			TranslationHandler.checkTranslationIsUnique(false, trigger.new); 
		}

		if(trigger.isUpdate) {
			TranslationHandler.checkTranslationIsUnique(false, trigger.new); 
		}
	}
}