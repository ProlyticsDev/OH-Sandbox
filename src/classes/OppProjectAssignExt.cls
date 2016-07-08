//SalesFix : Custom Controller for ProjectAssignments Visfualforce page
public with sharing class OppProjectAssignExt {

    //Variables
    private Id oppId; 
    public Opportunity Opp {get; set;}    
    public Id selectedProjectId {get;set;}
    public List<Project_Enquiry__c> currentProjects {get;set;}

    public Boolean canEdit {get; set;}    
    public Boolean canSave {get; set;}    
    public Boolean canCancel {get; set;}    

    //Constructor
    public OppProjectAssignExt() {
        oppId = ApexPages.currentPage().getParameters().get('id');        
        canEdit = true; canSave = false; canCancel = false;
        initData();        
    }

    public PageReference Save(){        
        try{
            Integer primaryPa = 0;
            for(Project_Enquiry__c pa : currentProjects){
                if(pa.Primary__c) primaryPa++; 
            }
            if(primaryPa > 1){
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Only One Project Assignmet Can be Primary.'));
            }else{
                update currentProjects;
                initData();
                canEdit = true;                
            }        
        }catch(DMLException dex){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, dex.getDmlMessage(0)));
        }
        catch(Exception ex){
            system.debug('Error in ProjectAssignments page : ' + ex);
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error in saving the records.'));    
        }
        return null;
    }

    public PageReference Cancel(){
        initData();
        canEdit = true;
        return null;
    }

    Public PageReference Edit(){
        canEdit = false;
        return null;
    }

    private void initData(){
        Opp = [Select Id, (Select Id,Name,Project__c,Status__c,Reason__c,Disqualified_Reason_Detail__c,
                            Primary__c,Client_Enquiry__c,Manager_Approval__c 
                            From Project_Enquiries__r) 
                From Opportunity Where Id=:oppId limit 1];
        
        currentProjects = new List<Project_Enquiry__c>();
        if(opp.Project_Enquiries__r != null && opp.Project_Enquiries__r.size() > 0){
            currentProjects.addAll(opp.Project_Enquiries__r);
            selectedProjectId = currentProjects[0].Id;    
        }        
    }

}