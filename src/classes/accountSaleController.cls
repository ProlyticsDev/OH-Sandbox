public with sharing class accountSaleController 
{
    public list<CustomOpportunity> listCustomOpportunities {get; private set;}
    public boolean isPDF {get; private set;}
    public integer index {get;private set;}
    
    public accountSaleController()
    {
        list<string> oppIdList = this.GetParameters();
        this.CreateOppList(oppIdList);
        
        this.isPDF = false;
        if(apexPages.currentPage().getParameters().containsKey('isPDF'))
        {
            this.isPDF = true;
        }
    }
    
    public PageReference ChangePage()
    {
        PageReference objPageReference = new PageReference('/apex/accountSaleVfp?isPDF=true');
        objPageReference.setRedirect(true);
        return objPageReference;
    }
    
    private list<string> GetParameters()
    {
        string oppIds = '';
        list<string> oppList = new list<string>();
        
        //There preference is explicit oppids, if not revert to looking for a journal id.
        if(apexPages.currentPage().getParameters().containsKey('oids')){
            oppIds = apexPages.currentPage().getParameters().get('oids');
            oppList = oppIds.split(',');
        }
        //alternatively process based off a journal id
        else if(apexPages.currentPage().getParameters().containsKey('jids')){
            Id[] jIds = new Id[]{};
            for(String s: apexPages.currentPage().getParameters().get('jids').split(',')){
                jIds.add(s);
            }
            //Id jId = apexPages.currentPage().getParameters().get('jids');
            //loop through journal receipts and return all related opportunities.
            for(Receipt__c r: [select Id, Opportunity__c from Receipt__c where Journal__c in: jIds]){
                oppList.add(r.Opportunity__c);
            }
        }
        
        
        return oppList;
    }
    
    private void CreateOppList(list<string> listOppIds)
    {
        this.listCustomOpportunities = new list<CustomOpportunity>();
        list<Opportunity> listOpps = [
            Select Id, Net_Price__c, Deposit_Transferred__c, Deposit_Received__c,
               OH_Commission_Total__c,
                   Account.Name,
                   Ledger_Number__c,
                   Primary_Product__c, Primary_Product__r.Name, 
                    Primary_Product__r.Settlement_Date__c, 
                        Primary_Product__r.Project__c, Primary_Product__r.Project__r.Name, 
                            Primary_Product__r.Project__r.Project_Manager__c, 
                            Primary_Product__r.Project__r.Project_Manager__r.Name,
                                Primary_Product__r.Project__r.Vendor__c,
                                Primary_Product__r.Project__r.Vendor__r.Name,
                                Primary_Product__r.Project__r.Vendor__r.PersonMailingCountry,
                                Primary_Product__r.Project__r.Vendor__r.PersonMailingPostalCode, 
                                Primary_Product__r.Project__r.Vendor__r.PersonMailingState,
                                Primary_Product__r.Project__r.Vendor__r.PersonMailingCity, 
                                Primary_Product__r.Project__r.Vendor__r.PersonMailingStreet
            From Opportunity
            Where Id in: listOppIds];
        
        index = 0;
        for(Opportunity o : listOpps)
        {
            this.listCustomOpportunities.add(new CustomOpportunity(o, ++index));
        }
    }
    
    public with sharing class CustomOpportunity
    {
        public Opportunity opp{get; set;}
       
        public integer index {get; private set;}
        public decimal creditAmount {get; private set;}
        public decimal gstCommission {get; private set;}
        public decimal totalCommission {get; private set;}
        public string formattedTodayDate {get; private set;}
        public string formattedExchangedDate {get; private set;}
        public string productProject {get; private set;}
        public string vendorAddress {get; private set;}
        
        public CustomOpportunity(Opportunity paramOpp, integer paramIndex)
        {
            this.opp = paramOpp;
            this.index = paramIndex;
            this.opp.OH_Commission_Total__c = ohHelper.NormalizeDecimal(this.opp.OH_Commission_Total__c);
            this.gstCommission = this.opp.OH_Commission_Total__c * 0.1;
            this.totalCommission = this.opp.OH_Commission_Total__c + this.gstCommission;
            //this.creditAmount = ohHelper.NormalizeDecimal(this.objReceipt.Credit_Amount__c);
            
            this.formattedTodayDate = datetime.now().format('d-MMMM-yyyy');
            this.formattedExchangedDate = '';
            if(this.opp.Primary_Product__r.Settlement_Date__c != null)
            {
                this.formattedExchangedDate = datetime.newInstance(this.opp.Primary_Product__r.Settlement_Date__c, null).format('d-MMMM-yyyy');
            }
            
            this.productProject = this.opp.Primary_Product__r.Name + ' - ' + this.opp.Primary_Product__r.Project__r.Name;
            
            this.vendorAddress = '';
            this.vendorAddress += (string.isBlank(this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingStreet) ? '' : this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingStreet + '<br />');
            this.vendorAddress += (string.isBlank(this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingCity) ? '' : this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingCity + ', ');
            this.vendorAddress += (string.isBlank(this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingState) ? '' : this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingState + ' ');
            this.vendorAddress += (string.isBlank(this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingPostalCode) ? '' : this.opp.Primary_Product__r.Project__r.Vendor__r.PersonMailingPostalCode + ' ');
        }
    }
    
}