public with sharing class enquiryController {

    public id projectId{get; set;}
    public string projectName{get; set;}
    public string sourceName{get; set;}
    public string leadSource{get; set;}
    public string leadTime{get; set;}
    public boolean success{get; set;}
    public boolean display{get; set;}
    public task t{get; set;}
    
    Map<String, Id> projectsMappingName;
    Map<Id, String> projectsMappingId;
    
    public List<SelectOption> options {get; set;}
    public List<SelectOption> enquiries {get; set;}
    public Map<String,List<String>> projectToEnquiries {get; set;}
    
    
    public enquiryController(){
    
        success = true;
        display = false;
        projectsMappingName = new Map<String, Id>();
        projectsMappingId = new Map<Id, String>();
        
        Map<String, String> projects = new Map<String, String>();
        for (Project__c p: [SELECT Id, Name FROM Project__c WHERE isDeleted = false]) {
        	projects.put(p.Name, p.Name);  
            projectsMappingName.put(p.Name, p.Id);
            projectsMappingId.put(p.Id, p.Name); 
        }
        projectToEnquiries = TStringUtils.getDependentOptions('Lead', 'Project_Picklist__c', 'Enquiry_Source__c', projects);
    }
    
    /*public selectOption[] getProjects(){
        selectOption[] projectOptions = new selectOption[]{};
        //add a default value
        projectOptions.add(new selectOption('','--Please Select--'));
        //return all active projects as selectoptions.
        for(Project__c p: [select Id, Name from Project__c where isDeleted = false]){
            //add as a selectoption
            projectOptions.add(new selectOption(p.Id, p.Name));
        }
        return projectOptions;
    }*/
    
    public List<SelectOption> getProjects() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--Please Select--'));
        for(String p : projectToEnquiries.keySet()) {
            if (p != null && p != '')
            	options.add(new SelectOption(projectsMappingName.get(p), p));
        }	
        return options;
    }
    
    public PageReference getEnquirySources() {
        enquiries = new List<SelectOption>();
        enquiries.add(new SelectOption('', '--Please Select--'));
        if (projectId != null) {
            List<String> dependentSources = projectToEnquiries.get(projectsMappingId.get(projectId));
            if (dependentSources != null) {
                for(String es : dependentSources) {
                    if (es != null && es != '')
                        enquiries.add(new SelectOption(es, es));
                }	
            }
        }
        return null;
    }

    /*public selectOption[] getSources(){
        //get the lead source options from the lead source object.
        
        selectOption[] leadSources = new selectOption[]{};
        
        Schema.DescribeFieldResult ls = Lead.Enquiry_Source__c.getDescribe();
        Schema.PicklistEntry[] ple = ls.getPicklistValues();
        //add a default value
        leadSources.add(new selectOption('','--Please Select--'));
        for(Schema.PicklistEntry p: ple){
            //add active picklist entries to selectOption list
            if(p.isActive()){
                leadSources.add(new selectOption(p.getValue(), p.getLabel()));
            }
        }
    
        return leadSources;
    }*/
    
    public void createEnquiry(){
        //set display to true, this will show the blue panel at the bottom of the screen
        display = true;
        OppToTaskMapping__c enquiryMethodMapping = OppToTaskMapping__c.getValues('Walk-In - Did Not Register');
        
        //create a task
        t = new Task(
                OwnerId = UserInfo.getUserId(),
                Subject = enquiryMethodMapping.Task_Subject__c, 
                Description = 'Generated from the Enquiry homepage component', 
                Priority = 'Normal',
                Status = 'Completed', 
                Is_New__c = true,
                Category__c = enquiryMethodMapping.Category__c,
                Type = enquiryMethodMapping.Type__c,
                ActivityDate = date.today(),
                Activity_Date__c = date.today()
            );
        if(projectId != null  && leadSource != null && leadSource != ''){
            sourceName = leadSource;
            success = true;
            try{
                projectName = [select Name from Project__c where id =: projectId].Name;
                t.Project_Name__c = projectName;
            }
            catch(exception e){
                //error finding the project name
                success = false;
            }
        
            t.WhatId = projectId;
            t.Lead_Source__c = leadSource;
            leadTime = dateTime.now().format('h:mm a');
            if(success){
                try{
                    insert t;
                    projectId = null;
                    leadSource = null;   
                }
                catch(exception e){
                    //couldn't write the task, it won't be pretty, but write an error to the page.
                    success = false;
                }            
            }
            else{
                success = false;
            }

        }
        else{
            leadTime = null;
            success = false;
        }     
    }
    
    static testMethod void enquiryControllerTest(){
        OppToTaskMapping__c mapping = new OppToTaskMapping__c(
            Name = 'Walk-In - Did Not Register',
            Enquiry_Method__c = 'Walk-In',
            Task_Subject__c = 'Walk-In Enquiry – Did Not Register',
            Category__c = 'Walk In - Did Not Register',
            Type__c = 'Walk-In'
        );
        insert mapping;
        
        //insert some projects
        Project__c project = new Project__c();
        project.Name = 'Test Project';
        project.City__c = 'Test'; 
        project.Description__c = 'Sample Description'; 
        project.Region__c = 'Melbourne'; 
        project.Street_Address__c = '12 Test'; 
        project.Zip_Postal_Code__c = 'Victoria';    
        project.Status__c = 'Planned';
        insert project;
        
        Project__c project1 = new Project__c();
        project1.Name = 'Test Project1';
        project1.City__c = 'Test'; 
        project1.Description__c = 'Sample Description'; 
        project1.Region__c = 'Melbourne'; 
        project1.Street_Address__c = '12 Test'; 
        project1.Zip_Postal_Code__c = 'Victoria';    
        project1.Status__c = 'Planned';
        insert project1;
        
        //create a copy of the controller
        enquiryController ec = new enquiryController();
        //do some page actions
        ec.getProjects();
        ec.getEnquirySources();
        //ec.getSources();
        //submit a blank form to cause an error
        ec.createEnquiry();
        system.assert(ec.t.Id == null);
        //add some values
        ec.projectId = project.Id;
        ec.leadSource = 'Test Source';
        //submit again.
        ec.createEnquiry();
        system.assert(ec.t.Id != null);
    
    }
    
}