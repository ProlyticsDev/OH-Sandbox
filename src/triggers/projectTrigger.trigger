trigger projectTrigger on Project__c (after insert, before update) {
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
        	ohHelper.createOrAssignCreditorLedger(Trigger.new);    
        }
    }
    
    if (Trigger.isBefore) {
        if (Trigger.isUpdate) {
            List<Project__c> projects = new List<Project__c>();
            for(Project__c objProject : Trigger.new) {
                if(objProject.Solicitor__c != Trigger.oldMap.get(objProject.Id).Solicitor__c) {
                	projects.add(objProject);
                }
            }
            ohHelper.createOrAssignCreditorLedger(projects);
        }
    }
}