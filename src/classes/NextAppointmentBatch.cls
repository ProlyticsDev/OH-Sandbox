global class NextAppointmentBatch implements Database.Batchable<SObject> {
  
  String query;
  DateTime dt;

  global NextAppointmentBatch() {
    query = 'Select Id, AccountId, (Select StartDateTime from Events where Type = \'Inside Sales Appointment\' and StartDateTime >: dt Order By StartDateTime asc limit 1) from Opportunity where RecordType.Name = \'Apartments\'';
  }
  
  global Database.QueryLocator start(Database.BatchableContext BC) {
    dt = DateTime.now();
    return Database.getQueryLocator(query);
  }

     global void execute(Database.BatchableContext BC, List<sObject> scope) {       
       List<Account> accList = new List<Account>();
    for(sObject sobj : scope){
      Opportunity opp = (Opportunity)sobj;
      if(opp.Events != null && opp.Events.size() == 1){
        opp.Next_Appointment_Date__c = opp.Events[0].StartDateTime.date();      
        Account acc = new Account(Id = opp.AccountId);
        acc.Next_Appointment_Date__c = opp.Events[0].StartDateTime.date();      
        accList.add(acc);
      }
    }
    Database.update(scope, false);    

    if(accList.size() > 0)
      Database.update(accList, false);
  }
  
  global void finish(Database.BatchableContext BC) {
    
  }
  
}