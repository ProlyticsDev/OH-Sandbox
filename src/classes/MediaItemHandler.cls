/**
* @author J.HESKETH
* @date 07/03/2016
* @description Handler class for media items. Media item specific business logic should reside here. 
* HISTORY 
* JH - Created validate media item relationships 
* 06/04/2016 - Added suburb lookup to validation 
* 06/05/2016 - Removed obsolete code 
*/ 
public class MediaItemHandler {

     /**
    * @author J.HESKETH
    * @date 05/03/2016
    * @description Validates that there is only one related object to the media item (either project, product or competitor project) 
    */ 
    public static void validateMediaItemRelationships(List<Media_Item__c> mediaToValidate) {
        if(mediaToValidate != null && !mediaToValidate.isEmpty()) {
            for(Media_Item__c mItem :mediaToValidate) {
                Boolean hasError = false; 
                //iterate through media checking their relationships - throw an error if its relate
                if(String.isNotBlank(mItem.Project__c)) {
                    if(String.isNotBlank(mItem.Product__c) || String.isNotBlank(mItem.Competitor_Project__c) || String.isNotBlank(mItem.Suburb__c)) {
                       hasError = true;
                    }
                }

                if(String.isNotBlank(mItem.Product__c)) {
                    if(String.isNotBlank(mItem.Competitor_Project__c) || String.isNotBlank(mItem.Project__c) || String.isNotBlank(mItem.Suburb__c)) {
                        hasError = true;
                    }
                }

                if(String.isNotBlank(mItem.Competitor_Project__c)) {
                    if(String.isNotBlank(mItem.Product__c) || String.isNotBlank(mItem.Project__c) || String.isNotBlank(mItem.Suburb__c)) {
                        hasError = true;
                    }
                }

                if(String.isNotBlank(mItem.Suburb__c)) {
                    if(String.isNotBlank(mItem.Product__c) || String.isNotBlank(mItem.Project__c) || String.isNotBlank(mItem.Competitor_Project__c)) {
                        hasError = true;
                    }
                }
                //throw the error to the ui 
                if(hasError) {
                     mItem.addError('You can only select either a Project, Product, Competitor Project or Suburb.');
                }
            }
        }
    }

    /**
    * @author JH 
    * @date 16/06/2016
    * @description Check if theres any other hero media items selected for the project, product, com proj or suburb. 
    **/
    public static void heroAlreadySelected(List<Media_Item__c> mediaItems)  {
          if(mediaItems != null && !mediaItems.isEmpty()) { 
            //jh - don't throw an error when the current media item is the hero! 
            Set<String> existingRecords = new Set<String>(); 
            for(Media_Item__c mItem :mediaItems) {
                if(mItem.Hero__c) {
                    existingRecords.add(mItem.Id); 
                }
            } 

            //jh build a map of hero media items 
            Map<Id, Media_Item__c> heroMediaItems = new Map<Id, Media_Item__c>(); 
            List<Media_Item__c> heroMItems = [SELECT Id, Hero__c, Project__c, Product__c,Competitor_Project__c, Suburb__c  
                                              FROM Media_Item__c WHERE Hero__c = true AND Id NOT IN :existingRecords];
            for(Media_Item__c mItem :heroMItems) {
                    if(String.isNotBlank(mItem.Project__c)) {
                        heroMediaItems.put(mItem.Project__c, mItem); 
                    }
                    else if(String.isNotBlank(mItem.Product__c)) {
                        heroMediaItems.put(mItem.Product__c, mItem);
                    }
                    else if(String.isNotBlank(mItem.Competitor_Project__c)) {
                        heroMediaItems.put(mItem.Competitor_Project__c, mItem);
                    }
                    else if(String.isNotBlank(mItem.Suburb__c)) {
                        heroMediaItems.put(mItem.Suburb__c, mItem);
                    }
            }
            
            for(Media_Item__c mItem :mediaItems) {
                if(mItem.Hero__c) {
                    if(heroMediaItems.get(mItem.Project__c) != null) {
                        mItem.addError('A hero media item already exists for the project. <a target="_blank" href=/' + 
                            heroMediaItems.get(mItem.Project__c).Id +'>View Existing Hero Image</a>', false); 
                    }
                    else if(heroMediaItems.get(mItem.Product__c) != null) {
                        mItem.addError('A hero media item already exists for the product. <a target="_blank" href=/' + 
                            heroMediaItems.get(mItem.Product__c).Id +'>View Existing Hero Image</a>', false); 
                    }
                    else if(heroMediaItems.get(mItem.Competitor_Project__c) != null) {
                        mItem.addError('A hero media item already exists for the competitor project. <a target="_blank" href=/' + 
                            heroMediaItems.get(mItem.Competitor_Project__c).Id +'>View Existing Hero Image</a>', false); 
                    }
                    else if(heroMediaItems.get(mItem.Suburb__c) != null) {
                        mItem.addError('A hero media item already exists for the suburb. <a target="_blank" href=/' + 
                            heroMediaItems.get(mItem.Suburb__c).Id +'>View Existing Hero Image</a>', false); 
                    }
                }
            }
        }
    }

    /**
    * @author J.HESKETH
    * @date 09/03/2016
    * @description method simply deletes media items that are passed into it. 
    */ 
    public static void deleteMediaItems(List<Media_Item__c> itemsToDelete) {
        if(itemsToDelete != null && !itemsToDelete.isEmpty()) {
            delete itemsToDelete; 
        }
    }
}