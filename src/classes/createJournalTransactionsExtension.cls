public with sharing class createJournalTransactionsExtension {
    public Map<Trust_Account__c, List<ReceiptWrapper>> receipts {get; set;}
    public Map<TrustAccountWrapper, List<PaymentWrapper>> transactions2 {get; set;}
    public boolean fromPageTwo {get; set;}
    
    public abaUtility.aba[] abaPreviews{get; set;}
    public string abaREF{get; set;}
    
    public Integer transactionsSize {
        get {
            return (transactions2 != null) ? transactions2.size() : -1;
        }
        set;
    }
    
    private Map<Id, Opportunity> opportunities;
    private Map<Id, Trust_Account__c> trustAccounts;
    
    public Integer opportunitiesSize {
        get {
            return (opportunities != null) ? opportunities.size() : -1;
        }
        set;
    }
    
    public boolean hasErrors {
        get {
            return ApexPages.hasMessages();
        }
    }
    
    public String accountSaleType {get; set;}
    
    static final Map<String, Id> recordTypes;
    static {
        recordTypes = new Map<String, Id>();
        for(RecordType rt : [SELECT Id, Name 
                             FROM Recordtype 
                             WHERE SobjectType='Receipt__c' AND Name IN ('Payment','Journal')]){
            recordTypes.put(rt.Name, rt.Id);
        }
    } 
    
    static final Map<Id, Bank_Account__c> generalBankAccounts;
    static final Map<Id, Bank_Account__c> allBankAccounts;
    static {
        allBankAccounts = new Map<Id, Bank_Account__c>();
        generalBankAccounts = new Map<Id, Bank_Account__c>();
        for (Bank_Account__c b : [SELECT Id, Name, Account__c, Type__c, Bank_Account_Name__c, Bank_Account_Number__c, BSB_Number__c  FROM Bank_Account__c]) { //Assumption: There will be only one 'General' Account per OH Account
            if (b.Type__c == 'General')
                generalBankAccounts.put(b.Account__c, b);
            allBankAccounts.put(b.Id, b);
        }
    }
    
    public createJournalTransactionsExtension(ApexPages.StandardSetController ssc) {
        receipts = new Map<Trust_Account__c, List<ReceiptWrapper>>();
        transactions2 = new Map<TrustAccountWrapper, List<PaymentWrapper>>();
        opportunities = new Map<Id, Opportunity>();
        trustAccounts = new Map<Id, Trust_Account__c>();
        
        for(Opportunity o : (List<Opportunity>)ssc.getSelected()) {
            opportunities.put(o.Id, null);
        }
        
        if (opportunities.isEmpty())
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No opportunities were selected.'));
        
        String url = (Test.isRunningTest()) ? 'https://dummy/depositTransfer' : ApexPages.currentPage().getUrl();
        if (url.contains('depositTransfer'))
            accountSaleType = 'DT';
        else if (url.contains('section24'))
            accountSaleType = 'S24';
        else if (url.contains('disburse'))
            accountSaleType = 'DIS';
        else if (url.contains('commissionRelease'))
            accountSaleType = 'CR';
    }
    
    public void process() {
        Map<Opportunity, Id> oppToTrustAccount = new Map<Opportunity, Id>();
        List<Opportunity> opportunities = new List<Opportunity>();
        
        for (Opportunity o : [SELECT Id, Name, Full_Deposit_Required__c, Balance_Of_Deposit__c, Ledger_Balance_Correct__c,
                                     Funds_to_Retain_v2__c, Available_Funds_to_Transfer_v2__c, Customer_Reference__c, 
                                     Primary_Product__r.Project__r.Trust_Account__c,
                                     Primary_Product__r.Project__r.Solicitor__c,
                                     Primary_Product__r.Project__r.Creditor_Ledger__c,
                                     Primary_Product__r.Project__r.Creditor_Ledger__r.Name,
                                     Primary_Product__r.Solicitor__c,
                                     Primary_Product__r.Project__r.Solicitors_Bank_Account__c,
                                     Primary_Product__r.Project__r.Solicitors_Bank_Account__r.Name,
                                     Primary_Product__r.Project__r.Solicitors_Payment_Method__c,
                                     Primary_Product__r.Project__r.OH_Account__c,
                                     Primary_Product__r.Solicitors_Bank_Account__c,
                                     Primary_Product__r.Solicitors_Bank_Account__r.Name,
                                     Primary_Product__r.Solicitors_Payment_Method__c,
                                     Primary_Product__r.Name,
                                     Primary_Product__r.Project__r.Name,
                                     Primary_Product__c,
                                     Primary_Product__r.Project__c
                              FROM Opportunity
                              WHERE Id IN :this.opportunities.keySet()]) {
            opportunities.add(o);
                                  
            oppToTrustAccount.put(o, o.Primary_Product__r.Project__r.Trust_Account__c);
        }
        
        Map<Id, List<Creditor_Ledger__c>> taToclMap = getTrustAccountToCreditorLedgerMap(oppToTrustAccount.values());
        
        for (Opportunity o: opportunities) {
            ReceiptWrapper rw = new ReceiptWrapper();
            rw.Opportunity = o;
            rw.journal_amount = (accountSaleType == 'CR') ? o.Funds_to_Retain_v2__c : o.Available_Funds_to_Transfer_v2__c;
            
            Id trustAccountId = oppToTrustAccount.get(o);
            List<Creditor_Ledger__c> ledgers = taToclMap.get(trustAccountId);
            rw.creditor_ledger = (accountSaleType == 'CR') ? getCreditorLedgerForJournal(ledgers, o, true) : getCreditorLedgerForJournal(ledgers, o, false);
            
            //Used only at disbursements
            if (accountSaleType == 'DIS') {
                rw.ohJournalTransfer = new ReceiptWrapper();
                rw.ohJournalTransfer.Opportunity = o;
                rw.ohJournalTransfer.creditor_ledger = getCreditorLedgerForJournal(ledgers, o, true);
                rw.ohJournalTransfer.journal_amount = o.Funds_to_Retain_v2__c;
            }
            //Used only at disbursements
            
            if (receipts.containsKey(trustAccounts.get(trustAccountId))) {
                receipts.get(trustAccounts.get(trustAccountId)).add(rw);
            } else {
                List<ReceiptWrapper> listWrappers = new List<ReceiptWrapper>();
                listWrappers.add(rw);
                receipts.put(trustAccounts.get(trustAccountId), listWrappers);
            }
            receipts.get(trustAccounts.get(trustAccountId)).sort();
        }
        
    }
    
    public Creditor_Ledger__c getCreditorLedgerForJournal(List<Creditor_Ledger__c> ledgers, Opportunity o, boolean isDisbursement) {
        try {
            for (Creditor_Ledger__c c : ledgers) {
                if (c.Account__c != null && c.Trust_Account__c != null) {
                    if (!isDisbursement) {
                        if (c.Account__c == o.Primary_Product__r.Solicitor__c && c.Trust_Account__c == o.Primary_Product__r.Project__r.Trust_Account__c) {
                            if (c.Ledger_Balance__c >= 0) {
                                return c; //First Priority
                            } else {
                                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Wizard cannot continue as ' + c.Name + ' has a negative Ledger Balance.' ));
                                return null;
                            }
                        } else if (c.Account__c == o.Primary_Product__r.Project__r.Solicitor__c && c.Trust_Account__c == o.Primary_Product__r.Project__r.Trust_Account__c) {
                            if (c.Ledger_Balance__c >= 0) {
                                return c; //Second Priority
                            } else {
                                ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Wizard cannot continue as ' + c.Name + ' has a negative Ledger Balance.' ));
                                return null;
                            }
                        } else {
                            //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'No matching Creditor Ledger found.'));
                        }
                    } else {
                        if (c.Account__c == o.Primary_Product__r.Project__r.OH_Account__c) {
                            if (c.Ledger_Balance__c >= 0) {
                              return new Creditor_Ledger__c(Id = c.Id, Name = c.Name);
                            } else {
                              ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: Wizard cannot continue as ' + c.Name + ' has a negative Ledger Balance.' ));
                                return null;
                            }
                        }
                    }
                }
            }
        } catch (Exception e) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage() + ' : ' + e.getStackTraceString()));
        }
        
        //Error state:
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, '\'' + o.Name + '\' or ' + '\'' + o.Primary_Product__r.Project__r.Name + '\'' + ' does not have an associated Creditor Ledger.'));
        return null;
    }
    
    public Map<Id, List<Creditor_Ledger__c>> getTrustAccountToCreditorLedgerMap(List<Id> keySet) {
        Map<Id, List<Creditor_Ledger__c>> result = new Map<Id, List<Creditor_Ledger__c>>();
        try {
            for (Trust_Account__c t : [SELECT Id
                                       , Name
                                       , Bank_Account__c
                                       , Bank_Code__c
                                       , Name_of_Use_Text__c
                                       , Name_of_Use_Number__c
                                       , Bank_Account__r.Name
                                       , Bank_Account__r.BSB_Number__c
                                       , Bank_Account__r.Bank_Account_Number__c
                                       , (SELECT Id, Name, Account__c, Trust_Account__c, Ledger_Balance__c  
                                          FROM Creditor_Ledgers__r)
                                       FROM Trust_Account__c
                                       WHERE Id IN :keySet]) {
                trustAccounts.put(t.Id, t);
                result.put(t.Id, t.Creditor_Ledgers__r);
            }
        } catch (Exception e) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage() + ' : ' + e.getStackTraceString()));
        }
        
        return result;      
    }
    
    public void back() {
        transactions2.clear();
    }
    
    public void generatePayments() {
        List<JournalWrapper> journals = new List<JournalWrapper>();
            
        for (Trust_Account__c t : receipts.keySet()) {
            List<ReceiptWrapper> wrappers = receipts.get(t);
            
            for (ReceiptWrapper rw : wrappers) {
                if (rw.checked || rw.ohJournalTransfer.checked) {
                    if (rw.checked) {
                        if (accountSaleType != 'CR')
                            journals.add(getJournalWrapper(rw, t, 'Journal to Creditor Ledger'));
                        else
                            journals.add(getJournalWrapper(rw, t, 'Journal to OH Creditor Ledger'));
                    }
                        
                    //Used only at disbursements
                    if (rw.ohJournalTransfer != null && rw.ohJournalTransfer.checked) {
                        JournalWrapper j = getJournalWrapper(rw.ohJournalTransfer, t, 'Journal to OH Creditor Ledger');
                        if (j != null) journals.add(j);
                    }
                        
                } 
            }
            
        }
        normalize(journals);
        
    }
    
    public JournalWrapper getJournalWrapper(ReceiptWrapper rw, Trust_Account__c t, String description) {
        try {
            if (rw != null && t != null) {
                Receipt__c journal = new Receipt__c();
                journal.RecordTypeId = recordTypes.get('Journal') ;
                journal.Opportunity__c = rw.opportunity.Id;
                journal.Amount__c = rw.journal_amount;
                journal.Description__c = description;
                journal.Product__c = rw.opportunity.Primary_Product__c;
                journal.Trust_Account__c = t.Id;
                journal.Creditor__c = rw.creditor_ledger.Id;
                
                JournalWrapper journalWrapper = new JournalWrapper();
                journalWrapper.projectId = rw.opportunity.Primary_Product__r.Project__c;
                journalWrapper.projectName = rw.opportunity.Primary_Product__r.Project__r.Name;
                journalWrapper.productId = rw.opportunity.Primary_Product__c;
                journalWrapper.productName = rw.opportunity.Primary_Product__r.Name;
                journalWrapper.journal = journal;
                journalWrapper.opportunityId = rw.opportunity.Id;
                journalWrapper.opportunityName = rw.opportunity.Name;
                journalWrapper.paymentWrapper.trustAccount = t;
                journalWrapper.paymentWrapper.creditorLedger = rw.creditor_ledger;
                journalWrapper.paymentWrapper.paymentMethod = (rw.opportunity.Primary_Product__r.Solicitors_Payment_Method__c != null) ? rw.opportunity.Primary_Product__r.Solicitors_Payment_Method__c : rw.opportunity.Primary_Product__r.Project__r.Solicitors_Payment_Method__c;
                if ((accountSaleType != 'CR') && (accountSaleType != 'DIS')) {
                    journalWrapper.paymentWrapper.bankAccountId = (rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__c != null) ? rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__c : rw.opportunity.Primary_Product__r.Project__r.Solicitors_Bank_Account__c;
                    journalWrapper.paymentWrapper.bankAccountName = (rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__r.Name != null) ? rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__r.Name : rw.opportunity.Primary_Product__r.Project__r.Solicitors_Bank_Account__r.Name;
                } else {
                    if (journalWrapper.journal.Description__c == 'Journal to OH Creditor Ledger') {
                        journalWrapper.paymentWrapper.bankAccountId = generalBankAccounts.get(rw.opportunity.Primary_Product__r.Project__r.OH_Account__c).Id;
                        journalWrapper.paymentWrapper.bankAccountName = generalBankAccounts.get(rw.opportunity.Primary_Product__r.Project__r.OH_Account__c).Name;
                    } else {
                        journalWrapper.paymentWrapper.bankAccountId = (rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__c != null) ? rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__c : rw.opportunity.Primary_Product__r.Project__r.Solicitors_Bank_Account__c;
                        journalWrapper.paymentWrapper.bankAccountName = (rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__r.Name != null) ? rw.opportunity.Primary_Product__r.Solicitors_Bank_Account__r.Name : rw.opportunity.Primary_Product__r.Project__r.Solicitors_Bank_Account__r.Name;
                    }
                }
                return journalWrapper;
            }
        } catch (Exception e) {
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage() + ' : ' + e.getStackTraceString()));
        }
        
        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Unable to create the Journal.'));
        return null;
    }
    
    public void normalize(List<JournalWrapper> journals) {
        if (!journals.isEmpty()) {
            Map<Trust_Account__c, Map<PaymentWrapper, List<JournalWrapper>>> transactions = new Map<Trust_Account__c, Map<PaymentWrapper, List<JournalWrapper>>>();
            Map<PaymentWrapper, Receipt__c> paymentwrappersToReceipt = new Map<PaymentWrapper, Receipt__c>();
            
            for (JournalWrapper journal : journals) {
                if (journal.paymentWrapper.trustAccount != null) {
                    transactions.put(journal.paymentWrapper.trustAccount, new Map<PaymentWrapper, List<JournalWrapper>>());
                }
                Receipt__c payment = new Receipt__c();
                payment.RecordTypeId = recordTypes.get('Payment');
                
                if ((accountSaleType == 'CR') || (accountSaleType == 'DIS')) {
                    payment.Description__c = 'Full Commission';
                } else {
                    payment.Description__c = 'Deposit Transfer Payment';    
                }
                
                payment.Creditor__c = journal.paymentWrapper.creditorLedger.Id;
                payment.Payment_Method__c = journal.paymentWrapper.paymentMethod;
                payment.Bank_Account__c = journal.paymentWrapper.bankAccountId;
                payment.Trust_Account__c = journal.paymentWrapper.trustAccount.Id;
                
                paymentwrappersToReceipt.put(journal.paymentWrapper, payment);
            }
            
            for (PaymentWrapper p : paymentwrappersToReceipt.keySet()) {
                Receipt__c r = paymentwrappersToReceipt.get(p); 
                p.payment = r;
                transactions.get(trustAccounts.get(r.Trust_Account__c)).put(p, new List<JournalWrapper>());    
            }
            
            for (JournalWrapper j : journals) {
                Map<PaymentWrapper, List<JournalWrapper>> paymentToJournals = transactions.get(trustAccounts.get(j.paymentWrapper.trustAccount.Id));
                for (PaymentWrapper p : paymentToJournals.keySet()) {
                    if (j.paymentWrapper.equals(p)) {
                        paymentToJournals.get(p).add(j);
                        p.sumAmount += j.journal.Amount__c;
                    }
                }
            }
            
            for (Trust_Account__c t : transactions.keySet()) {
                TrustAccountWrapper tw = new TrustAccountWrapper(t);
                transactions2.put(tw, new List<PaymentWrapper>());
                Map<PaymentWrapper, List<JournalWrapper>> paymentToJournals = transactions.get(t);
                transactions2.get(tw).addAll(paymentToJournals.keySet());
                List<PaymentWrapper> pays = transactions2.get(tw);
                for (PaymentWrapper pay : pays) {
                    pay.journals.clear();
                    pay.journals.addAll(paymentToJournals.get(pay));
                }
            }
        }
        
        
    }
    
    public void create() {
        fromPageTwo = true;
        List<Receipt__c> eft = new List<Receipt__c>();
        List<Receipt__c> cheque = new List<Receipt__c>();
        List<Receipt__c> journals = new List<Receipt__c>();
        Map<Id, TrustAccountWrapper> trustAccounts = new Map<Id, TrustAccountWrapper>();
        
        for (TrustAccountWrapper trustAccountWrapper : transactions2.keySet()) {
            List<PaymentWrapper> paymentwrappers = transactions2.get(trustAccountWrapper);
            trustAccounts.put(trustAccountWrapper.trustAccount.Id, trustAccountWrapper);
            
            for (PaymentWrapper p : paymentWrappers) {
                if (p.checked) {
                    if (p.paymentMethod == 'EFT') {
                        trustAccountWrapper.eftPayments.add(p.getPayment());
                        eft.add(p.getPayment());
                    }else if (p.paymentMethod == 'Cheque') {
                        trustAccountWrapper.chequePayments.add(p.getPayment());
                        cheque.add(p.getPayment());
                    }

                    try {
                    for (JournalWrapper journal : p.journals) {
                        trustAccountWrapper.journals.add(journal.journal);
                        journals.add(journal.journal);
                    }
                    } catch (Exception e) {
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error: ' + e.getMessage() + ' : ' + e.getStackTraceString()));
                    }
                }
            }
        }
        
        try {
            insert journals;
            insert eft;
            insert cheque;
            
            //Assign Bulk Payment Id to Journals
            List<Receipt__c> toUpdateWithBulkPayments = new List<Receipt__c>();
            for (TrustAccountWrapper t : transactions2.keySet()) {
                for (PaymentWrapper p : transactions2.get(t)) {
                    for (JournalWrapper j : p.journals) {
                        j.journal.Bulk_Payment__c = p.payment.Id;
                        toUpdateWithBulkPayments.add(j.journal);
                    }
                }
            }
            
            update toUpdateWithBulkPayments;
           
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(0)));
        }        
        
        Map<Id, Bank_Account__c> bulkPaymentToBankAccount = new Map<Id, Bank_Account__c>();
        for (Receipt__c p : eft) {
            bulkPaymentToBankAccount.put(p.Id, allBankAccounts.get(p.Bank_Account__c));
        }
        for (Receipt__c p : cheque) {
            bulkPaymentToBankAccount.put(p.Id, allBankAccounts.get(p.Bank_Account__c));
        }
        
        //abaPreviews = abaUtility.createABAReceipts(journals, bulkPaymentToBankAccount, trustAccounts, false);
        abaPreviews = abaUtility.createABAReceipts2(transactions2, bulkPaymentToBankAccount, false);
        generateABAFiles();
    }
    
    public void generateABAFiles(){
        if(abaPreviews != null && !abaPreviews.isEmpty()){
            Id abaFolderId;
            try{
                abaFolderId = [SELECT Id FROM Folder WHERE Type = 'Document' AND DeveloperName = 'ABA_Files' LIMIT 1].Id;
            }
            catch(queryException q){
                System.debug('Error finding ABA Folder: '+q.getMessage());
            }
            
            Document[] abaDocs = new Document[]{};

            for(abaUtility.aba a: abaPreviews){
                if(a.abaString != null && a.errors.isEmpty()){
                    Document abaDoc = new Document();
                    abaDoc.Name = a.abaName+'.aba';
                    abaDoc.Body = a.abaString != null ? blob.valueOf(a.abaString) : blob.valueOf('');
                    abaDoc.ContentType = 'application/octet-stream';
                    abaDoc.folderId = abaFolderId;
                    abaDocs.add(abaDoc);
                    
                    TrustAccountWrapper wrapper = new TrustAccountWrapper(a.trustAccount);
                    if (transactions2.containsKey(wrapper)) {
                        for (TrustAccountWrapper t : transactions2.keySet()) {
                            if (wrapper.equals(t)) {
                                t.abafile = abaDoc;
                            }
                        }
                    }
                }
                else{
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Errors were found whilst creating ABA '+ a.abaName + ''));
                    for(string e: a.errors){
                        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, a.abaName+':'+e));    
                    }
                }
            }

            insert abaDocs;
        }
    }
    
    public void generateAccountSales() {
        if (transactions2 != null && !transactions2.isEmpty()) {
            List<Attachment> accountSaleFiles = new List<Attachment>();
            
            for (TrustAccountWrapper t : transactions2.keySet()) {
                List<PaymentWrapper> payments = transactions2.get(t);
                for (PaymentWrapper p : payments) {
                    List<JournalWrapper> journals = p.journals;
                    for (JournalWrapper j : journals) {
                        Attachment journalAccountSalesReport = new Attachment();
                    
                        journalAccountSalesReport.Name = 'Account Sale - ' + j.opportunityName + '.pdf';
                        journalAccountSalesReport.ContentType = 'application/pdf';
                        journalAccountSalesReport.ParentId = j.journal.Id;
                        
                        PageReference pdfJ;
                        if (accountSaleType == 'DT')
                            pdfJ = Page.taxInvoice;
                        else if (accountSaleType == 'S24')
                            pdfJ = Page.taxInvoice24;
                        else if (accountSaleType == 'DIS')
                            pdfJ = Page.disburseInvoice;
                        else if (accountSaleType == 'CR')
                            pdfJ = Page.commissionInvoice;
                        
                        pdfJ.getParameters().put('id', j.journal.Id);
                        pdfJ.getParameters().put('processedDate', Datetime.now().format('dd/MM/yyyy'));
                        Blob dataJ = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdfJ.GetContentAsPDF();
                        journalAccountSalesReport.Body = dataJ;
                        
                        Attachment bPAccountSalesReport = new Attachment();
                    
                        bPAccountSalesReport.Name = 'Account Sale - ' + j.opportunityName + '.pdf';//Datetime.now().format('yyyy-MM-dd');
                        bPAccountSalesReport.ContentType = 'application/pdf';
                        bPAccountSalesReport.ParentId = p.payment.Id;
                        
                        PageReference pdfBP;
                        if (accountSaleType == 'DT')
                            pdfBP = Page.taxInvoice;
                        else if (accountSaleType == 'S24')
                            pdfBP = Page.taxInvoice24;
                        else if (accountSaleType == 'DIS')
                            pdfBP = Page.disburseInvoice;
                        else if (accountSaleType == 'CR')
                            pdfBP = Page.commissionInvoice;
                        
                        pdfBP.getParameters().put('id', j.journal.Id);
                        pdfBP.getParameters().put('processedDate', Datetime.now().format('dd/MM/yyyy'));
                        Blob dataBP = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdfBP.GetContentAsPDF();
                        bPAccountSalesReport.Body = dataBP;
                        
                        accountSaleFiles.add(journalAccountSalesReport);
                        accountSaleFiles.add(bPAccountSalesReport);
                    }
                }
                
            }
            
            try {
                insert accountSaleFiles;
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO, 'Account sales generated successfully.')); 
            } catch (Exception e) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, e.getMessage()));    
            }
        }
    }
    
    public class ReceiptWrapper implements Comparable {
        public boolean checked = true;
        public Creditor_Ledger__c creditor_ledger {get; set;}
        public Opportunity opportunity {get; set;} 
        public Decimal journal_amount {get; set;}
        public ReceiptWrapper ohJournalTransfer {get; set;}
        
        public boolean getChecked() {
            return this.checked;
        }
        
        public void setChecked(boolean checked) {
            this.checked = checked;
        }
        
        /*public Decimal getJournal_amount() {
            journal_amount = opportunity.Available_Funds_to_Transfer_v2__c;
            journal_amount = journal_amount.setScale(2);
            return opportunity.Available_Funds_to_Transfer_v2__c;
        }
        
        public void setJournal_amount(Decimal journal_amount) {
            this.journal_amount = journal_amount;
        }*/
        
        public Integer compareTo(Object compareTo) {
            ReceiptWrapper other = (ReceiptWrapper) compareTo;
            if (this.creditor_ledger.name > other.creditor_ledger.name)
                return -1;
            else if (this.creditor_ledger.name == other.creditor_ledger.name)
                return 0;
            return 1;
        }
    }
   
    public class JournalWrapper {
        public Receipt__c journal {get; set;}
        public Id projectId {get; set;}
        public String projectName {get; set;}
        public Id productId {get; set;}
        public String productName {get; set;}
        public Id opportunityId {get; set;}
        public String opportunityName {get; set;}
        public PaymentWrapper paymentWrapper {get; set;}
        
        
        public JournalWrapper() {
            this.paymentWrapper = new PaymentWrapper();
            this.paymentWrapper.addJournal(this);
        }
        
    }
    
    public class PaymentWrapper {
        public Receipt__c payment;
        public boolean checked = true;
        public Trust_Account__c trustAccount {get; set;}
        public Creditor_Ledger__c creditorLedger {get; set;}
        public List<JournalWrapper> journals {get; set;}
        public Id bankAccountId {get; set;}
        public String bankAccountName {get; set;}
        public String paymentMethod {get; set;}
        public String reference {get; set;}
        public Double sumAmount {get; set;}
        
        public Receipt__c getPayment() {
            if (this.payment != null) {
                payment.Amount__c = sumAmount;
                payment.Payment_Method__c = paymentMethod;
                payment.Payment_Reference__c = reference;
            }
            return payment;
        }
        
        public void setPayment(Receipt__c payment) {
            this.payment = payment;
        }
        
        public boolean getChecked() {
            return this.checked;
        }
        
        public void setChecked(boolean checked) {
            this.checked = checked;
        }
        
        public List<SelectOption> getPaymentMethods() {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('Cheque','Cheque'));
            options.add(new SelectOption('EFT','EFT'));
            return options;
        }
        
        public PaymentWrapper() {
            journals = new List<JournalWrapper>();
            sumAmount = 0.0;
        }
        
        public void addJournal(JournalWrapper j) {
            journals.add(j);
        }
        
        public boolean equals(Object obj) {
            if (obj instanceof PaymentWrapper) {
                PaymentWrapper p = (PaymentWrapper)obj;
                return ((bankAccountName == p.bankAccountName) && (creditorLedger.Name == p.creditorLedger.Name));
            }
            return false;
        }
        
        public Integer hashCode() {
            return (31 * bankAccountName.hashCode()) ^ creditorLedger.Name.hashCode();
        }
        
    }
    
    public class TrustAccountWrapper implements Comparable {
        
        public Trust_Account__c trustAccount {get; set;}
        public Document abafile {get; set;}
        public List<Receipt__c> eftPayments {get; set;}
        public List<Receipt__c> chequePayments {get; set;}
        public List<Receipt__c> journals {get; set;}
        public String abaReference {get; set;}
        
        public TrustAccountWrapper(Trust_Account__c trustAccount) {
            this.trustAccount = trustAccount;
            this.eftPayments = new List<Receipt__c>();
            this.chequePayments = new List<Receipt__c>();
            this.journals = new List<Receipt__c>();
        }
        
        public Decimal getTotalJournalAmount() {
            Decimal total = 0;
            for (Receipt__c j : journals) {
                total += j.Amount__c;
            }
            total = total.setScale(2);
            return total;
        }
        
        public Decimal getTotalChequeAmount() {
            Decimal total = 0;
            for (Receipt__c c : chequePayments) {
                total += c.Amount__c;
            }
            total = total.setScale(2);
            return total;
        }
        
        public Decimal getTotalEftAmount() {
            Decimal total = 0;
            for (Receipt__c e : eftPayments) {
                total += e.Amount__c;
            }
            total = total.setScale(2);
            return total;
        }
        
        public String getABAUrl() {
            if (abafile != null)
                return '/servlet/servlet.FileDownload?file=' + abafile.Id;
            return null;
        }

        public Integer compareTo(Object compareTo) {
            TrustAccountWrapper other = (TrustAccountWrapper) compareTo;
            if (this.trustAccount.name > other.trustAccount.name)
                return 1;
            else if (this.trustAccount.name == other.trustAccount.name)
                return 0;
            return -1;
        }
        
        public boolean equals(Object obj) {
            if (obj instanceof TrustAccountWrapper) {
                TrustAccountWrapper t = (TrustAccountWrapper)obj;
                return ((trustAccount.Id == t.trustAccount.Id));
            }
            return false;
        }
        
        public Integer hashCode() {
            return (31 * trustAccount.Name.hashCode());
        }
    }
    
}