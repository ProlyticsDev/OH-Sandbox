/*
    Type:       Controller Extension
    Purpose:    For Selecting Lead Record Type - Overwrite standard create new Lead page

    Used By:    Lead object
    ---------------------------------------------------------------
    History:
      v1.0 created -- Ji Zhang (jzhang@coretec.com.au) 02/01/2013
      v1.01 updated add validLead to check must have at least 1 contact form eg. email, phone, mobilephone -- Ji Zhang 16/01/2013
        HR - 22/06/2016 Fix the return from the save button      
*/

public without sharing class LeadExcon {
       
    public Lead leadRecord{
        get{
            if(leadRecord == null){
                leadRecord = new Lead();
                // set owner to current login user
                LeadRecord.OwnerId = userInfo.getUserId();
            }
            return leadRecord;
        }
        set;
    }
    
    // to display lead owner name in text
    public String ownerName{
        get{
            if(ownerName == null){
                ownerName = userInfo.getName();
            }
            return ownerName;
        }
        set;
    }
    
    private String recordTypeId{get;set;}
    public String recordTypeName{get;set;}
    public String project {get;set;}
    public String enquirySource {get;set;}
    
    public List<SelectOption> options {get; set;}
    public List<SelectOption> enquiries {get; set;}
    
    public Map<String,List<String>> projectToEnquiries {get; set;}
    
    public LeadExcon(ApexPages.StandardController controller){
        recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        // should always have a recordType be passed in
        if(recordTypeId != null){
            RecordType rt = [select developerName from RecordType where id =: recordTypeId];
            recordTypeName = rt.DeveloperName;
        }
        leadRecord.RecordTypeId = recordTypeId;
        
        Map<String, String> projects = new Map<String, String>();
        for (Project__c p: [SELECT Id, Name FROM Project__c WHERE IsDeleted = false]) {
        	projects.put(p.Name, p.Name);    
        }
        projectToEnquiries = TStringUtils.getDependentOptions('Lead', 'Project_Picklist__c', 'Enquiry_Source__c', projects);
    }
    
    //HR - 22/06/2016 Fix the return from the save button      
    public pageReference saveLead(){
        if(validLead()){
            if (validateProjectAndEnquiry()) {
                try{
                    leadRecord.Project_Picklist__c = project;
                    leadRecord.Enquiry_Source__c = enquirySource;
                    insert leadRecord;
                }catch(Exception e){
                    ApexError.AddException(e);
                    system.debug('$$$error: insert lead failed!');
                }
            } else {
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select a Project and an Enquiry Source.')); 
            	return null;    
            }
        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please choose either an Email or Phone or Mobile.')); 
            return null;
        }

        Lead convertedLead = [SELECT Id, ConvertedOpportunityId, ConvertedAccountId FROM Lead WHERE Id =:leadRecord.Id limit 1]; 
        if(convertedLead!=null) {
            try{
                if(convertedLead.ConvertedOpportunityId!=null){
                    return new PageReference('/' + convertedLead.ConvertedOpportunityId);  
                }
                String accId = convertedLead.ConvertedAccountId;
                String recId = UtilClass.orgRecordTypeMap.get('opportunity_apartments').Id;
                Account acc = [SELECT Id, (SELECT Id, RecordTypeId FROM Opportunities WHERE RecordTypeId=:recId ORDER BY LastModifiedDate DESC LIMIT 1) 
                                FROM Account WHERE Id=:accId];
                return new PageReference('/' + acc.Opportunities[0].Id);
            }catch(Exception ex){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Failed to find existing opportunity.')); 
                return new PageReference('/');
            }
        }
        else {
            return new PageReference('/' + leadRecord.Id); 
        }

        return null; 
    }
    
    public pageReference cancelLead(){
        
        return new PageReference('/home/home.jsp');
    }
    
    public pageReference saveNew(){
        // check email, phone, mobile phone cannot all be null and blank
        if(validLead()){
            if (validateProjectAndEnquiry()) {
            	try{
                	leadRecord.Project_Picklist__c = project;
                	leadRecord.Enquiry_Source__c = enquirySource;
                	insert leadRecord;
            	}catch(Exception e){
                    ApexError.AddException(e);
                	system.debug('$$$error: insert lead failed!');
            	}    
            } else {
            	ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please select a Project and an Enquiry Source.')); 
            	return null;    
            }

        }else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error, 'Please choose either an Email or Phone or Mobile.')); 
            return null;
        }
        return (new PageReference('/apex/LeadNew?RecordType=' + RecordTypeId)).setRedirect(true);
    }
    
    private Boolean validLead(){
        
        // check email, phone, mobile phone cannot all be null and blank
        if((leadRecord.email != null && leadRecord.email != '') 
         ||(leadRecord.phone != null && leadRecord.phone != '')
         ||(leadRecord.mobilephone != null && leadRecord.mobilephone != '')){
            return true;
         }
         return false;
    }
    
    private boolean validateProjectAndEnquiry() {
    	if ((project != null && project != '' && project != '--None--') 
                    && (enquirySource != null && enquirySource != '' && enquirySource != '--None--')) {
        	return true;
        }    
        return false;
    }
    
    public List<SelectOption> getProjects() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('--None--', '--None--'));
        for(String p : projectToEnquiries.keySet()) {
            if (p != null && p != '')
            	options.add(new SelectOption(p, p));
        }	
        return options;
    }
    
    public PageReference getEnquirySources() {
        enquiries = new List<SelectOption>();
        enquiries.add(new SelectOption('--None--', '--None--'));
        if (project != null) {
            List<String> dependentSources = projectToEnquiries.get(project);
            if (dependentSources != null) {
                for(String es : dependentSources) {
                    if (es != null && es != '')
                        enquiries.add(new SelectOption(es, es));
                }	
            }
        }
        return null;
    }
    
    static testMethod void leadExconTest(){   
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Web Form',
            Enquiry_Method__c = 'Web Form',
            Task_Subject__c = 'Submitted Web Form',
            Category__c = 'Web Form',
            Type__c = 'Web Form Submission'
        );
        insert mapping;
          
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.Owner_Assignment__c = userInfo.getUserId();
        project.City__c = 'Test'; 
        project.Description__c = 'Sample Description'; 
        project.Region__c = 'Melbourne'; 
        project.Street_Address__c = '12 Test'; 
        project.Zip_Postal_Code__c = 'Victoria';    
        project.Status__c = 'Planned';
        insert project;
        system.debug('$$$inserted project:' + project);
        
        Lead lead = new Lead();
        lead.Salutation = 'Mr';
        lead.LastName = 'lname';
        lead.Date_of_Enquiry__c = date.today();
        lead.leadSource = 'D3';
        lead.Enquiry_Method__c = 'Web Form';
        lead.Property_Type__c = 'Apartment';
        //lead.Status = 'Open';
        lead.Auto_Convert__c = true;
        lead.Project_Picklist__c = 'Test Project';
        lead.LeadSource = 'The Age';
        lead.email = 'testa@email.com';
        lead.Search_Campaign__c = false;
        lead.Status = 'Qualified';
        //insert lead;
        
        RecordType rt = [select developerName from RecordType where developerName =: 'Apartments' limit 1];
        system.assertNotEquals(rt,null);
        PageReference pageRef = Page.LeadNew;
        Test.setCurrentPageReference(pageRef);
        System.currentPageReference().getParameters().put('RecordType',rt.id);  
        ApexPages.StandardController sc = new ApexPages.standardController(lead);  
        LeadExCon excon = new LeadExCon(sc); 
        system.assertNotEquals(excon.leadRecord, null);      
        system.assertNotEquals(excon.ownerName, null); 
        excon.leadRecord.Salutation = 'Mr';
        excon.leadRecord.LastName = 'lname';
        excon.leadRecord.Date_of_Enquiry__c = date.today();
        excon.leadRecord.leadSource = 'D3';
        excon.leadRecord.Enquiry_Method__c = 'Web Form';
        excon.leadRecord.Property_Type__c = 'Apartment';
        excon.leadRecord.Auto_Convert__c = true;
        excon.leadRecord.Project_Picklist__c = 'Test Project';
        excon.leadRecord.LeadSource = 'The Age';
        excon.leadRecord.email = 'testB@email.com';
        excon.leadRecord.Search_Campaign__c = false;
        excon.leadRecord.Status = 'Qualified';
        excon.saveLead();
        excon.cancelLead();
        //system.assertNotEquals(LeadUtility.returnOpptyId, null);
    }
}