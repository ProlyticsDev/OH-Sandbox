/**
* @author JH 
* @date 24/03/2016
* @description Schedule for all opportunities. Passes in a query of all opps. 
*/ 
public with sharing class NextAppointmentBatchSchedule implements Schedulable{
    
    public void execute(SchedulableContext sc) {
     
        NextAppointmentBatch nextOppBatch = new NextAppointmentBatch();
        Database.executeBatch(nextOppBatch );  
    }
}