//SalesFix : Campaign Management Extension Controller
public class CampaignExtnController {

	//Variables
	private Campaign parentCampaign;
	public Integer childCampCount {get; set;}
	public Integer existingCount {get; set;} 
	public Integer delIndex {get; set;}
	public List<CampaignWrapper> childCampaigns {get; set;}
	//Constructor
	public CampaignExtnController(ApexPages.StandardController stdController) {
        parentCampaign = [Select Id,Name,Project__c,Channels__c,StartDate,EndDate,ActualCost,IsActive 
                          from Campaign where Id =: stdController.getId() limit 1];
        
		List<Campaign> childCamps = [Select Id,Name,StartDate,EndDate,ActualCost,
									IsActive,Project__c,Channels__c 
									From Campaign where ParentId =:parentCampaign.Id ];
		existingCount = childCamps.size();
		childCampaigns = new List<CampaignWrapper>();
		for(Integer i=0;i<childCamps.size(); i++){
			childCampaigns.add(new CampaignWrapper(i,childCamps[i]));
		}
	}

	public PageReference MangeCampaigns(){
		if(childCampCount > 0){
			for(Integer i=0;i<childCampCount;i++){
				Campaign c = new Campaign();
				c.ParentId = parentCampaign.Id;
				c.Name = parentCampaign.Name;
				c.IsActive = true;
				c.Project__c = parentCampaign.Project__c;
				c.Channels__c = parentCampaign.Channels__c;
				childCampaigns.add(new CampaignWrapper(existingCount + i, c ));
			}
		}
		return null;
	}

	public PageReference UpdateChildCampaigns(){
		try{
			List<Campaign> cList = new List<Campaign>();
			for(CampaignWrapper cw : childCampaigns){
				cList.add(cw.camp);
			}
			upsert cList;
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Campaign records are updated successfully.'));			
		}catch(Exception ex){
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));			
		}
		return null;
	}

	public PageReference deleteCampaign(){
		system.debug('delete Index : ' + delIndex);
		if(delIndex >= 0){
			Integer idxToDel = 0;
			for(CampaignWrapper cw : childCampaigns){
				if(cw.index == delIndex){
					if(String.isNotEmpty(cw.camp.Id)){
						delete cw.camp;	
					}
					childCampaigns.remove(idxToDel);
					break;
				}
				idxToDel++;				
			}
		}
		return null;
	}

	public class CampaignWrapper{
		public Integer index {get; set;}
		public Campaign camp {get; set;}
		public CampaignWrapper(Integer idx, Campaign c){
			this.index = idx;
			this.camp = c;
		}
	}

}