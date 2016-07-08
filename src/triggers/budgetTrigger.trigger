trigger budgetTrigger on Budget__c (After Insert) {

/*
Created by: Colin Johnson, Aprika (colin.johnson@aprika.com.au)
Created date: 18 February 2013
Trigger Purpose: Take the record being inserted and create a duplicate Budget record with a Type value of Balance
*/

    //Declare the variables required
    Budget__c[] bList = new Budget__c[]{}; //List for new Budget records    
    
    For(Budget__c b: trigger.new){
        
            
        //If the Budget record has a Type of 'Actual' then create a duplicate 'Balance' record
        If(b.Type__c == 'Actual'){
            //Create a duplicate record of the Budget record
            Budget__c bNew = new Budget__c(Name=b.Name + ' (Balance)', End_Date__c = b.End_Date__c, Project__c = b.Project__c, Start_Date__c = b.Start_Date__c, Type__c = 'Balance', Related_Record__c = b.Id);
            //Add the new Budget Item record to the list to be inserted
            bList.add(bNew);
        }
        //Insert the list of duplicate Budget Item records
    }
    insert bList;
  
}