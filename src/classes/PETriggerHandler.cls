//SalesFix : Trigger Handler for Project Enquiry Trigger
public class PETriggerHandler 
{
    //recursive check
    public static Boolean run = true;
    public static Boolean runOnce{
        get{
            if(run){
                run = false;return true;
            }
            return run;
        }
    }

    //variables
    Private final string DisqStatus = 'Disqualified';    
    Private List<Project_Enquiry__c> oldPAs;
    Private List<Project_Enquiry__c> newPAs;
    Private Map<Id,Project_Enquiry__c> oldPAMap;
    Private Map<Id,Project_Enquiry__c> newPAMap;
    Private Boolean isUpdate;
    private Boolean isDel; 

    //constructor
    public PETriggerHandler(){
        this.oldPAs = (List<Project_Enquiry__c>)trigger.old;
        this.newPAs = (List<Project_Enquiry__c>)trigger.new;
        this.oldPAMap = (Map<Id,Project_Enquiry__c>)trigger.oldMap;
        this.newPAMap = (Map<Id,Project_Enquiry__c>)trigger.newMap;
        this.isUpdate = trigger.isUpdate;
        this.isDel = trigger.isDelete; 
    }

    //Handler After Insert
    public void HandleAfterInsert(){
        handlePrimaryProject();
        updateCampaignRollupCount();
    }

    //Handle Before Update
    public void HandleBeforeUpdate(){
        handleBeforePrimaryUpdate();
    }

    //Handle After Update
    public void HandleAfterUpdate(){
        if(runOnce){
            handlePrimaryProject();
            handleDisqualifiedProjects();       
        }      
        updateCampaignRollupCount();  
    }

    //jh - for after deletion 
    public void HandleAfterDelete() { 
        updateCampaignRollupCount(); 
    }

    private void handleBeforePrimaryUpdate(){
        Map<Id,Project_Enquiry__c> primOppProj = new Map<Id,Project_Enquiry__c>();
        for(Project_Enquiry__c pa : newPAs){
            if(pa.Primary__c){
                primOppProj.put(pa.Opportunity__c,pa);
            }
        }
        if(primOppProj.isEmpty()) return;        

        List<Project_Enquiry__c> paList = new List<Project_Enquiry__c>();
        List<Opportunity> oppsWithPEs = [Select Id, (Select Id, Primary__c,Status__c From Project_Enquiries__r ) 
                                           From Opportunity Where Id in : primOppProj.keySet() ];    

        //update the previous primary records to non primary since only one primary record can exist at a time.
        for(Opportunity opp : oppsWithPEs){
            Project_Enquiry__c primPE = primOppProj.get(opp.Id);
            for(Project_Enquiry__c pa : opp.Project_Enquiries__r){
                if(pa.Primary__c && pa.Id != primPE.Id && pa.Status__c != 'Disqualified'){
                    primPE.Primary__c.addError('Current Primary Project Enquiry must be disqualified before making this enquiry as primary');
                    return;    
                }
            }
        }        

    }
    //when a project assignmet becomes primary, perform the below actions
    //1. update the project details on the parent opportunity
    //2. make the othere primary project assignment for the opporutnity as non primary    
    private void handlePrimaryProject(){
        //if any project assignment record is updated to primary
        Map<Id,Project_Enquiry__c> primOppProj = new Map<Id,Project_Enquiry__c>();
        for(Project_Enquiry__c pa : newPAs){
            if(pa.Primary__c){
                primOppProj.put(pa.Opportunity__c,pa);
            }
        }
        if(primOppProj.isEmpty()) return;        

        //sync the primary project assignment details to the parent opportunity
        List<Opportunity> oppsToUpdate = [Select Id From Opportunity Where Id in : primOppProj.keySet()];
        for(Opportunity opp : oppsToUpdate){
            Project_Enquiry__c pa = primOppProj.get(opp.Id);
            opp.Project__c = pa.Project__c;
            opp.LeadSource = pa.Lead_Source__c;
            opp.Channel_Account__c = pa.Channel_Account__c;
            opp.Enquiry_Method__c = pa.Enquiry_Method__c;
            opp.Enquiry_Source__c = pa.Enquiry_Source__c;
            opp.Enquiry_Source_Other__c = pa.Enquiry_Source_Other__c;
            opp.LeadSource = pa.Lead_Source__c;
            opp.Web_Form_Source__c = pa.Web_Form_Source__c;
            opp.CampaignId = pa.Campaign__c;
            opp.Originating_Campaign__c = pa.Campaign__c;
            opp.UTM_Campaign__c = pa.UTM_Campaign__c;
            opp.UTM_Content__c = pa.UTM_Content__c;
            opp.UTM_Medium__c = pa.UTM_Medium__c;
            opp.UTM_Source__c = pa.UTM_Source__c;
            opp.UTM_Term__c = pa.UTM_Term__c;
            opp.Lot_No__c = pa.Product_Interest__c;
            opp.Project_Stage__c = pa.Project_Stage__c;   
            opp.Property_Connect__c = pa.Property_Connect__c;
            opp.Building_Type__c = pa.Building_Type__c;
            opp.Product_Size__c = pa.Product_Size__c;
            opp.Bdr__c = pa.Bdr__c;
            opp.Bth__c = pa.Bth__c;
            opp.Study__c = pa.Study__c;
            opp.Car__c = pa.Car__c;
            opp.Storeys__c = pa.Storeys__c;
            opp.Rating__c = pa.Rating__c;
            opp.Buyer_Type__c = pa.Buyer_Type__c;
            opp.Buyer_Experience__c = pa.Buyer_Experience__c;
            opp.Purchase_Window__c = pa.Purchase_Window__c;
            opp.Price_Point__c = pa.Price_Point__c;
            opp.Finance__c = pa.Finance__c;
            opp.FIRB__c = pa.FIRB__c;
            opp.Household_Type__c = pa.Household_Type__c;
            opp.Suburb__c = pa.Suburb__c;

        } 
        //set the flag to false to avoid duplicate entry of project enquiry record
        OpportunityUtility.CanCreatePE = false;                                     
        update oppsToUpdate;    
    }

