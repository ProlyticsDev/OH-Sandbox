public class MediaAddGalleryItems {

	public String objectId {
		get {
			return ApexPages.currentPage().getParameters().get('id'); 
		} set;}
	public MediaAddGalleryItems() {
		
	}

	public PageReference done() {
		PageReference pageRef = new PageReference('/' + objectId); 
		return pageRef; 
	}
}