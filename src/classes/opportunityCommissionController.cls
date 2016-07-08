public class opportunityCommissionController{

    public List<string> allCategories {get;set;}
    public List<string> SummaryCategory {get;set;}
    public Opportunity Opp{get;set;}
    public Map<string,CommissionModel> Commissions{get;set;}

    
    public Map<string,string> categoryMap{ get;set; }

    public opportunityCommissionController(ApexPages.StandardController controller){
        if(Opp == null){
            Set<string> ids = new Set<string>();
            ids.add(controller.getId());
            Opportunity[] opps= CommissionDetail_Helper.GetOpps(ids).values();
            if (!opps.IsEmpty()) Opp=opps[0];
        }
    }
    
    public void Init(){
        if(commissions ==null)
        {
            categoryMap = new Map<string,string>();
            commissions=new Map<string,CommissionModel>();
    //step 1 get all category
    //the order of the category controls the comission detail section order
            allCategories=CommissionDetail_Helper.getCategories(categoryMap);
            for(string cat: allCategories){
                if(cat!=null){
                    CommissionModel model=new CommissionModel();
                    model.CategoryName=cat;
                    //model.Num='0';
                    model.CanAdd=true;
                    commissions.put(cat.tolowerCase(),model);
                }
            }
    
    
    //step 2 remove category that does not below to this record type of opportunity
            CommissionDetail_Helper.RemoveCommissionCategory(opp,commissions);
            allCategories.Clear();
            allCategories.AddAll(commissions.keyset());

            SummaryCategory = new List<string>();
            for (string cat: allCategories){
                if (cat.toLowerCase()=='house' || cat.toLowerCase()=='management') continue;
                SummaryCategory.add(cat);
            }
    
    // step 3, generate accounts for auto generated commissions 
            Map<string,set<id>> accountMap= new Map<string,set<id>>(); 
            Map<id,Account> accountNameMap= new Map<id,Account>(); 
            //staff
            set<id> SCs=new set<id>();
            if(opp.Salesperson_pa__c!=null) {SCs.add(opp.Salesperson_pa__c);accountNameMap.put(opp.Salesperson_pa__c,opp.Salesperson_pa__r);}
            if(opp.Sales_Consultant_2__c!=null) {SCs.add(opp.Sales_Consultant_2__c);accountNameMap.put(opp.Sales_Consultant_2__c,opp.Sales_Consultant_2__r);}
            if(opp.Sales_Consultant_3__c!=null) {SCs.add(opp.Sales_Consultant_3__c);accountNameMap.put(opp.Sales_Consultant_3__c,opp.Sales_Consultant_3__r);}
            if(opp.Sales_Consultant_4__c!=null) {SCs.add(opp.Sales_Consultant_4__c);accountNameMap.put(opp.Sales_Consultant_4__c,opp.Sales_Consultant_4__r);}
            if(SCs.Size()>0)accountMap.put('staff',SCs);
            //channel
            set<id> chs=new set<id>();
            if(opp.Channel_Account__c!=null) {chs.add(opp.Channel_Account__c);accountNameMap.put(opp.Channel_Account__c,opp.Channel_Account__r);} 
            if(opp.Channel_Account_2__c!=null) {chs.add(opp.Channel_Account_2__c);accountNameMap.put(opp.Channel_Account_2__c,opp.Channel_Account_2__r);}
            if(chs.Size()>0)accountMap.put('channel',chs);
            //Management - same as staff but under seperate category on the page layout
            set<id> mgt=new set<id>();
            if(opp.Sales_Manager__c!=null) {mgt.add(opp.Sales_Manager__c);accountNameMap.put(opp.Sales_Manager__c,opp.Sales_Manager__r);} 
            if(opp.Channel_Manager__c!=null) {mgt.add(opp.Channel_Manager__c);accountNameMap.put(opp.Channel_Manager__c,opp.Channel_Manager__r);}
            if(mgt.Size()>0)accountMap.put('management',mgt);
            //OH
            set<id> ohs=new set<id>();
            if(opp.project__r.OH_Account__c!=null) ohs.add(opp.project__r.OH_Account__c); 
            if(ohs.Size()>0)accountMap.put('oliver hume',ohs);
    
    //Step 3 create the data model
            Commission__c[] comms = [select 
                                Id,
                                Account__c,
                                Account__r.Name,
                                Amount__c,
                                Amount_Excl__c,
                                Category__c,
                                Name,
                                Due_Date__c,
                                GST__c,
                                GST_Status__c,
                                Import_Name__c,
                                Oliver_Hume__c,
                                Oliver_Hume__r.Name,
                                Opportunity__c,
                                Opportunity__r.Name,
                                Opportunity__r.Expected_Settlement_Date__c,
                                Opportunity__r.Project__r.Vendor__r.Vendor_Payment_Terms_Days__c,
                                Opportunity__r.Project__r.Solicitor__c,
                                Opportunity__r.Channel_Paid_Direct__c,
                                Opportunity__r.Primary_Product__r.Stage_Number__c,
                                Payment_Stage__c,
                                Product__c,
                                Product__r.Name,
                                Project__c,
                                Project__r.Name,
                                Role__c,
                                Status__c,
                                Type__c,
                                Vendor_Sales_Authority__c,
                                Vendor_Sales_Authority__r.Account__c,
                                Vendor_Sales_Authority__r.Name,
                                Vendor_Sales_Authority__r.Account__r.Name,
                                Vendor_Sales_Authority__r.Commission_Percent__c,
                                Vendor_Sales_Authority__r.Settled_Percent__c,
                                Vendor_Sales_Authority__r.Vendor_Authority__r.Type__c,
                                Vendor_Sales_Authority__r.Consultancy_Fee_Dollars__c,
                                Vendor_Sales_Authority__r.OH_Commission__c,
                                Incentive__c,
                                Vendor_Authority__c,
                                Vendor_Authority__r.id,
                                Vendor_Authority__r.Name,
                                Vendor_Authority__r.Commission_Based_On__c, 
                                Vendor_Authority__r.Admin_Fee__c,
                                Vendor_Authority__r.OH_Commission_Dollars__c,
                                Total_Commission_Amount__c,
                                Payment_Percentage__c,
                                OH_Commission_percentage__c,
                                Commission_percentage__c,
                                Commission_Invoice_To__c,
                                Total_Commission_Dollars_Flat_Fee__c,
                                IsAutoCreated__c,
                                Amount_Change_Reason__c,
                                Payment_Type__c,
                                Sequence__c, 
                                RecordTypeId
                            from Commission__c
                            where Opportunity__c = :Opp.Id
                            order by Category__c asc,IsAutoCreated__c desc, name];

            Map<string,CommissionData> ComDataMap = new Map<string,CommissionData>();
            // go through the list to create the primary commission - P1 COmmissions
            for( Commission__c c : comms)
            {
                if(c.Category__c==null)continue;
                
                string cat=c.Category__c.tolowercase();
                if(!commissions.containskey(cat))continue;
                
                if(c.Payment_Type__c== null || c.Payment_Type__c.equalsIgnoreCase('P1') ){
                    CommissionModel ccl=commissions.get(cat);
                    CommissionData cd=new CommissionData(c);
                    ccl.Commissions.Add(cd);
                    cd.Num=''+ ccl.Commissions.Size();
                    
                    comDataMap.put(cat+c.Sequence__c, cd);
                }
                
            }
//Add P2 Commission to the commission Model from database
            for( Commission__c c : comms)
            {
                if(c.Category__c==null)continue;
                string cat=c.Category__c.tolowercase();
                if(c.Payment_Type__c!= null &&  c.Payment_Type__c.equalsIgnoreCase('P2') ){
                    if(comDataMap.ContainsKey(cat+c.Sequence__c)){
                        CommissionData cd= comDataMap.get(cat+c.Sequence__c);
                        cd.Payment_2 = c;
                    }
                }
            }

//if P2 was not in Commssion Data Model, we create it from Payment_1
            for(string cdMap: comDataMap.KeySet() ){
                CommissionData cd = comDataMap.get(cdMap);
                if(cd.Payment_2==null){
                    cd.Payment_2= new Commission__c();
                    cd.Payment_2.RecordTypeId = cd.Payment_1.RecordTypeId;
                    cd.Payment_2.Opportunity__c = cd.Payment_1.Opportunity__c;
                    cd.Payment_2.IsAutoCreated__c = cd.Payment_1.IsAutoCreated__c;
                    cd.Payment_2.Category__c = cd.Payment_1.Category__c;
                    cd.Payment_2.Sequence__c = cd.Payment_1.Sequence__c;
                    cd.Payment_2.Payment_Type__c = 'P2';
                    cd.Payment_2.Account__c = cd.Payment_1.Account__c;
                }
            }

            VA = getVendorAuthority();

            //List<Commission__c> toUpsert = new List<Commission__c>();
            for(string catkey: accountMap.keyset()){
                if(commissions.containskey(catkey)){
                    CommissionModel ccl=commissions.get(catkey);
                    for(CommissionData c: ccl.commissions){
                        if(accountMap.get(catkey).Contains(c.Payment_1.Account__c)) accountMap.get(catKey).Remove(c.Payment_1.Account__c);
                    }
                    
                    for(Id i:accountMap.get(catkey)){
                        CommissionData nc = new CommissionData();
                        if(catkey == 'oliver hume') CommissionDetail_Helper.CreateOliverHumeEntityCommissionDetails(nc,opp,i,VA, ccl.Commissions.Size()+1);
                        if(catkey == 'channel' && opp.Channel_Paid_Direct__c != true) CommissionDetail_Helper.CreateChannelCommissionDetails(nc,opp,i,getVSA(i), accountNameMap.get(i));
                        if(catkey == 'staff') CommissionDetail_Helper.CreateSalesConsultantCommissionDetails(nc,opp,i,getVSA(i), accountNameMap.get(i));
                        if(catkey == 'management') CommissionDetail_Helper.CreateSalesConsultantCommissionDetails(nc,opp,i,getVSA(i), accountNameMap.get(i));
                         
                        //fill common fields
                        nc.Payment_1.RecordTypeId = CommissionDetail_Helper.getCommissionRecordType(catkey);
                        nc.Payment_1.IsAutoCreated__c = true;
                        nc.Payment_1.Category__c = categoryMap.get(catkey);
                        nc.Payment_1.Sequence__c = ccl.Commissions.Size()+1;
                        nc.Payment_1.Payment_Type__c = 'P1';
                        nc.Payment_1.Account__c = i;
                        nc.Payment_1.Status__c = 'Pending';
                        
                        nc.Payment_2.IsAutoCreated__c = true;
                        nc.Payment_2.Category__c = categoryMap.get(catkey);
                        nc.Payment_2.RecordTypeId = CommissionDetail_Helper.getCommissionRecordType(catkey);
                        nc.Payment_2.Sequence__c = ccl.Commissions.Size()+1;
                        nc.Payment_2.Payment_Type__c = 'P2';
                        nc.Payment_2.Account__c = i;
                        nc.Payment_2.Status__c = 'Pending';
                        
                        if ( nc.isValid ){
                            ccl.Commissions.Add(nc);
                            nc.Num=''+ ccl.Commissions.Size();
                        }
                    }
                    Msg+=' After: ' + ccl.commissions.Size();
                }
            }
            
       
            for(string cat:allCategories){
                if(!commissions.ContainsKey(cat)){
                    commissions.put(cat,new CommissionModel());
                }
            }

        }
    }

    public Vendor_Authority__c VA{get;Set;}

    public PageReference SaveData(){
        string error ='';
        List<Commission__c> toUpsert = new List<Commission__c>(), toDelete= new List<Commission__c>();
        
        decimal totalOH = 0,total=0, amountP1PlusP2, lastOHAmount;
        Boolean paidMoreThanReceived = false;

        for(string key:commissions.keyset()){
            
            CommissionModel cm = commissions.get(key);
            for(CommissionData cd:cm.commissions){
                
                if(cd.Payment_2.account__c != cd.Payment_1.account__c) cd.Payment_2.account__c = cd.Payment_1.account__c;
                
                //if(cd.Payment_1.Total_Commission_Amount__c==null || cd.Payment_1.Total_Commission_Amount__c==0 || cd.Payment_1.amount__c==null || cd.Payment_1.amount__c==0) continue; 
                string err = cd.Validate();
                if(err == null){
                    
                    if(cd.Payment_1.Amount__c != cd.OldAmountP1) cd.Payment_1.Amount_Change_Reason__c = cd.ChangeReason;
                    toUpsert.add(cd.Payment_1);
                    
                    //Commented out following condition
                    //As UI only set the Payment_1.Total_Commission_Amount__c
                    //therefore Payment_2.Total_Commission_Amount__c is always null or 0
                    if(/*cd.Payment_2.Total_Commission_Amount__c!=null && cd.Payment_2.Total_Commission_Amount__c>0 &&*/ cd.Payment_2.amount__c!=null && cd.Payment_2.amount__c>0){ 
                        if(cd.Payment_2.Amount__c != cd.OldAmountP2) cd.Payment_2.Amount_Change_Reason__c = cd.ChangeReason;
                        if(cd.Payment_2.Oliver_Hume__c != cd.Payment_1.Oliver_Hume__c) cd.Payment_2.Oliver_Hume__c =cd.Payment_1.Oliver_Hume__c; 
                        toUpsert.add(cd.Payment_2);
                    }
                    //Business Rule if Payment 2's Amount is 0 and it is already in database, remove it from DB
                    else if((cd.Payment_2.amount__c==null || cd.Payment_2.amount__c==0) && cd.Payment_2.Id!=null){
                        toDelete.Add(cd.Payment_2);
                    }
                }
                if (!string.IsBlank(err)) Error+= err + '\r\n';

                amountP1PlusP2 = (cd.Payment_1.Amount__c!=null?cd.Payment_1.Amount__c:0) + (cd.Payment_2.Amount__c!=null?cd.Payment_2.Amount__c:0);

                if (cd.Payment_1.Category__c!=null&&cd.Payment_1.Category__c.equalsIgnoreCase('oliver hume') /*&& cd.Payment__1.Sequence__c==1*/)
                {
                    if (lastOHAmount != null && amountP1PlusP2 > lastOHAmount) {
                        paidMoreThanReceived = true;
                    }
                    totalOH+=amountP1PlusP2;
                    lastOHAmount = amountP1PlusP2;
                }
                else
                {
                    total+=amountP1PlusP2;
                }
            }
        }

        if (paidMoreThanReceived)
        {
            error+='OH Entities cannot pay out more than they receive';
        }
        
        // Switched off since calculating incorrectly
        /*if (totalOH<total)
        {
            error+='Total OH commission must be greater than other commissions';
        }
        */
        //ApexPages.getMessages().clear();
        if(error!=''){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,Error));
            return null;
        }
        
        string s='';
        Savepoint sp = Database.setSavepoint();
        try{
            if(!toUpsert.isEmpty()) Database.upsert(toUpsert, true);
            if(!toDelete.isEmpty()) Database.delete(toDelete, true);
            return new PageReference('/' + Opp.Id);
        }catch(Exception ex){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Error when saving:' + ex.getMessage() + ' ' + s ));
            Database.Rollback(sp);
            return null;
        }
    }
    
    string msg='';
    public string getMsg(){
        return msg;
    }
    
    private Map<Id,Vendor_Sales_Authority__c> vsas = null;
    public Vendor_Sales_Authority__c getVSA(Id SalesOrChannelId){
        if ( vsas == null ){
            vsas = new Map<Id,Vendor_Sales_Authority__c>();
            for( Vendor_Sales_Authority__c vsa : [select 
                                                    Commission_percent__c,
                                                    Commission_Dollars__c,
                                                    P1_Payment_Trigger__c,
                                                    P1_Payment_Percentage__c,
                                                    P2_Payment_Trigger__c,
                                                    P2_Payment_Percentage__c,
                                                    OH_Commission__c,
                                                    Active__c,
                                                    Account__c,                                                 
                                                    Name,
                                                    Vendor_Authority__c,
                                                    Vendor_Authority__r.Name,
                                                    Account__r.GST_Status__c,
                                                    Id 
                                                 from Vendor_Sales_Authority__c 
                                                 where Active__c = true and
                                                    Project__c = :Opp.Project__c and
                                                    (
                                                        Account__c = :Opp.Salesperson_pa__c or
                                                        Account__c = :Opp.Sales_Consultant_2__c or
                                                        Account__c = :Opp.Sales_Consultant_3__c or
                                                        Account__c = :Opp.Sales_Consultant_4__c or
                                                        Account__c = :Opp.Channel_Account__c or
                                                        Account__c = :Opp.Channel_Account_2__c or
                                                        Account__c = :Opp.Channel_Manager__c or
                                                        Account__c = :Opp.Sales_Manager__c
                                                    )])
            vsas.put(vsa.Account__c, vsa);
        }
        return vsas.get(SalesOrChannelId);
    }
    
    public Vendor_Authority__c getVendorAuthority(){
        Set<id> prods= new set<id>();
        for(Item__c ps:[select product__c from Item__c where Opportunity__c = : opp.id]){
            prods.add(ps.Product__c);
        }
        Product_Assignment__c[] pas = [select 
                                            Vendor_Authority__r.Id, 
                                            Vendor_Authority__r.Vendor__c, 
                                            Vendor_Authority__r.Name, 
                                            Vendor_Authority__c, 
                                            Vendor_Authority__r.Commission_Based_On__c, 
                                            Vendor_Authority__r.Admin_Fee__c,
                                            Vendor_Authority__r.OH_Commission_Dollars__c,
                                            Vendor_Authority__r.P1_Payment_Trigger__c, 
                                            Vendor_Authority__r.P2_Payment_Trigger__c,
                                            Vendor_Authority__r.P2_Payment_Percentage__c, 
                                            Vendor_Authority__r.OH_Commission_Percent__c,
                                            Vendor_Authority__r.P1_Payment_Percentage__c
                                    from Product_Assignment__c where Active__c=true and Product__c in: prods
                                    order by CreatedDate desc limit 1];
        return pas.Size()==0?null:pas[0].Vendor_Authority__r;
    }
}