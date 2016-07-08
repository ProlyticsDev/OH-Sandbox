/*
* Author: J HESKETH 
* Date: 25/02/2016
* Summary: Displays related media item thumbnails & takes user to the CDN URL when a thumbnail is clicked. 
*/ 
public class MediaItemThumbnailController {
	public List<Media_Item__c> thumbnailUrls { get; set; }
	public Boolean hasMediaItems { get; set; } 

	public ApexPages.StandardController stdCont { 
		get; 
		set{
 			if(stdCont!=null) {
 				return;
 			}

            stdCont = value; 
            loadMediaItemThumbnails(); 
		}
	}

	public MediaItemThumbnailController() {
		thumbnailUrls = new List<Media_Item__c>(); 
		hasMediaItems = false; 
	}

	//loads the media items related to the project or product. 
	public void loadMediaItemThumbnails() {
		String recordId = stdCont.getId(); 
		if(String.isNotBlank(recordId)) {
			thumbnailUrls = [SELECT Name, CDN_Thumbnail_URL__c, CDN_URL__c 
							 FROM Media_Item__c 
							 WHERE (Project__c = :recordId 
							 OR Product__c = :recordId
							 OR Competitor_Project__c = :recordId
							 OR Suburb__c = :recordId)
							 AND CDN_URL__c != null
							 AND File_Type__c = 'Project Images']; 
		}

		if(thumbnailUrls.isEmpty()) {
			hasMediaItems = false; 
		}
		else {
			hasMediaItems = true; 
		}
		//check if there are more than x media items, if there are display a show more link/view  
		//if(mediaItems.size() > 8)
	}

}