    //when a project assignments gets disqualified, check if all of the project assignment for 
    //the opportunity has been disqualified (and approved by manager for retail opps).
    //If Yes, then enable cross selling by auto inserting project assignment records linking 
    //current active projects to the opportunities.
    private void handleDisqualifiedProjects(){
        //If a project assignment gets disqualified, get the related opportunity ids
        Set<Id> disqIds = new Set<Id>();
        for(Project_Enquiry__c pa : newPAs){
            system.debug('The disqualified status: ' + pa.Status__c); 
            if((String.isNotBlank(pa.Opportunity__c) 
               && ((pa.Status__c == DisqStatus && oldPAMap.get(pa.Id).Status__c != DisqStatus))) ||
               (pa.Property_Connect__c && pa.Status__c == 'Submit for Disqualification' 
                && oldPAMap.get(pa.Id).Status__c != 'Submit for Disqualification')
            ){
                //jh - no longer needed
                //|| (pa.Manager_Approval__c && !oldPAMap.get(pa.Id).Manager_Approval__c)
                disqIds.add(pa.Opportunity__c);
            }
        }
        if(disqIds.isEmpty()) return;

        //query all the project assignment records for the above opportunity ids
        List<Opportunity> oppsWithPAs = [Select Id, Sales_Channel__c,AccountId,
                                        (Select Id,Status__c,Project__c,Manager_Approval__c From Project_Enquiries__r) 
                                        From Opportunity Where Id in : disqIds];

        //for the opportunities, find out if there any other non disqualified projects        
        List<Opportunity> oppsToCrossSell = new List<Opportunity>();
        Map<Id,Set<Id>> oppWithPAIds = new Map<Id,Set<Id>>();        
        Boolean bCrossSellAllowed;
        for(Opportunity opp : oppsWithPAs){
            bCrossSellAllowed = true;
            Set<Id> paIds = new Set<Id>();
            for(Project_Enquiry__c pa : opp.Project_Enquiries__r){
                paIds.add(pa.Project__c);  
                if(pa.Status__c != DisqStatus) {
                    bCrossSellAllowed = false; 
                    break; 
                }
                //jh - original salefix logic
                /*if(((opp.Sales_Channel__c != 'Retail' && pa.Status__c != DisqStatus)
                || (opp.Sales_Channel__c == 'Retail' && (pa.Status__c != DisqStatus || !pa.Manager_Approval__c)))){
                        bCrossSellAllowed = false; break;
                }*/ 
            }
            oppWithPAIds.put(opp.Id,paIds);
            if(bCrossSellAllowed) oppsToCrossSell.add(opp);        
        }
        if(oppsToCrossSell.isEmpty()) return;

        //query the current active projects
        List<Project__c> activeProjects = [ select Id,Name,Status__c from Project__c 
                                where Status__c in ('Planned', 'In Progress') 
                                and RecordType.Name = 'Apartments' 
                                and Business_Unit__c = 'Apartments' ] ;
        
        //create project assignment records linking the active projects and the opportunities                        
        List<Project_Enquiry__c> paList = new List<Project_Enquiry__c>();                        
        for(Opportunity opp : oppsToCrossSell){
            for(Project__c prj : activeProjects){
                if(oppWithPAIds.get(opp.Id).contains(prj.Id))
                    continue;

                Project_Enquiry__c pa = new Project_Enquiry__c();
                pa.Opportunity__c = opp.Id;
                pa.Project__c = prj.Id;
                pa.Status__c = 'Preselected';                
                pa.Property_Connect__c = true;
                paList.add(pa);
            }
        }                        

        if(paList.size() > 0) insert paList;
    }

    //update campaign rollup count field
    private void updateCampaignRollupCount(){
        Set<Id> campIds = new Set<Id>();
        //jh - based on new business rules can be called from a delete trigger, I don't want to change existing code so have just added the below
        if(isDel) {
            newPAs = oldPAs; 
        }
        
        for(Project_Enquiry__c pa : newPAs){
            if(!isUpdate && String.isNotBlank(pa.Campaign__c) || (isUpdate && (oldPAMap.get(pa.Id).Campaign__c != pa.Campaign__c))){
                //jh - someone could blank out the campaign ID, in this case use the camp id so the campaign rollup can be updated..
                if(String.isNotBlank(pa.Campaign__c)) {
                    campIds.add(pa.Campaign__c);
                }
                
                if(oldPAMap != null && !oldPAMap.isEmpty() && String.isNotBlank(oldPAMap.get(pa.Id).Campaign__c)){
                    campIds.add(oldPAMap.get(pa.Id).Campaign__c); 
                }
            }
        } 
        if(campIds.size() > 0) {
            List<Campaign> camps =  [Select Id, (Select Id From Project_Enquiries__r) 
                                    From Campaign Where Id in :campIds];
            for(Campaign c : camps){
                c.No_Of_Project_Enquiries__c = c.Project_Enquiries__r.size();
            }
            update camps;
        }
    }

}