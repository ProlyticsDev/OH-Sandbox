public with sharing class commissionStatementController {
    /*
    public List<Id> accountIds {get; set;}
    public Date startDate {get; set;}
    public Date endDate {get; set;}
    public commission[] commissions{get; set;}
    
    
    public commissionStatementController(){
        //the page will be passed in 3 params, set account only.
        generateData();
        
    }
    
    public void generateData(){
        //accounts
        accountIds = new List<Id>();
        String accounts = ApexPages.CurrentPage().GetParameters().Get('account');
        string startString = ApexPages.CurrentPage().GetParameters().Get('start');
        string endString = ApexPages.CurrentPage().GetParameters().Get('end');
        //finish here if we do not have the correct data
        if(accounts == null || startString == null || endString == null) return;
        startDate = date.valueOf(startString);
        endDate = date.valueOf(endString);
        
        for(String s : accounts.split(';')){
            try{
                Id accountId = s;

                accountIds.Add(accountId);
            }
            catch (Exception e) {}
        }
        
        //first create some maps to store the accounts and various commission records
        //we will loop through these later to build up the commission list
        Map<Id, Account> accountMap = new Map<Id,Account>();
        Map<Id, Commission__c[]> settledMap = new Map<Id, Commission__C[]>();
        Map<Id, Commission__c[]> pendingMap = new Map<Id, Commission__C[]>();
        
        for(Account a: [select Id, Name, Payroll_ID__c, Retainer_Balance__c from Account where Id in : accountIds]){
            accountMap.put(a.Id, a);
            settledMap.put(a.Id, new Commission__c[]{});
            pendingMap.put(a.Id, new Commission__c[]{});
        }
        for(Commission__c c: [select Id, Opportunity__r.Exchanged_Date__c, Opportunity__r.Primary_Product__r.Street_Number__c, Opportunity__r.Primary_Product__r.Street_Name__c, Opportunity__r.Purchaser__c, Amount__c, Account__c,
                                Payment_Stage__c, Opportunity__r.Ref__c
                        from Commission__c
                        where Due_Date__c >= : startDate and Account__c in : accountIds and Type__c = 'Commission Generated' and Status__c = 'Payable'
                        order by Due_Date__c asc]){
            settledMap.get(c.Account__c).add(c);
        }
        for(Commission__c c: [select Id, Opportunity__r.Exchanged_Date__c, Opportunity__r.Primary_Product__r.Street_Number__c, Opportunity__r.Primary_Product__r.Street_Name__c, Opportunity__r.Purchaser__c, Amount__c, Account__c,
                                Payment_Stage__c, Opportunity__r.Ref__c
                        from Commission__c
                        where Account__c in : accountIds and Type__c = 'Commission Generated' and Status__c = 'Pending' and Opportunity__r.Exchanged_Date__c != null
                        order by Due_Date__c asc]){
            pendingMap.get(c.Account__c).add(c);
        }
        //now build out the templates for each statement.
        commissions = new commission[]{};
        for(Id i: accountMap.keySet()){
            commissions.add(new commission(accountMap.get(i), pendingMap.get(i), settledMap.get(i), startDate, endDate));
        }
    
    }
    
    public class commission{
    
        public Date startDate {get; set;}
        public Date endDate {get; set;}
        //constructor, should pass in the account, and commission lists
        public commission(Account acct, Commission__c[] pending, Commission__c[] settled, date startDate, date endDate){
            this.settled = settled;
            this.pending = pending;
            this.acct = acct;
            this.startDate = startDate;
            this.endDate = endDate;
        }
        
        // The get for this should only be called by page code looping over orderedMonths,
        // meaning that Initialise() will have been called by that method.
        public List<Commission__c> settled {get; set;}
        public List<Commission__c> pending {get; set;}
        public Double settledTotal {get; set;}
        public decimal commissionDue{get; set;}
        public decimal retainerTotal{get; set;}
    
        public Map<Date, List<Commission__c>> commissionMap {get; set;}
        public Map<Date, Double> pendingTotals {get; set;}
    
        public Boolean noSettled {get; set;}
        public Boolean noPending {get; set;}
    
        private List<Date> orderedMonths;
        private Map<Id, Double> runningTotal;
        private Account acct;
    
        private Boolean initialised = false;
    
        public List<Date> GetMonths()
        {
            Initialise();
    
            return orderedMonths;
        }
    
        public Map<Id, Double> GetRunningTotal()
        {
            Initialise();
    
            return runningTotal;
        }
    
        public Account GetAcct()
        {
            Initialise();
    
            return acct;
        }
    
        public Date GetStatementStart()
        {
            Initialise();
    
            return startDate;
        }
        
        public Date GetStatementEnd()
        {
            Initialise();
    
            return endDate;
        }
    
        private void Initialise()
        {
            if(initialised)
            {
                return;
            }
    
            // Dates should be used to find the whole months
    
            orderedMonths = new List<Date>();
            commissionMap = new Map<Date, List<Commission__c>>();
            runningTotal = new Map<Id, Double>();
            pendingTotals = new Map<Date, Double>();
    
            /* This is passed in.
            if(accountId != null && startDate != null && endDate != null)
            {
                settled = [select Id, Opportunity__r.Exchanged_Date__c, Opportunity__r.Primary_Product__r.Address__c, Opportunity__r.Purchaser__c, Amount__c,
                                    Payment_Stage__c, Opportunity__r.Ref__c
                            from Commission__c
                            where Opportunity__r.Exchanged_Date__c >= : startDate and Account__c = : accountId and Type__c = 'Commission Paid' and Status__c = 'Payable'
                            order by Opportunity__r.Exchanged_Date__c asc];
    
                pending = [select Id, Opportunity__r.Exchanged_Date__c, Opportunity__r.Primary_Product__r.Address__c, Opportunity__r.Purchaser__c, Amount__c,
                                    Payment_Stage__c, Opportunity__r.Ref__c
                            from Commission__c
                            where Account__c = : accountId and Type__c = 'Commission Generated' and Status__c = 'Pending' and Opportunity__r.Exchanged_Date__c != null
                            order by Opportunity__r.Exchanged_Date__c asc];
    
                acct = [select Id, Name, Payroll_ID__c from Account where Id = : accountId limit 1];
            }
            
    
            Double total = 0.0;
            settledTotal = 0.0;
    
            noSettled = (settled != null || settled.Size() == 0);
            noPending = (pending != null || pending.Size() == 0);
    
            if(settled != null && settled.Size() > 0)
            {
                for(Commission__c c : settled)
                {
                    total += c.Amount__c;
    
                    runningTotal.Put(c.Id, total);
                }
            
                settledTotal = total;   
            }
    
            total = 0.0;
    
            if(pending != null && pending.Size() > 0)
            {
                Date currentMonth = pending.Get(0).Opportunity__r.Exchanged_Date__c.ToStartOfMonth();
    
                orderedMonths.Add(currentMonth);
                commissionMap.Put(currentMonth, new List<Commission__c>());
                pendingTotals.Put(currentMonth, 0.0);
    
                // Calculate the pending totals for each month
                for(Commission__c c : pending)
                {
                    if(c.Opportunity__r.Exchanged_Date__c.ToStartOfMonth() > currentMonth)
                    {
                        currentMonth = c.Opportunity__r.Exchanged_Date__c.ToStartOfMonth();
                        orderedMonths.Add(currentMonth);
    
                        commissionMap.Put(currentMonth, new List<Commission__c>());
                        pendingTotals.Put(currentMonth, 0.0);
                    }
    
                    commissionMap.Get(currentMonth).Add(c);
    
                    Double amount = (c.Amount__c == null ? 0.0 : c.Amount__c);
    
                    pendingTotals.Put(currentMonth, pendingTotals.Get(currentMonth) + amount);
                }
            }
            //work out the commission due
            if(acct.Retainer_Balance__c > settledTotal){
                commissionDue = 0;
                retainerTotal = settledTotal;
            }
            else{
                commissionDue = settledTotal - acct.Retainer_Balance__c;
                retainerTotal = acct.Retainer_Balance__c;
            }
            initialised = true;
        }
    }
 */   
}