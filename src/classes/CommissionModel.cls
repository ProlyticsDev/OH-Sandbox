public class CommissionModel {
	public CommissionModel(){Commissions=new List<CommissionData>();}
	public string CategoryName{get;set;}
	public List<CommissionData> Commissions{get;set;}
	public boolean Visible{get;set;}
	public boolean CanAdd{get;set;}
		
// a list of commission Data, 
// e.g. Oliver Hume Entity Commissions	
//	public class CatetoryCommissionList{
//	}
	
	
	
}