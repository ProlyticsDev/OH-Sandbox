public with sharing class buildersrunController {

    //used to specify the number of additional task rows to create
    public integer rows{get; set;}
    public Builders_Run__c dummyRun{get; set;}
    
    public buildersrunController(ApexPages.StandardController controller) {


        rawBRs = new runRow[]{};    
        rawBRs.add(new runRow()); 
        runVillageError = false;

       this.project = (project__c)controller.getRecord();

               
       rows = 1;
        //set dummy
        dummyRun = new Builders_Run__c();
        dummyRun.Date__c = date.today();
        if(project != null && project.Id != null){
            dummyRun.Project__c = project.Id;            
        }
        

    }

    public Project__c project{get; set;}
    public Id selectProject{get; set;}
    public date inputdate{get;set;}
    private runRow[] rawBRs;  
    public boolean runVillageError{get; set;}

        
    public runRow[] newBRs {
       get { 
           runRow[] tempBR = new runRow[]{};
           for(runRow br: rawBRs){
               if(!br.isDeleted){
                   tempBR.add(br);
               }
           }
           return tempBR; }
       set { newBRs = value; }
    }

    Public class runRow{
    
        Public Builders_Run__c newBR{get;set;}
        Public boolean isDeleted{get; set;}
        
        public boolean runProjectError{get; set;}
        public boolean runBuilderError{get; set;}
        public boolean runUserError{get; set;}

            
        Public runRow(){
        
            this.newBR = new Builders_Run__c();
            this.isDeleted = false;
            
            runBuilderError = false;

            
        
        }
        
        public void deleteRow(){
            this.isDeleted = true;
        }
           
    }
    
    public void addRow(){
        //add another row to the Builders Run table

        try{
           for(integer i = 0; i < rows; i++){
               rawBRs.add(new runRow());
           } 
        }
        catch(exception e){
            //there was a problem, probably that an invalid integer was specified.
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Please check you have entered a valid number of rows: '+e.getMessage()));
        }
        
    }

    
    Public pageReference createRuns(){

        boolean hasErrors = false;

            if(dummyRun.Display_Village__c == null){
                runVillageError = true;
                hasErrors = true;
            }
            else{
                runVillageError = false;
            }
    
        Builders_Run__c[] insertBR = new Builders_Run__c[]{};

        for(runRow br: newBRs){

            
            if(br.newBR.Display_Builder__c == null || br.newBR.Display_Builder__c ==''){
                br.runBuilderError = true;
                hasErrors = true;
            }
            else{
                br.runBuilderError = false;
            }            
            
            br.newBR.Name = dummyRun.Display_Village__c + ' (' + br.newBR.Display_Builder__c + ' - ' + dummyRun.Date__c.format() + ')';
            br.newBR.Project__c = dummyRun.Project__c;
            br.newBR.Date__c = dummyRun.Date__c;
            br.newBR.Display_Village__c = dummyRun.Display_Village__c;
            insertBR.add(br.newBR);
        }  
        if(!hasErrors){
            try{     
                insert insertBR;  
                //write a message to the page, and reset the builders run lists.
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Thank you, your new Builders Run(s) have been saved successfully'));
                rawBRs = new runRow[]{};    
                rawBRs.add(new runRow());
                return new pageReference('/' + project.Id);  
            }
            catch(dmlException d){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Failed to save.  Please check your entries and try again.'));
                return null;    
            }  
        }
        else{
            //some required fields were not added, so add an error message to the page.
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Required fields missing.  Please check your entries and try again.'));
            return null;
        }    
    }
    

}