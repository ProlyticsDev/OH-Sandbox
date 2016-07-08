@isTest
private class CommissionModelTests {
	static Account acc;
	static void SetUp() {
		acc = new Account();
		acc.Name = 'Test';
		acc.RecordTypeId = UtilClass.orgRecordTypeMap.get('account_oliver_hume_account').Id;
		insert acc;
	}

	static testMethod void TestListCtrlProperties() {
		SetUp();

		Commission__c c = new Commission__c();
		Commission__c c2 = new Commission__c();
		c.Account__c = acc.Id;

		CommissionList_Controller ctlr = new CommissionList_Controller();
		ctlr.ComModel = new CommissionModel();
		ctlr.ComModel.Commissions.add(new CommissionData(c,c2));
		ctlr.TheCategory = 'oliver hume';
		ctlr.OHAccount = acc.Id;
		ctlr.ParentOpportunity = null;
		ctlr.Add();
		ctlr.Add();
		ctlr.TheCategory = 'Management';
		ctlr.Add();
		System.assert(ctlr.getSectionHeader() != '');
		System.assert(ctlr.getShortName() != '');
	}

	static testMethod void TestCommissionModel() {
		CommissionModel m = new CommissionModel();
		m.CategoryName = 'oliver hume';
		m.Commissions = new List<CommissionData>();
		m.Visible = true;
		m.CanAdd = true;

		System.assert(m.CategoryName != '');
	}

	static testMethod void TestCommissionData(){
		SetUp();
		acc.GST_Status__c = 'GST';
		Commission__c c = new Commission__c();
		Commission__c c2 = new Commission__c();
		c.Category__c  = 'oliver hume';
		c.Account__c = acc.Id;


		CommissionData d = new CommissionData();
		d = new CommissionData(c,c2);
		d.LabelNames = new Map<String,String>();
		d.HeaderVisible = true;
		d.IsNew = false;
		d.isValid = false;
		d.Num = '1';
		d.Header = 'Test Header';
		d.ChangeReason = 'Change Reason';
		d.Validate();
		d.Payment_1.Amount__c = 100;
		d.Validate();
		d.oldAmountP1 = 120;
        System.assert(d.Validate().contains('Please enter valid payment percentage between 1 and 100'));
		
        c.Payment_Percentage__c = 30;
        c.OH_Commission_Percentage__c = -1;
        CommissionData d2 = new CommissionData(c,c2);
        System.assert(d2.Validate().contains('Please enter valid OH commission percentage'));

        c.OH_Commission_Percentage__c = 30;
        d2 = new CommissionData(c,c2);
        System.assert(d2.Validate().contains('Please enter a valid commission amount'));

        c.Total_Commission_Amount__c = 100;
		d2 = new CommissionData(c,c2);
        System.assert(d2.Validate().contains('Please enter a valid commission percentage'));
        
        c.Commission_Percentage__c = 50;
        d2 = new CommissionData(c,c2);
        System.assert(d2.Validate().contains('Payment Trigger cannot be blank'));
        
        c.Payment_Stage__c = 'Settled';
        d2 = new CommissionData(c,c2);
        System.assert(d2.Validate().contains('Payment due date cannot be blank'));
        
        System.assert(d.getFuncName()!='');		
		d.UpdateGSTStatus();

		c.RecordTypeId = CommissionDetail_Helper.getRecordTypeMap().get('channel');
		d2 = new CommissionData(c,c2);
		System.assert(d2.Validate().contains('"Oliver Hume Account" cannot be blank'));

		c.Oliver_Hume__c = acc.Id;
		d2 = new CommissionData(c,c2);
		System.debug('xx0: '+d2.Validate());

		d.SetGSTStatus('gst');
		
	}

	static testmethod void testDetailController(){
		CommissionDetailController ctlr= new CommissionDetailController();
		ctlr.CommData = new CommissionData();
		ctlr.CommData.Num = '1';
		ctlr.TheCategory = 'Management';

		string s = ctlr.getLabelPrefix();
		s = ctlr.getSectionHeader();

		System.assert(s!='');
		
	}

}