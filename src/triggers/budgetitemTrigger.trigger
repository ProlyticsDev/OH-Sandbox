trigger budgetitemTrigger on Budget_Item__c (After Insert) {

/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 18 February 2013
Trigger Purpose: Take the record being inserted and create a duplicate Budget Item record with a Type value of Balance
*/

    //Declare the variables required
    Budget_Item__c[] biList = new Budget_Item__c[]{}; //List for new Budget Item records    
    
    For(Budget_Item__c bi: trigger.new){
        
            
        //If the Budget Item record has a Type of 'Actual' then create a duplicate 'Balance' record
        If(bi.Type__c == 'Actual'){
            //Create a duplicate record of the Budget Item record
            Budget_Item__c biNew = new Budget_Item__c(Name=bi.Name + ' (Balance)', Agent__c = bi.Agent__c, Budget__c = bi.Budget__c, End_Date__c = bi.End_Date__c, Salesperson__c = bi.Salesperson__c, Start_Date__c = bi.Start_Date__c, Type__c = 'Balance', Related_Record__c = bi.Id, Salesperson_pa__c = bi.Salesperson_pa__c);
            //Add the new Budget Item record to the list to be inserted
            biList.add(biNew);
        
        }
        //Insert the list of duplicate Budget Item record.
    }
    insert biList;    
  
}