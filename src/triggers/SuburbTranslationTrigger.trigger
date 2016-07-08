trigger SuburbTranslationTrigger on Suburb_Translation__c (before insert, before update) {

	if(trigger.isBefore) {
		if(trigger.isInsert) {
			TranslationHandler.checkTranslationIsUnique(true, trigger.new); 
		}

		if(trigger.isUpdate) {
			TranslationHandler.checkTranslationIsUnique(true, trigger.new); 
		}
	}

}