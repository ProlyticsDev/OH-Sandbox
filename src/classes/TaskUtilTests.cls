@IsTest
private class TaskUtilTests {
    static testmethod void testUpdateOfActivityDate() {
        Test.startTest();
           OppToTaskMapping__c mapping = new OppToTaskMapping__c(
                Name = 'Walk-In New',
                Enquiry_Method__c = 'Walk-In',
                Task_Subject__c = 'Walk-In Enquiry',
                Category__c = 'Walk In - New',
                Type__c = 'Walk-In'
            );
            insert mapping;
         //Create 2 Projects
            Project__c[] projects = new Project__c[]{};
            Project__c p1 = new Project__c(Name = 'Test Project 1', 
                                           Marketing_Notifications__c = userInfo.getUserId(),
                                            City__c = 'Test', 
                                             Description__c = 'Sample Description', 
                                             Region__c = 'Melbourne', 
                                             Street_Address__c = '12 Test', 
                                             Zip_Postal_Code__c = 'Victoria',
                                             Status__c = 'Planned'
                                           );
            projects.add(p1);
            insert projects;
            
            Campaign[] cams = new Campaign[]{};
            //Create 1 parent Campaign
            Campaign parentCampaign = new Campaign(Name = 'Parent Campaign', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', isActive = true);
            insert parentCampaign;
            //create 1 child campaign
            Campaign childCampaign = new Campaign(Name = 'Child Campaign', Project__c = p1.Id, StartDate = date.today().toStartOfMonth(), EndDate = date.today().addMonths(1).toStartOfMonth().addDays(-1), Channels__c = 'Channel1;Channel2', ParentId = parentCampaign.Id, isActive = true);
            insert childCampaign;
            //create some sample opportunities to test campaign assignment.
            Account acc1 = new Account(Name = 'Account 1');
            insert acc1;
        
           Opportunity opp1 = new Opportunity(Name = 'Test Opp1', StageName = 'New Enquiry', CloseDate = date.today(), Date_of_Enquiry__c = date.today(), Enquiry_Source__c = 'Channel1', AccountID = acc1.Id, Project_Picklist__c = 'Test Project 1');
           insert opp1;
           Test.stopTest();
            
            Task task = retrieveTaskByOppId(opp1.Id);
            
            System.assertEquals(task.ActivityDate, Date.today(), 'Due date should be today.');
            System.assertEquals(task.Activity_Date__c, task.ActivityDate, 'Activity Date should be updated.');
            
            task.ActivityDate = Date.today().addDays(3);
            
            update task;
            
            task = retrieveTaskByOppId(opp1.Id);
            
            System.assertEquals(task.ActivityDate, Date.today().addDays(3), 'Due date should be updated to 3 days later.');
            System.assertEquals(task.Activity_Date__c, task.ActivityDate, 'Activity Date should be updated.');
            
    }
    
    private static Task retrieveTaskByOppId(Id oppId) {
        return [Select Id, WhatId, WhoId, ActivityDate, Activity_Date__c FROM Task WHERE WhatId =: oppId limit 1];
    }
}