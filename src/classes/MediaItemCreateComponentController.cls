/**
* @description: This class handles the creation of media items - either through a bulk operation (products) or for single item creation
* @author: J.HESKETH 
* @date: 19/02/2016
* HISTORY: 
* 18/03/2016 - Updated to return the page reference of the page with the embedded iframe. 
* 30/03/2016 - Updates to contain the iframe within the same page and handle the case where the component is used with a standard controller
* - not a set controller. 
*/ 
public with sharing class MediaItemCreateComponentController {

   


    //component parameters 
    public List<sObject> genericObjs {get;set;} 
    public Boolean isAProduct { get; set; }
    public Boolean isAProject { get; set; }
    public Boolean isACompProject { get; set; }
    public Boolean isASuburb { get; set; }

    public Media_Item__c mediaItemDetails { get;set; }
    public Boolean errMsgPresent {get;set;}
    public List<String> recordNames { get; set; }

    //displayed 
    public boolean displayUpload { get; set; }
    public String mediaItemIds { get; set; }

    public ApexPages.StandardSetController stdSetCont { 
        get; 
        set {
            if(stdSetCont!=null)return; 
            if(value != null) {
                stdSetCont = value; 
                initialise(true); 
            }
        }
    }
    //jh - 
    public ApexPages.StandardController stdCont {
        get; 
        set {
            if(stdCont != null) return; 
            if(value != null) {
                stdCont = value; 
                initialise(false); 
            }
        }
    }

    //jh - at the time of writing constructors in component controllers are virtually useless as the assignTo hasn't completed. 
    public MediaItemCreateComponentController () {
        
    }

    //JH - Get the selected records and throw an error if none are selected 
    //make a list of record names for display to user
    public void initialise (Boolean isSet) {
        mediaItemDetails = new Media_Item__c(); 
        mediaItemIds = ''; 
        displayUpload = false; 
        if(isSet) {
            //at time of writing addFields doesn't play nicely with unit tests
            if(!Test.isRunningTest()) {
                //jh - different behaviour based on whether there is one record (standard controller) or many (standard set controller)
                stdSetCont.addFields(new List<String>{'Name'});  
            }

            genericObjs = stdSetCont.getSelected();
            if(genericObjs == null || genericObjs.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Media Items must be attached to a Project, Product or Suburb so select one or more records before clicking the "Add Media Items" button.')); 
                errMsgPresent = true; 
            } 
            else if(genericObjs.size() > 95) {
                //jh - as the records are passed on to a iframe (via url param) constrained by the url string length. 
                //which should never be more than 2000 characters 
                //the base url is around 65 char with each id around 19chars  
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Cannot take more than 95 records. Please select no more than 95 records.')); 
                errMsgPresent = true; 
            }
        }
        else {
            if(!Test.isRunningTest()) {
                stdCont.addFields(new List<String>{'Name'});
            }
            //jh - if we aren't dealing with a set controller instantiate the sobj list with the current record. 
            genericObjs = new List<Sobject>{stdCont.getRecord()}; 
        }

        if(genericObjs != null && !genericObjs.isEmpty()) {
            //build a list of the record names to display records which are having the media items attached 
            recordNames = new List<String>(); 
            for(sObject item :genericObjs) {
                recordNames.add((string)item.get('Name')); 
            }
        }
    }

    //Return user to the page they came from 
    public PageReference cancel() {
        if(stdSetCont != null) {
            return stdSetCont.Cancel(); 
        }
        return stdCont.Cancel();  
    }

    //Insert the media items against the selected objects, redirect user to embedded iframe passing in the 
    //newly created media item id's as url params 
    public void next() {

        List<Media_Item__c> mItems = new List<Media_Item__c>();
        if(String.isNotBlank(mediaItemDetails.Name) && String.isNotBlank(mediaItemDetails.Description__c)) { 
            //for each sobject create a new media item 
            for(sObject obj :genericObjs) {
                Media_Item__c mediaItem = mediaItemDetails.clone(); 
                mediaItem.Status__c = 'New'; 
                if(isAProject) {
                    mediaItem.Project__c = (Id)obj.get('Id'); 
                }
                else if(isAProduct) {
                    mediaItem.Product__c = (Id)obj.get('Id'); 
                }
                else if(isACompProject) {
                    mediaItem.Competitor_Project__c = (Id)obj.get('Id'); 
                }
                else if(isASuburb) {
                    mediaItem.Suburb__c = (Id)obj.get('Id'); 
                }

                mItems.add(mediaItem); 
            }

            //perform the insert of the new media items 
            Savepoint sp = Database.setSavepoint(); 
            try {
                insert mItems; 
            }
            catch (DmlException dmlEx) {
                Database.rollback(sp); 
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The insert failed with the error ' + dmlEx.getMessage()));
            }

            String urlIds = ''; 
            //build a string of all the media item ids: 
            for(Media_Item__c media :mItems) {
                if(String.isBlank(urlIds)) {
                    urlIds += media.Id; 
                }
                else if(String.isNotBlank(urlIds)) {
                    urlIds += ',' + media.Id; 
                }
            }

            mediaItemIds = urlIds; 
            displayUpload = true; 
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Name & description must be populated to continue.'));
        }
    }
}