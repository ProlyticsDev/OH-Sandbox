//SalesFix : Trigger Handler to support campaign memeber trigger
public with sharing class CampaignMemberTriggerHandler {
    //variables
    Private List<CampaignMember> oldCMs;
    Private List<CampaignMember> newCMs;
    Private Map<Id,CampaignMember> oldCMMap;
    Private Map<Id,CampaignMember> newCMMap;
    Private Boolean isUpdate;
    Private Final String GlobaUnsubscribeCampaign = 'Oliver Hume Master - Email Opt Out';

    //constructor
    public CampaignMemberTriggerHandler(){
        this.oldCMs = (List<CampaignMember>)trigger.old;
        this.newCMs = (List<CampaignMember>)trigger.new;
        this.oldCMMap = (Map<Id,CampaignMember>)trigger.oldMap;
        this.newCMMap = (Map<Id,CampaignMember>)trigger.newMap;
        this.isUpdate = trigger.isUpdate;
    }

	public void HandleAfterInsert() {
		handlerEmailUnsubscribe(true);
	}

	public void HandleAfterUpdate() {
		handlerEmailUnsubscribe(true);
	}

	public void HandleAfterDelete() {
		handlerEmailUnsubscribe(false);
	}

	//when a campaign member is inserted or updated for the master email unsubscribe campaign,
	//update the Email unsubscribe field on the linked Lead/Contact	to true
	//when a campaing memeber is removed from the master unsubscribe campaign, update the
	//email optout field on the corresponding lead/contact to false.
	private void handlerEmailUnsubscribe(Boolean optOut){
		List<Campaign> masterCamp = [Select Id From Campaign Where Name = :GlobaUnsubscribeCampaign];
		if(masterCamp.size() > 0){
			Id masterEmailCampId = masterCamp[0].Id;
			system.debug('GlobalCamp size : ' + masterCamp.size());
			system.debug('GlobalCampId from handler : ' + masterEmailCampId);
			Set<Id> leadIds = new Set<Id>();
			Set<Id> contactIds = new Set<Id>();

			List<CampaignMember> listToIterate;
			if(optOut == true)//when its optOut, campaignmember is either created or updated. so look in new CMS
				listToIterate = newCMs;
			else // when its not optOut, campaignmember is removed from the campaign. so look in the old CMs
				listToIterate = oldCMs;

			for(CampaignMember cm : listToIterate){
				system.debug('campaign memeber : ' + cm.Status + '-' + cm.CampaignId + '-'+cm.LeadId + '-'+cm.ContactId);
				if(cm.CampaignId == masterEmailCampId && cm.Status == 'Unsubscribed'){
					if(String.isNotBlank(cm.LeadId))
						leadIds.add(cm.LeadId);
					else if(String.isNotBlank(cm.ContactId))
						contactIds.add(cm.ContactId);
				}
			}

			if(leadIds.size() > 0)
				updateLeadEmailOptOut(leadIds,optOut);

			if(contactIds.size() > 0)
				updateContactEmailOptOut(contactIds,optOut);				

		}
	}

	private void updateLeadEmailOptOut(Set<Id> leadIds,Boolean optOutStatus){
		List<Lead> leadsToUpdate = [Select Id,HasOptedOutOfEmail From Lead Where Id in :leadIds];
		for(Lead l : leadsToUpdate){
			l.HasOptedOutOfEmail = optOutStatus;
		}
		update leadsToUpdate;
	}

	private void updateContactEmailOptOut(Set<Id> contactIds,Boolean optOutStatus){
		List<Contact> contactsToUpdate = [Select Id,HasOptedOutOfEmail From Contact Where Id in :contactIds];
		for(Contact c : contactsToUpdate){
			c.HasOptedOutOfEmail = optOutStatus;
		}
		update contactsToUpdate;
	}
}