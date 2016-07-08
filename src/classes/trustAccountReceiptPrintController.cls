public with sharing class trustAccountReceiptPrintController
{
    public List<Receipt__c> receipts {get; set;}

    public trustAccountReceiptPrintController()
    {
        String recordIds = ApexPages.CurrentPage().GetParameters().Get('ids');

        receipts = [select Id, Transaction_ID_Reference__c, Date__c, Amount__c, Credit_Amount__c, Description__c,
                            Payment_Method__c, Received_From__c, Product__r.Name, Trust_Account__r.Name,
                            Trust_Account_Receipt_Number__r.TA_Receipt_Number__c, Product__r.Address__c, Product__r.Project__r.OH_Account__r.Name, Product__r.Project__r.OH_Account__r.BillingStreet,
                            Product__r.Project__r.OH_Account__r.BillingCity, Product__r.Project__r.OH_Account__r.BillingState, Product__r.Project__r.OH_Account__r.BillingPostalCode, Product__r.Project__r.OH_Account__r.Phone,
                            Product__r.Project__r.OH_Account__r.Fax, Product__r.Project__r.OH_Account__r.ACN__c, Product__r.Project__r.OH_Account__r.ABN__c
                    from Receipt__c
                    where Id in : recordIds.split(';')];
    }
}