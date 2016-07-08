public with sharing class trustAccountReceiptGeneratorController
{
    public ApexPages.StandardSetController ssc;

    public Map<Id, Boolean> toPrint {get; set;}
    public Map<Id, Boolean> toEmail {get; set;}

    public String printIds {get; private set;}

    public Boolean saved {get; set;}

    public trustAccountReceiptGeneratorController(ApexPages.StandardSetController ssc)
    {
        this.ssc = ssc;

        toPrint = new Map<Id, Boolean>();
        toEmail = new Map<Id, Boolean>();

        saved = false;

        for(Receipt__c r : (List<Receipt__c>)ssc.GetSelected())
        {
            toPrint.Put(r.Id, r.Communication_Preference__c == 'Print' || r.Communication_Preference__c == 'Both');
            toEmail.Put(r.Id, r.Communication_Preference__c == 'Email' || r.Communication_Preference__c == 'Both');
        }
    }

    public List<Receipt__c> GetReceipts()
    {
        // have to do this because when VF calls GetRecords() it doesn't respect the set page size
        return [select Communication_Preference__c, Date__c, Project__c, Received_From__c, Amount__c, Description__c, Payment_Method__c,
                        Trust_Account__c, Trust_Account__r.Name, Opportunity__r.Account.IsPersonAccount,
                        Opportunity__r.Account.BillingStreet, Opportunity__r.Account.BillingCity, Opportunity__r.Account.BillingState,
                        Opportunity__r.Account.BillingPostalCode, Opportunity__r.Account.Person_Account_Email__c, Opportunity__r.Account.Phone,
                        Trust_Account_Receipt_Number__r.TA_Receipt_Number__c
                from Receipt__c where Id in : toPrint.KeySet()];
    }

    public PageReference SaveAndEmail()
    {
        // First of all generate receipt numbers for thees receipts
        Map<Id, List<Receipt__c>> trustAccountReceiptNumbers = new Map<Id, List<Receipt__c>>();
        List<Receipt__c> receiptsToUpdate = new List<Receipt__c>();

        // Receipts without a number need a new one created
        for(Receipt__c r : (List<Receipt__c>)ssc.GetSelected())
        {
            if(r.Trust_Account_Receipt_Number__c != null)
            {
                continue;
            }

            if(trustAccountReceiptNumbers.Get(r.Trust_Account__c) == null)
            {
                trustAccountReceiptNumbers.Put(r.Trust_Account__c, new List<Receipt__c>{r});
            }
            else
            {
                trustAccountReceiptNumbers.Get(r.Trust_Account__c).Add(r);
            }

            receiptsToUpdate.Add(r);
        }

        ohHelper.GenerateReceiptNumber(trustAccountReceiptNumbers);
        update receiptsToUpdate;

        saved = true;
        return null;
    }

    public PageReference Print()
    {
        printIds = '';

        for(Id receiptId : toPrint.KeySet())
        {
            if(toPrint.Get(receiptId))
            {
                printIds += receiptId + ';';
            }
        }

        printIds = printIds.Left(printIds.Length() - 1);
    
        return null;    
    }
}