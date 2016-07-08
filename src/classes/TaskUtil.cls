public without sharing class TaskUtil {
    public static void updateActivityDate(List<Task> newTasks, Map<Id, Task> oldTasks) {
        if (oldTasks == null || newTasks == null)
            return;
        
        Task oldTask;
        //Update custom activity date field whenever Due Date is changed.
        for (Task task : newTasks) {
             oldTask = oldTasks.get(task.Id);
             
             if (oldTask.ActivityDate != task.ActivityDate)
                task.Activity_Date__c = task.ActivityDate;
             
        }
    }
    
    public static void updateActivityDate(List<Task> newTasks) {
        if (newTasks == null)
            return;
            
        Set<Id> oppIds = new Set<Id>();
        for (Task task : newTasks) {
            if (task != null && task.WhatId != null)
                if (String.valueOf(task.WhatId).subString(0,3) == '006')
                    oppIds.add(task.WhatId);
        }
        
        if (oppIds.size() > 0) {
            Map<Id, Opportunity> opportunities = new Map<Id, Opportunity>([SELECT Id, Project_Picklist__c FROM Opportunity WHERE Id IN :oppIds]);
            
            for (Task task : newTasks) {
                if (task.Activity_Date__c == null || task.Activity_Date__c != task.ActivityDate) {
                    if (task.ActivityDate == null)
                        task.ActivityDate = Date.today();
                        
                    task.Activity_Date__c = task.ActivityDate;    
                }
                
                Opportunity opportunity = opportunities.get(task.WhatId);
                if (opportunity != null && String.IsNotBlank(opportunity.Project_Picklist__c) &&
                   (task.Project_Name__c == null || task.Project_Name__c != opportunity.Project_Picklist__c))
                       task.Project_Name__c = opportunity.Project_Picklist__c;
                   
            }
        }
    }
}