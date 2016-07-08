public with sharing class vendorAuthorityUtility {

/*    
When a VA’s Exclusive period expires, we need to establish if the VA is finished, or if it going to default 
to a General period. If there will be a General period, then no action should be taken.

If there isn’t going to be a General period, then all Product Assignment records covered by the VA need to 
have their ‘Active’ field set to FALSE.

When the General period expires, then all Product Assignment records covered by the VA need to have their 
‘Active’ field set to FALSE.

*/


    public static void updateProductAsignment(Map<Id, Vendor_Authority__c> vaMap, Map<Id, Vendor_Authority__c> vaMapOld){
        Vendor_Authority__c[] expiredAuths = new Vendor_Authority__c[]{};
        for(Vendor_Authority__c va: vaMap.values()){
            //check to see if either of the expiry fields have changed.
            if((va.General_Expired__c || va.Exclusive_Expired__c) && (va.General_Expired__c != vaMapOld.get(va.Id).General_Expired__c || va.Exclusive_Expired__c != vaMapOld.get(va.Id).Exclusive_Expired__c)){
                //something has changed and expired.
                
                //make sure OH are covered
                if(!isCurrent(va.Exclusive_Start_Date__c, va.Exclusive_End_Date__c) && !isCurrent(va.General_Start_Date__c, va.General_End_Date__c)){
                    //this va doesn't have a valid general or exlusive period, mark for further processing
                    expiredAuths.add(va);
                }
                
            }
        }
        //we have now identified VA's that aren't covered, query the product assignments and update them accordingly.
        Product_Assignment__c[] updatedAssignments = new Product_Assignment__c[]{};
        for(Product_Assignment__c pa: [select Id, Active__c from Product_Assignment__c where Vendor_Authority__c in:expiredAuths and Active__c = true]){
            pa.Active__c = false;
            updatedAssignments.add(pa);
        }
        try{
            update updatedAssignments;
        }
        catch(exception e){
            system.debug('Couldn\'t update assignments: '+e.getMessage());
        }   
    }
    
    
    
    public static boolean isCurrent(date startDate, date endDate){
        //take the start date and end date and figure out if we are still in the active period
        //validate the start and end dates
        //start date is empty
        if(startDate == null){
            //end date must have a value
            if(endDate > date.today()) return true;
        }
        //start date is les or equal to today
        if(startDate <= date.today()){
            //end date can be empty or in the future.
            if(endDate == null || endDate > date.today()) return true;
        }
        //end date is empty
        if(endDate == null){
            //start date must be les or equal than today
            if(startDate <= date.today()) return true;
        }
        //end date is greater than today
        if(endDate > date.today()){
            //start date must be empty or less or equal than today
            if(startDate == null || startDate <= date.today()) return true;
        }
        
        return false;
    }
    
    /*
    Develop a batch class that runs daily to evaluate whether all documents are still valid and approved.
     These are all held on the sales person’s Person Account record in the ‘Documents’ custom object.

    If the Person Account field ‘VSA Override’ is TRUE, do not review the status of the documents and do
     not set the ‘Active’ field on the VSA records to FALSE.

    If any documents are not valid (e.g. Active = FALSE or Validated = FALSE), then the VSA records 
    relating to the Person Account should have the Active field set to FALSE.
    */
    
    /* 
    select Id, (select Id, Vendor_Authority__r.Project__c, Vendor_Authority__r.Project__r.Name, Role__c from Vendor_Sales_Authorities__r where Active__c = true and (Role__c = 'Host' or Role__c = 'Cadet' or Role__c = 'Sales Consultant')), (select Id, Name, Project__c, Type__c, Validated__c, Active__c, Expiry_Date__c from Documents__r where Active__c = true and Validated__c = true and Expiry_Date__c > TODAY) from Account where VSA_Override__c = false and isPersonAccount = true and (RecordType.DeveloperName = 'Staff_Account')
     query above will be limited to OH Staff and Channel Partner Person Accounts
    */
    
    //Method takes a list of Accounts
    public static void checkProjectDocuments(Account[] accs){
        //list for updated VSA's
        Vendor_Sales_Authority__c[] vsaList = new Vendor_Sales_Authority__c[]{};
        //loop through each account and validate that they have the correct documents for each active VSA.
        for(Account a: accs){
            //for each account, create a document map for easy access.
            Map<Id, Set<String>> docMap = new Map<Id, Set<String>>();
            Document__c[] docList = new Document__c[]{};
            for(Document__c d: a.Documents__r){
                //does the project exist in the map already?
                if(d.Type__c == 'Commission Agreement' || d.Type__c == 'Project Acceptance Letter'){
                    //doesn't exist so initialise
                    if(docMap.get(d.Project__c) == null){
                        docMap.put(d.Project__c, new Set<String>());
                    }
                    //at this point the project will exist in the map so just add the document type
                    docMap.get(d.Project__c).add(d.Type__c);
                
                }
                //assume the project is initialised in the map at this point, add the document to the correct project list.
                docList.add(d);
            }
            
            //loop through each vsa and make sure we have the right documents
            for(Vendor_Sales_Authority__c vsa: a.Vendor_Sales_Authorities__r){
                boolean isValidated = false;
                //process Sales Consultants first as they have more docs
                if(vsa.Role__c == 'Sales Consultant'){
                    //now loop through their docs for this project.
                    boolean agentRepAuthority = false;
                    boolean agentsRepLicence = false; 
                    boolean authorityToRecruit = false;
                    boolean commissionAgreement = false;
                    boolean eligibilityDeclaration = false;
                    boolean employmentContract = false;
                    boolean mGSProfile = false;
                    boolean oHSPolicies = false;
                    boolean personalDetailsForm = false;
                    boolean policeCheck = false;
                    boolean projectAcceptanceLetter = false;
                    boolean superannuationForm = false;
                    //for(Document__c d: docMap.get(vsa.Vendor_Authority__r.Project__c)){
                    for(Document__c d: docList){
                        if(d.Type__c == 'Agent Rep Authority') agentRepAuthority = true;
                        else if(d.Type__c == 'Agent’s Rep Licence') agentsRepLicence = true;
                        else if(d.Type__c == 'Authority to Recruit') authorityToRecruit = true;
                        else if(d.Type__c == 'Eligibility Declaration') eligibilityDeclaration = true;
                        else if(d.Type__c == 'Employment Contract') employmentContract = true;
                        else if(d.Type__c == 'MGS Profile') mGSProfile = true;
                        else if(d.Type__c == 'OH&S Policies') oHSPolicies = true;
                        else if(d.Type__c == 'Personal Details Form') personalDetailsForm = true;
                        else if(d.Type__c == 'Police Check') policeCheck = true;
                        else if(d.Type__c == 'Superannuation Form') superannuationForm = true;
                        //These 2 are project specific.
                        
                    }
                    //Now check the project specific documents
                    if(vsa.Vendor_Authority__r.Project__c != null && docMap.get(vsa.Vendor_Authority__r.Project__c) != null && docMap.get(vsa.Vendor_Authority__r.Project__c).containsAll(new String[]{'Project Acceptance Letter','Commission Agreement'})){
                        projectAcceptanceLetter = true;
                        commissionAgreement = true;
                    }
                    //all documents need to exist
                    if(!agentRepAuthority || !agentsRepLicence || !authorityToRecruit || !commissionAgreement || !eligibilityDeclaration || !employmentContract || !mGSProfile || !oHSPolicies || !personalDetailsForm || !policeCheck || !projectAcceptanceLetter || !superannuationForm){
                        //if any of them are false, mark the VSA as Active__c = false
                        vsa.Active__c = false;
                        //add to a list for update.
                        vsaList.add(vsa);
                    }       
                }
                if(vsa.Role__c == 'Cadet' || vsa.Role__c == 'Host'){
                    //now loop through their docs for this project.
                    boolean agentRepAuthority = false;
                    boolean agentsRepLicence = false; 
                    boolean authorityToRecruit = false;
                    //boolean commissionAgreement = false;
                    boolean eligibilityDeclaration = false;
                    boolean employmentContract = false;
                    //boolean mGSProfile = false;
                    boolean oHSPolicies = false;
                    boolean personalDetailsForm = false;
                    boolean policeCheck = false;
                    //boolean projectAcceptanceLetter = false;
                    boolean superannuationForm = false;
                    for(Document__c d: docList){
                        if(d.Type__c == 'Agent Rep Authority') agentRepAuthority = true;
                        else if(d.Type__c == 'Agent’s Rep Licence') agentsRepLicence = true;
                        else if(d.Type__c == 'Authority to Recruit') authorityToRecruit = true;
                        //else if(d.Type__c == 'Commission Agreement') commissionAgreement = true;
                        else if(d.Type__c == 'Eligibility Declaration') eligibilityDeclaration = true;
                        else if(d.Type__c == 'Employment Contract') employmentContract = true;
                        //else if(d.Type__c == 'MGS Profile') mGSProfile = true;
                        else if(d.Type__c == 'OH&S Policies') oHSPolicies = true;
                        else if(d.Type__c == 'Personal Details Form') personalDetailsForm = true;
                        else if(d.Type__c == 'Police Check') policeCheck = true;
                        //else if(d.Type__c == 'Project Acceptance Letter') projectAcceptanceLetter = true;
                        else if(d.Type__c == 'Superannuation Form') superannuationForm = true;
                    }
                    //all documents need to exist
                    if(!agentRepAuthority || !agentsRepLicence || !authorityToRecruit || !eligibilityDeclaration || !employmentContract || !oHSPolicies || !personalDetailsForm || !policeCheck || !superannuationForm){
                        //if any of them are false, mark the VSA as Active__c = false
                        vsa.Active__c = false;
                        //add to a list for update.
                        vsaList.add(vsa);
                    }       
                }
            }
        }
        update vsaList;
    }   
}