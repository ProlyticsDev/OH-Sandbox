public class CommissionData {
    public Commission__c Payment_1{get;set;}
    public Commission__c Payment_2{get;set;}
    public boolean isValid{ get; set;}
    private final MAP<String, ID> rTMap;
    
    public CommissionData(Commission__c c){
        Payment_1=c; 
        IsNew=false; 
        hasGST=true;
        OldAmountP1 = c.Amount__c;
        TotalOldAmount = c.Total_Commission_Amount__c;
        OldIncentive = c.Incentive__c;
        isValid = true;
        
        rTMap=CommissionDetail_Helper.getRecordTypeMap();

        if(c.Id!=null)SetGSTStatus(c.GST_Status__C);
    }
    public CommissionData(Commission__c c,Commission__c c2)
    {
            this(c);
            Payment_2=c2;
            OldAmountP2 = c2.Amount__c;         
    } 
    public CommissionData()
    {
        this(new Commission__c(), new Commission__c());
    }

    public Map<string,string> LabelNames{get;set;}
    public string Num{get;set;}
    public boolean HeaderVisible {get;set;}
    public string Header {get;set;}
    public boolean IsNew {get;set;}
    
    public decimal OldAmountP1 {get;set;}
    public decimal OldAmountP2 {get;set;}
    public decimal TotalOldAmount {get;set;}
    public decimal OldIncentive {get;set;}
    public string ChangeReason {get;set;}
    
    public string Validate(){
        System.Debug('Error is: ' + Payment_1.Category__c + ' ' + Payment_1.Amount__c);

        if(Payment_1.Payment_Percentage__c == null || Payment_1.Payment_Percentage__c <1 || Payment_1.Payment_Percentage__c > 100){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter valid payment percentage between 1 and 100%';
        }
        
        if(Payment_1.OH_Commission_Percentage__c != null && (Payment_1.OH_Commission_Percentage__c <0 || Payment_1.OH_Commission_Percentage__c > 100)){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter valid OH commission percentage';
        }

        if(Payment_1.Total_Commission_Amount__c == null || Payment_1.Total_Commission_Amount__c < 0) {
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter a valid commission amount';
        }

        if (Payment_1.Category__c.toLowerCase()!='house' && Payment_1.Total_Commission_Dollars_Flat_Fee__c == null && (Payment_1.Commission_Percentage__c == null || Payment_1.Commission_Percentage__c < 0 || Payment_1.Commission_Percentage__c > 100 ))
        {
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter a valid commission percentage';
        }

        if(String.isBlank(Payment_1.Commission_Invoice_To__c) && Payment_1.RecordTypeID == rTMap.get('oliver hume')){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : "Commission Invoice To" cannot be blank';
        }

        if(Payment_1.RecordTypeID == rTMap.get('channel') || Payment_1.RecordTypeID == rTMap.get('staff') /*|| Payment_1.Category__c.toLowerCase()=='house'*/) {
            if (Payment_1.OH_Commission_Percentage__c == 0 )Payment_1.OH_Commission_Percentage__c = null;
            if (Payment_1.Commission_Percentage__c == 0 )Payment_1.Commission_Percentage__c = null;

            if (Payment_1.Oliver_Hume__c == null){
                return Payment_1.Category__c + ' commission ' + Num + ' P1 : "Oliver Hume Account" cannot be blank';
            }
            if (Payment_1.Total_Commission_Dollars_Flat_Fee__c == null && 
                (Payment_1.OH_Commission_Percentage__c == null || Payment_1.Commission_Percentage__c == null)) {
                return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter both commission percentages or the commission flat fee amount';
            }
            if (Payment_1.Total_Commission_Dollars_Flat_Fee__c != null && Payment_1.OH_Commission_Percentage__c != null && Payment_1.Commission_Percentage__c != null) {
                return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter either the commission percentages or the commission flat fee but not both';
            }            
        }
        
        if(String.isBlank(Payment_1.Payment_Stage__c)){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Payment Trigger cannot be blank';
        }

        if(Payment_1.Due_Date__c == null){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Payment due date cannot be blank';
        }
        
        if(!String.isBlank(Payment_2.Payment_Stage__c) && Payment_2.Due_Date__c == null){
            return Payment_2.Category__c + ' commission ' + Num + ' P2 : Payment due date cannot be blank';
        }

        if(Payment_2.Amount__c !=null && Payment_2.Amount__c > 0 && Payment_2.Amount__c>0 && (String.isBlank(Payment_2.Payment_Stage__c) || Payment_2.Due_Date__c==null)){
            return Payment_2.Category__c + ' commission ' + Num + ' P2 : Payment due date and Payment Stage cannot be blank';
        }

        if((Payment_2.Amount__c ==null || Payment_2.Amount__c==0) && (!String.isBlank(Payment_2.Payment_Stage__c) || Payment_2.Due_Date__c!=null)){
            return Payment_2.Category__c + ' commission ' + Num + ' P2 : Payment Amount cannot be blank';
        }

        if(Payment_1.Amount__c ==null || Payment_1.Amount__c<=0){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter valid amount or percentage ';
        }
        
        if(Payment_1.Total_Commission_Dollars_Flat_Fee__c != null && Payment_1.Total_Commission_Dollars_Flat_Fee__c < 0){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Please enter a valid flat fee';
        }
        
        if( !IsNew && oldAmountP1!=null &&  math.abs(Payment_1.Amount__c - oldAmountP1) > 0.01 && (ChangeReason== null || ChangeReason == '')){
            return Payment_1.Category__c + ' commission ' + Num + ' P1 : Amount changed but no reason provided: New value: ' +  Payment_1.Amount__c + ' old value: ' + oldAmountP1;
        }
        
        else if( !IsNew && oldAmountP2!=null &&  math.abs(Payment_2.Amount__c - oldAmountP2) > 0.01 && (ChangeReason== null || ChangeReason == '')){
            return Payment_1.Category__c + ' commission ' + Num + ' P2 : Amount changed but no reason provided: New value: ' +  Payment_2.Amount__c + ' old value: ' + oldAmountP2;
        }
        
        if( !IsNew && OldIncentive!=null &&  Payment_1.Incentive__c != OldIncentive && (ChangeReason== null || ChangeReason == '')){
            return Payment_1.Category__c + ' commission ' + Num + ' : Incentive Amount changed but no reason provided';
        }
        return null;
    }
    
    public string getFuncName(){
        return Payment_1.Category__c.Replace(' ','')+Num;
    }
    
    public void UpdateGSTStatus(){
    	if (  Payment_1.Account__c == null ) return;
        Account[] accs=[select gst_status__c from account where id=: Payment_1.Account__c];
        System.Debug('The Account is '  + accs);
        if(accs.Size()>0) SetGSTStatus(accs[0].GST_Status__c); 
    }
    public void SetGSTStatus(string gststatus){
        hasGSt = gststatus!=null&&gststatus.equalsIgnoreCase('GST Exempt')?false:true;
    }
    
    public boolean hasGST{get;set;}
}