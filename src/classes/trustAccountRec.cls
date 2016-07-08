public with sharing class trustAccountRec {
    
    public decimal openingBalance{get; set;}
    public decimal closingBalance{get; set;}
    public string closingDate{get; set;}
    public decimal totalReceiptsBank{get; set;}
    public decimal totalPaymentsBank{get; set;}
    
    
    
    public decimal totalReceiptsSFDC{get; set;}
    public decimal totalPaymentsSFDC{get; set;}
    
    public decimal totalFeeAdjustments{get; set;}
    public decimal totalCreditAdjustments{get; set;}
    
    public decimal totalUnpresentedPayments{get; set;}
    public decimal totalUnpresentedReceipts{get; set;}
    
    public decimal totalUnresolvedAdjustments{get; set;}
    public decimal salesforceOpeningBalance{get; set;}
    public decimal salesforceClosingBalance{get; set;}
    public decimal varianceBalance{get; set;}
    
    //new
    public decimal reconciledBankBalance{get; set;}
    public decimal closingCashbookBalance{get; set;}
        
    private integer classInt;
    private string getClass(){
        string classString;
        //returns an integer that can be used for a specific row in any list to aid with client side validation
        if(classInt == null){
            classString = 'sf0';
            classInt = 0;
        }
        else{
            classInt++;
            classString = 'sf'+string.valueOf(classInt);
        }
        return classString;
    }
    
    public Id trustAccountId{get; set;}
    public document csvFile{get; set;}
    
    public boolean showCsvStatus{get; set;}
    public integer csvRows{get; set;}
    public Receipt__c dummyReceipt{get; set;}
    public selectOption[] getTrustAccountOptions(){
        //Query all trust accounts and build the trust account select list.
        selectOption[] trustOptions = new selectOption[]{};
        trustOptions.add(new selectOption('','--Please Select--'));
        for(Trust_account__c t: [select Id, Name from Trust_Account__c order by Name]){
            trustOptions.add(new selectOption(t.Id, t.Name));
        }
        
        return trustOptions;
    }
    //Unpresented Payments List
    public Receipt__c[] unpresentedPayments{get; set;}
    public Receipt__c[] unpresentedReceipts{get; set;}
    public Adjustment__c[] unresolvedAdjustments{get; set;}
    public boolean showStep4{get; set;}
    
    public class xRow{
        //Transaction Amount (Positive and Negative values)
        public Double xAmount{get; set;}
        //Transaction Date
        public date xDate{get; set;}
        //Transaction Description
        public date xDatenew{get; set;}
        public string xDescription{get; set;}
        //swift code
        public string xSwiftCode{get; set;}
        //trust account number
        public string xAccount{get; set;}
        //a code that is used by the bank (eg balance = 15, debit cheques = 475, credit cheques = 175 etc....
        public string xCode{get; set;}
        public string xCodeDesc{get; set;}
        //Trust Account Cheque Number
        public string xChequeNumber{get; set;}
        //other variables
        public boolean isReconciled{get; set;}
        //project
        public String projectName {get; set;}
        //produc
        public String productName {get;set;}
    }
    
    //Classes to encapsulate various transaction types.
    public class receipt implements Comparable{
        //reference to external controller
        private trustAccountRec tar;
        public string receiptClass{get; set;}
        public Receipt__c receipt{get; set;}
        public boolean isSelected{get; set;}
        public integer score{get; set;}
        //dummy adjustment to leverage the receipt lookup
        public Adjustment__c dummyAdjustment{get; set;}
        
        public Integer compareTo(Object compareTo) {
            receipt ctr = (receipt)compareTo;
            if (score == ctr.score) return 0;
            if (score < ctr.score) return 1;
            return -1;        
        }
        
        public receipt(trustAccountRec tar){
            this.isSelected = false;
            this.dummyAdjustment = new Adjustment__c();
            this.tar = tar;
            this.receiptClass = tar.getClass();
        }
        
        //if an existing payment is associated, update the ammount to be reconciled.
        public void updateAmount(){
            if(dummyAdjustment.Transaction__c != null){
                //query the transaction and get the amount.
                try{
                    Receipt__c matchedReceipt = [select Id, Amount__c,Name,Trust_Account__c, Opportunity__c, Project__c, Product__r.Name, Payment_Method__c,Transaction_ID__c,Trust_Account__r.Trust_Account_Bank_Balance_Date__c,Trust_Account__r.Bank_Statement_Balance__c,Reconciled__c, Date_Reconciled__c, Date__c from Receipt__c where Id=: dummyAdjustment.Transaction__c and Reconciled__c = false];
                    this.receipt.Amount__c = matchedReceipt.Amount__c;
                    //we can also update the opportunity? / dummyAdjustment for usability
                    this.receipt = matchedReceipt;
                    this.dummyAdjustment.Opportunity__c = matchedReceipt.Opportunity__c;
                    
                }
                catch(exception e){
                    //add an message to the page explaining that the receipt is unavailable, probably due to it already being reconciled.
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Receipt unavailable, probably due to already being reconciled.  Please choose another transaction.'));
                }
            }
        }
    
    }
    
    public class payment implements Comparable{
        //reference to external controller
        private trustAccountRec tar;
        public string paymentClass{get; set;}
        public Receipt__c payment{get; set;}
        public boolean isSelected{get; set;}
        public integer score{get; set;}
        
        //dummy adjustment to leverage the receipt lookup
        public Adjustment__c dummyAdjustment{get; set;}
        
        public Integer compareTo(Object compareTo) {
            payment ctp = (payment)compareTo;
            if (score == ctp.score) return 0;
            if (score < ctp.score) return 1;
            return -1;        
        }
        
        public payment(trustAccountRec tar){
            this.isSelected = false;
            this.dummyAdjustment = new Adjustment__c();
            this.tar = tar;
            this.paymentClass = tar.getClass();
        }
        
        //if an existing payment is associated, update the ammount to be reconciled.
        public void updateAmount(){
            if(dummyAdjustment.Transaction__c != null){
                //query the transaction and get the amount.
                try{
                    Receipt__c matchedPayment = [select Id, Name, Project__c, Product__r.Name,Trust_Account__c,Trust_Account__r.Trust_Account_Bank_Balance_Date__c,Trust_Account__r.Bank_Statement_Balance__c,Amount__c,Transaction_ID__c,Opportunity__c, Payment_Method__c, Reconciled__c, Date_Reconciled__c, Date__c from Receipt__c where Id=: dummyAdjustment.Transaction__c and Reconciled__c = false];
                    /*
                    this.payment.Amount__c = matchedPayment.Amount__c;
                    this.payment.Opportunity__c = matchedPayment.Opportunity__c;
                    */
                    this.payment = matchedPayment;
                    this.dummyAdjustment.Opportunity__c = matchedPayment.Opportunity__c;
                    
                }
                catch(exception e){
                    //add an message to the page explaining that the receipt is unavailable, probably due to it already being reconciled.
                    ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Payment unavailable, probably due to already being reconciled.  Please choose another transaction.'));
                }
            }
        }
    }
    
    public class adjustment implements Comparable{
        //reference to external controller
        private trustAccountRec tar;
        public string adjustmentClass{get; set;}
        public Adjustment__c adjustment{get; set;}
        public boolean isSelected{get; set;}
        public integer score{get; set;}
        public Adjustment__c exAdj{get; set;}
        
        public adjustment(trustAccountRec tar){
            this.isSelected = false;      
            this.tar = tar;
            this.adjustmentClass = tar.getClass();
        }
        
        public Integer compareTo(Object compareTo) {
            adjustment cta = (adjustment)compareTo;
            if (score == cta.score) return 0;
            if (score < cta.score) return 1;
            return -1;        
        }
        
        
        //method gets a matching Adjustment from SFDC, and pre poulates the new adjustment
        public void loadExisting(){
            try{
                exAdj = [select Id, Name, Notes__c, Amount__c, Type__c, Status__c, Resolved_Date__c, Date__c,Trust_Account__c from Adjustment__c where Id =: this.adjustment.Adjustment__c];
                //transfer this data to the new adjustment
                this.adjustment.Notes__c = exAdj.Notes__c;
                this.adjustment.Resolved_Date__c = date.today();
                this.adjustment.Date__c = date.today();
                this.adjustment.Trust_Account__c = tar.trustAccountId;
                if(MATH.signum(exAdj.Amount__c) > 0){
                    //existing is positive, create negative
                    this.adjustment.Amount__c = exAdj.Amount__c *-1;
                    this.adjustment.Type__c = 'Fees';
                    this.adjustment.Status__c = 'Resolved';
                }
                else if(MATH.signum(exAdj.Amount__c) < 0){
                    //existing is negative, create positive.
                    this.adjustment.Amount__c = MATH.abs(exAdj.Amount__c);
                    this.adjustment.Type__c = 'Credit';
                    this.adjustment.Status__c = 'Assigned';
                }
            }
            catch(exception e){
                //do something here
            }
        }
        
    }
    //Container Classes
    public class receiptContainer{
        //is there a reconciliation error?
        public boolean isError{get; set;}
        public string errorMessage{get; set;}
        public string errorType{get; set;}
        private trustAccountRec tar;
        public xRow xRow{get; set;}
        //prop converts the xrow to a 
        public xRow[] xRows{get; set;}
        //a list containing 1 new receipt that will be used to add an existing receipt that hasn't matched.
        public receipt[] newReceipts{get; set;}
        //a list of receipts that have been matched.
        public receipt[] receipts{get; set;}
        public boolean showMatchedReceipts{get; set;}
        public boolean showMatchedAdjustments{get; set;}
        //a list of adjustments that have been matched
        public adjustment[] adjustments{get; set;}
        //a list containing 1 adjustment that will be used to create a new adjustment.
        public adjustment[] newAdjustments{get; set;}
        public boolean isReconciled{get; set;}
        //a list containing 1 adjustment that will be used to associate an existing adjustment
        public adjustment[] existingAdjustments{get; set;}
        //public string style {get; set;}
        
        public receiptContainer(trustAccountRec tar){
            //Ref to outer class
            this.tar = tar;
            //set error to false
            isError = false;
            //list of matched receipts
            receipts = new receipt[]{};
            //list of matched adjustments
            adjustments = new adjustment[]{};
            //list to store an existing receipt that wasn't matched.
            newReceipts = new receipt[]{};
            receipt newReceipt = new receipt(this.tar);
            //initialise the new receipt object with a new Receipt__c sObject
            newReceipt.receipt = new Receipt__c();
            newReceipts.add(newReceipt);
            //create the default new adjustment
            adjustment newAdjustment = new adjustment(this.tar);
            newAdjustment.adjustment = new Adjustment__c(Type__c = 'Credit');
            newAdjustments = new adjustment[]{newAdjustment};
            //new adjustment used to match an existing adjustment.
            adjustment existingAdjustment = new adjustment(this.tar);
            existingAdjustment.adjustment = new Adjustment__c();
            existingAdjustments = new adjustment[]{existingAdjustment};
            //by default, we'll show the matched receipts.
            showMatchedReceipts = true;
            showMatchedAdjustments = true;
            //this.style = 'padding-left:10px; padding-right:10px; padding-bottom:20px; padding-top:10px;display:none;';
        }
        
        
        //method that adds an additional receipt to the manual matching section
        public void newManualReceipt(){
            receipt newReceipt = new receipt(this.tar);
            //initialise the new receipt object with a new Receipt__c sObject
            newReceipt.receipt = new Receipt__c();
            newReceipts.add(newReceipt);
        }   
    }
    
    public class paymentContainer{
        //is there a reconciliation error?
        public boolean isError{get; set;}
        public string errorMessage{get; set;}
        public string errorType{get; set;}
        //Ref to outer class.
        private trustAccountRec tar;
        public xRow xRow{get; set;}
        public xRow[] xRows{get; set;}
        //list of all matched payments
        public payment[] payments{get; set;}
        //used to manually match a payment
        public boolean showMatchedPayments{get; set;}
        public boolean showMatchedAdjustments{get; set;}
        public payment[] newPayments{get; set;}
        //a list of adjustments that have been matched
        public adjustment[] adjustments{get; set;}
        public boolean isReconciled{get; set;}
        //a list containing 1 adjustment that will be used to create a new adjustment.
        public adjustment[] newAdjustments{get; set;}
        //a list containing 1 adjustment that will be used to associate an existing adjustment
        public adjustment[] existingAdjustments{get; set;}
        
        paymentContainer(trustAccountRec tar){
            isError = false;
            this.tar = tar;
            //matched payments
            payments = new payment[]{};
            //matched adjustments
            adjustments = new adjustment[]{};
            //list to match 1 existing payment that wasn't matched.
            newPayments = new payment[]{};
            payment newPayment = new payment(this.tar);
            newPayment.payment = new Receipt__c();
            newPayments.add(newPayment);
            
            //create the default new payment
            adjustment newAdjustment = new adjustment(this.tar);
            newAdjustment.adjustment = new Adjustment__c(Type__c = 'Fees');
            newAdjustments = new adjustment[]{newAdjustment};
            //new adjustment used to match an existing adjustment.
            adjustment existingAdjustment = new adjustment(this.tar);
            existingAdjustment.adjustment = new Adjustment__c();
            existingAdjustments = new adjustment[]{existingAdjustment};
            
            //default is to show matched payments
            showMatchedPayments = true;
            showMatchedAdjustments = true;
        }
        
        //method that adds an additional receipt to the manual matching section
        public void newManualPayment(){
            payment newPayment = new payment(this.tar);
            //initialise the new payment object with a new Receipt__c sObject
            newPayment.payment = new Receipt__c();
            newPayments.add(newPayment);
        } 
    }
    
    //Lists accessed by the page.
    public receiptContainer[] receipts{get; set;}
    public paymentContainer[] payments{get; set;}
    public adjustment[] adjustments{get; set;}

    public Trust_Account__c trustAccount{get; set;}

    public trustAccountRec(ApexPages.StandardController controller) {
        this.trustAccountId = controller.getId();
        //comment out after testing
        //this.trustAccountId = 'a0bN0000002HysB';
        //this.trustAccount = [select Id, Name, Ledger_Balance__c, Total_Adjustments__c, Total_Receipts__c, Total_Payments__c from Trust_Account__c where Id ='a0bN0000002HysB'];
        showCsvStatus = false;
        dummyReceipt = new Receipt__c(Date__c = date.today());
        csvFile = new Document();
        
        refreshTrustAccount();
        showStep4 = false;
    }
    
    public void processCSV(){
    
//TODO: Change this in the UI and validate Date
        if(dummyReceipt.Date__c == null){
            dummyReceipt.Date__c = date.today();
        }
        if(csvFile != null && csvFile.Body != null && csvFile.ContentType != null && csvFile.Name != null){
            //have all the requirements to try to process the csv
            String docBody = csvFile.Body.toString();
            system.debug('The doc body: '+docBody);
            String[] csvXRows = docBody.split('\r');
            system.debug('Split into rows: '+csvXRows.size());
            //loop through until we get to the CSV header row. 
            integer startRow = 1;
            integer endRow;
            
            for(integer i = csvXRows.size()-1; i >=0; i--){
                //check that the row chosen has 9 columns. and has some values to indicate it's a valid row
                if(csvXRows[i].split(',').size() == 9 && csvXRows[i].split(',')[0] != null){
                    endRow = i;
                    break;
                }
            }
            //integer endRow = csvXRows.size()-1;

            if(startRow != null && endRow != null){
                //CSV looks legit, so show step4.
                showStep4 = true;
                //get the opening and closing balance from the csv
                String[] openingRow = csvXRows[0].split(',');
                this.openingBalance = Double.valueOf(openingRow[8]);
                String[] closingRow = csvXRows[endRow].split(',');
                this.closingDate = normalize(closingRow[3]);
                this.closingBalance = Double.valueOf(closingRow[8]);
                //configure base date for converting excel date number to date.
                xRow[] xRows = new xRow[]{};
                for(integer i = startRow; i < endRow; i++){
                    
                    String[] rowList = csvXRows[i].split(',');
                    if(rowList.size() == 9){
                        xRow newRow = new xRow();
                        //populate the relevant row info
                        newRow.xSwiftCode = normalize(rowList[0]);
                        newRow.xAccount = normalize(rowList[2]);
                        //create the date integers
                        string[] dateSplit = normalize(rowList[3]).split('/');
                        integer dayInt = Integer.valueOf(dateSplit[0]);
                        integer monthInt = Integer.valueOf(dateSplit[1]);
                        integer yearInt = Integer.valueOf(dateSplit[2]);
                        newRow.xDate = Date.newInstance(yearInt, monthInt, dayInt);
                        newRow.xCode = normalize(rowList[4]);
                        newRow.xCodeDesc = normalize(rowList[5]);
                        newRow.xChequeNumber = normalize(rowList[6]);
                        newRow.xDescription = normalize(rowList[7]);
                        newRow.xAmount = Double.valueOf(normalize(rowList[8]));
                        newRow.xDatenew=date.parse(normalize(rowList[3]));
                        xRows.add(newRow);
                    }
                }
                //Rows are now stored in the xRows list.
                csvRows = xRows.size();
                showCsvStatus = true;
                
                //loop through CSV rows and build out the page data.
                //Create the Receipts first.
                receipts = new receiptContainer[]{};
                payments = new paymentContainer[]{};
                adjustments = new adjustment[]{};
                for(xRow x: xRows){
                    if(x.xAmount > 0){
                        //Create a new receipt
                        receiptContainer newReceipt = new receiptContainer(this);
                        newReceipt.xRow = x;
                        newReceipt.xRows = new xRow[]{x};
                        receipts.add(newReceipt);
                    }
                    else if(x.xAmount < 0){
                        //Create a new payment
                        paymentContainer newPayment = new paymentContainer(this);
                        //convert x.xAmount to a positive number
                        //x.xAmount = math.abs(x.xAmount);
                        newPayment.xRow = x;
                        newPayment.xRows = new xRow[]{x};
                        payments.add(newPayment);
                    }
                }
                //Variables to store the matched payments and receipts
                Receipt__c[] matchedPayments = new Receipt__c[]{};
                Receipt__c[] matchedReceipts = new Receipt__c[]{};
                
                //Get All Non Reconciled Transactions Here.
                for(Receipt__c r: [select Id,
                                          Name,
                                          Type__c, 
                                          Description__c, 
                                          Amount__c,
                                          Transaction_ID__c,
                                          Trust_Account__c, 
                                          Date__c, 
                                          Received_From__c, 
                                          Payment_Method__c, 
                                          Customer_Ref__c, 
                                          Product__r.Name, 
                                          Project__c, 
                                          Opportunity__c, 
                                          Opportunity__r.Name, 
                                          Opportunity__r.AccountId, 
                                          Opportunity__r.Account.Name, 
                                          Opportunity__r.Account.isPersonAccount, 
                                          Opportunity__r.Account.LastName, 
                                          Opportunity__r.Account.FirstName, 
                                          Bank_Account__c, 
                                          Bank_Account__r.Name, 
                                          Bank_Account__r.BSB_Number__c,
                                          Trust_Account__r.Trust_Account_Bank_Balance_Date__c, 
                                          Trust_Account__r.Bank_Statement_Balance__c,
                                          Journal__c, Journal__r.Payment_Reference__c, 
                                          Journal__r.Cheque_Number__c, 
                                          Journal__r.Cheque_Number__r.Cheque_Number__c  
                                          from Receipt__c where Trust_Account__c =: trustAccountId and Reconciled__c = false and Opportunity__c != null and Opportunity__r.AccountId != null /*and X3rd_Party_Transaction__c = false*/]){
                    if(r.Type__c == 'Payment'){
                        matchedPayments.add(r);
                    }
                    else if(r.Type__c == 'Receipt'){
                        matchedReceipts.add(r);
                    }
                }
                Adjustment__c[] creditAdjustments = new Adjustment__c[]{};
                Adjustment__c[] debitAdjustments = new Adjustment__c[]{};
                //Adjustment__c[] feeAdjustments = new Adjustment__c[]{};
                //Get All Unreconciled Adjustments Here
                for(Adjustment__c a: [select Id,
                                             Name,
                                             Type__c,
                                             Date__c,
                                             Status__c,
                                             Amount__c, 
                                             Notes__c, 
                                             Trust_Account__c, 
                                             Opportunity__c, 
                                             Transaction__c, 
                                             Transaction_Amount__c,
                                             Resolved_Date__c
                                             from Adjustment__c where (Status__c = 'Unassigned' or Status__c = 'Unresolved') and Trust_Account__c =: trustAccountId]){
                    if(a.Amount__c > 0){
                        creditAdjustments.add(a);
                        system.debug('Credit Adjustment Added');
                    }
                    else if(a.Amount__c < 0){
                        debitAdjustments.add(a);
                        system.debug('Debit Adjustment Added');
                    }
                    /*
                    else if(a.Type__c == 'Fees'){
                        feeAdjustments.add(a);
                    }
                    */
                }
                //list of potential matching payments/receipts added, now perform matching algorithm to transactions in the CSV.
                
                //loop through transactions we've identified as Receipts first.
                for(receiptContainer nr: receipts){
                    //for each receipt, loop through the unreconciled receipt transactions and see if there is any match.
                    for(Receipt__c er: matchedReceipts){
                        //setup some lower case data from the existing receipt.
                        //only match on name where is it a person account
                        string lowerFirst;
                        string lowerLast;
                        string projectLower;
                        string productLower;
                        string referenceLower;
                        if(er.Opportunity__r.Account != null && er.Opportunity__r.Account.FirstName != null){
                            lowerFirst = er.Opportunity__r.Account.FirstName.toLowerCase();
                            
                        }
                        if(er.Opportunity__r.Account != null && er.Opportunity__r.Account.LastName != null){
                            lowerLast = er.Opportunity__r.Account.LastName.toLowerCase();
                        }
                        if(er.Project__c != null){
                            projectLower = er.Project__c.toLowerCase();
                        }
                        if(er.Product__c != null && er.Product__r.Name != null){
                            productLower = er.Product__r.Name.toLowerCase();
                        }
                        if(er.Customer_Ref__c != null){
                            referenceLower = er.Customer_Ref__c.toLowerCase();
                        }
                        //setup up some score markers
                        decimal amountMatch;
                        decimal nameMatch;
                        decimal projectMatch;
                        decimal productMatch;
                        decimal referenceMatch;
                        decimal receiptMatch;
                        decimal dateMatch;
                        
                        //first we'll look at the amount, must be less or equal to the existing record
                        if(nr.xRow.xAmount <= er.Amount__c){
                            //The amount is valid, now detirmine it's match score.
                            amountMatch = (nr.xRow.xAmount / er.Amount__c);
                        }
                        else{
                            //doesn't meet the criteria, no match so break from the loop.
                            continue;
                        }
                        //Dont match on payment type at the moment, focus on description field.
                        
                        //Description matching.
                        //this is the description from the transaction
                        string xDesc = nr.xRow.xDescription!=null?nr.xRow.xDescription.toLowerCase():null;
                        //create a set of invidual elements too.
                        set<string> xDescSet = new set<string>();
                        if(xDesc != null){
                            xDescSet.addAll(xDesc.split(' '));
                        }
                        //for each element of the description, try and match agains various receipt data.
                        //match against purchaser first name
                        if(er.Opportunity__r.Account != null && er.Opportunity__r.Account.isPersonAccount){
                            decimal firstMatch = 0;
                            decimal  lastMatch = 0;  
                            if(lowerFirst != null){
                                //we have a first name associated with the existing receipt, see if it is in this part of the description.
                                if(xDesc.contains(lowerFirst)){
                                    //we have at least a partial match, score .25
                                    firstMatch = .15;
                                }
                                if(xDescSet.contains(lowerFirst)){
                                    //we have an exact match, so score .5
                                    firstMatch = .30;
                                }
                            }
                            if(lowerLast != null){
                                //we have a first name associated with the existing receipt, see if it is in this part of the description.
                                if(xDesc.contains(lowerLast)){
                                    //we have at least a partial match, score .40
                                    lastMatch = .40;
                                }
                                if(xDescSet.contains(lowerLast)){
                                    //we have an exact match, so score .70
                                    lastMatch = .70;
                                }
                            }
                            //total the name matching scores.
                            nameMatch = firstMatch + lastMatch;
                        }
                        
                        //match against project name
                        if(projectLower != null){
                            if(xDesc.contains(projectLower)){
                                //score .4 for a partial match
                                projectMatch = .4;
                            }
                            else if(xDescSet.contains(projectLower)){
                                //score .6 for a full project match.
                                projectMatch = .6;
                                
                            }
                        }
                        //match against product name / lot number
                        if(productLower != null){
                            //first establish if there was a project match.
                            if(projectMatch != null){
                                //we have matched somewhat on the project, so do the product calculations accordingly.
                                if(xDesc.contains(productLower)){
                                    productMatch = projectMatch + .2;
                                }
                                if(xDescSet.contains(productLower)){
                                    productMatch = projectMatch +.2;
                                }
                                //if at this point we have udpdated productMatch, add an additional score to project match.
                                if(productMatch != null){
                                    projectMatch += .3;
                                }
                            }
                        }
                        //match against the customer reference
                        if(referenceLower != null){
                            if(xDesc.contains(referenceLower)){
                                //.6 for a partial reference match
                                referenceMatch = .6;
                            }
                            if(xDescSet.contains(referenceLower)){
                                //give 100% for a complete reference match
                                referenceMatch = 1;
                            }
                        }
                        //Match Transaction within a 10 day window.   
                        if(nr.xRow.xDate != null && er.Date__c != null){
                            //we have date records to analyse
                            integer age = er.Date__c.daysBetween(nr.xRow.xDate);
                            if(age >= 10){
                                //Transaction is too old, don't count it in list.
                                continue;
                            }
                            else{
                                dateMatch = (10-age)/10;
                                //make sure date match isn't more than 1!
                                if(dateMatch > 1){
                                    dateMatch = 1;
                                }
                            }
                        }
                        //calculate the score and add the receipt to the container.
                        receipt newReceipt = new receipt(this);
                        newReceipt.receipt = er;
                        integer scoreCount = 0;
                        decimal totalDecimal = 0;
                        if(amountMatch != null){
                            scoreCount++;
                            totalDecimal += amountMatch;
                        }
                        if(nameMatch != null){
                            scoreCount++;
                            totalDecimal += nameMatch;
                        }
                        if(projectMatch != null){
                            scoreCount++;
                            totalDecimal += projectMatch;
                        }
                        if(productMatch != null){
                            scoreCount++;
                            totalDecimal += productMatch;
                        }
                        if(referenceMatch != null){
                            scoreCount++;
                            totalDecimal += referenceMatch;
                        }
                        if(dateMatch != null){
                            scoreCount++;
                            totalDecimal += dateMatch;
                        }
                        if(scoreCount > 0 && totalDecimal > 0){
                            //don't add if we have no score.
                            //calculate the average percentage score.
                            decimal averageCalc = (totalDecimal/scoreCount)*100;
                            newReceipt.score = integer.valueOf(averageCalc);
                            nr.receipts.add(newReceipt);
                            
                        }
                    }
                    //after matching the reciepts, sort them by score.
                    nr.receipts.sort();
                    //we should also limit the list to 5
                    /*
                    for(integer i = 5; i < nr.receipts.size(); i++){
                        nr.receipts.remove(i);

                    }
                    */
                    while(nr.receipts.size() > 3){
                        nr.receipts.remove(3);
                    }
                    //should never be bigger than 5
                    system.assert(nr.receipts.size() <= 5, 'Receipts is greather than 5, actual: '+nr.receipts.size());
                    //should we show the receipts?
                    if(nr.receipts.isEmpty()){
                        nr.showMatchedReceipts = false;
                    }
                    

//TODO: Clip the list to 5/10 results.                    
                    for(Adjustment__c ea: debitAdjustments){
                        system.debug('Looping through debit adjustment: '+ea.Name);
                        //setup some lower case data from the existing adjustment.
                        string notesLower;
                        if(ea.Notes__c != null){
                            notesLower = ea.Notes__c.toLowerCase();
                        }
                        
                        //setup up some score markers
                        decimal amountMatch;
                        decimal dateMatch;
                        decimal notesMatch;
                        
                        //first we'll look at the amount, must be less or equal to the existing record
                        if(nr.xRow.xAmount <= MATH.abs(ea.Amount__c)){
                            //The amount is valid, now detirmine it's match score.
                            amountMatch = (nr.xRow.xAmount / MATH.abs(ea.Amount__c));
                            system.debug('Amount Match: '+MATH.abs(ea.Amount__c));
                        }
                        else{
                            //doesn't meet the criteria, no match so break from the loop.
                            continue;
                        }
                        //Match Transaction within a 10 day window.   
                        if(nr.xRow.xDate != null && ea.Date__c != null){
                            //we have date records to analyse
                            integer age = ea.Date__c.daysBetween(nr.xRow.xDate);
                            system.debug('Adjustment Age: '+age);
                            if(age >= 10){
                                //Transaction is too old, don't count it in list.
                                continue;
                            }
                            else{
                                dateMatch = (10-age)/10;
                                //make sure date match isn't more than 1!
                                if(dateMatch > 1){
                                    dateMatch = 1;
                                }
                            }
                        }
                        
                        //Notes/Description matching.
                        //this is the description from the transaction
                        string xDesc = nr.xRow.xDescription!=null?nr.xRow.xDescription.toLowerCase():null;
                        //create a set of invidual elements too.
                        set<string> xDescSet = new set<string>();
                        if(xDesc != null && notesLower != null){
                            xDescSet.addAll(xDesc.split(' '));
                        
                            //for each element of the description, try and match agains various notes data on the adjustment
                            //match against the adjustment notes.
                            //first try a direct match
                            if(notesLower == xDesc){
                                notesMatch = 1;
                            }
                            else{
                                //match in part
                                string[] notesList = notesLower.split(' ');
                                decimal notesTotal = notesList.size();
                                decimal notesScore =  0;
                                //firstly check all components against one another and build up a quality score.
                                for(String s: notesList){
                                    for(String t: xDescSet){
                                        decimal nScore = 0;
                                        if(s.contains(t) || t.contains(s)){
                                            //partial match score .5
                                            nScore = .5;
                                        }
                                        if(s == t){
                                            nScore = 1;
                                        }
                                        //update noteMatch
                                        notesScore +=nScore;
                                    }
                                }
                                if(notesScore < 0 && notesTotal > 0){
                                    notesMatch = (notesScore/notesTotal);
                                }
                            }
                            
                        }
                        //calculate the score and add the adjustment to the container.
                        adjustment newAdjustment = new adjustment(this);
                        newAdjustment.adjustment = ea;
                        integer scoreCount = 0;
                        decimal totalDecimal = 0;
                        if(amountMatch != null){
                            scoreCount++;
                            totalDecimal += amountMatch;
                        }
                        if(notesMatch != null){
                            scoreCount++;
                            totalDecimal += notesMatch;
                        }
                        if(dateMatch != null){
                            scoreCount++;
                            totalDecimal += dateMatch;
                        }
                        if(scoreCount > 0 && totalDecimal > 0){
                            //don't add if we have no score.
                            //calculate the average percentage score.
                            decimal averageCalc = (totalDecimal/scoreCount)*100;
                            system.debug('Match Score: '+averageCalc);
                            newAdjustment.score = integer.valueOf(averageCalc);
                            nr.adjustments.add(newAdjustment);
                            
                        }
                    
                    }
                    //sort the new adjustments
                    nr.adjustments.sort();
                    //we should also limit the list to 5
                    /*
                    for(integer i = 5; i < nr.adjustments.size(); i++){
                        nr.adjustments.remove(i);

                    }
                    */
                    while(nr.adjustments.size() > 3){
                        nr.adjustments.remove(3);
                    }
                    //only render if we have matched some adjutments
                    nr.showMatchedAdjustments = !nr.adjustments.isEmpty()?true:false;
                }
                
                //Now do the same matching for payments
                for(paymentContainer np: payments){
                    system.debug('Processing Payment: '+np.xRow.xDescription);
                    //for each payment, loop through the unreconciled payment transactions and see if there is any match.
                    for(Receipt__c ep: matchedPayments){
                        system.debug('Processing matched payment: '+ep.Name);
                        system.debug('Matched payment Amount: '+ep.Amount__c);
                        //setup some lower case data from the existing payment record.
                        //string companyLower;
                        string accLower;
                        string bsbLower;
                        string chequeLower;
                        
                        //Payment Reference on the Journal
                        string referenceLower;
                        /*
                        //Get the Solicitor Company Name from the Bank Account Associated to the Payment.
                        if(ep.Bank_Account__c != null && ep.Bank_Account__r.Account__c != null && ep.Bank_Account__r.Account__r.Name != null){
                            companyLower = p.Bank_Account__r.Account__r.Name.toLowerCase();
                        }
                        */
                        //get the account details associated to the payment
                        if(ep.Bank_Account__c != null && ep.Bank_Account__r.BSB_Number__c != null){
                            bsbLower = ep.Bank_Account__r.BSB_Number__c.toLowerCase();
                        }
                        if(ep.Bank_Account__c != null && ep.Bank_Account__r.Name != null){
                            accLower = ep.Bank_Account__r.Name.toLowerCase();
                        }
                        //try and get the cheque number from the cheque associated to the payment
                        if(ep.Journal__c != null && ep.Journal__r.Cheque_Number__c != null && ep.Journal__r.Cheque_Number__r.Cheque_Number__c != null){
                            chequeLower = string.valueOf(ep.Journal__r.Cheque_Number__r.Cheque_Number__c);
                        }
                        //Try and find the Payment Reference on the journal (this will typically be the Account and BSB unless overidden)
                        if(ep.Journal__c != null && ep.Journal__r.Payment_Reference__c != null){
                            referenceLower = ep.Journal__r.Payment_Reference__c;
                        }
                        
                        
                        //setup up some score markers
                        decimal amountMatch;
                        decimal dateMatch;                        
                        
                        //decimal companyMatch
                        decimal accMatch;
                        decimal bsbMatch;
                        decimal referenceMatch;
                        //cheque match
                        decimal chequeMatch;
                        
                        //first we'll look at the amount, must be greater or equal to the existing record.
                        system.debug('Perform Amount Match');
                        system.debug(MATH.abs(np.xRow.xAmount));
                        system.debug(ep.Amount__c);                        
                        if(MATH.abs(np.xRow.xAmount) >= ep.Amount__c){
                            //The amount is valid, now detirmine it's match score.
                            amountMatch = (ep.Amount__c/MATH.abs(np.xRow.xAmount));
                            system.debug('Amount Match OK: '+amountMatch);
                        }
                        else{
                            system.debug('Amount match failed.');
                            //doesn't meet the criteria, no match so break from the loop.
                            continue;
                        }
                        //match based on date
                        //Match Transaction within a 10 day window.   
                        if(np.xRow.xDate != null && ep.Date__c != null){
                            //we have date records to analyse
                            integer age = ep.Date__c.daysBetween(np.xRow.xDate);
                            system.debug('Performing age match. Age: '+age);
                            if(age >= 10){
                                //Transaction is too old, don't count it in list.
                                system.debug('Age Match Failed');
                                continue;
                            }
                            else{
                                dateMatch = (10-age)/10;
                                //make sure date match isn't more than 1!
                                if(dateMatch > 1){
                                    dateMatch = 1;
                                }
                                system.debug('Date Match Passed: '+dateMatch);
                            }
                        }
                        
                        //Dont match on payment type at the moment, focus on description field.
                        
                        //Description matching.
                        //this is the description from the transaction, will most likely contain acc number bsb and or cheque number
                        string xDesc = np.xRow.xDescription!=null?np.xRow.xDescription.toLowerCase():null;
                        //create a set of invidual elements too.
                        set<string> xDescSet = new set<string>();
                        if(xDesc != null){
                            xDescSet.addAll(xDesc.split(' '));
                        }
                        //for each element of the description, try and match agains various payment data.
                        
                        //match the bank account details
                        if(accLower != null){
                            if(xDesc.contains(accLower)){
                                //.6 for a partial reference match
                                accMatch = .6;
                            }
                            if(xDescSet.contains(accLower)){
                                //give 100% for a complete reference match
                                accMatch = 1;
                            }
                        }
                        if(bsbLower != null){
                            if(xDesc.contains(bsbLower)){
                                //.6 for a partial reference match
                                accMatch = .6;
                            }
                            if(xDescSet.contains(bsbLower)){
                                //give 100% for a complete reference match
                                bsbMatch = 1;
                            }
                        }
                        
                        //match against the customer reference
                        if(referenceLower != null){
                            if(xDesc.contains(referenceLower)){
                                //.6 for a partial reference match
                                referenceMatch = .6;
                            }
                            if(xDescSet.contains(referenceLower)){
                                //give 100% for a complete reference match
                                referenceMatch = .100;
                            }
                        }
                        //does the cheque number match
                        if(chequeLower != null && np.xRow.xChequeNumber != null){
                            if(chequeLower.contains(np.xRow.xChequeNumber) || np.xRow.xChequeNumber.contains(np.xRow.xChequeNumber)){
                                //we have some kind of partial match, could be trailing 0's, give a partial match
                                chequeMatch = .75;
                            }
                            if(chequeLower == np.xRow.xChequeNumber){
                                //we have an exact cheque match, give over 1, we will use this as an override and score the whole transaction as 100%
                                chequeMatch = 1.1;
                            }
                        }
                        
                        //calculate the score and add the payment to the container.
                        payment newPayment = new payment(this);
                        newPayment.payment = ep;
                        integer scoreCount = 0;
                        decimal totalDecimal = 0;
                        if(amountMatch != null){
                            scoreCount++;
                            totalDecimal += amountMatch;
                        }
                        if(dateMatch != null){
                            scoreCount++;
                            totalDecimal += dateMatch;
                        }
                        if(accMatch != null){
                            scoreCount++;
                            totalDecimal += accMatch;
                        }if(bsbMatch != null){
                            scoreCount++;
                            totalDecimal += bsbMatch;
                        }
                        if(referenceMatch != null){
                            scoreCount++;
                            totalDecimal += referenceMatch;
                        }
                        if(chequeMatch != null){
                            if(chequeMatch <= 1){
                                //process normally
                                scoreCount++;
                                totalDecimal += chequeMatch;
                            }
                            else{
                                //has been set to override, match whole record as 100%
                                scoreCount = 1;
                                totalDecimal = 1;
                            }
                        }
                        
                        if(scoreCount > 0 && totalDecimal > 0){
                            //don't add if we have no score.
                            //calculate the average percentage score.
                            decimal averageCalc = (totalDecimal/scoreCount)*100;
                            newPayment.score = integer.valueOf(averageCalc);
                            np.payments.add(newPayment);
                            
                        }
                    }
                    //after matching the reciepts, sort them by score.
                    np.payments.sort();
                    //we should also limit the list to 5
                    /*
                    for(integer i = 5; i < np.payments.size(); i++){
                        np.payments.remove(i);

                    }
                    */
                    while(np.payments.size() > 3){
                        np.payments.remove(3);
                    }
                    //Should we show the matched payments section
                    if(np.payments.isEmpty()){
                        np.showMatchedPayments = false;
                    }
//TODO: Clip the list to 5/10 results.                    
                    for(Adjustment__c ea: creditAdjustments){
                        //setup some lower case data from the existing adjustment.
                        string notesLower;
                        if(ea.Notes__c != null){
                            notesLower = ea.Notes__c.toLowerCase();
                        }
                        
                        //setup up some score markers
                        decimal amountMatch;
                        decimal dateMatch;
                        decimal notesMatch;
                        
                        //first we'll look at the amount, must be less or equal to the existing record
                        if(MATH.abs(np.xRow.xAmount) <= MATH.abs(ea.Amount__c)){
                            //The amount is valid, now detirmine it's match score.
                            amountMatch = (MATH.abs(np.xRow.xAmount) / MATH.abs(ea.Amount__c));
                        }
                        else{
                            //doesn't meet the criteria, no match so break from the loop.
                            continue;
                        }
                        //Match Transaction within a 10 day window.   
                        if(np.xRow.xDate != null && ea.Date__c != null){
                            //we have date records to analyse
                            integer age = ea.Date__c.daysBetween(np.xRow.xDate);
                            if(age >= 10){
                                //Transaction is too old, don't count it in list.
                                continue;
                            }
                            else{
                                dateMatch = (10-age)/10;
                                //make sure date match isn't more than 1!
                                if(dateMatch > 1){
                                    dateMatch = 1;
                                }
                            }
                        }
                        
                        //Notes/Description matching.
                        //this is the description from the transaction
                        string xDesc = np.xRow.xDescription!=null?np.xRow.xDescription.toLowerCase():null;
                        //create a set of invidual elements too.
                        set<string> xDescSet = new set<string>();
                        if(xDesc != null && notesLower != null){
                            xDescSet.addAll(xDesc.split(' '));
                        
                            //for each element of the description, try and match agains various notes data on the adjustment
                            //match against the adjustment notes.
                            //first try a direct match
                            //check the variables
                            if(notesLower == xDesc){
                                notesMatch = 1;
                            }
                            else{
                                //match in part
                                string[] notesList = notesLower.split(' ');
                                decimal notesTotal = notesList.size();
                                decimal notesScore =  0;
                                //firstly check all components against one another and build up a quality score.
                                for(String s: notesList){
                                    for(String t: xDescSet){
                                        decimal nScore = 0;
                                        if(s.contains(t) || t.contains(s)){
                                            //partial match score .5
                                            nScore = .5;
                                        }
                                        if(s == t){
                                            nScore = 1;
                                        }
                                        //update noteMatch
                                        notesScore +=nScore;
                                    }
                                }
                                if(notesScore < 0 && notesTotal > 0){
                                    notesMatch = (notesScore/notesTotal);
                                }
                            }
                            
                        }
                        //calculate the score and add the adjustment to the container.
                        adjustment newAdjustment = new adjustment(this);
                        newAdjustment.adjustment = ea;
                        integer scoreCount = 0;
                        decimal totalDecimal = 0;
                        if(amountMatch != null){
                            scoreCount++;
                            totalDecimal += amountMatch;
                        }
                        if(notesMatch != null){
                            scoreCount++;
                            totalDecimal += notesMatch;
                        }
                        if(dateMatch != null){
                            scoreCount++;
                            totalDecimal += dateMatch;
                        }
                        if(scoreCount > 0 && totalDecimal > 0){
                            //don't add if we have no score.
                            //calculate the average percentage score.
                            decimal averageCalc = (totalDecimal/scoreCount)*100;
                            newAdjustment.score = integer.valueOf(averageCalc);
                            np.adjustments.add(newAdjustment);
                            
                        }
                    
                    }
                    //sort the new adjustments
                    np.adjustments.sort();
                    //we should also limit the list to 5
                    /*
                    for(integer i = 5; i < np.adjustments.size(); i++){
                        np.adjustments.remove(i);

                    }
                    */
                    while(np.adjustments.size() > 3){
                        np.adjustments.remove(3);
                    }
                    //only render if we have matched some adjutments
                    np.showMatchedAdjustments = !np.adjustments.isEmpty()?true:false;
                }
                   refreshPayments();
                  // refreshReceipts();
                   refreshUnresolvedAdjustments();
                   //set the salesforce opening balance.
                   system.assert(trustAccount.Ledger_Balance__c != null);
                   //salesforceOpeningBalance = trustAccount.Ledger_Balance__c + totalUnresolvedAdjustments - totalUnpresentedPayments - totalUnpresentedReceipts;
            }
            else{
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'Invalid format for CSV, Please choose a valid .csv file.'));
                showStep4 = false;
            }
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'File Corrupt, please choose a valid .csv file.'));
            showStep4 = false;
        }
    }
    
    public String normalize(String source) {
        if (source != null) {
            return source.removeStart('"').removeEnd('"');
        }
        return source;
    }
    
    public void refreshTrustAccount(){
        if(trustAccountId != null){
            trustAccount = [select Id, Name, Ledger_Balance__c, Total_Adjustments__c, Total_Receipts__c, Total_Payments__c from Trust_Account__c where Id =: trustAccountId];
        }
        else{
            trustAccount = null;
        }
    }
    
    public void refreshAdjustments(){
        //this method is called once the Adjustments tab has been clicked.  render a list of any adjustments that are going to be created.
        //reset the adjustments list.
        adjustments = new adjustment[]{};
    
        //loop through rceipts and grab any selected new adjustments.
        for(receiptContainer r: receipts){
            if(r.newAdjustments[0].isSelected){
                //ensure the default status is set correctly.
                adjustment adj = r.newAdjustments[0];
                adj.adjustment.Status__c = 'Unassigned';
                adjustments.add(adj);
            }
            if(r.existingAdjustments[0].isSelected){
                //ensure the default status is set correctly.
                adjustment adj = new adjustment(this);
                adj.adjustment = r.existingAdjustments[0].adjustment.clone(false, true);
                adj.adjustment.Amount__c = MATH.abs(adj.adjustment.Amount__c);
                adj.adjustment.Type__c = 'Credit';
                adj.adjustment.Status__c = 'Assigned';
                adj.adjustment.Adjustment__c = r.existingAdjustments[0].adjustment.Id;
                adj.adjustment.Resolved_Date__c = date.today();
                adj.adjustment.Date__c = date.today();
                adj.adjustment.Notes__c = r.xRow.xDescription;
                adjustments.add(adj);
            }
            //also see if any of the matched adjustments are selected.
            for(adjustment a: r.adjustments){
                if(a.isSelected){
                    //assume the existing record is now resoved.
                    //a.adjustment.Status__c = 'Resolved';
                    //create a new adjustment, just clone the existing one.
                    adjustment newAdj = new adjustment(this);
                    //we are matching the existing adjustment, so create a new one to balance it out.
                    Adjustment__c newA = new Adjustment__c();
                    //set the type to credit as it is in place of a receipt.
                    newA.Type__c = 'Credit';
                    newA.Status__c = 'Assigned';
                    //set the related adjustment
                    newA.Adjustment__c = a.adjustment.Id;
                    newA.Notes__c = r.xRow.xDescription;
                    //set the resolved date
                    newA.Date__c = date.today();
                    newA.Resolved_Date__c = date.today();
                    //set the Amount
                    //As this is a receipt adjustment, will be a positive value
                    newA.Amount__c = MATH.abs(a.adjustment.Amount__c);
                    newAdj.adjustment = newA;
                    //now add the new adjustment container to the list.
                    adjustments.add(newAdj);
                }
            }
        }
        //loop through the payments and grab any selected new adjustments.
        for(paymentContainer p: payments){
            if(p.newAdjustments[0].isSelected){
                //ensure the default status is set correctly.
                adjustment adj = p.newAdjustments[0];
                adj.adjustment.Status__c = 'Unresolved';
                adjustments.add(adj);
            }
            if(p.existingAdjustments[0].isSelected){
                //ensure the default status is set correctly.
                adjustment adj = new adjustment(this);
                adj.adjustment = p.existingAdjustments[0].adjustment.clone(false, true);
                adj.adjustment.Amount__c = adj.adjustment.Amount__c*-1;
                adj.adjustment.Type__c = 'Fees';
                adj.adjustment.Status__c = 'Resolved';
                adj.adjustment.Adjustment__c = p.existingAdjustments[0].adjustment.Id;
                adj.adjustment.Resolved_Date__c = date.today();
                adj.adjustment.Date__c = date.today();
                adj.adjustment.Notes__c = p.xRow.xDescription;
                adjustments.add(adj);
            }
            
            //also see if any of the matched adjustments are selected.
            for(adjustment a: p.adjustments){
                if(a.isSelected){
                    //assume the existing record is now resoved.
                    //a.adjustment.Status__c = 'Assigned';
                    //create a new adjustment, just clone the existing one.
                    adjustment newAdj = new adjustment(this);
                    //we are matching the existing adjustment, so create a new one to balance it out.
                    Adjustment__c newA = new Adjustment__c();
                    //Set the status.
                    newA.Status__c = 'Resolved';
                    newA.Type__c = 'Fees';
                    //set the related adjustment
                    newA.Adjustment__c = a.adjustment.Id;
                    //set the resolved date
                    newA.Date__c = date.today();
                    newA.Resolved_Date__c = date.today();
                    //set the Amount
                    //As this is a payment adjustment, ensure is is a negative value.
                    newA.Amount__c = a.adjustment.Amount__c * -1;
                    newA.Notes__c = p.xRow.xDescription;
                    newAdj.adjustment = newA;
                    //now add the new adjustment container to the list.
                    adjustments.add(newAdj);
                }
            }
        }
        
    }
    
    public void refreshPayments(){
        //reset the list
        unpresentedPayments = new Receipt__c[]{};
        //query for current unpresented payments
        Map<Id, Receipt__c> paymentMap = new Map<Id, Receipt__c>([select Id, Project__c, Product__r.Name, Type__c, Date__c, Opportunity__c,Trust_Account__c,Trust_Account__r.Trust_Account_Bank_Balance_Date__c,Trust_Account__r.Bank_Statement_Balance__c, Opportunity__r.Name, Name, Description__c, Amount__c,Transaction_ID__c,Payment_Method__c, Journal__r.Payment_Reference__c from Receipt__c where Trust_Account__c =: trustAccountId and Reconciled__c = false and Type__c = 'Payment']);
        
        //loop through the payment map, remove any payments that have been reconciled in the current bank rec.
        for(Id i: paymentMap.keyset()){
            //loop through payments and see if we have reconciled any of the existing payments.
            for(paymentContainer p: payments){
                //Check to see if we have reconciled with a new payment
                boolean hasMatched = false;
                for(payment pa: p.newPayments){
                    if(pa.isSelected && pa.dummyAdjustment.Transaction__c == i){
                        //we have reconciled this against a new payment
                        paymentMap.remove(i);
                        hasMatched = true;
                        break;
                    }
                }
                if(hasMatched) break;
                //check to see if we have matched with an auto matched existing payment.
                hasMatched = false;
                for(payment pay: p.payments){
                    if(pay.isSelected && pay.payment.Id == i){
                        //we have selected an existing payment that matches
                        paymentMap.remove(i);
                        hasMatched = true;
                        break;
                    }
                }
                if(hasMatched) break;
            }
        }
        //once we have removed any matches from the payment map, add the remaining to a list that will be displayed on the page.
        unpresentedPayments.addAll(paymentMap.values());
        //update totals
        totalUnpresentedPayments = 0;
        for(Receipt__c p: unpresentedPayments){
            totalUnpresentedPayments += MATH.abs(p.Amount__c);
        }
        //Payments should be a negative figure
        //totalUnpresentedPayments = totalUnpresentedPayments*-1;
    }
    
    /* 
    public void refreshReceipts(){
        //reset the list
        unpresentedReceipts = new Receipt__c[]{};
        //query for current unpresented payments
        Map<Id, Receipt__c> receiptMap = new Map<Id, Receipt__c>([select Id, Type__c, Date__c, Opportunity__c, Opportunity__r.Name, Name, Description__c, Amount__c, Payment_Method__c, Journal__r.Payment_Reference__c from Receipt__c where Trust_Account__c =: trustAccountId and Reconciled__c = false and Type__c = 'Receipt']);
        
        //loop through the payment map, remove any payments that have been reconciled in the current bank rec.
        for(Id i: receiptMap.keyset()){
            //loop through payments and see if we have reconciled any of the existing payments.
            for(receiptContainer r: receipts){
                //Check to see if we have reconciled with a new payment
                if(r.newReceipts[0].isSelected && r.newReceipts[0].dummyAdjustment.Transaction__c == i){
                    //we have reconciled this against a new payment
                    receiptMap.remove(i);
                    break;
                }
                //check to see if we have matched with an auto matched existing payment.
                boolean hasMatched = false;
                for(receipt rec: r.receipts){
                    if(rec.isSelected && rec.receipt.Id == i){
                        //we have selected an existing payment that matches
                        receiptMap.remove(i);
                        hasMatched = true;
                        break;
                    }
                }
                if(hasMatched) break;
            }
        }
        //once we have removed any matches from the payment map, add the remaining to a list that will be displayed on the page.
        unpresentedReceipts.addAll(receiptMap.values());
        //update totals
        totalUnpresentedReceipts = 0;
        for(Receipt__c r: unpresentedReceipts){
            totalUnpresentedReceipts += MATH.abs(r.Amount__c);
        }
    }
    */
    public void refreshUnresolvedAdjustments(){
        //Reset the list of adjustments
        unresolvedAdjustments = new Adjustment__c[]{};
        //Query any unresolved adjustments
        Map<Id, Adjustment__c> adjustmentMap = new Map<Id, Adjustment__c>([select Id, Name, Type__c, Status__c, Amount__c, Notes__c, Date__c from Adjustment__c where Trust_Account__c =:trustAccountId and (Status__c = 'Unresolved' or Status__c = 'Unassigned')]);
        
        for(Id i: adjustmentMap.keyset()){
            //loop through receipts and see if we have resolved any of these adjustments.
            for(receiptContainer rc: receipts){
                boolean hasMatched = false;
                //check the matched adjustments first, have any of them been matched?
                for(adjustment a: rc.adjustments){
                    //check if the adjustment has been selected and if the id matched.
                    if(a.isSelected && a.adjustment.Id == i){
                        adjustmentMap.remove(i);
                        hasMatched = true;
                        break;
                    }
                }
                if(hasMatched) break;
                //then check to see if an adjustment has been manually matched?    
                //check the manually matched record.
                if(rc.existingAdjustments[0].isSelected && rc.existingAdjustments[0].exAdj.Id == i){
                    adjustmentMap.remove(i);
                    break;
                }
            }
            //now loop through payments.
            for(paymentContainer pc: payments){
                boolean hasMatched = false;
                //check the matched adjustments first, have any of them been matched?
                for(adjustment a: pc.adjustments){
                    //check if the adjustment has been selected and if the id matched.
                    if(a.isSelected && a.adjustment.Id == i){
                        adjustmentMap.remove(i);
                        hasMatched = true;
                        break;
                    }
                }
                if(hasMatched) break;
                //then check to see if an adjustment has been manually matched?    
                //check the manually matched record.
                if(pc.existingAdjustments[0].isSelected && pc.existingAdjustments[0].exAdj.Id == i){
                    adjustmentMap.remove(i);
                    break;
                }
            }
        }
        //add all the values from the map to the list
        unresolvedAdjustments.addAll(adjustmentMap.values());
        totalUnresolvedAdjustments = 0;
        //loop through unresolvedAdjustments and create the total
        for(Adjustment__c a: unresolvedAdjustments){
            totalUnresolvedAdjustments += a.Amount__c;
        }
        //we also need to add any adjustments created during this bank rec for the figure to be accurate.
        if(totalCreditAdjustments != null && totalFeeAdjustments != null){
            totalUnresolvedAdjustments += (totalCreditAdjustments - totalFeeAdjustments);
        }
    }
    
   private Set<Id> transactionIdSet;
   private boolean transactionReconciled(Id transactionId){
    //first make sure the list exists
    if(transactionIdSet == null){
        transactionIdSet = new Set<Id>();
    }
    if(transactionId != null && transactionIdSet.contains(transactionId)){ 
        return true;
        }
    else{
        transactionIdSet.add(transactionId);
        return false;
    }
    
   }
    
    private Set<Id> adjustmentIdSet;
    private boolean adjustmentReconciled(Id adjustmentId){
        //first make sure the list exists
        if(adjustmentIdSet == null){
            adjustmentIdSet = new Set<Id>();
        }
        if(adjustmentId != null && adjustmentIdSet.contains(adjustmentId)){ 
            return true;
        }
        else{
            adjustmentIdSet.add(adjustmentId);
            return false;
        }
    }
    
    public void validateTransactions(){
        //reset totals
        system.debug('start of validate transactions');
        totalReceiptsBank = 0;
        totalPaymentsBank = 0;
        totalReceiptsSFDC = 0;
        totalPaymentsSFDC = 0;
        totalFeeAdjustments = 0;
        totalCreditAdjustments = 0;
        //2 sets store a list of matched transactions ensuring they only get reconciled once.
        //loop through the receipts
        //for each selected receipt and adjustment, ensure the values stack up so the whole amount is reconciled.
            //if the whole amount is reconciled, update the reconciled box on the transaction
            //if there is an error for a transaction (not reconciled, or over reconciled) throw an inline error/validation
        for(receiptContainer rc: receipts){
            //what is the transaction amount?
            decimal xAmount = MATH.abs(rc.xRow.xAmount);
            //add totalReceiptsBank
            totalReceiptsBank +=xAmount;
            decimal reconciledTotal = 0;
            Map<String,String> receiptids = new Map<String,String>();
            //loop through matched receipts first.
            for(receipt r: rc.receipts){
                if(r.isSelected){
                    reconciledTotal += MATH.abs(r.receipt.Amount__c);
                    //add to totalReceiptsSFDC
                    totalReceiptsSFDC += MATH.abs(r.receipt.Amount__c);
                    receiptids.put(r.receipt.Id,r.receipt.Name);
                }
            }
            //check the existing receipts
            for(receipt rcr: rc.NewReceipts){
                if(rcr.isSelected && rcr.receipt.Amount__c != null){
                    reconciledTotal += MATH.abs(rcr.receipt.Amount__c);
                    //add to totalReceiptsSFDC
                    totalReceiptsSFDC += MATH.abs(rcr.receipt.Amount__c);
                    receiptids.put(rcr.receipt.Id,rcr.receipt.Name);
                }
            }
            //check matched adjustments.
            for(adjustment a: rc.adjustments){
                if(a.isSelected){
                    reconciledTotal += MATH.abs(a.adjustment.Amount__c);
                    //add to totalCreditAdjustments
                    totalCreditAdjustments += MATH.abs(a.adjustment.Amount__c);
                }
            }
            //check a manually matched adjustment
            if(rc.existingAdjustments[0].isSelected && rc.existingAdjustments[0].adjustment.Amount__c != null){
                reconciledTotal += MATH.abs(rc.existingAdjustments[0].adjustment.Amount__c);
                totalCreditAdjustments += MATH.abs(rc.existingAdjustments[0].adjustment.Amount__c);
            }
            //check a newly created adjustments
            if(rc.newAdjustments[0].isSelected && rc.newAdjustments[0].adjustment.Amount__c != null){
                reconciledTotal += MATH.abs(rc.newAdjustments[0].adjustment.Amount__c);
                 totalCreditAdjustments += MATH.abs(rc.newAdjustments[0].adjustment.Amount__c);
            }
            
            //if the reconciled amount is greater than the transaction amount, we have a problem.
            if(reconciledTotal > xAmount){
                rc.isError = true;
                rc.errorMessage = 'The amount reconciled is greater than the transaction amount for the following receipts:';
                rc.errorType = 'ERROR';
                rc.isReconciled = false;
                /*if (rc.style.contains('display:none;'))
                    rc.style = rc.style.remove('display:none;');*/
                
            }
            else if(reconciledTotal == xAmount){
                rc.isReconciled = true;
                rc.isError = true;
                rc.errorType = 'CONFIRM';
                rc.errorMessage = 'Transaction reconciled! for the following receipts:';
                /*if (!rc.style.contains('display:none;'))
                    rc.style += 'display:none;';*/
            }
            else if(reconciledTotal < xAmount){
                //the full amount hasn't been reconciled.
                rc.isError = true;
                rc.errorType = 'WARNING';
                rc.isReconciled = false;
                rc.errorMessage = 'The full transaction amount is yet to be reconciled for the following receipts:';
                /*if (rc.style.contains('display:none;'))
                    rc.style = rc.style.remove('display:none;');*/
            }
            //rc.errorMessage=receiptids+rc.errorMessage;
            if(receiptids.size()>0)
            {
                for(String r:receiptids.keyset())
                {
                    rc.errorMessage+='<a href="/'+r+'">'+receiptids.get(r)+'</a>';
                    if(receiptids.keyset().size()>1)
                    rc.errorMessage+=',';
                    
                }
                if(receiptids.keyset().size()>1){
                    rc.errorMessage=rc.errorMessage.substring(0,rc.errorMessage.length()-1);
                    rc.errorMessage+='.';
                }   
            }
        }
        
                
        //loop through the payments
        //for each selected payment and adjustment, ensure the values stack up so the whole amount is reconciled.
            //if the whole amount is reconciled, update the reconciled box on the transaction
            //if there is an error for a transaction (not reconciled, or over reconciled) throw an inline error/validation   
        for(paymentContainer pc: payments){
            //what is the transaction amount?
            decimal xAmount = MATH.abs(pc.xRow.xAmount);
            //add to totalPaymentsBank
            totalPaymentsBank += xAmount;
            decimal reconciledTotal = 0;
            //loop through matched payments.
            for(payment p: pc.payments){
                if(p.isSelected){
                    reconciledTotal += MATH.abs(p.payment.Amount__c);
                    //add to totalPaymentsSFDC
                    totalPaymentsSFDC += MATH.abs(p.payment.Amount__c);
                }
            }
            //check the existing payment
            for(payment pcp: pc.newPayments){
                if(pcp.isSelected && pcp.payment.Amount__c != null){
                    reconciledTotal += MATH.abs(pcp.payment.Amount__c);
                    //add to totalPaymentsSFDC
                    totalPaymentsSFDC += MATH.abs(pcp.payment.Amount__c);
                }
            }
            //check matched adjustments.
            for(adjustment a: pc.adjustments){
                if(a.isSelected){
                    reconciledTotal += MATH.abs(a.adjustment.Amount__c);
                    //add to totalFeeAdjustments
                    totalFeeAdjustments += MATH.abs(a.adjustment.Amount__c);
                }
            }
            //check a manually matched adjustment
            if(pc.existingAdjustments[0].isSelected && pc.existingAdjustments[0].adjustment.Amount__c != null){
                reconciledTotal += MATH.abs(pc.existingAdjustments[0].adjustment.Amount__c);
                //add to total Fee adjustments
                totalFeeAdjustments += MATH.abs(pc.existingAdjustments[0].adjustment.Amount__c);
            }
            //check a newly created adjustments
            if(pc.newAdjustments[0].isSelected && pc.newAdjustments[0].adjustment.Amount__c != null){
                reconciledTotal += MATH.abs(pc.newAdjustments[0].adjustment.Amount__c);
                totalFeeAdjustments += MATH.abs(pc.newAdjustments[0].adjustment.Amount__c);
            }
            
            //if the reconciled amount is greater than the transaction amount, we have a problem.
            if(reconciledTotal > xAmount){
                pc.isError = true;
                pc.errorMessage = 'The amount reconciled is greater than the transaction amount.';
                pc.errorType = 'ERROR';
                pc.isReconciled = false;
            }
            else if(reconciledTotal == xAmount){
                pc.isReconciled = true;
                pc.isError = true;
                pc.errorType = 'CONFIRM';
                pc.errorMessage = 'Transaction reconciled!';
            }
            else if(reconciledTotal < xAmount){
                //the full amount hasn't been reconciled.
                pc.isError = true;
                pc.errorType = 'WARNING';
                pc.isReconciled = false;
                pc.errorMessage = 'The full transaction amount is yet to be reconciled. ';
            }
            
        }
        
        //Validate the Adjustments and Unpresented Payments
        refreshUnresolvedAdjustments();
        refreshPayments();
        //refreshReceipts();
        //ensure all the totals are the correct neg/pos value.
        
//        totalReceiptsBank
        //totalPaymentsBank = totalPaymentsBank*-1;
//        totalReceiptsSFDC
        //totalPaymentsSFDC = totalPaymentsSFDC*-1;
        //totalFeeAdjustments = totalFeeAdjustments*-1;
//        totalCreditAdjustments = 0;
        //salesforceClosingBalance = salesforceOpeningBalance + totalReceiptsSFDC + totalPaymentsSFDC + (totalCreditAdjustments + totalFeeAdjustments);
        
        closingCashbookBalance = trustAccount.Ledger_Balance__c + totalReceiptsSFDC;
        reconciledBankBalance = closingBalance - totalUnpresentedPayments - totalUnresolvedAdjustments;
        varianceBalance = reconciledBankBalance - closingCashbookBalance;
        
        //potentially ensure that the payments/receipts themselves aren't over reconciled??
        
        //Update the closing date and balance to the trust account 
        //trustAccount.Bank_Statement_Balance__c  = closingCashbookBalance;
        //trustAccount.Trust_Account_Bank_Balance_Date__c = Date.parse(closingDate);

        //update trustAccount;
        
        //Check with Col, can you reconcile a bank transaction of a > value than a recipet/payment?
        system.debug('end of validateTransactions');
    }
    
    
        /* DEV ONLY DO NOT DEPLPOY */
    public void loadTestData(){
        //load the csv
        csvFile = [select Id, Name, Body, ContentType from Document where Id = '015N00000002pSB'];
        //set the trust account
        trustAccountId = 'a0bN0000002Hg4M';
        //process the csv
        processCSV();
    }
   /*  END DEV ONLY*/
    
    
    public void processTransactions(){
        //create lists for the different types of records we are going to be inserting
        Receipt__c[] recTransactions = new Receipt__c[]{};
        Adjustment__c[] recAdjustments = new Adjustment__c[]{};
        Map<Id,Trust_Account__c> TrustAccountmaptobeupserted= new Map<Id,Trust_Account__c>();
        List<Trust_Account__c> TrustAccountlisttobeupserted= new List<Trust_Account__c>();
        system.debug('Transactions Commited Here');
        
        //Process Receipts.
        for(receiptContainer rc: receipts){
            //first check any matched receipts.
            for(receipt r: rc.receipts){
                if(r.isSelected){
                    //mark the receipt as reconciled, add to the list.
                    r.receipt.Reconciled__c = true;
                    //r.receipt.Date_Reconciled__c = date.today();
                    r.receipt.Date_Reconciled__c = rc.xRow.xDateNew;
                    recTransactions.add(r.receipt);                    
                }
                trustAccount.Bank_Statement_Balance__c  = closingBalance;
                trustAccount.Trust_Account_Bank_Balance_Date__c = Date.parse(closingDate);
                /*if(rc.xRow.xCodeDesc=='CLOSING BALANCE')
                {
                    r.receipt.Trust_Account__r.Trust_Account_Bank_Balance_Date__c = rc.xRow.xDatenew;
                    r.receipt.Trust_Account__r.Bank_Statement_Balance__c = rc.xRow.xAmount;
                }*/
            }
            //then check the manually matched receipts.
            for(receipt rcr: rc.newReceipts){
                if(rcr.isSelected){
                    if(rcr.dummyAdjustment.Transaction__c != null){
                        //if the dummy adjustment has the transaction populated, that means we matched an existing receipt.
                        //first assign to a variable.
                        Receipt__c manualReceipt = rcr.receipt;
                        //mark as reconciled
                        manualReceipt.Reconciled__c = true;
                        //manualReceipt.Date_Reconciled__c = date.today();
                        manualReceipt.Date_Reconciled__c = rc.xRow.xDateNew;
                        recTransactions.add(manualReceipt);
                    }
                    else if(rcr.dummyAdjustment.Opportunity__c != null){
                        //an opportunity has been provided to link the transaction to, so update the pre-existing receipt.
                        Receipt__c updateReceipt =rcr.receipt;
                        updateReceipt.Reconciled__c = true;
                        //updateReceipt.Date_Reconciled__c = date.today();
                        updateReceipt.Date_Reconciled__c = rc.xRow.xDateNew;
                        updateReceipt.Trust_Account__c = trustAccountId;
                        updateReceipt.Opportunity__c = rcr.dummyAdjustment.Opportunity__c;
                        recTransactions.add(updateReceipt); 
                    }
                    /*if(rc.xRow.xCodeDesc=='"CLOSING BALANCE"')
                            {
                                rcr.receipt.Trust_Account__r.Trust_Account_Bank_Balance_Date__c = rc.xRow.xDatenew;
                                rcr.receipt.Trust_Account__r.Bank_Statement_Balance__c = rc.xRow.xAmount; 
                            }*/
                    trustAccount.Bank_Statement_Balance__c  = closingBalance;
                    trustAccount.Trust_Account_Bank_Balance_Date__c = Date.parse(closingDate);
                        
                }
            }
           // for(Trust_Account__c tc:TrustAccountsettobeupserted)
         //   {
          //    TrustAccountlisttobeupserted.add(tc);
          //  }
          // TrustAccountlisttobeupserted.addall(TrustAccountmaptobeupserted.values());
            //now check any matched adjustments
            for(adjustment ma: rc.adjustments){
                if(ma.isSelected){
                    //mark as assigned.
                    ma.adjustment.Status__c = 'Resolved';
                    ma.adjustment.Resolved_Date__c = date.today();
                    //add the notes from the bank statement for reference
                    ma.adjustment.Notes__c = rc.xRow.xDescription;
                    //add the adjustment to the list for update
                    recAdjustments.add(ma.adjustment);
                    //create a new adjustment to balance the resolved one.
                    Adjustment__c balanceAdjustment = ma.adjustment.clone(false, true);
                    //change some of the details.
                    balanceAdjustment.Amount__c = MATH.abs(balanceAdjustment.Amount__c);
                    balanceAdjustment.Trust_Account__c = trustAccountId;
                    balanceAdjustment.Status__c = 'Assigned';
                    balanceAdjustment.Adjustment__c = ma.adjustment.Id;
                    balanceAdjustment.Type__c = 'Credit';
                    recAdjustments.add(balanceAdjustment);
                }
            }
            //now check the manually matched adjustmemt.
            if(rc.existingAdjustments[0].isSelected){
                //the adjustment is selected.
                Adjustment__c selectedAdjustment = rc.existingAdjustments[0].adjustment;
                //update some of the adjustment information
                selectedAdjustment.Resolved_Date__c = date.today();
                selectedAdjustment.Status__c = 'Resolved';
                //update the notes as well
                selectedAdjustment.Notes__c = rc.xRow.xDescription;
                //add to the list
                recAdjustments.add(selectedAdjustment);
                //create a new adjustment to balance the resolved one.
                Adjustment__c balanceAdjustment = selectedAdjustment.clone(false, true);
                //change some of the details.
                balanceAdjustment.Amount__c = MATH.abs(balanceAdjustment.Amount__c);
                balanceAdjustment.Trust_Account__c = trustAccountId;
                balanceAdjustment.Status__c = 'Assigned';
                balanceAdjustment.Adjustment__c = selectedAdjustment.Id;
                balanceAdjustment.Type__c = 'Credit';
                recAdjustments.add(balanceAdjustment);
            }
            //now see if we have manually created any adjustments.
            if(rc.newAdjustments[0].isSelected){
                //the new adjustment has been selected. update some details. (it will already have some input from the page
                Adjustment__c newAdjustment = rc.newAdjustments[0].adjustment;
                newAdjustment.Trust_Account__c = trustAccountId;
                newAdjustment.Status__c = 'Unassigned';
                //add to the list for insert.
                recAdjustments.add(newAdjustment);
            }
            

        }
        //Process Payments
        for(paymentContainer pc: payments){
            //first check any matched payments.
            for(payment p: pc.payments){
                if(p.isSelected){
                    //mark the payment as reconciled, add to the list.
                    p.payment.Reconciled__c = true;
                    //p.payment.Date_Reconciled__c = date.today();
                    p.payment.Date_Reconciled__c = pc.xRow.xDateNew;
                    recTransactions.add(p.payment);
                }
            }
            //then check the manually matched payments.
            for(payment pcp: pc.newPayments){
                if(pcp.isSelected){
                    if(pcp.dummyAdjustment.Transaction__c != null){
                        //if the dummy adjustment has the transaction populated, that means we matched an existing payment.
                        //first assign to a variable.
                        Receipt__c manualPayment = pcp.payment;
                        //mark as reconciled
                        manualPayment.Reconciled__c = true;
                        //manualPayment.Date_Reconciled__c = date.today();
                        manualPayment.Date_Reconciled__c = pc.xRow.xDateNew;
                        recTransactions.add(manualPayment);
                    }
                    else if(pcp.dummyAdjustment.Opportunity__c != null){
                        //an opportunity has been provided to link the transaction to, so update the pre-existing payment.
                        Receipt__c updatePayment = pcp.payment;
                        updatePayment.Reconciled__c = true;
                        //updatePayment.Date_Reconciled__c = date.today();
                        updatePayment.Date_Reconciled__c = pc.xRow.xDateNew;
                        updatePayment.Trust_Account__c = trustAccountId;
                        updatePayment.Opportunity__c = pcp.dummyAdjustment.Opportunity__c;
                        recTransactions.add(updatePayment);                 
                    }
                }            
            }
            //now check any matched adjustments
            for(adjustment ma: pc.adjustments){
                if(ma.isSelected){
                    //mark as assigned.
                    ma.adjustment.Status__c = 'Assigned';
                    ma.adjustment.Resolved_Date__c = date.today();
                    //add the notes from the bank statement for reference
                    ma.adjustment.Notes__c = pc.xRow.xDescription;
                    //add the adjustment to the list for update
                    recAdjustments.add(ma.adjustment);
                    //create a new adjustment to balance the resolved one.
                    Adjustment__c balanceAdjustment = ma.adjustment.clone(false, true);
                    //change some of the details.
                    balanceAdjustment.Amount__c = balanceAdjustment.Amount__c*-1;
                    balanceAdjustment.Trust_Account__c = trustAccountId;
                    balanceAdjustment.Status__c = 'Resolved';
                    balanceAdjustment.Adjustment__c = ma.adjustment.Id;
                    balanceAdjustment.Type__c = 'Fee';
                    recAdjustments.add(balanceAdjustment);
                }
            }
            //now check the manually matched adjustmemt.
            if(pc.existingAdjustments[0].isSelected){
                //the adjustment is selected.
                Adjustment__c selectedAdjustment = pc.existingAdjustments[0].adjustment;
                //update some of the adjustment information
                selectedAdjustment.Resolved_Date__c = date.today();
                selectedAdjustment.Status__c = 'Assigned';
                //update the notes as well
                selectedAdjustment.Notes__c = pc.xRow.xDescription;
                //add to the list
                recAdjustments.add(selectedAdjustment);
                //create a new adjustment to balance the resolved one.
                Adjustment__c balanceAdjustment = selectedAdjustment.clone(false, true);
                //change some of the details.
                balanceAdjustment.Amount__c = balanceAdjustment.Amount__c*-1;
                balanceAdjustment.Trust_Account__c = trustAccountId;
                balanceAdjustment.Status__c = 'Resolved';
                balanceAdjustment.Adjustment__c = selectedAdjustment.Id;
                balanceAdjustment.Type__c = 'Fee';
                recAdjustments.add(balanceAdjustment);
            }
            //now see if we have manually created any adjustments.
            if(pc.newAdjustments[0].isSelected){
                //the new adjustment has been selected. update some details. (it will already have some input from the page
                Adjustment__c newAdjustment = pc.newAdjustments[0].adjustment;
                //Ensure the amount is a negative value.
                newAdjustment.Amount__c = newAdjustment.Amount__c *-1;
                newAdjustment.Trust_Account__c = trustAccountId;
                newAdjustment.Status__c = 'Unresolved';
                //add to the list for insert.
                recAdjustments.add(newAdjustment);
            }

        }
        //upsert the lists
        
        //before updating the list, double check that we haven't got any duplicate transaction or adjustments.
        //Reset the sets used for duplicate checking.
        adjustmentIdSet = null;
        transactionIdSet = null;
        string adjustmentError = '';
        string transactionError = '';
        system.debug('Processing: '+recTransactions.size()+' transactions');
        for(Adjustment__c a: recAdjustments){
            if(adjustmentReconciled(a.Id)){
                //we have already seen this adjustment, so flag an error
                adjustmentError += '<a href="/'+a.id+'">'+a.Name+'</a>';
            }
        }
        boolean isGreaterThanone = false;
        for(Receipt__c r: recTransactions){
            if(transactionReconciled(r.Id)){
                //we have already seen this transaction
                if(isGreaterThanone){
                    transactionError += '\'';
                }
                isGreaterThanone = true;
                transactionError +='<a href="/'+r.id+'">'+r.Name+'</a>';
            }
            
        }
        if(adjustmentError != '' || transactionError != ''){
            //we have some errors, so don't commit the records.
            if(adjustmentError != ''){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'There were Adjustments reconciled to more than 1 transaction:'+adjustmentError.removeEnd(',')+' Please resolve'));
            }
            if(transactionError != ''){
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,'There were Payments/Receipts reconciled to more than 1 transaction:'+transactionError.removeEnd(',')+' Please resolve'));
            }
        }
        else{
            //everything looks ok, so lets update the records.
            
            upsert recAdjustments;
            upsert recTransactions;
            update trustAccount;
            //message to page saying we've been successful
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.CONFIRM,'Trust Account Reconciliation Successful.'));
            resetPage();    
        }
        
    }
    
    public void resetPage(){
        showCsvStatus = false;
        dummyReceipt = new Receipt__c(Date__c = date.today());
        csvFile = new Document();
        refreshTrustAccount();
        showStep4 = false;
        receipts = new receiptContainer[]{};
        payments = new paymentContainer[]{};
        adjustments = new adjustment[]{};
    }
}