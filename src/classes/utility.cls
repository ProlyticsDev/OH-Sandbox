public with sharing class utility {

	//utility methods and variables.  Initialy used to manage recursion.
	
	
	//used to manage item trigger recursion
	public static Set<String> itemIdSet = new set<String>();
	public static boolean itemAlreadyProcessed(Id itemId) {
        
        if(itemIdSet.contains(itemId)){
        	system.debug('Item Not Processed: '+itemId);
        	return true;
        }
        else{
        	itemIdSet.add(itemId);
        	system.debug('Item Processed: '+itemId);
        	return false;
        }
    }
	
	//used to manage commission trigger recursion
	public static Set<String> commissionIdSet = new set<String>();
	public static boolean commissionAlreadyProcessed(Id commissionId) {
        
        if(commissionIdSet.contains(commissionId)){
        	system.debug('Commission Not Processed: '+commissionId);
        	return true;
        }
        else{
        	commissionIdSet.add(commissionId);
        	system.debug('Commission Processed: '+commissionId);
        	return false;
        }
    }
	
	//used to manage opportunity AFTER trigger recursion
	public static Set<String> oppIdSet = new set<String>();
    public static boolean oppAlreadyProcessed(Id oppId) {
        
        if(oppIdSet.contains(oppId)){
        	system.debug('Opp Not Processed: '+oppId);
        	return true;
        }
        else{
        	oppIdSet.add(oppId);
        	system.debug('Opp Processed: '+oppId);
        	return false;
        }
    }
    
    //used to manage opportunity BEFORE trigger recursion
	public static Set<String> oppBeforeIdSet = new set<String>();
    public static boolean oppBeforeAlreadyProcessed(Id oppBeforeId) {
        if(oppBeforeIdSet.contains(oppBeforeId)){
        	system.debug('Opp Before Not Processed: '+oppBeforeId);
        	return true;
        }
        else{
        	oppBeforeIdSet.add(oppBeforeId);
        	system.debug('Opp Before Processed: '+oppBeforeId);
        	return false;
        }
    }
    //used to manage opportunity After Update trigger recursion
	public static Set<String> oppAfterUpdateIdSet = new set<String>();
    public static boolean oppAfterUpdateAlreadyProcessed(Id oppAfterUpdateId) {
        if(oppAfterUpdateIdSet.contains(oppAfterUpdateId)){
        	system.debug('Opp AfterUpdate Not Processed: '+oppAfterUpdateId);
        	return true;
        }
        else{
        	oppAfterUpdateIdSet.add(oppAfterUpdateId);
        	system.debug('Opp AfterUpdate Processed: '+oppAfterUpdateId);
        	return false;
        }
    }
    
    //used to manage opportunity account team trigger recursion
	public static Set<String> oppAccIdSet = new set<String>();
    public static boolean oppAccAlreadyProcessed(Id oppAccId) {
        
        if(oppAccIdSet.contains(oppAccId)){
        	system.debug('OppAcc Not Processed: '+oppAccId);
        	return true;
        }
        else{
        	oppAccIdSet.add(oppAccId);
        	system.debug('Opp Acc Processed: '+oppAccId);
        	return false;
        }
    }
    
    //used to manage opportunity budget trigger recursion
    public static Set<String> budgetOppIdSet = new set<String>();
    public static boolean budgetOppAlreadyProcessed(Id budgetOppId) {
        
        if(budgetOppIdSet.contains(budgetOppId)){
        	system.debug('Budget Opp Not Processed: '+budgetOppId);
        	return true;
        }
        else{
        	budgetOppIdSet.add(budgetOppId);
        	system.debug('Budget Opp Processed: '+budgetOppId);
        	return false;
        }
    }
    
    //used to manage opportunity commission trigger recursion
    public static Set<String> commOppIdSet = new set<String>();
    public static boolean commOppAlreadyProcessed(Id commOppId) {
        
        if(commOppIdSet.contains(commOppId)){
        	system.debug('Commission Opp Not Processed: '+commOppId);
        	return true;
        }
        else{
        	commOppIdSet.add(commOppId);
        	system.debug('Commission Opp Processed: '+commOppId);
        	return false;
        }
    }
    
    //used to manage account trigger recursion
	public static Set<String> accIdSet = new set<String>();
    public static boolean accAlreadyProcessed(Id accId) {
        
        if(accIdSet.contains(accId)){
        	system.debug('Acc Not Processed: '+accId);
        	return true;
        }
        else{
        	accIdSet.add(accId);
        	system.debug('Acc Processed: '+accId);
        	return false;
        }
    }
    
    //method takes an id and a date, and returns a custom unique id.
    public static string uniqueId(Id projectId, Date enquiryDate){
	   	//convert to 15 digit case sensitive version
	    String shortId = String.valueOf(projectId).left(15);
	    Date startEnquiryDate = enquiryDate.toStartOfMonth();
	    String dateString = String.valueOf(startEnquiryDate.year())+String.valueOf(startEnquiryDate.month())+String.valueOf(startEnquiryDate.day());
    
    	system.debug('custom unique Id: '+shortId+dateString);
    	return shortId+dateString;
    
    }
    
    public static Budget__c createBudget(Opportunity opp){
    	//take an opportunity and create a budget record.
    	Budget__c newBudget = new Budget__c();
    	//set the project
    	newBudget.Project__c = opp.Project__c;
    	//set the start/end date
    	newBudget.Start_Date__c = opp.Date_of_Enquiry__c.toStartOfMonth();
    	newBudget.End_Date__c = newBudget.Start_Date__c.addMonths(1).addDays(-1);
    	newBudget.Name = opp.Project_Picklist__c+' '+newBudget.Start_Date__c.Month()+'-'+newBudget.Start_Date__c.year();
    	newBudget.Type__c = 'Actual';
    	
    	return newBudget;
    }
    
    public static Budget__c createBudgetA(Budget__c budget){
    	//take a budget and create a budget record based off of the lead start date
    	Budget__c newBudget = new Budget__c();
    	//set the project
    	newBudget.Project__c = budget.Project__c;
    	//set the start/end date
    	newBudget.Start_Date__c = budget.Lead_Start_Date__c.toStartOfMonth();
    	newBudget.End_Date__c = budget.Lead_Start_Date__c.toStartOfMonth().addMonths(1).addDays(-1);
    	newBudget.Name = budget.Project__r.Name+' '+newBudget.Start_Date__c.Month()+'-'+newBudget.Start_Date__c.year();
    	newBudget.Type__c = 'Actual';
    	return newBudget;
    }
    
    public static Budget__c createBudgetB(Budget__c budget){
    	//take a budget and create a budget record based off of the lead end date
    	Budget__c newBudget = new Budget__c();
    	//set the project
    	newBudget.Project__c = budget.Project__c;
    	//set the start/end date
    	newBudget.Start_Date__c = budget.Lead_End_Date__c.toStartOfMonth();
    	newBudget.End_Date__c = budget.Lead_End_Date__c.toStartOfMonth().addMonths(1).addDays(-1);
    	newBudget.Name = budget.Project__r.Name+' '+newBudget.Start_Date__c.Month()+'-'+newBudget.Start_Date__c.year();
    	newBudget.Type__c = 'Actual';
    	return newBudget;
    }
    
}