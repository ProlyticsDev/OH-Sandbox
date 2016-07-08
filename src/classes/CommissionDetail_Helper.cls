public class CommissionDetail_Helper {

    static final string SystemRecalcReason = 'Opportunity Net Price Changed - System Recalculation';
    private static final string 
        Oliver_Hume_Entity_Commision = 'Commission to Oliver Hume Entity {0}',
        Channel_Commission = 'Channel Commission Payments',
        Sales_Commission='Sales Consultant {0} Commission Details',
        House_Commission='House Commission from Builder',
        Management_Commission = 'Commission Details';
    
    
    private static final string 
        Oliver_Hume_Entity_Commision_Label = 'OHE{0} ',
        Channel_Commission_Label = 'Channel',
        Sales_Commission_Label = 'SC {0}',
        SM_Commission_Label='Sales Manager',
        CM_Commission_Label='Channel Manager',
        House_Commission_Label='OH Entity {0}';
    

    public static string GetSectionHeader(string Category, string Num){
        if(Category==null)return '';
        Category=Category.ToLowerCase();
        
        if(Category=='oliver hume')
            return string.format(Oliver_Hume_Entity_Commision,new string[]{num});
        else if(Category=='staff')
            return string.format(Sales_Commission,new string[]{num});
        else if(Category=='channel')
            return Channel_Commission;
        else if(Category=='management')
            return Management_Commission;
        else if(Category=='house')
            return House_Commission;
        return '';
    }
    
    public static string GetShortName(string Category){
        if(Category==null)return '';
        Category=Category.ToLowerCase();
        
        if(Category=='oliver hume')
            return 'OH Entity Commission';
        else if(Category=='staff')
            return 'Sales Consultant Commission';
        else if(Category=='channel')
            return 'Channel Commission';
        else if(Category=='management')
            return 'Management Commission';
        else if(Category=='house')
            return 'House Commission From Builder';
        return '';
    }
    
    public static string GetLabelPrefix(string Category, string Num){
        if(Category==null)return '';
        Category=Category.ToLowerCase();
        
        if(Category=='oliver hume')
            return string.format(Oliver_Hume_Entity_Commision_Label,new string[]{num});
        else if(Category=='staff'){
            return string.format(Sales_Commission_Label,new string[]{num});
        }
        else if(Category=='channel')
            return Channel_Commission_Label;
        else if(Category=='management')
            if(num!='2')return SM_Commission_Label;
            else return CM_Commission_Label;
        else if(Category=='house')
            return string.format(House_Commission_Label,new string[]{num});
        return '';
    }
    
    private static List<string> allCategories;
    
// get all commission categories
    public static List<string> getCategories(Map<string,string> CategoryMap){
        if ( allCategories == null ){
            allCategories = new List<string>();
            for( Schema.PicklistEntry f : Commission__c.Category__c.getDescribe().getPicklistValues() ){
                allCategories.add(f.getValue().ToLowerCase());
                if(CategoryMap!=null) CategoryMap.put(f.getValue().ToLowerCase(),f.getValue());
            }
        }
        return allCategories;
    }
    
//Remove category that does not below to the opportunity
//e.g. New Communitity Sale with Build Commision , should not have Sales Cosultant Commission
    public static void RemoveCommissionCategory(Opportunity opp, Map<string,CommissionModel> commissions){
        
        for(string cat: commissions.keyset()){
            if(!getRenderSection(cat,opp.RecordType.Name)) {commissions.remove(cat);}
        }
    }
    
    public static boolean IsNewCommmunity(string RecordTypeName){
        return RecordTypeName == 'Tenant Purchase Scheme' || RecordTypeName == 'Development Sites' || RecordTypeName == 'New Communities';
    }
    
    public static boolean getRenderSection(string Category, string RecordTypeName){
        if(Category==null||Category=='')return false;
        Category=Category.ToLowerCase();
        
        if(IsNewCommmunity(RecordTypeName))
            return Category == 'oliver hume' || Category == 'house' || Category == 'staff'; else
            return Category == 'oliver hume' || Category == 'staff' || Category=='channel' || Category=='management';
        
    }
    
// record type for commission
    private static Map<string,id> recordtypemap;
    
    public static Map<String,id> getRecordTypeMap(){
        if(recordtypemap==null){
            recordtypemap= new Map<string,id>();
            for(RecordType rt : [select id,name from RecordType where Sobjecttype='Commission__c']){
                recordtypemap.put(rt.name.tolowercase(), rt.id);
            }
        }
        return recordtypemap;
    }
    public static id getCommissionRecordType(string cat){
        cat = cat.tolowercase();
        if(getRecordTypeMap().containskey(cat)) return getRecordTypeMap().get(cat);
        else if(cat=='house') return getRecordTypeMap().get('oliver hume');
        else return getRecordTypeMap().get('staff');
    }
    
    @TestVisible
    private static decimal GSTInclusive(Account acc, decimal net ){
        if (acc.GST_Status__c == 'GST') return net * 0.1;
        return net;
    }
    
    
    ///////////////////////////---Create Commission ---////////////////////////////////////////////
    public static CommissionData CreateOliverHumeEntityCommissionDetails(CommissionData comm, Opportunity opp, Id accId, Vendor_Authority__c va, integer num){
        if (opp == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no valid Opportunity record.')); comm.isValid = false;}
        if (va == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no valid Vendor Authority record.')); comm.isValid = false;}
        if (opp != null && opp.Project__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no related Project record on the Opportunity.')); comm.isValid = false;}
        if (opp != null && opp.Project__r.Vendor__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no related Vendor record on the Project.')); comm.isValid = false;}
        if (opp != null && opp.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There are no Payment Days specified on the Vendor record for the Opportunity.')); comm.isValid = false;}
        if (va!=null && va.OH_Commission_Dollars__c > 0 && va.Admin_Fee__c > 0 )  {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'You cannot have a Vendor Authority with both a fixed Commision Amount and an Admin Fee set.')); comm.isValid = false;}
        
        
        //commented out following three lines ,move to controller
        //as these three line won't called if VSA/VA is null
        if (comm.isValid){
            comm.Payment_1.Opportunity__c = opp.id;
            comm.Payment_1.Sequence__c = num;
            comm.Payment_1.Payment_Type__c = 'P1';
            comm.Payment_1.Account__c = accid;
            
            comm.Payment_1.Commission_Invoice_To__c = va.Vendor__c;
            comm.Payment_1.Commission_percentage__c= va.OH_Commission_Percent__c;
            comm.Payment_1.Amount__c = 0;
            comm.Payment_1.Total_Commission_Amount__c = 0;
            comm.Payment_1.Payment_Stage__c = va.P1_Payment_Trigger__c;
            comm.Payment_1.Payment_Percentage__c = va.P1_Payment_Percentage__c;
            comm.Payment_1.Total_Commission_Dollars_Flat_Fee__c = va.OH_Commission_Dollars__c;
            comm.Payment_1.Vendor_Authority__r = va;
            comm.Payment_1.Vendor_Authority__c = va.Id;
            comm.hasGST=true;
            
            if(va.OH_Commission_Percent__c!=null)
                comm.Payment_1.Total_Commission_Amount__c = opp.net_Price__c * (va.OH_Commission_Percent__c /100);
            if(va.OH_Commission_Dollars__c!=null)
            	comm.Payment_1.Total_Commission_Amount__c = va.OH_Commission_Dollars__c;
            if(va.Admin_Fee__c!=null) 
             	comm.Payment_1.Total_Commission_Amount__c = comm.Payment_1.Total_Commission_Amount__c - va.Admin_Fee__c;
                
            if(va.P1_Payment_Percentage__c!=null)
                comm.Payment_1.Amount__c = (comm.Payment_1.Total_Commission_Amount__c * (va.P1_Payment_Percentage__c /100));            
            
            comm.Payment_1.Due_Date__c=SetOliverHumePaymentDate(opp,va.P1_Payment_Trigger__c);  
            
            comm.Payment_2.Opportunity__c = opp.id;
            comm.Payment_2.Commission_Invoice_To__c = va.Vendor__c;
            comm.Payment_2.Commission_percentage__c = va.OH_Commission_Percent__c;
            comm.Payment_2.Payment_Stage__c = va.P2_Payment_Trigger__c;
            comm.Payment_2.Payment_Percentage__c = va.P1_Payment_Percentage__c;
            comm.Payment_2.Vendor_Authority__r = va;
            comm.Payment_2.Vendor_Authority__c = va.Id;
            
            if(comm.Payment_2.Payment_Percentage__c!=null && comm.Payment_2.Payment_Percentage__c>0){
                comm.Payment_2.Payment_Percentage__c = 100 - comm.Payment_1.Payment_Percentage__c;
            }
            comm.Payment_2.Due_Date__c=SetOliverHumePaymentDate(opp,va.P2_Payment_Trigger__c);  
        }
        return comm;
    }

    public static CommissionData CreateChannelCommissionDetails(CommissionData comm, Opportunity opp, Id AccId, Vendor_Sales_Authority__c vsa, Account acc){
        if (opp == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no Opportunity record.')); comm.isValid = false;}
        if (vsa == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no Vendor Sales Authority record for ' + acc.Name + ' Channel Commission.')); comm.isValid = false;}
        if (vsa != null && vsa.Account__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no Account linked to the Vendor Sales Authority record.')); comm.isValid = false;}
        if (vsa != null && vsa.Account__r.GST_Status__c == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no GST Status on the Account "' + acc.Name + '" linked to the Vendor Sales Authority record.')); comm.isValid = false;}
        if (opp != null && opp.Project__r == null)  {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no related Project record on the Opportunity.')); comm.isValid = false;}
        if (opp != null && opp.Project__r.Vendor__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no related Vendor record on the Project.')); comm.isValid = false;}
        if (opp != null && opp.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There are no Payment Days specified on the Vendor record for the Opportunity.')); comm.isValid = false;}
        
        if (comm.isValid){
            comm.Payment_1.Opportunity__c = opp.id;
            comm.Payment_1.Oliver_Hume__c = opp.project__r.OH_Account__c;
            comm.Payment_1.Commission_percentage__c= vsa.commission_percent__c;
            comm.Payment_1.OH_Commission_Percentage__c = vsa.OH_Commission__c;
            comm.Payment_1.Amount__c = 0;
            comm.Payment_1.Total_Commission_Amount__c = 0;
            comm.Payment_1.Payment_Stage__c = vsa.P1_Payment_Trigger__c;
            comm.Payment_1.Payment_Percentage__c = vsa.P1_Payment_Percentage__c;
            comm.Payment_1.Vendor_Sales_Authority__r = vsa;
            comm.Payment_1.Vendor_Sales_Authority__c = vsa.id;
            comm.SetGSTStatus(acc.GST_Status__c);
            //comm.Payment_1.oliver_hume__c=opp.project__r.OH_Account__c;
            
            if(vsa.commission_percent__c!=null && vsa.OH_Commission__c != null)
                comm.Payment_1.Total_Commission_Amount__c = GSTInclusive(vsa.Account__r, opp.net_Price__c) * ((vsa.OH_Commission__c /100) * (vsa.commission_percent__c/100));
            if(vsa.P1_Payment_Percentage__c!=null)
                comm.Payment_1.Amount__c = (comm.Payment_1.Total_Commission_Amount__c * (vsa.P1_Payment_Percentage__c /100));
            
            comm.Payment_1.Due_Date__c = SetChannelPaymentDate(opp,vsa.P1_Payment_Trigger__c);

            comm.Payment_2.Opportunity__c = opp.id;
            comm.Payment_2.Oliver_Hume__c = opp.project__r.OH_Account__c;
            comm.Payment_2.Commission_percentage__c = vsa.commission_percent__c;
            comm.Payment_2.OH_Commission_Percentage__c = vsa.OH_Commission__c;
            comm.Payment_2.Amount__c = 0;
            comm.Payment_2.Total_Commission_Amount__c = 0;
            comm.Payment_2.Payment_Stage__c = vsa.P2_Payment_Trigger__c;
            comm.Payment_2.Payment_Percentage__c = vsa.P2_Payment_Percentage__c;
            comm.Payment_2.Vendor_Sales_Authority__r = vsa;
            comm.Payment_2.Vendor_Sales_Authority__c = vsa.id;
            
            
            if(vsa.commission_percent__c!=null && vsa.OH_Commission__c != null)
                comm.Payment_2.Total_Commission_Amount__c = (((GSTInclusive(vsa.Account__r, opp.net_Price__c) * (vsa.OH_Commission__c /100))) * (vsa.commission_percent__c/100));
            if(vsa.P2_Payment_Percentage__c!=null)
                comm.Payment_2.Amount__c = (comm.Payment_2.Total_Commission_Amount__c * (vsa.P2_Payment_Percentage__c /100));

            comm.Payment_2.Due_Date__c = SetChannelPaymentDate(opp,vsa.P2_Payment_Trigger__c);
 
        }
        return comm;
    }

    public static CommissionData CreateSalesConsultantCommissionDetails(CommissionData comm, Opportunity opp, Id accid, Vendor_Sales_Authority__c vsa, Account acc){
        if (opp == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no Opportunity record.')); comm.isValid = false;}
        if (vsa == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no Vendor Sales Authority record for ' + acc.Name + ' Staff Commission.')); comm.isValid = false;}
        if (vsa != null && vsa.Account__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no Account linked to the Vendor Sales Authority record.')); comm.isValid = false;}
        if (vsa != null && vsa.Account__r.GST_Status__c == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no GST Status on the Account "' + acc.Name + '" linked to the Vendor Sales Authority record.')); comm.isValid = false;}
        if (opp != null && opp.Project__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no related Project record on the Opportunity.')); comm.isValid = false;}
        if (opp != null && opp.Project__r.Vendor__r == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There is no related Vendor record on the Project.')); comm.isValid = false;}
        if (opp != null && opp.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c == null) {ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'There are no Payment Days specified on the Vendor record for the Opportunity.')); comm.isValid = false;}
        
        if (comm.isValid){
            comm.Payment_1.Opportunity__c = opp.id;
            comm.Payment_1.Commission_Invoice_To__c = vsa.Account__c;
            comm.Payment_1.Commission_percentage__c= vsa.commission_percent__c;
            comm.Payment_1.Oliver_Hume__c = opp.project__r.OH_Account__c;
            comm.Payment_1.OH_Commission_percentage__c= vsa.OH_Commission__c;
            comm.Payment_1.Amount__c = 0;
            comm.Payment_1.Total_Commission_Amount__c = 0;
            comm.Payment_1.Payment_Stage__c = vsa.P1_Payment_Trigger__c;
            comm.Payment_1.Payment_Percentage__c = vsa.P1_Payment_Percentage__c;
            comm.Payment_1.Vendor_Sales_Authority__r = vsa;
            comm.Payment_1.Vendor_Sales_Authority__c = vsa.id;

            comm.Payment_1.Total_Commission_Dollars_Flat_Fee__c=vsa.Commission_Dollars__c;
            comm.Payment_1.Total_Commission_Amount__c = (vsa.commission_percent__c == null || vsa.OH_Commission__c == null) ? 0: (opp.net_Price__c * (vsa.OH_Commission__c / 100) * (vsa.commission_percent__c/100));
            comm.SetGSTStatus(acc.GST_Status__c);

            
            if(vsa.commission_percent__c!=null)
                comm.Payment_1.Total_Commission_Amount__c = (GSTInclusive(vsa.Account__r, opp.net_Price__c) * (vsa.commission_percent__c /100));
            if(vsa.P1_Payment_Percentage__c!=null)
                comm.Payment_1.Amount__c = (comm.Payment_1.Total_Commission_Amount__c * (vsa.P1_Payment_Percentage__c /100));

            comm.Payment_1.Due_Date__c=SetSalesConsultantPaymentDate(opp,vsa.P1_Payment_Trigger__c);
            
            comm.Payment_1.Amount__c = (comm.Payment_1.Total_Commission_Dollars_Flat_Fee__c == null || comm.Payment_1.Total_Commission_Dollars_Flat_Fee__c == 0) ? 
                comm.Payment_1.Total_Commission_Amount__c : comm.Payment_1.Total_Commission_Dollars_Flat_Fee__c;
            comm.Payment_1.Vendor_Sales_Authority__c=vsa.id;
            
             
            
            comm.Payment_2.Opportunity__c = opp.id;
            comm.Payment_2.Commission_Invoice_To__c = vsa.Account__c;
            comm.Payment_2.Commission_percentage__c = vsa.commission_percent__c;
            comm.Payment_2.Oliver_Hume__c = comm.Payment_1.oliver_hume__c=opp.project__r.OH_Account__c;
            comm.Payment_2.Amount__c = 0;
            comm.Payment_2.Total_Commission_Amount__c = 0;
            comm.Payment_2.Payment_Stage__c = vsa.P2_Payment_Trigger__c;
            comm.Payment_2.Payment_Percentage__c = vsa.P2_Payment_Percentage__c;
            comm.Payment_2.Vendor_Sales_Authority__r = vsa;
            
            if(vsa.commission_percent__c!=null)
                comm.Payment_2.Total_Commission_Amount__c = (GSTInclusive(vsa.Account__r, opp.net_Price__c) * (vsa.commission_percent__c /100));
            if(vsa.P2_Payment_Percentage__c!=null)
                comm.Payment_2.Amount__c = (comm.Payment_2.Total_Commission_Amount__c * (vsa.P2_Payment_Percentage__c /100));

            comm.Payment_2.Due_Date__c=SetSalesConsultantPaymentDate(opp,vsa.P2_Payment_Trigger__c);
        }
        return comm;
    }

    private static string GetCommissionKey(Commission__c c){
        return GetCommissionKey(c.Opportunity__c,c.Category__c,Integer.valueOf(c.Sequence__c));
    }
    private static string GetCommissionKey(string oppid, string category, Integer seq){
        return (oppid+':'+category+':'+ seq).toLowerCase();
    }

    public static void RecalcCommission(set<string> netpricechanged, set<string> datechanged){
        set<string> allOpps = new set<string>();
        allOpps.addAll(netpricechanged);
        allOpps.addAll(datechanged);
        Map<Id,Opportunity> opps = GetOpps(allOpps);

        Map<Id,Commission__c> toupdate = new Map<Id,Commission__c>();
        
        Commission__c[] comms=getCommissions(allOpps);

//create map Opportunity P1 commission Map
        Map<string,Commission__c> OppP1CommMap=new Map<String,Commission__c>();
        for (Commission__c c: comms){
            if (c.Payment_Type__c == 'P1')OppP1CommMap.put(GetCommissionKey(c),c);
        }

        for(Commission__c c: comms){
//business rule
//don't recalc commission if paid commission
            if (c.Status__c!=null && c.Status__c.equalsIgnoreCase('paid'))continue;

//if change dates on opps
            if (datechanged.contains(c.Opportunity__c)){
                date d = RecalcDate(c,opps.get(c.Opportunity__c));
                if (d!=null) toUpdate.put(c.Id,new Commission__c(Id=c.Id,Due_Date__c=d));
            }

//don't recalc commission amount if users overwrite it (but still recalc dates)
            if (c.Amount_Change_Reason__c!=null && c.Amount_Change_Reason__c!='' && c.Amount_Change_Reason__c != SystemRecalcReason)continue;

//if change net price on opps
            if (netpricechanged.contains(c.Opportunity__c)){
                 RecalcAmount(c, opps.get(c.Opportunity__c),toupdate, OppP1CommMap);
            }
        }

        if (!toupdate.isEmpty())update toupdate.values();
    }


/* REQ: Due Date Automation, Email

From: Pamela Baxter-Smith <p.baxter-smith@oliverhume.com.au>
Sent: Monday, 2 May 2016 5:52 PM
To: Mark Townsend
Cc: Tony Goodson
Subject: Oliver Hume Consolidated Amendments and Bug Fixes for Comms VFP
 
When Payment Stage = Unconditional and the Opportunity Record Type is NOT EQUAL to New Communities
2.     Take the Forecast Unconditional Due Date (new field) and
3.     When Record Type = Oliver Hume: Due Date = Forecast Unconditional Due Date + Vendor Payment Terms; OR
4.     When Record Type = Channel: Due Date = Forecast Unconditional Due Date + Vendor Payment Terms + 7 Days
5.     When Record Type = Staff: Due Date = Forecast Unconditional Due Date + Vendor Payment Terms + Days Up to Last Day of the next month
 
6.     When Payment Stage = Unconditional and the Opportunity Record Type is EQUAL to New Communities
7.     Take the Unconditional Due Date and
8.     When Record Type = Oliver Hume: Due Date = Unconditional Due Date + Vendor Payment Terms; OR
9.     When Record Type = Channel: Due Date = Unconditional Due Date + Vendor Payment Terms + 7 Days
10.  When Record Type = Staff: Due Date = Unconditional Due Date + Vendor Payment Terms + Days Up to Last Day of the next month
 
 
11.  When Payment Stage = Settlement
12.  Take the Expected Settlement Date and
13.  When Record Type = Oliver Hume: Due Date = Expected Settlement Date + Vendor Payment Terms; OR
14.  When Record Type = Channel: Due Date = Expected Settlement Date + Vendor Payment Terms + 7 Days
15.  When Record Type = Staff: Due Date = Expected Settlement Date + Vendor Payment Terms + Days Up to Last Day of the next month


REFACTORED BASED ON EXISTING CODE - PSUEDO:
IF Stage Unconditional
	Record Type = 'Oliver Hume' { Due Date = Is NOT NewCommunities ? 
										Forecast Unconditional Due Date + Vendor Payment Terms;
										Unconditional Due Date + Vendor Payment Terms;}		
																		
	Record Type = 'Channel' { Due Date = Is NOT NewCommunities ? 
										Forecast Unconditional Due Date + Vendor Payment Terms + 7;
										Unconditional Due Date + Vendor Payment Terms + 7 ;}	
																			
	Record Type = 'Staff' { Due Date = Is NOT NewCommunities ? 
										Forecast Unconditional Due Date + Vendor Payment Terms + Days Up to Last Day of the next month;
										Unconditional Due Date + Vendor Payment Terms + Days Up to Last Day of the next mont ;}										

IF Stage Settlement
	Record Type = 'Oliver Hume' { Due Date = Expected Settlement Date + Vendor Payment Terms;}
										
	Record Type = 'Channel' { Due Date = Expected Settlement Date + Vendor Payment Terms + 7 Days}
										
	Record Type = 'Staff' { Due Date = Expected Settlement Date + Vendor Payment Terms + Days Up to Last Day of the next month}	
	
	
	
REFACTORED BASED ON EXISTING CODE - PSUEDO: PASS2
IF Stage Unconditional
	Due Date = Is NOT NewCommunities ?  Forecast Unconditional Due Date + Vendor Payment Terms; Unconditional Due Date + Vendor Payment Terms;}		
	Record Type = 'Channel' { Due Date = Due Date + 7 }	
	Record Type = 'Staff' { Due Date = Due Date + Days Up to Last Day of the next month }	

IF Stage Settlement
	Due Date = Expected Settlement Date + Vendor Payment Terms;
	Record Type = 'Channel' { Due Date = Due Date + 7 }	
	Record Type = 'Staff' { Due Date = Due Date + Days Up to Last Day of the next month }	
											


UPDATED 13/5/2016
	Ignore new communities - Use Forcast Uncoditional Due Date if it exists otherwise use Due Date
*/
    public static Date SetOliverHumePaymentDate( Opportunity opp,string paymenttrigger){
        PaymentTrigger = string.IsBlank(paymenttrigger) ? '' : PaymentTrigger.toLowerCase();
        integer days = ( opp.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c == null ) ? 0: integer.valueOf(opp.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c);

/*
IF Stage Unconditional
	Record Type = 'Oliver Hume  {Forecast Unconditional Due Date != null ? 
										Forecast Unconditional Due Date + Vendor Payment Terms;
										Unconditional Due Date + Vendor Payment Terms;}		
																		
IF Stage Settlement
	Record Type = 'Oliver Hume' { Due Date = Expected Settlement Date + Vendor Payment Terms;}
										
*/    
        
        if(paymentTrigger.indexOf('unconditional')>-1){
        	return (opp.Forecast_Unconditional_Date__c == null ? opp.Unconditional_Due_Date__c : opp.Forecast_Unconditional_Date__c).addDays(days);    
        }  
        if(paymentTrigger.indexOf('settled')>-1 && opp.Expected_Settlement_Date__c != null){
            return opp.Expected_Settlement_Date__c.AddDays(days);
        }
        
        return null;
    }
    
    public static Date SetSalesConsultantPaymentDate(Opportunity opp, string PaymentTrigger){
/*
REFACTORED BASED ON EXISTING CODE - PSUEDO: PASS2
IF Stage Unconditional
	Record Type = 'Staff' { Due Date = Due Date + Days Up to Last Day of the next month }	

IF Stage Settlement
	Record Type = 'Staff' { Due Date = Due Date + Days Up to Last Day of the next month }	
*/
		Date newDate = SetOliverHumePaymentDate(opp, PaymentTrigger);
        System.Debug( 'Staff Due Date: ' + string.valueOf( newDate ));		
		if ( newDate == null ) return null;
	    newDate = newDate.AddMonths(2);
        System.Debug( 'Staff Due Date: Add 2 Months' + string.valueOf( newDate ));		
        System.Debug( 'Staff Due Date: Subtract 1 Day' + string.valueOf( Date.newInstance(newDate.year(), newDate.Month(), 1).AddDays(-1) ));		
	    
        return Date.newInstance(newDate.year(), newDate.Month(), 1).AddDays(-1);
    }

    public static Date SetChannelPaymentDate(Opportunity opp, string PaymentTrigger){
/*
REFACTORED BASED ON EXISTING CODE - PSUEDO: PASS2
IF Stage Unconditional
	Record Type = 'Channel' { Due Date = Due Date + 7 }	

IF Stage Settlement
	Record Type = 'Channel' { Due Date = Due Date + 7 }	

*/
		Date newDate = SetOliverHumePaymentDate(opp, PaymentTrigger);
        System.Debug( 'Channel Due Date: ' + string.valueOf( newDate ));
        
        if ( newDate == null ) return null;
	    System.Debug( 'Channel Due Date: Adding 7 Days: ' + string.valueOf( newDate.AddDays( 7) ));
        return newDate.AddDays(7);
    }
    
    public static Date RecalcDate(Commission__c c, Opportunity opp){
        string catname = string.IsBlank(c.Category__c) ? '' : c.Category__c.tolowercase();
        if (catname == 'oliver hume') return SetOliverHumePaymentDate(opp,c.Payment_Stage__c);
        if (catname == 'staff')	      return SetSalesConsultantPaymentDate(opp,c.Payment_Stage__c);
        if (catname == 'channel')     return SetChannelPaymentDate(opp,c.Payment_Stage__c);
        return null;
    }

    public static void RecalcAmount(Commission__c c, Opportunity opp, Map<Id,Commission__c> toupdate,Map<String, Commission__c> P1Map){
        Commission__c newcom = new Commission__c(id= c.Id);
        if (toUpdate.containsKey(c.id)) newcom = toupdate.get(c.id);
        

        string catname = c.Category__c==null?'':c.Category__c.tolowercase();
        Commission__c p1com = P1Map.get(GetCommissionKey(c));
        if (p1com == null) return;
        Commission__c OHCom = P1Map.get(GetCommissionKey(c.Opportunity__c,'Oliver Hume',1));
        
        Decimal AdminFee = (OHCom != null && OHCom.Vendor_Authority__r!=null && OHCom.Vendor_Authority__r.Admin_Fee__c!=null)?OHCom.Vendor_Authority__r.Admin_Fee__c:0;
        Decimal Perc = p1Com.Commission_Percentage__c ==null?1.0:(p1Com.Commission_Percentage__c/100.0);
        Decimal OHPerc = p1Com.OH_Commission_Percentage__c ==null?1.0:(p1Com.OH_Commission_Percentage__c/100.0);

// we don't re-calc if the percentage is 0
        if (c.Payment_Percentage__c== null || c.Payment_Percentage__c<=0) return; 
// we don't re-calc if Flat fee is presented
        else if (c.Total_Commission_Dollars_Flat_Fee__c !=null && c.Total_Commission_Dollars_Flat_Fee__c>0) return;

// calc p1/p2 of Oliver hume commission
        else if (catname == 'oliver hume'){
            decimal total = opp.Net_Price__c * perc  - AdminFee;
            
            if (c.Payment_Type__c=='P1')newcom.Total_Commission_Amount__c =total;
                
            newcom.Amount__c = total * 1.1 * c.Payment_Percentage__c/100.0;
            newcom.Amount_Excl__c = newcom.Amount__c /1.1;
        }
// calc p1/p2 for staff/channel/management commission
        else {
            
            decimal gst = (c.Account__r.GST_Status__c!=null&& c.Account__r.GST_Status__c.equalsIgnoreCase('gst exempt'))?1.0:1.1;
            decimal incentive = (catname=='staff' && c.Incentive__c != null)?c.Incentive__c:0;
            decimal total =opp.Net_Price__c * Perc * OHPerc - AdminFee + incentive;

            if (c.Payment_Type__c=='P1') newcom.Total_Commission_Amount__c = total * gst;   
            newcom.Amount__c = total * gst * c.Payment_Percentage__c/100.0;
            newcom.Amount_Excl__c = newcom.Amount__c /gst;
        }

        System.debug('---- New Commission is : ' + newCom);
        System.Debug('---- old Commission is : ' + c);
        System.Debug('---- old Commission Data 0: ' + p1com);
        System.Debug('---- old Commission Data 1: ' + OHCom);
        System.Debug('---- old Commission Data 2: ' + AdminFee + ' ' + Perc  + ' '+ OHPerc);

        newcom.Amount_Change_Reason__c = SystemRecalcReason;
        toupdate.put(c.Id,newcom);
    }


    public static Map<Id,Opportunity> GetOpps(set<string> ids){
        return new Map<Id,Opportunity>([select 
                        id,
                        Name,
                        Contract_Price__c,
                        Primary_Product__r.Name,
                        Primary_Product__r.Stage_Number__c,
                        Project_Stage__c, 
                        Net_Price__c, 
                        Salesperson_pa__c, 
                        Salesperson_pa__r.Name, 
                        Salesperson_pa__r.GST_Status__c,
                        Sales_Consultant_2__c,
                        Sales_Consultant_2__r.Name,
                        Sales_Consultant_2__r.GST_Status__c,
                        Sales_Consultant_3__c,
                        Sales_Consultant_3__r.Name,
                        Sales_Consultant_3__r.GST_Status__C,
                        Sales_Consultant_4__c,
                        Sales_Consultant_4__r.Name,
                        Sales_Consultant_4__r.GST_Status__c,
                        Project__r.OH_Account__c,
                        Project__r.Vendor__r.Vendor_Payment_Terms_Days__c,  
                        Project__r.Solicitor__c,
                        Channel_Account__c, 
                        Channel_Account__r.Name,
                        Channel_Account__r.GST_Status__c,
                        Channel_Account_2__c,
                        Channel_Account_2__r.Name,
                        Channel_Account_2__r.GST_Status__c,
                        Channel_Manager__c,
                        Channel_Manager__r.Name,
                        Channel_Manager__r.GST_Status__c,
                        Sales_Manager__c,
                        Sales_Manager__r.Name,
                        Sales_Manager__r.GST_Status__c,
                        Expected_Settlement_Date__c, 
                        Project__c,
                        Channel_Paid_Direct__c,
                        RecordType.Name,
                        RecordType.DeveloperName,
                        Unconditional_Due_Date__c,
                        Forecast_Unconditional_Date__c,
                        Settlement_Due_Date__c
             from Opportunity where Id in: ids]);
    }


    public static List<Commission__c> getCommissions(set<string> OppIds){
    
        return [select id,
                    Due_Date__c,
                    Category__c,
                    Opportunity__c,
                    Payment_Type__c,
                    Payment_Stage__c,
                    Amount_Change_Reason__c,
                    Status__c,
                    Account__r.GST_Status__c,
                    Sequence__c,
                    Payment_Percentage__c,
                    Incentive__c,
                    
                    OH_Commission_Percentage__c,
                    Total_Commission_Amount__c,
                    Commission_Percentage__c,
                    Amount__c,
                    Total_Commission_Dollars_Flat_Fee__c,
                    recordtype.Name,
                    Vendor_Authority__c,
                    Vendor_Authority__r.Admin_Fee__c //,
                    //Vendor_Authority__r.P1_Payment_trigger__c,
                    //Vendor_Authority__r.P2_Payment_trigger__c,
                    //Vendor_Sales_Authority__c,
                    //Vendor_Sales_Authority__r.P1_Payment_Trigger__c,
                    //Vendor_Sales_Authority__r.P2_Payment_Trigger__c
                from 
                    Commission__c 
                where Opportunity__c in: OppIds 
                //and (Vendor_Sales_Authority__c != null or Vendor_Authority__c != null) 
                //and Status__c != 'Paid' 
                //and   Amount_Change_Reason__c = ''
                ];
    }

    

    public static string ToCurrency(Decimal rA){
        List<String> args = new String[]{'0','number','###,###,##0.00'};
        return '$'+ String.format(rA.format(), args);
    }
}