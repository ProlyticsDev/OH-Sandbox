//SalesFix : Trigger on Project Enquiry Object using Trigger Handler pattern
//jh - 20/06/2016 Recalculate the No of Project Enquiries after delete 
trigger PETrigger on Project_Enquiry__c (after insert,after update,before update, after delete) {
	//Create the Handler instance
	PETriggerHandler peh = new PETriggerHandler();


	//handle after update
	if(trigger.isBefore && trigger.isUpdate){
		peh.HandleBeforeUpdate();
	}
	
	//handle after insert
	if(trigger.isAfter && trigger.isInsert){
		peh.HandleAfterInsert();
	}

	//handle after update
	if(trigger.isAfter && trigger.isUpdate){
		peh.HandleAfterUpdate();
	}

	//jh - after delete actions
	if(trigger.isAfter && trigger.isDelete) {
		peh.HandleAfterDelete(); 
	}

}