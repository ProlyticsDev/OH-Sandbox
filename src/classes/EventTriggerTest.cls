@isTest
private class EventTriggerTest {
    
    @isTest static void insertAcc(){
        Account acc = new Account(name = 'TestEventTrigger');
        insert acc;   
        
        Opportunity opp = new Opportunity();
        RecordType objRecordTypeOpportunity = [Select id from RecordType where name = 'Apartments' and sobjectType='opportunity' limit 1];
        opp.name = 'TestEventOpportunity';
        opp.recordTypeId = objRecordTypeOpportunity.id;
        opp.accountid = acc.Id;
        opp.StageName = 'New Enquiry';
        opp.CloseDate = date.today()+2;
        opp.Date_of_Enquiry__c = date.today();
		opp.Property_Type__c = 'Apartment';
        opp.Enquiry_Method__c = 'Phone';
        opp.Rating__c = 'Cold';
        insert opp;
        
        Event ev = new Event();
        ev.Ownerid = userinfo.getUserId();
        ev.Subject = 'Inside Sales Appointment';
        ev.StartDateTime = datetime.now().addDays(1);
        ev.EndDateTime = datetime.now().addDays(2);
        ev.Type = 'Inside Sales Appointment';
        ev.Appointment_Type__c = 'Meeting';
        ev.Appointment_Status__c ='Appointment Complete' ;        
        ev.Location_Type__c = 'Phone';
        ev.WhatId = opp.Id;
        insert ev;
        
        Opportunity oppt = new Opportunity();
        oppt = [select Next_Appointment_Date__c from Opportunity where id =: ev.WhatId];
                       
        System.assertEquals(oppt.Next_Appointment_Date__c,ev.StartDateTime.date());
        
        Database.executeBatch(new NextAppointmentBatch());
    }
}