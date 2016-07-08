/**
* @author       J.Hesketh
* @date         08/03/2016
* @description  Provides a separation from the lead utility for refactoring the lead utility according to the new approach. 
*               HR - 30/03/2016 - add lead conversion for the property reservation by modifing performLeadConversion method
*  ---------------------------------------------------------------
*  @history:
*  04/04/2016 - J.H Updates to handle new property connect lead type. 
*  05/04/2016 - H.R Add auto submit for approval for the property reservation leads
*  07/04/2016 - H.R Rollup the list and net price of the options/upgrades 
*  13/04/2016 - H.R Change product status to available for deleted leads
*  14/04/2016 - JH Updates to handle Apartments, New Communities & Subscription record types. 
*  14/06/2016 - HR Add exception handling
*  28/06/2016 - JH Added method to share leads with their creators. 
**/
public class LeadFramework {
    public class NotImplementedException extends Exception {}
     
    //jh expose a static map of duplicate lead email addresses  & their duplicate account  
    public static Map<String, Account> duplicateAccEmail { get; set; }
    public static List<OpportunityShare> oppSharesForInsert { get; set; }
    public static final String LEAD_APARTMENT_RECORDTYPE = 'lead_apartments'; 
    public static final String LEAD_NEW_COMMUNITIES_RECORDTYPE = 'lead_new_communities';
    public static final String LEAD_RESERVATION_REQUEST_RECORDTYPE = 'lead_reservation_request';
    public static final String LEAD_PROPERTY_CONNECT_RECORDTYPE = 'lead_property_connect'; 
    public static final String LEAD_DSA_RECORDTYPE = 'lead_development_sites'; 
    public static final String LEAD_MEMBERSHIPENQUIRY_RECORDTYPE = 'lead_membership_enquiry'; 
    public static final String LEAD_PROPERTY_FUND_RECORDTYPE = 'lead_synergy'; 
    public static final String LEAD_SUBSCRIPTION_RECORDTYPE = 'lead_subscription'; 
    public static final String ACCOUNT_BUSINESS_RECORDTYPE = 'account_business_account'; 
    //jh - added for salesfix logic 
    public static final String PROJECT_APARTMENT_RECORDTYPE = 'project__c_apartments'; 
    public static final RecordType OPPORTUNITY_APARTMENT_RECORDTYPE = UtilClass.orgRecordTypeMap.get('opportunity_apartments'); 

  
    public static final String PROPERTY_RESERVATION_BUCKET_ACCOUNT;  
    static{
        try {
            if(Test.isRunningTest()) {
                insert new Account(Name = 'Purchaser Details TBC'); 
            }
            else {
                PROPERTY_RESERVATION_BUCKET_ACCOUNT = [SELECT Id FROM Account WHERE Name='Purchaser Details TBC' LIMIT 1].Id;
            }
        }catch (Exception ex){
            throw new NotImplementedException('Purchaser Details TBC account missing. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    //SalesFix : variables used to link Campaign to project enquiry object during lead conversion    
    private static Map<String, Map<String, Campaign[]>> childCampaignMap;
    private static Map<String, Map<String, Campaign>> parentCampaignMap;

    //jh - legacy list 
    public static List<Opportunity> existingOppsToUpdate { get; set; }

    //jh - legacy list for tasks to be inserted 
    public static List<Task> taskList { get; set; }

    //jh - legacy list that needs to be available for salesfix 
    public static List<Account> pAcctList { get; set; }
    public static Id returnOpptyId{ get; set; } 
    //jh - required for salesfix work, map of projects keyed by name
    public static Map<String, Project__c> projectMap { 
        get {
            if(projectMap == null) {
                projectMap = new Map<String, Project__c>(); 
            }
            return projectMap; 
        } 
        set; 
    } 

    public static List<Lead> badLeadResults = new List<Lead>(); 
    public static List<Note> badLeadNotes = new List<Note>(); 

    /**
     *  @author J.H
     *  @date   04/04/2016
     *  @description Filters out only the leads that should be converted, then passes them on to the conversion method.
     *  Each record type may have specific criteria as to what should be converted. 
     *  @history  
     * 04/04/2016 - jh created 
     * 06/04/2016 jh - added property connect filtering of leads 
     * 13/04 jh - added iteration through for DSA lead conversion 
     * - Added iteration through for leads that come in from apartments, new communities & synergy 
     * - Added HR's code for reservation requests  
     * 08/06/2016 - bug fixes for the website project phase 1
     * 23/06/2016 - New req around membership enquiries added the handling into the framework for the new record type 
     */
    public static void leadTriggerHandler(List<Lead> allLeads) {
        List<Lead> leadsToConvert = new List<Lead>();
        
        //property connect leads are only autoconverted if they have a project relationship populated: 
        Map<String, List<Lead>> filteredLeads = UtilClass.filterObjectsByRecordType(allLeads, 'Lead'); 
        if(filteredLeads != null && !filteredLeads.isEmpty()) {
            for(Lead pConnectLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_PROPERTY_CONNECT_RECORDTYPE).DeveloperName)) {
                if(String.isNotBlank(pConnectLead.Project__c) && !pConnectLead.IsConverted && pConnectLead.Auto_Convert__c 
                    && !pConnectLead.IsDeleted) {
                        leadsToConvert.add(pConnectLead); 
                    }
            } 

            for(Lead dsaLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_DSA_RECORDTYPE).DeveloperName)) {

                if(String.isNotBlank(dsaLead.Status) && dsaLead.Status == 'Qualified' && !dsaLead.IsConverted
                    && dsaLead.Auto_Convert__c && !dsaLead.IsDeleted) {
                    //jh - if there are no company fields convert as a person account  
                    leadsToConvert.add(dsaLead); 
                }
            }

            //jh - change to allow website consumers to enquiry about different levels of membership 
            for(Lead membershipEnquiry :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_MEMBERSHIPENQUIRY_RECORDTYPE).DeveloperName)) {
                if(!membershipEnquiry.IsConverted && !membershipEnquiry.IsDeleted) {
                    leadsToConvert.add(membershipEnquiry); 
                }
            }

            for(Lead apartmentLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_APARTMENT_RECORDTYPE).DeveloperName)) {
                if(!apartmentLead.IsConverted && !apartmentLead.IsDeleted && apartmentLead.Auto_Convert__c 
                    && (String.isNotBlank(apartmentLead.Project__c) )) {
                    //jh - added util method to get the projects - check that the project picklist value is in the map.. 
                    //&& String.isNotBlank(UtilClass.activeProjectMap.get(apartmentLead.Project_Picklist__c).Id)) || (String.isNotBlank(apartmentLead.Project_Picklist__c) 
                        
                    leadsToConvert.add(apartmentLead); 
                }
            }

            for(Lead ncLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_NEW_COMMUNITIES_RECORDTYPE).DeveloperName)) {
                if(!ncLead.IsConverted && ncLead.Auto_Convert__c && !ncLead.IsDeleted && (String.isNotBlank(ncLead.Project__c) 
                    )) {
                    //|| (String.isNotBlank(ncLead.Project_Picklist__c) && String.isNotBlank(UtilClass.activeProjectMap.get(ncLead.Project_Picklist__c).Id))
                    leadsToConvert.add(ncLead); 
                }
            }

            for(Lead pfLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_PROPERTY_FUND_RECORDTYPE).DeveloperName)) {
                if(!pfLead.IsConverted && pfLead.Auto_Convert__c && !pfLead.IsDeleted && (String.isNotBlank(pfLead.Project__c))) {
                    leadsToConvert.add(pfLead); 
                }
            }

            for(Lead subLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_SUBSCRIPTION_RECORDTYPE).DeveloperName)) {
                if(!subLead.IsConverted && subLead.Auto_Convert__c && !subLead.IsDeleted) {
                    leadsToConvert.add(subLead); 
                }
            }

            List<Lead> propertyReservationUpdatePrimaryProductStatus = new List<Lead>(); 
            
            for(Lead rrLead :filteredLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).DeveloperName)) {            
                if(rrLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).Id 
                    && rrLead.Approved_Property_Reservation_Lead__c == false && rrLead.isConverted == false && rrLead.Status!='Reservation Declined'){                
                        propertyReservationUpdatePrimaryProductStatus.add(rrLead); 
                }
                

                if(rrLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).Id && rrLead.Approved_Property_Reservation_Lead__c==true 
                    && rrLead.isConverted == false && !rrLead.IsDeleted){
                    leadsToConvert.add(rrLead);
                }
            }

            if(propertyReservationUpdatePrimaryProductStatus != null && !propertyReservationUpdatePrimaryProductStatus.isEmpty()) {
                LeadFramework.updateProductStatus(propertyReservationUpdatePrimaryProductStatus); 
                LeadFramework.submitLeadsForApproval(propertyReservationUpdatePrimaryProductStatus);
            }

            if(leadsToConvert != null && !leadsToConvert.isEmpty()) {
                performLeadConversion(leadsToConvert); 
            }
        }
    }

    /** 
    * @author       H.R
    * @date         28/04/2016
    * @description  Update the product status to available for deleted leads
    **/
    public static void performeAfterDeleteActions(List<Lead> leads) {
        List<String> productIds = new List<String>(); 

        try{
            for(Lead lead : leads){
                if(lead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).Id) {
                    productIds.add(lead.Primary_Product__c); 
                }
            }        
            
            if(productIds != null && !productIds.isEmpty()) {
                updateProductOnDeletedLeads(productIds); 
            }
        }catch (Exception ex){
            throw new NotImplementedException('Product update failed, after lead deletion. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /** 
    * @author       J.H
    * @date         07/03/2016
    * @description  Routes the lead conversion based upon its record type. 
    * Calls worker methods that are required for record type.  
    * 10/03 updated to use a list of lead convert contexts for conversion 
    * 19/03 - HR - Added lead conversion logic to convert property reservation leads
    **/
    public static void performLeadConversion(List<Lead> leadsToBeConverted) {
        //HR - Id to lead map to be accesed for passing to the future method
        Map<String, Lead> allLeadsMap = new Map<String, Lead>();
        
        try{
            allLeadsMap.putAll(leadsToBeConverted);
            
            //jh dedup the leads against existing accounts & opportunities 
            deduplicateLeadEmailAgainstAccounts(leadsToBeConverted); 

            //build a map of opportunities by project name - code taken from legacy class  
            Map<String,List<Opportunity>> oppsInProject = buildOpportunityListForProject(leadsToBeConverted);  
            
            //opportunity shares will need to be inserted after processing 
            oppSharesForInsert = new List<OpportunityShare>(); 
            List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>(); 

            //jh - store a map of leads that are company related - there account record types will need to be updated post conversion. 
            Map<String, Lead> businessLeads = new Map<String, Lead>(); 
            //jh iterate through the leads and pull out their record type names by ID. 
            for(Lead theLead :leadsToBeConverted) {
                //jh all actions should be done through the lead convert class (OOB)
                //worker functions just update the current lead convert context as apporpriate 
                Database.LeadConvert lc = new Database.LeadConvert(); 
                lc.setLeadId(theLead.Id); 
                lc.setConvertedStatus('Qualified');

                //try and set the owner of the converted records, this can't affect the orginal lead owner.
                lc.setOwnerId(UserInfo.getUserId());
               

                //jh based on the separate record types build the lead conversion logic 
                //need to pass in the lead conversion context into worker methods for update 
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_APARTMENT_RECORDTYPE).Id) {                
                    createAccountOnConversion(true, lc, theLead); 
                    createOpportunityOnConversion(lc, theLead, oppsInProject); 
                }

                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_NEW_COMMUNITIES_RECORDTYPE).Id) {
                    createAccountOnConversion(true, lc, theLead); 
                    createOpportunityOnConversion(lc, theLead, oppsInProject); 
                }
                //jh - property connect enquiries should create a business or person acc. 
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_PROPERTY_CONNECT_RECORDTYPE).Id) {
                    createAccountOnConversion(true, lc, theLead); 
                    if(String.isNotBlank(theLead.Company) || String.isNotBlank(theLead.Company_Synergy__c) ||
                        String.isNotBlank(theLead.ABN__c) || String.isNotBlank(theLead.ACN__c)) {
                      
                         businessLeads.put(theLead.Id, theLead);  
                    }
                      lc.setDoNotCreateOpportunity(true);
                }

                //jh 23/06/2016 - new req, create a person account with silver membership & tasks for subsequent enquiries 
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_MEMBERSHIPENQUIRY_RECORDTYPE).Id) {
                    createAccountOnConversion(true, lc, theLead); 
                    lc.setDoNotCreateOpportunity(true); 
                }

                //jh - subscription leads should just convert into a account with the subscription options (no op)
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_SUBSCRIPTION_RECORDTYPE).Id) {
                    createAccountOnConversion(true, lc, theLead); 
                    lc.setDoNotCreateOpportunity(true); 
                }

                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_DSA_RECORDTYPE).Id) {
                    if(String.isNotBlank(theLead.Company) || String.isNotBlank(theLead.Company_Synergy__c) ||
                        String.isNotBlank(theLead.ABN__c) || String.isNotBlank(theLead.ACN__c)) {

                        lc.setDoNotCreateOpportunity(true);  
                        businessLeads.put(theLead.Id, theLead); 
                        createAccountOnConversion(true, lc, theLead); 
                    }
                    else {
                        createAccountOnConversion(true, lc, theLead); 
                        createOpportunityOnConversion(lc, theLead, oppsInProject); 
                    }
                }
                
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).Id){
                    lc.setOwnerId(UserInfo.getUserId());
                    lc.setAccountId(PROPERTY_RESERVATION_BUCKET_ACCOUNT);               
                }

                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_PROPERTY_FUND_RECORDTYPE).Id) {
                    lc.setOwnerId(UserInfo.getUserId()); 
                    createAccountOnConversion(true, lc, theLead); 
                    lc.setDoNotCreateOpportunity(true); 
                }

                leadConverts.add(lc); 
            }

            //jh - if the list of contexts has values go through and convert them 
            //each context could be setup differently based on the lead record types 
            List<Database.LeadConvertResult> leadConversionResult = new List<Database.LeadConvertResult>(); 
            if(leadConverts != null && !leadConverts.isEmpty()) {
                try {
                    leadConversionResult = Database.convertLead(leadConverts);   
                }
                catch (Exception ex) {
                    //jh - there's been a failure 
                    for(Database.LeadConvertResult res :leadConversionResult) {
                        badLeadResults.add(addLeadToBadLeadQueue(new Lead(Id = res.getLeadId()))); 
                        //TODO: Fix the error message
                        badLeadNotes.add(createNoteForBadLead(res.getLeadId(), ''));
                    }
                    throw new NotImplementedException('Failed to perform lead conversion. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
                }

                if(leadConversionResult != null && !leadConversionResult.isEmpty()) {
                    postConversionProcessing(leadConversionResult, allLeadsMap, businessLeads, oppsInProject); 
                }
            }

            //jh - update an opportunities which are in the update list 
            if(existingOppsToUpdate != null && !existingOppsToUpdate.isEmpty()) {
                update existingOppsToUpdate; 
            }

            //jh - refactored legacy code to be bulkified 
           if(taskList != null && !taskList.isEmpty()) {
                upsert taskList; 
            } 

              //both these lists should be populated 
            if(badLeadResults != null && !badLeadResults.isEmpty() && badLeadNotes != null && !badLeadNotes.isEmpty()) {
                update badLeadResults; 
                insert badLeadNotes; 
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed to perform lead conversion. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
     * @author      JH 
     * @date        04/04/2016
     * @description Moved existing post conversion logic into a separate method 
     * 18/05/2016 JH - Salesfix merge changes 
     */
    public static void postConversionProcessing(List<Database.LeadConvertResult> conversionResults, Map<String,Lead> allLeadsMap, 
        Map<String, Lead> businessLeads, Map<String,List<Opportunity>> oppsInProject) {
        Map<String, String> opps = new Map<String, String>();
        Set<String> optionIds = new Set<String>();
        Map<String, String> contactOppIdMap = new Map<String, String>();

        List<Account> businessAccountsToUpdate = new List<Account>(); 
      
        //jh - required for salesfix 
        List<Project_Enquiry__c> paList = new List<Project_Enquiry__c>(); 

        //salesfix/web merge 
        Set<Id> updateOpptySet = new Set<Id>(); 
        Set<Id> updateAccSet = new Set<Id>(); 
        //Map to Track the owners of New Opportunities based on lead ownership
        Map<Id, Id> oppOwnerMap = new Map<Id, Id>(); 
        //end
        //jh - list of person accs to update for property connect conversions. 
        List<Account> personAccsForUpdate = new List<Account>(); 

        //jh - increase performance by only doing this if there's a membership lead 
        Group membershipEnquiryGroup = [SELECT Id 
                                        FROM Group 
                                        WHERE Type = 'Regular' 
                                        AND DeveloperName = 'Membership_Enquiries' limit 1]; 

        GroupMember groupMember = [SELECT UserOrGroupId FROM GroupMember WHERE GroupId = :membershipEnquiryGroup.Id limit 1]; 
        
        try{
            for(Database.LeadConvertResult result : conversionResults){
                //jh - need to specifically filter out only property reservations  
                Lead theLead = allLeadsMap.get(result.getLeadId()); 
                if(theLead != null) {
                    //reservation request processing for options 
                    if(theLead.RecordTypeID == UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).Id) {
                        contactOppIdMap.put(result.getContactId(), result.getOpportunityId());
                        opps.put(result.getOpportunityId(), allLeadsMap.get(result.getLeadId()).Upgrade_Option_s_Id__c);
                        if(allLeadsMap.get(result.getLeadId()).Upgrade_Option_s_Id__c!=null){
                            for(String s : allLeadsMap.get(result.getLeadId()).Upgrade_Option_s_Id__c.split(','))
                                optionIds.add(s);
                        }
                    }

                    //jh - fix for issue where sub checkboxes weren't being copied onto an existing person acc
                    //this was due to the standard sf conversion logic only performing a merge on fields that don't have a value 
                    if(theLead.RecordTypeID == UtilClass.orgRecordTypeMap.get(LEAD_SUBSCRIPTION_RECORDTYPE).Id) {
                        if(duplicateAccEmail != null && duplicateAccEmail.get(theLead.Email) != null 
                            && String.isNotBlank(duplicateAccEmail.get(theLead.Email).Id)) {
                                if(theLead.Sub_DSA__c || theLead.Sub_OH_Corporate__c || theLead.Sub_OH_Property_Funds__c) {
                                    //jh - if any subscriptions are true update the p acc   
                                    Account updateAcc = new Account(Id = duplicateAccEmail.get(theLead.Email).Id);
                                    if(theLead.Sub_DSA__c) {
                                        updateAcc.Sub_DSA__pc = true; 
                                    }
                                    if(theLead.Sub_OH_Corporate__c) {
                                        updateAcc.Sub_OH_Corporate__pc = true; 
                                    }
                                    if(theLead.Sub_OH_Property_Funds__c) {
                                        updateAcc.Sub_OH_Property_Funds__pc = true; 
                                    }

                                    personAccsForUpdate.add(updateAcc); 
                                }
                        }  
                    }

                    //jh - for property connect conversions need to update the person acc to have a website category.. 
                    if(theLead.RecordTypeID == UtilClass.orgRecordTypeMap.get(LEAD_MEMBERSHIPENQUIRY_RECORDTYPE).Id) {
                        //jh - if its not in the map its new otherwise the acc already existed 
                        String whatId = ''; 
                        if(duplicateAccEmail != null && duplicateAccEmail.get(theLead.Email) != null 
                            && String.isNotBlank(duplicateAccEmail.get(theLead.Email).Id)) { 
                            
                            //jh - if the account already exists but has no website user category 
                            if(String.isBlank(duplicateAccEmail.get(theLead.Email).Website_User_Category__c)) {  
                                Account updateAcc = new Account(Id = duplicateAccEmail.get(theLead.Email).Id, Website_User_Category__c = 'Silver'); 
                                personAccsForUpdate.add(updateAcc); 
                            }
                               
                            whatId = duplicateAccEmail.get(theLead.Email).Id; 
                        }
                        else {
                            //jh - new person account was created so default to silver   
                            Account updateAcc = new Account(Id = result.getAccountId(), Website_User_Category__c = 'Silver'); 
                            whatId = result.getAccountId(); 
                            personAccsForUpdate.add(updateAcc); 
                        } 

                        if(String.isNotBlank(theLead.Comments__c)) {
                            String subject = ''; 
                            if(theLead.Comments__c.toLowerCase().Contains('gold')) {
                                subject = 'Call - Gold Enquiry'; 
                            }
                            else if(theLead.Comments__c.toLowerCase().Contains('plat')) {
                                subject = 'Call - Platinum Enquiry'; 
                            }
                            
                            if(String.isNotBlank(subject)) {
                                createTaskAfterConversion(theLead, groupMember.UserOrGroupId, subject, whatId);
                            } 
                        }
                    }

                    //jh - not sure if this code was from salesfix or another project but is required for ownership setup 
                    Boolean existingContact = false; 
                    Boolean existingOppty = String.isBlank(result.getOpportunityId()) ? true : false; 
                    String acctId = ''; 

                    Map<String, Boolean> personAcctExistsMap = personExists(theLead); 
                    for(String theAcctId :personAcctExistsMap.keySet()) {
                        acctId = theAcctId; 
                        existingContact = personAcctExistsMap.get(theAcctId); 
                    }

                    //--- add for fix start ---
                    if(!existingContact || !existingOppty){
                        updateOpptySet.add(result.getOpportunityId());
                        updateAccSet.add(result.getAccountId());
                        //here we also want to track the original lead owner against the opportunity
                        oppOwnerMap.put(result.getOpportunityId(), theLead.OwnerId);
                    }

                    if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_APARTMENT_RECORDTYPE).Id && projectMap.containsKey(theLead.Project_Picklist__c) 
                        && projectMap.get(theLead.Project_Picklist__c).RecordTypeId == UtilClass.orgRecordTypeMap.get(PROJECT_APARTMENT_RECORDTYPE).Id
                        && projectMap.get(theLead.Project_Picklist__c).Business_Unit__c == 'Apartments'
                        && String.isEmpty(theLead.Channel_Account__c)){
                        Id paAccntId = existingContact ? acctId : result.getAccountId();
                        Id paPrjId = projectMap.get(theLead.Project_Picklist__c).Id;   
                        Id paCampId = getCampaignId(theLead);
                        Id paOppId = existingOppty ? returnOpptyId : result.getOpportunityId() ;    
                        Boolean isPrimary = true;
                        if(existingOppty){
                            //jh - structure was radically different from original one method, for now have just used the index..   
                            if(oppsInProject != null && !oppsInProject.isEmpty() && oppsInProject.get(theLead.Email)[0] != null) {
                                Opportunity opp = oppsInProject.get(theLead.Email)[0];
                                if(opp != null && opp.Project_Enquiries__r != null && opp.Project_Enquiries__r.size() > 0) 
                                    isPrimary = false;    
                            }
                        }
                        Project_Enquiry__c pa = createProjectAssignment(paAccntId,paPrjId,paCampId,paOppId,theLead,isPrimary);                      
                        paList.add(pa);   
                    }
                    //end 

                    createTaskOnConversion(false, theLead, result, result.getOpportunityId(), String.isBlank(result.getOpportunityId())); 
                }

                if(businessLeads.get(result.getLeadId()) != null) {
                    Account acc = new Account(Id=result.getAccountId(), RecordTypeId=UtilClass.orgRecordTypeMap.get(ACCOUNT_BUSINESS_RECORDTYPE).Id);
                    businessAccountsToUpdate.add(acc);  
                }

                //jh - leads that failed to convert must have bad data therefore throw them in the bad lead queue 
                if(!result.isSuccess()) {
                   badLeadResults.add(addLeadToBadLeadQueue(new Lead(Id = result.getLeadId()))); 
                   //jh - if there's a failure just return the top level error message. 
                   badLeadNotes.add(createNoteForBadLead(result.getLeadId(), result.getErrors()[0].getMessage()));
                }
            }

            //jh previously always hit this block of code before merge have updated to only go in if one of the sets isn't empty.. 
            if(!updateAccSet.isEmpty() || !updateOpptySet.isEmpty()) {
                List<Opportunity> opportunitiesToUpdate = setOpportunityAccountOwnership(updateOpptySet, updateAccSet, oppOwnerMap); 
                if(opportunitiesToUpdate != null && !opportunitiesToUpdate.isEmpty()){
                   update opportunitiesToUpdate; 
                }
            }

            if(personAccsForUpdate != null && !personAccsForUpdate.isEmpty()) {
                update personAccsForUpdate; 
            }

            if(!ContactOppIdMap.isEmpty()){
                moveLeadAttachmentsToOpps(ContactOppIdMap);
            }

            if(businessAccountsToUpdate != null && !businessAccountsToUpdate.isEmpty()) {
                update businessAccountsToUpdate; 
            }

            if(!opps.isEmpty()) {
                propertyreservationConvertedOpps(opps, optionIds);
            }

            //SalesFix : insert the new project assignment records
            if(!paList.isEmpty()) insert paList;

        }catch (Exception ex){
            throw new NotImplementedException('Post conversion failed. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
     * @author HR
     * @date 05/05/2016
     * @description Attachments from leads to opportunities on conversion
    **/
    public static void moveLeadAttachmentsToOpps(Map<String, String> ContactOppIdMap){
        List<Attachment> attachments = new List<Attachment >();

        try{
            for(Attachment  a : [SELECT Id, ParentId, Body, BodyLength, ContentType, Description, IsPrivate, Name, OwnerId 
                                FROM Attachment  
                                WHERE ParentId IN: ContactOppIdMap.keySet()]){
                Attachment att = a.clone(false, true, false, false);
                att.ParentId = ContactOppIdMap.get(att.ParentId);
                attachments.add(att);
            }

            if(!attachments.isEmpty()){
                insert attachments;            
            }
        }catch (Exception ex){
            throw new NotImplementedException('Unable to create Attachment(s): '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
     * @author JH 
     * @date 18/05/2016 
     * @description for web merge - found new code that sets ownership for the accts & opps moved into this method. 
     */
    public static List<Opportunity> setOpportunityAccountOwnership(Set<Id> updateOpptySet, Set<Id> updateAccSet, Map<Id, Id> oppOwnerMap) {
        //calling opptunityUtility to update oppty
        //set oppty owner Id
        List<Opportunity> newOpptyList = new List<Opportunity>();
        newOpptyList = [Select OwnerId, AccountId, LeadSource, Project__c, Project_Picklist__c, 
                        Web_2_Lead__c, Notify_Owner__c, RecordTypeId,Business_Unit__c
                        From opportunity Where Id in: updateOpptySet];
        List<Opportunity> updateOpptyList = new List<Opportunity>();     
        //set account owner id
        List<Account> newAccList = new List<Account>();
        newAccList = [select OwnerId from Account where Id in: updateAccSet];
        List<Account> updateAccList = new List<Account>();
        
        //for each new account, update the owner to sys admin user
       
        for(Account a: newAccList){
            a.OwnerId = getAdminUserId();
            updateAccList.add(a);
        }
        //update the accounts here
        update updateAccList;
        //if(opptyList.isEmpty()){
        for(Opportunity o : newOpptyList){
            //SalesFix : skip the opportunity owner assignment for Apartments - its handled in process builder now
            if(o.RecordTypeId == OPPORTUNITY_APARTMENT_RECORDTYPE.Id && o.Business_Unit__c == 'Apartments')
                continue;
            
            if(o.Web_2_Lead__c){
                if(projectMap !=null && !projectMap.isEmpty()) {
                    Id opptyOwnerId = (projectMap.get(o.Project_Picklist__c)).Owner_Assignment__c;
                    o.ownerId = opptyOwnerId;
                    o.Notify_Owner__c = true;
                }
            }else{
                //set as lead owner, not current logged in user
                //Has to be done here as the convert process sets the owner as the context user due to privacy settings
                /* Commented Out Because this is Being Set on Convert. */
                o.ownerId = oppOwnerMap.get(o.Id);
            }
            updateOpptyList.add(o);
        }
        return updateOpptyList; 
    }

    /**
     * @author JH 
     * @date 29/04/2016 
     * @description If the lead has a project picklist value but no project lookup try & set this based on the project name. 
     */
    public static void setLeadProjectLookup(List<Lead> leads) {
        try{
            for(Lead theLead :leads) {
                if(String.isNotBlank(theLead.Project_Picklist__c) && String.isBlank(theLead.Project__c) && !theLead.IsConverted 
                    && !theLead.IsDeleted) {
                    if(UtilClass.activeProjectMap.containsKey(theLead.Project_Picklist__c)) {
                        theLead.Project__c = UtilClass.activeProjectMap.get(theLead.Project_Picklist__c).Id; 
                    }
                    else {
                        addLeadToBadLeadQueue(theLead); 
                        createNoteForBadLead(theLead.Id, 'The project name doesnt match a project in salesforce.'); 
                    }
                }
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed. Description: '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    } 

    /**
     * @author JH 
     * @date 14/04/2016 
     * @description adds the list of leads and creates notes against them as to why they are a bad lead. 
     * @param badLeads List of leads which are classified as bad leads (Classification happens outside of this method) 
     */
    public static Lead addLeadToBadLeadQueue(Lead badLead) {
        //HR - Get BadLead Queue Id
        try{
            Group badLeadQueue = [SELECT Id FROM Group where Name = 'Bad Leads' and Type = 'Queue' LIMIT 1];
            badLead.OwnerId = badLeadQueue.Id; 
            return badLead;
        }catch (Exception ex){
            throw new NotImplementedException('Unable to find the badLeadQueue. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    public static Note createNoteForBadLead(String leadId, String error) {
        try{
            //jh - add a note to the lead as to why its bad 
            Note leadNote = new Note(ParentId = leadId, Title = 'Conversion Failed', 
                                    Body = 'Convert failed due to the following errors: ' + error); 
            return leadNote; 
        }catch (Exception ex){
            throw new NotImplementedException('Unable to create Note for badLead. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    
    /** 
    * @author       HR
    * @date         01/04/2016
    * @description  Future method to update the opportunity stage, record type and the owner
    *               create property selection record for the option/upgrade and the primary product 
    **/
    @future
    public static void propertyreservationConvertedOpps(Map<String, String> allOppsMap, Set<String> optionIds){
        List<Opportunity> opps = new List<Opportunity>();
        List<Item__c> propertyselection = new List<Item__c>();
        Set<String> oppIds = allOppsMap.keySet();
        Set<String> optionProductIds = optionIds;
        Set<String> primaryProductIds = new Set<String>();
        
        try{
            String qry = 'SELECT '+UtilClass.getAllFields('Opportunity').get('Opportunity')+', Project__r.Owner_Assignment__c FROM Opportunity WHERE Id IN: oppIds';
            Map<String, Opportunity> allOpps = new Map<String, Opportunity>();
            
            for(Opportunity o : Database.query(qry))
                allOpps.put(o.Id, o);

            for(Opportunity o : allOpps.values()){
                optionProductIds.add(o.Primary_Product__c);
                primaryProductIds.add(o.Primary_Product__c);
            }
            
            Map<String, Product__c> products;

            if(optionIds!=null || !optionIds.isEmpty()){
                if(products == null) products = new Map<String, Product__c>();
                for(Product__c p : Database.query('SELECT '+UtilClass.getAllFields('Product__c').get('Product__c')+', RecordType.Name FROM Product__c WHERE Id IN: optionProductIds'))
                    products.put(p.Id, p); 
            }

            Map<String, Double> productPrice = new Map<String, Double>();
            for(Price__c p :[SELECT Price__c, Primary_Product__c, Product__c FROM Price__c WHERE Primary_Product__c IN: primaryProductIds AND Product__c IN: optionProductIds]){
                productPrice.put(p.Primary_Product__c+''+p.Product__c, p.Price__c);
            }

            for(Opportunity o : allOpps.values()){
                opps.add(new Opportunity(   Id              =   o.Id, 
                                            StageName       =   'Reservation', 
                                            NextStep        =   'Set appointment to sign contracts',
                                            RecordTypeId    =   UtilClass.orgRecordTypeMap.get('opportunity_portal').Id,
                                            OwnerId         =   allOpps.get(o.Id).Project__r.Owner_Assignment__c));
                
                propertyselection.add(new Item__c(  Opportunity__c          =   o.Id, 
                                                    Product__c              =   o.Primary_Product__c, 
                                                    Primary_Product__c      =   o.Primary_Product__c, 
                                                    Status__c               =   'Reservation',
                                                    Price__c                =   products!=null && products.containsKey(o.Primary_Product__c) ? products.get(o.Primary_Product__c).List_Price__c : 0,
                                                    Product_Record_Type__c  =   products!=null && products.containsKey(o.Primary_Product__c) ? products.get(o.Primary_Product__c).RecordType.Name : ''));
                if(allOppsMap.get(o.Id)!=null){
                    for(String s : allOppsMap.get(o.Id).split(',')){
                        Id tempId = Id.valueOf(s);
                        propertyselection.add(new Item__c(  Opportunity__c          =   o.Id, 
                                                            Product__c              =   tempId, 
                                                            Primary_Product__c      =   o.Primary_Product__c, 
                                                            Status__c               =   'Reservation',
                                                            //Price__c                =   products!=null && products.containsKey(tempId) ? products.get(tempId).List_Price__c : 0,
                                                            Price__c                =   productPrice!=null && productPrice.containsKey(o.Primary_Product__c+''+tempId) ? productPrice.get(o.Primary_Product__c+''+tempId) : 0,
                                                            Product_Record_Type__c  =   products!=null && products.containsKey(tempId) ? products.get(tempId).RecordType.Name : ''));
                    }
                }
            }

            if(!opps.isEmpty()) {
                update opps;
            }
            if(!propertyselection.isEmpty()) {
                insert propertyselection;
            }
        }catch (Exception ex){
            ApexError.AddException(new NotImplementedException('Unable to add the property selections in the Future method. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString()));
            throw new NotImplementedException('Unable to add the property selections. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    
    /**
    * @author       JH
    * @date         10/03/2016
    * @description  builds a map of all the opportunities that are related to the same projects as the list of leads. 
    * map key is email. Taken from the legacy code. 
    * 17/05/2016 JH - Merged Salesfix changes into here, SalesFix : change in opportunity matching logic  
    * get the most recent open opporuntiy instead of the opportunituy with the same project 
    **/
    public static Map<String,List<Opportunity>> buildOpportunityListForProject(List<Lead> leads) {
        system.assert(leads!=null); 
        //jh build  a set of the lead projects 
        Set<String> leadProjects = new Set<String>(); 
        //jh - was required for the salesfix code.. 
        Set<String> enquirySet = new Set<String>(); 

        try{
            for(Lead theLead :leads) {
                if(String.isNotBlank(theLead.Project_Picklist__c)) {
                    leadProjects.add(theLead.Project_Picklist__c); 
                }

                if(String.isNotBlank(theLead.Enquiry_Source__c)) {
                    enquirySet.add(theLead.Enquiry_Source__c); 
                }
            }

            //jh required for salesfix 
             //To do: project set
            List<Project__c> projectList = new List<Project__c>();
            projectList = [select id, Name,RecordTypeId,Owner_Assignment__c,Business_Unit__c from Project__c where Name in: leadProjects];
            for(Project__c p : projectList){
                projectMap.put(p.Name, p);
            }

            List<Opportunity> opps = [SELECT Name, OwnerId, Project__c, Project__r.Name, 
                                        LastModifiedDate, Owner.Email, AccountId, Notify_Owner__c, RecordTypeId
                                     FROM Opportunity
                                     WHERE Project__r.Name in: leadProjects 
                                     AND IsClosed =: false
                                     AND AccountId != null
                                     ORDER BY LastModifiedDate desc];

            Map<String, List<Opportunity>> opptyMap = new Map<String, List<Opportunity>>();
            if(!opps.isEmpty()){
                for(Opportunity o : opps){
                    List<Opportunity> oppList = new List<Opportunity>();
                    // only put the first one as it has the most recent last modified date
                    if(!opptyMap.containsKey(o.Project__r.Name)){
                        oppList.add(o);
                    }else{
                        oppList = opptyMap.get(o.Project__r.Name);
                        oppList.add(o);
                    }
                    opptyMap.put(o.Project__r.Name, oppList);
                }
            }

            if(pAcctList != null && !pAcctList.isEmpty()) {
                //SalesFix : change in opportunity matching logic  
                //get the most recent open opporuntiy instead of the opportunituy with the same project
                List<Opportunity> aptOpptyList = new List<Opportunity>();
                aptOpptyList = [SELECT Name, OwnerId, Project__c, Project__r.Name,
                             LastModifiedDate, Owner.Email, AccountId, Account.PersonEmail, Notify_Owner__c,
                             (SELECT Id FROM Project_Enquiries__r), RecordTypeId
                             FROM Opportunity
                             WHERE IsClosed =: false 
                             AND StageName != 'Reservation'
                             AND AccountId in: pAcctList
                             AND RecordTypeId =: OPPORTUNITY_APARTMENT_RECORDTYPE.Id
                             AND Business_Unit__c = 'Apartments'
                             AND Sales_Channel__c != 'Channel'
                             ORDER BY Account.PersonEmail,CreatedDate desc];

                //jh merged this from salesfix
                //SalesFix : Create a map of Email and the latest opp from the matched account
                //Map<String, Opportunity> aptOpptyMap = new Map<String, Opportunity>();
                
                if(!aptOpptyList.isEmpty()){
                    for(Opportunity o : aptOpptyList){
                        if(!opptyMap.containsKey(o.Account.PersonEmail))
                            opptyMap.put(o.Account.PersonEmail, new List<Opportunity>{o});
                    }
                }
                //jh - merged from salesfix.. 
                //SalesFix : identify the matching campaign based on project name and enquire source using the same logic from opportunity utitlity campaign association
                childCampaignMap = new Map<String, Map<String, Campaign[]>>();
                parentCampaignMap = new Map<String, Map<String, Campaign>>();
                String camQuery = 'select Id, Name, ParentId, Channels__c, StartDate, EndDate, Project__c, Project__r.Name from Campaign where isActive = true and Project__r.Name in: leadProjects ';
                if(!enquirySet.isEmpty()){
                    camQuery += 'and Channels__c includes (';
                    for(String s: enquirySet){
                        camQuery += '\''+s+'\',';
                    }
                    camQuery = camQuery.removeEnd(',');
                    camQuery += ') ';
                }
                camQuery += 'order by StartDate, createdDate asc';
                Campaign[] allCams = database.query(camQuery);
                if(allCams != null && !allCams.isEmpty()) {
                    buildCampaignMaps(allCams);
                }
            }

            return opptyMap; 
        }catch (Exception ex){
            throw new NotImplementedException('Failed to create OpportunityListForProject. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
    * @author       JH
    * @date         10/03/2016
    * @description  Based on a list of leads deduplicates against person accounts. Returns a map of email addresses 
    * and keyed to the accounts 
    **/
    public static void deduplicateLeadEmailAgainstAccounts(List<Lead> leads) {
        
        duplicateAccEmail = new Map<String, Account>(); 
        Set<String> leadEmailsForDedup = new Set<String>(); 
        for(Lead theLead :leads) {
            if(String.isNotBlank(theLead.Email)) {
                leadEmailsForDedup.add(theLead.Email); 
            }
        }

        try{
            List<Account> matchingAccounts = [Select Id, PersonEmail, Website_User_Category__c, PersonContactId 
                                              From Account
                                              WHERE PersonEmail IN :leadEmailsForDedup
                                              AND IsPersonAccount = true
                                              ORDER BY LastModifiedDate DESC]; 
            if(pAcctList == null) {
                pAcctList = new List<Account>(); 
            }
            //jh - needed this for the salesfix work 
            pAcctList.addAll(matchingAccounts); 

            if(matchingAccounts != null && !matchingAccounts.isEmpty()) {
                for(Account dupAccount :matchingAccounts) { 
                    if(leadEmailsForDedup.contains(dupAccount.PersonEmail)) {
                        duplicateAccEmail.put(dupAccount.PersonEmail, dupAccount);
                    }
                }
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed to deduplicateLeadEmailAgainstAccounts. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
    * @author       JH
    * @date         07/03/2016
    * @description  Checks if the lead is a duplicate 
    **/
    public static Boolean leadIsDuplicate(Lead theLead) {
        if(duplicateAccEmail.get(theLead.Email) != null) {
            return true; 
        }

        return false; 
    }

    /**
    * @author       JH
    * @date         09/03/2016
    * @description  determines if the lead is a individual or business  
    **/
    public static Boolean leadIsIndividual(Lead theLead) {
        //JH - if any company related fields are populated return false 
        if(String.isNotBlank(theLead.ABN__c) || String.isNotBlank(theLead.Company) 
            || String.isNotBlank(theLead.ACN__c)) {
            return false; 
        }
        else {
            return true; 
        }
    }

    /**
    * @author       JH 
    * @date         10/03/2016
    * @description  As part of the lead conversion process create a individual(person) account or a business account with contact. 
    *               dedup the accounts by email  
    **/
    public static Database.LeadConvert createAccountOnConversion(Boolean isIndividual, Database.LeadConvert leadContext, Lead theLead) {
        try{
            if(leadIsDuplicate(theLead)) {
                //jh if the lead is a dup set the existing acc id  
                leadContext.setAccountId(duplicateAccEmail.get(theLead.Email).Id); 
            }

            return leadContext; 
        }catch (Exception ex){
            throw new NotImplementedException('Failed to createAccountOnConversion. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /** 
    * @author       JH 
    * @date         10/03/2016
    * @description  if the person account already exists and there is a related opportunity 
    * with the same project as the lead then on convert merge the lead with the existing 
    * opportunity 
    */ 
    public static Database.LeadConvert createOpportunityOnConversion(Database.LeadConvert leadContext, Lead theLead, Map<String, List<Opportunity>> oppsForProjects) {
        try{
            if(String.isNotBlank(leadContext.getAccountId())) {

                String opptyId = ''; 
                Boolean existingOppty = false;
                Boolean existingContact = false; 
                String ownerEmail = ''; 
                Id acctId = null; 

                if(existingOppsToUpdate == null) {
                    existingOppsToUpdate = new List<Opportunity>(); 
                }

                Map<String, Boolean> personAccExistsMap = personExists(theLead); 
                for(String theAcctIds :personAccExistsMap.keySet()) {
                    acctId = theAcctIds; 
                    existingContact = personAccExistsMap.get(theAcctIds); 
                }
                //SalesFix : use the new logic only for apartment opps & retain the old logic for non apartment records
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_APARTMENT_RECORDTYPE).Id && projectMap.containsKey(theLead.Project_Picklist__c) 
                    && projectMap.get(theLead.Project_Picklist__c).RecordTypeId == UtilClass.orgRecordTypeMap.get(PROJECT_APARTMENT_RECORDTYPE).Id 
                    && projectMap.get(theLead.Project_Picklist__c).Business_Unit__c == 'Apartments'
                    && String.isEmpty(theLead.Channel_Account__c)){ //&& oppsForProjects.containsKey(theLead.Email)){ 
                    if(oppsForProjects.containsKey(theLead.Email)) {
                        Opportunity o =  oppsForProjects.get(theLead.Email)[0];
                        if(o.AccountId == acctId){
                            opptyId = o.Id;
                            existingOppty = true;
                            ownerEmail = theLead.Owner.Email;
                            Opportunity op = o;
                            if(op.OwnerId != userInfo.getUserId()){
                                op.Notify_Original_Owner__c = true; 
                            }
                            existingOppsToUpdate.add(op);
                            returnOpptyId = opptyId;
                            shareOpportunityRecord(o); 
                            //jh - 
                            leadContext.setDoNotCreateOpportunity(true); 
                        }
                    }
                } 
                else if(oppsForProjects.containsKey(theLead.Project_Picklist__c)) {
                    //jh - taken from legacy code sa
                     // list of all oppty with same project name
                    List<Opportunity> oppList = oppsForProjects.get(theLead.Project_Picklist__c);
                    for(Opportunity o : oppList){
                        // found existing oppty - same account and same project -- confirmed with david 
                        if(o.AccountId == duplicateAccEmail.get(theLead.Email).Id) {
                            if(existingOppsToUpdate == null) {
                                existingOppsToUpdate = new List<Opportunity>(); 
                            }
                            opptyId = o.Id;
                            existingOppty = true;
                            //jh - following is a refactor of the legacy code
                            //so there is a existing opportunity linked to the existing account 
                            //don't create a opportunity 
                            leadContext.setDoNotCreateOpportunity(true); 

                            //jh - if the above is true the opp name must be null (at time of writing)
                            leadContext.setOpportunityName(null); 
                            ownerEmail = theLead.Owner.Email;
                            Opportunity op = o;
                            //v1.07 start
                            //op.Notify_Owner__c = true;
                            //not same person then notify original owner
                            if(op.OwnerId != userInfo.getUserId()){
                                op.Notify_Original_Owner__c = true; 
                            }

                            //end - jh need to bulkify the update  
                            existingOppsToUpdate.add(op);
                            //v1.06 
                            returnOpptyId = opptyId;
                            // v1.04 sharing rule
                            // only add to sharing list if the current oppty owner is not same as current login

                            //jh - refactored the legacy sharing block into separate method :
                            shareOpportunityRecord(o); 
                            break; 
                        }
                        else {
                            //jh - in this case the opportunity doesn't exist so set its name 
                            //taken from legacy code 
                            // set oppty name
                            String d = String.valueOf(theLead.Date_of_Enquiry__c);
                            d = d.subString(8,10) + '-' + d.subString(5,7) + '-' + d.subString(0,4);
                            //d = d.subString(0,d.length()-9);
                            leadContext.setOpportunityName(theLead.LastName + ' - ' + theLead.Project_Picklist__c + ' - ' + d);
                        }
                    }
                }
            }
            return leadContext; 
        }catch (Exception ex){
            throw new NotImplementedException('Failed to createOpportunityOnConversion. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
    * @author       JH 
    * @date         10/03/2016
    * @description took this from existing code on the lead utility
    */ 
    public static void createTaskOnConversion(Boolean isCompleted, Lead theLead, Database.LeadConvertResult lcr, 
        String oppId, Boolean existingOpp) {
        if(taskList == null) {
            taskList = new List<Task>(); 
        }
        Boolean isWebToLead = theLead.Web_2_Lead__c;
        String firstName = theLead.FirstName != null ? theLead.FirstName : '';
        String lastName = theLead.LastName != null ? theLead.LastName : '';
        String phone = theLead.Phone != null ? theLead.Phone : '';
        String email = theLead.Email != null ? theLead.Email : '';
        String comments = theLead.Comments__c != null ? theLead.Comments__c : '';
        String leadSource = theLead.LeadSource;
        String leadEnquirySource = theLead.Enquiry_Source__c;
        String leadWebFormSource = theLead.Web_Form_Source__c != null ? theLead.Web_Form_Source__c : '';
        String propertyType = theLead.Property_Type__c;
        String pricePoint = theLead.Price_Point__c;
        String buyerType = theLead.Buyer_Type__c;
        String purchaseWindow = theLead.Purchase_Window__c;
        String suburb = theLead.Suburb__c;

        // for creating task only create task when
        // enquiry method = web form
        // added by PE: 3rd Oct 2012 - checks Web 2 Lead 
        // Salesfix: added second condition to check the field skip web form task 
        if(theLead.Enquiry_Method__c == 'Web Form' && !theLead.Skip_Web_Form_Task__c){
            if(isWebToLead){ //-- v1.01 commented out // reversed back v1.02
                Task taskRec = new Task();
                taskRec.Subject = 'Submitted Web Form';
                taskRec.Category__c = 'Web Form';
                taskRec.Type = 'Web Form';
                taskRec.Priority  = 'Normal';
                taskRec.Is_New__c = true;
                taskRec.Status = 'Completed';
                taskRec.WhoId = lcr.getContactId();
                if(!existingOpp){
                    taskRec.WhatId = lcr.getOpportunityId();
                }else{
                    taskRec.WhatId = oppId;
                }
                taskRec.Project_Name__c = theLead.Project_Picklist__c;
                taskRec.Description = 'First Name: ' + firstName + '\n' 
                                     +'Last Name: ' + lastName + '\n' 
                                     +'Phone: ' + phone + '\n'
                                     +'Email: ' + email + '\n'
                                     +'Lead Source: ' + leadSource + '\n'
                                     +'Enquiry Source: ' + leadEnquirySource + '\n'
                                     +'Lead Web Form Source: ' + leadWebFormSource + '\n'
                                     +'Suburb: ' + Suburb + '\n'
                                     +'Property Type: ' + propertyType + '\n'
                                     +'Price Point: ' + pricePoint + '\n' 
                                     +'Buyer Type: ' + buyerType + '\n'
                                     +'Purchase Window: ' + purchaseWindow + '\n'
                                     +'Comments: ' + comments;
                taskRec.ActivityDate = date.today();
                taskRec.Activity_Date__c = date.today();
                //jh - need to determine how these will be stored
                taskList.add(taskRec);
            }
        }
    }

    /**
     * @author JH 
     * @date 23/06/2016 
     * @description Creates a task that copies the content of the comments field from the lead 
     */
    public static void createTaskAfterConversion(Lead theLead, String ownerId, String subject, String whatId) {
        if(taskList == null) {
            taskList = new List<Task>(); 
        }
        Task taskRec = new Task();
        taskRec.Subject = subject;
        taskRec.Category__c = 'Website Membership Enquiry';
        taskRec.Type = 'Enquiry';
        taskRec.Priority  = 'Normal';
        taskRec.Is_New__c = true;
        taskRec.Status = 'Not Started';
        taskRec.OwnerId = ownerId; 
        //taskRec.WhoId = whoId;
        //assign to a public group for apartments  
        taskRec.WhatId = whatId;

        taskRec.Project_Name__c = theLead.Project_Picklist__c;
        taskRec.Description = theLead.Comments__c;
        taskRec.ActivityDate = date.today();
        taskRec.Activity_Date__c = date.today();

        taskList.add(taskRec);
    }

    /**
    * @author       JH 
    * @date         10/03/2016
    * @description  JH - Refactored from original logic, only add to sharing list if the 
    * current oppty owner is not same as current login
    * 
    */ 
    public static void shareOpportunityRecord(Opportunity theOpp) {
        // v1.04 sharing rule
        // only add to sharing list if the current oppty owner is not same as current login
        try{
            if(theOpp.OwnerId != userInfo.getUserId()){
                // create sharing rule -- manual sharing
                OpportunityShare oppShare = new OpportunityShare();
                oppShare.OpportunityId = theOpp.Id;
                oppShare.OpportunityAccessLevel = 'Read';
                oppShare.UserOrGroupId = userInfo.getUserId();
                oppSharesForInsert.add(oppShare);
            } 
        }catch (Exception ex){
            throw new NotImplementedException('Failed to shareOpportunityRecord. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    /**
    * @author pre-existing legacy code, merged into this class by JH 
    * @date merged into this class on 15/03/2016
    * @description returns the admin user id otherwise just returns a blank string (if the admin user cannot be found)
    */ 
    public static String getAdminUserId() {
        //Obtain the Oliver Hume User Record to reference the ID
        Profile adminProfile; 
        User adminUser;
        try{
            adminProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
            adminUser = [SELECT Id, FirstName, LastName from User WHERE FirstName = 'Oliver' AND LastName = 'Hume' AND ProfileId =:adminProfile.Id LIMIT 1];
        }
        catch (exception e){
            //couldn't locate the admin user, so just use the running user
            adminUser = [select id from User where Id =: userInfo.getUserId()];
        }

        if(adminUser != null) {
            return adminUser.Id; 
        }

        return ''; 
    }

    /**
    * @author       HR 
    * @date         17/03/2016
    * @description  update the product status for the Reservation Pending leads
    */ 
    public static void updateProductStatus(List<Lead> leads) {
        if(leads==null || leads.isEmpty()) return;
        List<Product__c> productsToUpdate = new List<Product__c>();
        try{
            Map<String, List<Lead>> reservationLeads = UtilClass.filterObjectsByRecordType(leads, 'Lead');
            if(reservationLeads != null && !reservationLeads.isEmpty()) {
                for(Lead l : reservationLeads.get(UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).DeveloperName)){
                    if(l.Status=='Reservation Pending' || l.Status=='Reservation Declined'){
                        productsToUpdate.add(new Product__c(id=l.Primary_Product__c, Internal_Status_Item__c=l.Status=='Reservation Declined' ? 'Available' : l.Status));                
                    }
                }
                  
                if(!productsToUpdate.isEmpty()){
                    update productsToUpdate;                
                }
            }
        }catch (Exception ex){
            throw new NotImplementedException('Unable to update the product status. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    
    /**
    * @author       HR 
    * @date         13/04/2016
    * @description  Change the status of the product to Available if the lead(s) deleted
    **/    
    public static void updateProductOnDeletedLeads(List<String> productIds){
        if(productIds.isEmpty()) return;
        
        List<Product__c> products = new List<Product__c>();
        try{
            for(String pId : productIds){
                products.add(new Product__c(Id=pId, Internal_Status_Item__c='Available'));
            }
            if(!products.isEmpty())
                update(products);
        }catch (Exception ex){
            throw new NotImplementedException('Failed to updateProductOnDeletedLeads. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    public static void filterReservationLeadsAndUpdateContractPrice(List<Lead> leads) {
        List<Lead> propertyReservationLeads = new List<Lead>(); 
        try{ 
            for(Lead theLead :leads) {
                if(theLead.RecordTypeId == UtilClass.orgRecordTypeMap.get(LEAD_RESERVATION_REQUEST_RECORDTYPE).Id 
                        && theLead.Approved_Property_Reservation_Lead__c == false && theLead.isConverted == false){
                    propertyReservationLeads.add(theLead); 
                }
            }

            if(propertyReservationLeads != null && !propertyReservationLeads.isEmpty()) {
                updateContractPrice(propertyReservationLeads); 
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed to filterReservationLeadsAndUpdateContractPrice. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    
    /**
    * @author       HR 
    * @date         07/04/2016
    * @description  Rollup the list and net price of the options/upgrades
    */
    @Testvisible public static Map<Id, Lead> leadsMapForTest = new Map<Id, Lead>();
    @Testvisible public static Double nPriceTest;
    public static void updateContractPrice(List<Lead> leads){
        Map<Id, Lead> leadsMap = new Map<Id, Lead>();
        leadsMap.putAll(leads);
        
        Set<Id> productIds = new Set<Id>();
        
        for(Lead l : leads){
            if(l.Upgrade_Option_s_Id__c!=null){
                for(String o : l.Upgrade_Option_s_Id__c.split(','))
                    productIds.add(o);
            }
        }

        try{
            Map<Id, Product__c> productPriceMap = new Map<Id, Product__c>([SELECT Id, Net_Price__c, List_Price__c FROM Product__c WHERE Id IN: productIds]);

            for(String lId : leadsMap.keySet()){
                if(leadsMap.get(lId).Upgrade_Option_s_Id__c!=null){
                    Double nPrice;
                    if(Test.isRunningTest())
                        nPrice = nPriceTest;
                    else
                        nPrice = leadsMap.get(lId).Primary_Product_Net_Price__c;
                    for(String pId : leadsMap.get(lId).Upgrade_Option_s_Id__c.split(',')){
                        nPrice += productPriceMap.get(pId).Net_Price__c;
                    }
                    leadsMap.get(lId).Contract_Price__c = nPrice;
                }else{
                    if(Test.isRunningTest())
                        leadsMap.get(lId).Contract_Price__c = nPriceTest;
                    else                    
                        leadsMap.get(lId).Contract_Price__c = leadsMap.get(lId).Primary_Product__r.List_Price__c;
                }
            }
            if(Test.isRunningTest())
                leadsMapForTest = leadsMap;
        }catch (Exception ex){
            throw new NotImplementedException('Failed updateContractPrice. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }    
    
    /**
    * @author       HR 
    * @date         05/04/2016
    * @description  Auto submit property reservation leads for approval
    */     
    public static void submitLeadsForApproval(List<Lead> leads){
        if(leads==null || leads.isEmpty()) return;

        List<Approval.ProcessSubmitRequest> psrs = new List<Approval.ProcessSubmitRequest>();
        
        try{
            for(Lead l : leads){
                Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
                psr.setProcessDefinitionNameOrId('Property_Reservation');
                psr.setObjectId(l.Id); 
                psrs.add(psr);
            }
            
            if(!psrs.isEmpty()){            
                List<Lead> newLeads = new List<Lead>();
                List<Approval.ProcessResult> results = Approval.process(psrs);            
            }
        }catch (Exception ex){
            if(!ex.getMessage().contains('ALREADY_IN_PROCESS'))
                throw new NotImplementedException('Failed to submit the lead(s) for approval. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    
    /**
    * @author       HR 
    * @date         23/03/2016
    * @description  validate the option(s) & upgrade(s) record types
    */
    public static void validateOptionsUpgradesforRecordType(List<Lead> leads){
        if(leads==null || leads.isEmpty()) return;
        Set<String>ValidRecordTypes = new Set<String>{'Option', 'Upgrade'};
        
        List<String> productIds = new List<String>();
        for(Lead l : leads){
            if(l.Upgrade_Option_s_Id__c!=null ){
                for(String s : l.Upgrade_Option_s_Id__c.split(','))
                    productIds.add(s);
            }
        }
        
        Map<String, String> productRecordTypeMap = new Map<String, String>();
        try{
            for(Product__c prod : [SELECT Id, RecordType.DeveloperName FROM Product__c WHERE Id IN: productIds]){
                productRecordTypeMap.put(prod.Id, prod.RecordType.DeveloperName);
            }
            
            List<LeadOptionsUpgrades> optionsupgrades = new List<LeadOptionsUpgrades>();
            
            for(Lead l : leads){
                if(l.Upgrade_Option_s_Id__c!=null ){
                    for(String s : l.Upgrade_Option_s_Id__c.split(','))         
                        optionsupgrades.add(new LeadOptionsUpgrades(l.Id, s, ValidRecordTypes.contains(productRecordTypeMap.get(s))));
                }
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed to validateOptionsUpgradesforRecordType. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    //SalesFix : When a lead has opted out of email, add them to the global email usubscribe campaign
    public static void EmailUnsubscribe(List<Lead> leadList){
        try{
            List<Campaign> masterCamp = [Select Id From Campaign Where Name = 'Oliver Hume Master - Email Opt Out'];        
            if(masterCamp.size() > 0){
                List<CampaignMember> existingLeadMembers = [Select Id,LeadId From CampaignMember Where LeadId in:leadList and CampaignId = :masterCamp[0].Id];
                Map<Id,CampaignMember> existingLeadMemberMap = new Map<Id,CampaignMember>();
                for(CampaignMember cm : existingLeadMembers){
                    existingLeadMemberMap.put(cm.LeadId,cm);
                }
                List<CampaignMember> cmList = new List<CampaignMember>();
                for(Lead l : leadList){
                    CampaignMember cm;
                    if(existingLeadMemberMap.containsKey(l.Id)){
                        cm = existingLeadMemberMap.get(l.Id);
                    }else{
                        cm = new CampaignMember();
                        cm.CampaignId = masterCamp[0].Id;
                        cm.LeadId = l.Id;                    
                    }
                    cm.Status = 'Unsubscribed';
                    cmList.add(cm);                        
                }            
                if(cmList.size() > 0) upsert cmList;
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed EmailUnsubscribe. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    //SalesFix : when a lead has opted back for email, remove them from the unsubscribe campaign if exist
    public static void EmailSubscribeBack(List<Lead> leadList){
        try{
            List<Campaign> masterCamp = [Select Id From Campaign Where Name = 'Oliver Hume Master - Email Opt Out'];
            if(masterCamp.size() > 0){
                List<CampaignMember> cmList = [Select Id from CampaignMember 
                                            Where LeadId in :leadList and CampaignId=:masterCamp[0].Id ];
                if(cmList.size() > 0) delete cmList;
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed EmailSubscribeBack. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

      //SalesFix : helper method to build the parent and child campaing maps to link to project enquiry
    private static void buildCampaignMaps(List<Campaign> allCams){  
         try{
            for(Campaign c: allCams){
                if(c.ParentId != null){
                    if(childCampaignMap.get(c.Project__r.Name) == null){
                        childCampaignMap.put(c.Project__r.Name, new Map<String, Campaign[]>());
                    }
                    if(String.isNotBlank(c.Channels__c)) {
                        for(String s: c.Channels__c.split(';')){
                            if(childCampaignMap.get(c.Project__r.Name).get(s) == null){
                                childCampaignMap.get(c.Project__r.Name).put(s, new Campaign[]{});
                            }
                            childCampaignMap.get(c.Project__r.Name).get(s).add(c);
                        }   
                    }
                }
                else{
                    if(parentCampaignMap.get(c.Project__r.Name) == null){
                        parentCampaignMap.put(c.Project__r.Name, new Map<String, Campaign>());  
                    }
                    if(String.isNotBlank(c.Channels__c)) {
                        for(String s: c.Channels__c.split(';')){
                            parentCampaignMap.get(c.Project__r.Name).put(s, c);
                        }
                    }
                }
            }
       }catch (Exception ex){
            throw new NotImplementedException('Failed to buildCampaignMaps. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    //SalesFix : helper method get the matching campaign id based on project name and enquiry source
    private static Id getCampaignId(Lead l){
        Id paCampId;

        //jh - check map is actually populated. 
        try{
            if(childCampaignMap != null && !childCampaignMap.isEmpty()) {
                if(childCampaignMap.get(l.Project_Picklist__c) != null && childCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c) != null){
                    Campaign[] sourceCampaigns = childCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c);
                    Campaign[] newChildCampaigns = new Campaign[]{};
                    boolean hasFound = false;
                    for(Campaign c: sourceCampaigns){
                        Date enqDate = Date.today();
                        for(Integer i = 0; i <8; i++){
                            if(c.StartDate<= enqDate && c.EndDate >= enqDate){
                                paCampId = c.Id;
                                hasFound = true;
                                break;  
                            }
                            else{
                                enqDate = enqDate.addDays(-7);
                            }
                        }
                    }
                    if(!hasFound){
                        Campaign lastCampaign = sourceCampaigns[sourceCampaigns.size()-1];
                        paCampId = lastCampaign.Id;
                    }
                }
                else{
                    if(parentCampaignMap.get(l.Project_Picklist__c) != null && parentCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c) != null){
                        Campaign matchingParentCampaign = parentCampaignMap.get(l.Project_Picklist__c).get(l.Enquiry_Source__c);
                        paCampId = matchingParentCampaign.Id;
                    }
                }
            }
            return paCampId;
        }catch (Exception ex){
            throw new NotImplementedException('Faild to getCampaignId. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }
    //SalesFix : helper method to create project assignment record
    private static Project_Enquiry__c createProjectAssignment(Id paAccntId,Id paPrjId,Id paCampId,Id paOppId, Lead l, Boolean isPrimary){
        try{
            Project_Enquiry__c pa = new Project_Enquiry__c();
            pa.Project__c = paPrjId;
            pa.Opportunity__c =  paOppId;
            pa.Campaign__c = paCampId;
            pa.Primary__c = isPrimary;
            pa.Status__c = 'Interested';
            pa.Client_Enquiry__c = true;
            pa.Property_Connect__c = l.Property_Connect__c;
            pa.Enquiry_Method__c = l.Enquiry_Method__c;
            pa.Enquiry_Source__c = l.Enquiry_Source__c;
            pa.Enquiry_Source_Other__c = l.Enquiry_Source_Other__c;
            pa.Lead_Source__c = l.LeadSource;
            pa.Web_Form_Source__c = l.Web_Form_Source__c;
            pa.Channel_Account__c = l.Channel_Account__c;
            pa.UTM_Campaign__c = l.UTM_Campaign__c;
            pa.UTM_Content__c = l.UTM_Content__c;
            pa.UTM_Medium__c = l.UTM_Medium__c;
            pa.UTM_Source__c = l.UTM_Source__c;
            pa.UTM_Term__c = l.UTM_Term__c;
            pa.Product_Interest__c = l.Product_Interest__c;
            pa.Project_Stage__c = l.Project_Stage__c;
            
            pa.Building_Type__c = l.Building_Type__c;
            pa.Product_Size__c = l.Product_Size__c;
            pa.Bdr__c = l.Bdr__c;
            pa.Bth__c = l.Bth__c;
            pa.Study__c = l.Study__c;
            pa.Car__c = l.Car__c;
            pa.Storeys__c = l.Storeys__c;
            pa.Rating__c = l.Rating__c;
            pa.Buyer_Type__c = l.Buyer_Type__c;
            pa.Buyer_Experience__c = l.Buyer_Experience__c;
            pa.Purchase_Window__c = l.Purchase_Window__c;
            pa.Price_Point__c = l.Price_Point__c;
            pa.Finance__c = l.Finance__c;
            pa.FIRB__c = l.FIRB__c;
            pa.Household_Type__c = l.Household_Type__c;
            pa.Suburb__c = l.Suburb__c;
            //jh - case 2068 
           // pa.Purchaser__c = paAccntId; 
            
            return pa;
        }catch (Exception ex){
            throw new NotImplementedException('Failed to createProjectAssignment. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
    * @author  JH 
    * @date 18/05/2016
    * @description checks if the lead is in the person acc map & if so returns the acc ID & whether the contact exists 
    **/ 
    public static Map<String, Boolean> personExists(Lead theLead) {
            Boolean existingContact = false; 
            String acctId = ''; 
            
            Map<String, Boolean> personAccExists = new Map<String, Boolean>(); 
            try{
                if(duplicateAccEmail.containsKey(theLead.Email)) {
                    //jh - i guess cause its ordered this is ok...
                    acctId = duplicateAccEmail.get(theLead.Email).Id; 
                    existingContact = true; 
                }

                personAccExists.put(acctId, existingContact);
                return personAccExists; 
            }catch (Exception ex){
                throw new NotImplementedException('Failed personExists. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
            }
    }

    /**
     * @author  JH 
     * @date 18/05/2016
     * @description salesfix merge - moved into its own method to tidy up the code abit.. 
     */
    public static void globalOptInOutUnsubscribeCampaign(Map<Id, Lead> newMap, Map<Id, Lead> oldMap) {
        //SalesFix : When a lead's email opt out status changes, add or remove them to the global email usubscribe campaign
        List<Lead> emailOptOutLds = new List<Lead>();
        List<Lead> emailOptInLeads = new List<Lead>();
        try{
            for(Lead theLead: newMap.values()){
                //SalesFix : When a lead's email opt out status changes, add or remove them to the global email usubscribe campaign
                if(theLead.HasOptedOutOfEmail && !oldMap.get(theLead.Id).HasOptedOutOfEmail){
                    emailOptOutLds.add(theLead);
                }
                if(!theLead.HasOptedOutOfEmail && oldMap.get(theLead.Id).HasOptedOutOfEmail){
                    emailOptInLeads.add(theLead);
                }
            }
            //SalesFix : When a lead's email opt out status changes, add or remove them to the global email usubscribe campaign
            if(!emailOptOutLds.isEmpty()) {
                EmailUnsubscribe(emailOptOutLds);
            }
            if(!emailOptInLeads.isEmpty()) {
                EmailSubscribeBack(emailOptInLeads);
            }
        }catch (Exception ex){
            throw new NotImplementedException('Failed globalOptInOutUnsubscribeCampaign. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
        }
    }

    /**
    * @author JH 
    * @date 28/06/2016
    * @description Takes a list of leads & creates sharing records for them with their creators. Cannot simply insert the sharing records 
    * as on create a share record would already exist between the record & the user. So need to check that a share record doesn't already 
    * exist for the creator & if not insert one. 
    **/
    public static void shareLeadsWithCreators(List<Lead> leads) {
        //check for sharing records for the leads first
        Set<Id> leadIds = new Set<Id>(); 
        for(Lead theLead :leads) {
            leadIds.add(theLead.Id); 
        }

        //jh - get any existing sharing records for our leads 
        List<LeadShare> existingLeadShares = [SELECT LeadId, UserOrGroupId 
                                          FROM LeadShare 
                                          WHERE LeadId IN :leadIds]; 

        Set<String> setOfExistingShares = new Set<String>(); 
        //jh build up a set of lead id + user group ids as the keys 
        for(LeadShare existingLeadShare :existingLeadShares) {
            String key = String.valueOf(existingLeadShare.LeadId) + String.valueOf(existingLeadShare.UserOrGroupId); 
            setOfExistingShares.add(key); 
        }

        List<LeadShare> leadSharingRecords = new List<LeadShare>(); 
        for(Lead theLead :leads) {
            String key = String.valueOf(theLead.Id) + String.valueOf(theLead.CreatedById); 
            if(!setOfExistingShares.contains(key)) {
                LeadShare lShare = new LeadShare(); 
                lShare.LeadAccessLevel = 'Read'; 
                lShare.LeadId = theLead.Id; 
                lShare.UserOrGroupId = theLead.CreatedById; 

                leadSharingRecords.add(lShare); 
            }
        }

        if(!leadSharingRecords.isEmpty()) {
            insert leadSharingRecords; 
        }
    }


    /**
     * @author  JH 
     * @date 18/05/2016
     * @description salesfix merge - moved into its own method to tidy up the code abit.. 
     */
    public static void emailOptOutLeads(List<Lead> leads) {
        //SalesFix : When a lead has opted out of email, add them to the global email usubscribe campaign
        List<Lead> emailOptOutLeads = new List<Lead>();
        for(Lead theLead :leads) {
            if(theLead.HasOptedOutOfEmail) {
                emailOptOutLeads.add(theLead); 
            }
        }

        if(emailOptOutLeads != null && !emailOptOutLeads.isEmpty()) {
            try{
                EmailUnsubscribe(emailOptOutLeads); 
            }catch (Exception ex){
                throw new NotImplementedException('Failed emailOptOutLeads. '+ex.getMessage()+'  StackTrace: '+ex.getStackTraceString());
            }
        }
    }

    /**
    * @author       HR 
    * @date         23/03/2016
    * @description  Inner class to keep lead, upgrade/option and is valid flag
    */
    class LeadOptionsUpgrades{
        String leadId;
        String productId;
        Boolean isValid;
    
        public LeadOptionsUpgrades(String lId, String pId, Boolean v){
            leadId = lId;
            productId = pId;
            isValid = v;
        }
    }

}