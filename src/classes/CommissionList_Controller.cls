public class CommissionList_Controller {
    
    public CommissionModel ComModel{get;set;} // a list commission of same category
    public string TheCategory{get;set;}
    public string OHAccount{get;set;}
    public string ParentOpportunity{get;set;}
    public Opportunity opp{get; set;}
	private boolean Is_Apartment{get;Set;}
	public boolean getIsApartment(){
		if(Is_Apartment==null)
			Is_Apartment = !CommissionDetail_Helper.IsNewCommmunity(Opp.RecordType.Name);
		return Is_Apartment;
	}
    string debug = '';
    public void Add(){
        Commission__c c = new Commission__c();
        Commission__c c2 = new Commission__c();
        
//business rule 
        if(TheCategory.equalsIgnoreCase('oliver hume') && ComModel.Commissions.Size() >0){
            if(ComModel.Commissions[ComModel.Commissions.Size()-1].Payment_1.Account__c!=null){
                Account[] accs=[select Name from Account where Id=:ComModel.Commissions[ComModel.Commissions.Size()-1].Payment_1.Account__c];
                if(accs.Size()>0){
                    c.Commission_Invoice_To__c= accs[0].name;//ComModel.Commissions[ComModel.Commissions.Size()-1].Payment_1.Commission_Invoice_To__c;
                    c2.Commission_Invoice_To__c= accs[0].name; //ComModel.Commissions[ComModel.Commissions.Size()-1].Payment_1.Commission_Invoice_To__c;
                }
            }
        }
    
        else if(TheCategory.equalsIgnoreCase('house') ){
            c.Account__c = OHAccount;
            c2.Account__c = OHAccount;
        }

        if(!TheCategory.equalsIgnoreCase('oliver hume')){
            c.oliver_hume__c=OHAccount;
            c2.oliver_hume__c=OHAccount;
        }
        c.Opportunity__c = ParentOpportunity;
        c2.Opportunity__c = ParentOpportunity;
        
        CommissionData cd=new CommissionData(c,c2);
        cd.HasGST=true;
        ComModel.Commissions.Add(cd);
        cd.Num=''+ ComModel.Commissions.Size();
        
        c.Sequence__c = ComModel.Commissions.Size();
        c.Category__c= TheCategory;
        c.IsAutoCreated__c = false;
        c.Payment_Type__c = 'P1';
        c.RecordTypeId = CommissionDetail_Helper.getCommissionRecordType(TheCategory);
        c.Status__c = 'Pending';
        
        
        c2.Sequence__c = ComModel.Commissions.Size();
        c2.Category__c= TheCategory;
        c2.IsAutoCreated__c = false;
        c2.Payment_Type__c = 'P2';
        c2.RecordTypeId = CommissionDetail_Helper.getCommissionRecordType(TheCategory);
        c2.Status__c = 'Pending';
        
        
        cd.IsNew=true;
    }
    
    public string getSectionHeader(){
        return CommissionDetail_Helper.GetSectionHeader(TheCategory,'');
    }
    
    public string getShortName(){
        return CommissionDetail_Helper.GetShortName(TheCategory);
    }
    
    public boolean getShowCategory(){
        if (TheCategory == 'channel') return !opp.Channel_Paid_Direct__c;
        return true;
    }
}