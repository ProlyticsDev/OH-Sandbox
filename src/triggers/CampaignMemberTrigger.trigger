//SalesFix : Trigger on CampaignMember
trigger CampaignMemberTrigger on CampaignMember (after insert,after update,after delete) {

	CampaignMemberTriggerHandler cmHandler = new CampaignMemberTriggerHandler();		
	if(trigger.isAfter && trigger.isInsert){
		cmHandler.HandleAfterInsert();
	}

	if(trigger.isAfter && trigger.isUpdate){
		cmHandler.HandleAfterUpdate();
	}

	if(trigger.isAfter && trigger.isDelete){
		cmHandler.HandleAfterDelete();
	}			

}