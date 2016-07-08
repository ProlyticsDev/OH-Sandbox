/**
 * @author J.HESKETH
 * @date 06/07/2016
 * @description provides handling for translation objects. This includes validating that a particular field only has one translation.
 */
public class TranslationHandler 
{
    /**
    * @author J.HESKETH
    * @date 06/07/2016
    * @description Builds a translation/field key to determine whether this translation is unique. 
    */
    public static void checkTranslationIsUnique(Boolean isSuburbTranslation, List<sObject> translations) {
        Map<String, sObject> translationsMap = new Map<String, sObject>(); 
        Map<String, String> languagesKeyedByFields = new Map<String, String>(); 
        for(SObject translation :translations) {
            //jh - build a key containing the field & language its been translated in 
            languagesKeyedByFields.put(String.valueOf(translation.get('Field__c')), String.valueOf(translation.get('Language__c')));
            translationsMap.put(String.valueOf(translation.get('Field__c')) +  String.valueOf(translation.get('Language__c')), translation); 
        }

        if(isSuburbTranslation) {
            List<Suburb_Translation__c> subTranslations = [SELECT Id, Language__c, Field__c 
                                                           FROM Suburb_Translation__c 
                                                           WHERE Language__c IN :languagesKeyedByFields.values()
                                                           AND Field__c IN :languagesKeyedByFields.keySet()]; 
            
            for(Suburb_Translation__c subTranslation :subTranslations) {
                if(languagesKeyedByFields.get(subTranslation.Field__c) == subTranslation.Language__c) {
                    Suburb_Translation__c subTrans = (Suburb_Translation__c) translationsMap.get(subTranslation.Field__c + subTranslation.Language__c); 
                    subTrans.addError('There is already a suburb translation for this field, in this language.');
                }
            }
        }
        else if(!isSuburbTranslation) {
            List<Project_Translation__c> projTranslations = [SELECT Id, Language__c, Field__c 
                                                           FROM Project_Translation__c 
                                                           WHERE Language__c IN :languagesKeyedByFields.values()
                                                           AND Field__c IN :languagesKeyedByFields.keySet()]; 
            
            for(Project_Translation__c projTranslation :projTranslations) {
                if(languagesKeyedByFields.get(projTranslation.Field__c) == projTranslation.Language__c) {
                    Project_Translation__c projTrans = (Project_Translation__c) translationsMap.get(projTranslation.Field__c + projTranslation.Language__c); 
                    projTrans.addError('There is already a project translation for this field, in this language.'); 
                }
            }
        }
    }
}