/**
 * @date        16/02/2016
 * @author      HR
 * @description Test lead conversion
**/
@isTest
private class LeadTriggerTest { 
    /**
    * @description  Test the lead conversion logic i.e. leads with not active project assigned to the queue else get converted
    **/
   /* static testMethod void leadconversionTest() {
        Lead leadwithoutproject = createLead(null);
        
        Lead leadwithnotvalidproject = createLead('projectnotvalid');
        
        //Queue
        String queueId = [SELECT Id FROM Group where Name = 'Bad Leads' and Type = 'Queue' LIMIT 1].Id;
        
        Project__c proj = createProject();
        insert proj;
        
        Lead leadwithproject = createLead(proj.Name);
        
        Test.startTest();
            insert leadwithoutproject;
            insert leadwithnotvalidproject;
            insert leadwithproject;
        Test.stopTest();
        
        Lead validateleadwithoutproject = [SELECT OwnerId, IsConverted FROM Lead WHERE Id=:leadwithoutproject.Id];
        System.assert(validateleadwithoutproject.IsConverted==false, 'Lead without project got converted');
        System.assert(validateleadwithoutproject.OwnerId==queueId, 'Different user got assigned');
        
        Lead validateleadwithproject = [SELECT OwnerId, IsConverted FROM Lead WHERE Id=:leadwithproject.Id];        
        System.assert(validateleadwithproject.IsConverted==true, 'Lead failed to convert.');
        
        Lead validateleadwithnotvalidproject = [SELECT OwnerId, IsConverted FROM Lead WHERE Id=:leadwithnotvalidproject.Id];  
        System.assert(leadwithnotvalidproject.IsConverted==false, 'Lead without valid project got converted.');
    }
    
    static Lead createLead(String proj){
        return new Lead(
                LastName                =   'raza', 
                Salutation              =   'Mr', 
                FirstName               =   'haider', 
                Email                   =   'h.raza1@oh.com.au', 
                MobilePhone             =   '0437400809', 
                Project_Picklist__c     =   proj, 
                Enquiry_Method__c       =   'Web Form', 
                Originating_Source__c   =   'Oliver Hume', 
                Web_2_Lead__c           =   true, 
                Buyer_Type__c           =   'Investor', 
                Purchase_Window__c      =   'Timeframe to purchase', 
                Enquiry_Source__c       =   'Agent Referral', 
                PostalCode              =   '3000', 
                Price_Point__c          =   '$300k‐$399k', 
                Bdr__c                  =   '1'     
        );
    }
    
    static Project__c createProject(){
        return new Project__c(
                Name                =   'TestProject',
                Owner_Assignment__c =   UserInfo.getUserId()
        );
    }*/
}