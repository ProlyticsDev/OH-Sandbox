@isTest
private class CampaignExtnControllerTest {
	
	@isTest static void TestCampaignExtnController() {
		Campaign c = new Campaign(Name='test campaign');
		insert c;

		Campaign childC = new Campaign(Name = 'test child', ParentId = c.Id);
		insert childC;

		ApexPages.StandardController sCntrl = new ApexPages.StandardController(c);		
		Test.setCurrentPage(Page.ManageChildCampaigns);
		CampaignExtnController cec = new CampaignExtnController(sCntrl);

		system.assertEquals(1,cec.existingCount);
		
		cec.childCampCount = 2;
		cec.MangeCampaigns();
		cec.UpdateChildCampaigns();
        cec.delIndex = 1;
        cec.deleteCampaign();
	}
	
	
}