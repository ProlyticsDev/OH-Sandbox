public with sharing class manageItemsExtension {

    public Opportunity opp{get; set;}
    public boolean showForm{get; set;}
    //Product Selection List - will only ever have <= 1 record
    public Item__c[] productSelectionList{get; set;}
    //Previous Property Selections
    public Item__c[] previousList{get; set;}
    public Item__C[] previousListNew;
    public integer listSize{get; set;}
    //used to hold the product types available.
    public selectOption[] typeOptions{get; set;}
    //used to hold the products available
    public selectOption[] productOptions{get; set;}
    //used to hold the various project stages.
    public selectOption[] stageOptions{get; set;}
    public string productType{get; set;}
    public Id productId{get; set;}
    public Product__c selectedProduct{get; set;}
    public String projectStage{get; set;}
    Map<String, Id> recordTypeMap;
    Map<String, Id> oppRecordTypeMap;
    public integer upgradeSize{get; set;}
    public integer optionSize{get; set;}
    public boolean showNewReceipts{get; set;}
    //Reservation Summary
    public decimal additionsTotal{get; set;}
    //boolean to track whether we show the reservation section at all
    public boolean showResiDetails{get; set;}
    public decimal receiptTotal{get; set;}
    public decimal receiptTotalBuild{get; set;}
    //used within the page session to detirmine if the user has transferred.  If they have, selectedProduct cannot equal null.
    public boolean hasTransferred;
    //id of the product the customer has transferred from.
    public id transferredFrom;
    //product id, product name, map used to construct item errors
    private Map<Id, String> itemMap;
    public string dbStage{get; set;}

    //fields to track various contract type values
    //Land Only
    public string landDiscount{
        get{
            return string.valueOf(opp.Discount__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Discount__c = decimal.valueOf(value);
            }
            else{
                opp.Discount__c = null;
            }
        }
    }
    public string landDeposit{
        get{
            return string.valueOf(opp.Full_Deposit_Required__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Full_Deposit_Required__c = decimal.valueOf(value);
            }
            else{
                opp.Full_Deposit_Required__c = null;
            }
        }
    }
    public string landRebate{
        get{
            return string.valueOf(opp.Rebate_Manual__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Rebate_Manual__c = decimal.valueOf(value);
            }
            else{
                opp.Rebate_Manual__c = null;
            }
        }
    }

    //Apartment
    public string aptDiscount{
        get{
            return string.valueOf(opp.Discount__c);
        }
         set{
             if(value != null && value.trim() != ''){
                 opp.Discount__c = decimal.valueOf(value);
             }
             else{
                 opp.Discount__c = null;
             }
         }
    }
    public string aptDeposit{
        get{
            return string.valueOf(opp.Full_Deposit_Required__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Full_Deposit_Required__c = decimal.valueOf(value);
            }
            else{
                opp.Full_Deposit_Required__c = null;
            }
        }
    }
    public string aptRebate{
        get{
            return string.valueOf(opp.Rebate_Manual__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Rebate_Manual__c = decimal.valueOf(value);
            }
            else{
                opp.Rebate_Manual__c = null;
            }
        }
    }

    //Split contract
    public string splitLandDiscount{
        get{
            return string.valueOf(opp.Discount__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Discount__c = decimal.valueOf(value);
            }
            else{
                opp.Discount__c = null;
            }
        }
    }
    public string splitLandDeposit{
        get{
            return string.valueOf(opp.Full_Deposit_Required__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Full_Deposit_Required__c = decimal.valueOf(value);
            }
            else{
                opp.Full_Deposit_Required__c = null;
            }
        }
    }
    public string splitLandRebate{
        get{
            return string.valueOf(opp.Rebate_Manual__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Rebate_Manual__c = decimal.valueOf(value);
            }
            else{
                opp.Rebate_Manual__c = null;
            }
        }
    }
    public string splitBuildDiscount{
        get{
            return string.valueOf(opp.Discount_Build__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Discount_Build__c = decimal.valueOf(value);
            }
            else{
                opp.Discount_Build__c = null;
            }
        }
    }
    public string splitBuildDeposit{
        get{
            return string.valueOf(opp.Full_Deposit_Required_Build__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Full_Deposit_Required_Build__c = decimal.valueOf(value);
            }
            else{
                opp.Full_Deposit_Required_Build__c = null;
            }
        }
    }
    public string splitBuildRebate{
        get{
            return string.valueOf(opp.Rebate_Manual_Build__c);
        }
        set{
            if(value != null && value.trim() != ''){
                opp.Rebate_Manual_Build__c = decimal.valueOf(value);
            }
            else{
                opp.Rebate_Manual_Build__c = null;
            }
        }
    }

    //Receipt Lists
    Public Receipt__c[] receipts{get; set;}

    //Receipt class for new receipts
    public class receipt{
        public boolean showReceipt{get; set;}
        public Receipt__c receipt{get; set;}
        public manageItemsExtension mex;
        //variable to track the required status of the type field as this is no longer bound to a sObject field.
        public boolean typeError{get; set;}

        //Hardcoded by Prolytics as per OH's request.
        public selectOption[] getReceiptTypes(){
            selectOption[] receiptOptions = new selectOption[]{};
            receiptOptions.add(new SelectOption('', '-- None --'));
            receiptOptions.add(new SelectOption('Initial Deposit','Initial Deposit'));
            receiptOptions.add(new SelectOption('Further Deposit','Further Deposit'));
            receiptOptions.add(new SelectOption('Full Deposit','Full Deposit'));
            receiptOptions.add(new SelectOption('Balance of Deposit','Balance of Deposit'));
            receiptOptions.add(new SelectOption('Option Fee','Option Fee'));
            receiptOptions.add(new SelectOption('Initial Deposit - Build','Initial Deposit - Build'));
            receiptOptions.add(new SelectOption('Further Deposit - Build', 'Further Deposit - Build'));
            receiptOptions.add(new SelectOption('Balance of Deposit - Build', 'Balance of Deposit - Build'));
            receiptOptions.add(new SelectOption('Full Deposit - Build', 'Full Deposit - Build'));

            return receiptOptions;

        }

        public receipt(Receipt__c receipt, manageItemsExtension mex){
            this.receipt = receipt;
            showReceipt = true;
            //provide a reference to the external controller
            this.mex = mex;
            typeError = false;
        }

        public void recordReceipt(){
            if(this.receipt.Description__c != null && this.receipt.Description__c != ''){
                //set the custom type error field.
                typeError = false;
                //method to transfer the receipt to the new list.
                mex.receipts.add(this.receipt);
                if(mex.newReceiptsActual.size() == 1){
                    //assume we are about to remove this 1, so don't show the list.
                    mex.showNewReceipts = false;
                }
                //as it's now added to the new list, don't show in current list
                this.showReceipt = false;
                //recalculate the receipt total
                mex.calcReceiptTotal();
            }
            else{
                //a type hasn't been specified, so just set the error to true and do nothing else.
                this.typeError = true;
            }
        }

        public void cancel(){
            //remove the receipt from the list

            //received a cancellation for this, check if the list size is 1, if so then we won't render the new receipts area
            if(mex.newReceiptsActual.size() == 1){
                //assume we are about to remove this 1, so don't show the list.
                mex.showNewReceipts = false;
            }

            this.showReceipt = false;
        }

    }
    //source list
    Public receipt[] newReceipts{get; set;}
    //actual list
    public receipt[] newReceiptsActual{
        get{
            //loop through new receipts and only return those that shoeReceipt = true
            receipt[] receiptsToAdd = new receipt[]{};
            if(newReceipts != null){
                for(receipt r: newReceipts){
                    if(r.showReceipt){
                        receiptsToAdd.add(r);
                    }
                }
            }
            return receiptsToAdd;
        }
        set{
            newReceipts = value;
        }
    }

    public void addNewReceipt(){
        //if newReceipts is null, create it
        if(newReceipts == null){
            newReceipts = new receipt[]{};
            //make the new receipts area visible
        }
        //add a new row
        Receipt__c newReceipt = new Receipt__c(RecordTypeId = ohHelper.recordTypes.get('Receipt'), Opportunity__c = opp.Id, Product__c = selectedProduct.Id, /*Type__c = 'Receipt',*/ Trust_Account__c = opp.Project__r.Trust_Account__c);
        newReceipts.add(new receipt(newReceipt, this));
        //make sure we are showing the list.
        showNewReceipts = true;
    }

    public void calcReceiptTotal(){
        receiptTotal = 0;
        receiptTotalBuild = 0;
        for(receipt__c r: receipts){
            if(productSelectionList[0].Product__r.Contract_Type__c == 'Split Contract'){
                if(r.Description__c.toLowerCase().contains('build')){
                    receiptTotalBuild += r.Amount__c;
                }
                else{
                    receiptTotal += r.Amount__c;
                }
            }
            else{
                receiptTotal += r.Amount__c;
            }
        }

    }

    public void addVariation(){
        addVac('Variation');
    }
    public void addCondition(){
        addVac('Condition');
    }
    public void addVac(String type){
        vac newVac = new vac(new Variation_Condition__c(Opportunity__c = opp.Id, Type__c = type));
        newVac.isEditable = true;
        //also set vacNew as we are jumping straight into editable mode
        newVac.vacNew = new Variation_Condition__c(Opportunity__c = opp.Id, Type__c = type);
        vacList.add(newVac);
    }


    public vac[] vacListFiltered{
        //only disaplys vac record that isDeleted = false;
        get{
            vac[] filteredVac = new vac[]{};
            for(vac v: vacList){
                //add if isDeleted = false
                if(!v.isDeleted){
                    filteredVac.add(v);
                }
            }
            return filteredVac;
        }
        set{
            vacList = value;
        }
    }

    //class and list to manage variations
    public vac[] vacList{get; set;}
    public class vac{
        public Variation_Condition__c vac{get; set;}
        //used to track changes during edit
        public Variation_Condition__c vacNew{get; set;}
        public boolean isDeleted{get; set;}
        public boolean isEditable{get; set;}
        //error properties
        public boolean nameError{get; set;}
        public boolean typeError{get; set;}
        public boolean conditionTypeError{get; set;}
        public boolean initialExpiryError{get; set;}
        public boolean priceError{get; set;}
        public boolean dateError{get; set;}
        public boolean statusError{get; set;}
        public boolean descriptionError{get; set;}

        public vac(Variation_Condition__c vac){
            //set some default values
            this.isEditable = false;
            this.isDeleted = false;
            this.vac = vac;

        }

        public void deleteVac(){
            //simply set isDeleted = true;
            this.isDeleted = true;
        }

        public void saveVac(){
            //check some validation
            //start off assuming the record is valid
            boolean isValid = true;
            if(this.vacNew.Name == null){
                this.nameError = true;
                isValid = false;
            }
            if(this.vacNew.Price__c == null && this.vacNew.Type__c == 'Variation'){
                //only perform this check if it is a variation
                this.priceError = true;
                isValid = false;
            }
            if(this.vacNew.Condition_Type__c == null && this.vacNew.Type__c == 'Condition'){
                //only perform this check if it is a variation
                this.conditionTypeError = true;
                isValid = false;
            }
            if(this.vacNew.Initial_Expiry_Date__c == null && this.vacNew.Type__c == 'Condition'){
                //only perform this check if it is a variation
                this.initialExpiryError = true;
                isValid = false;
            }
            if(this.vacNew.Condition_Due_Date__c == null && this.vacNew.Type__c == 'Condition'){
                //only perform this check if it is a condition.
                this.dateError = true;
                isValid = false;
            }
            if(this.vacNew.Status__c == null || this.vacNew.Status__c.trim() == ''){
                this.statusError = true;
                isValid = false;
            }
            if(this.vacNew.Description__c == null || this.vacNew.Description__c.trim() == ''){
                this.descriptionError = true;
                isValid = false;
            }
            if(isValid){
                //no problems with the fields, so process as per normal
                //set isEditable to false
                this.isEditable = false;
                //transfer vacNew to vac
                this.vac.Name = this.vacNew.Name;
                this.vac.Type__c = this.vacNew.Type__c;
                this.vac.Price__c = this.vacNew.Price__c;
                this.vac.Condition_Due_Date__c = this.vacNew.Condition_Due_Date__c;
                this.vac.Status__c = this.vacNew.Status__c;
                this.vac.Description__c = this.vacNew.Description__c;
            }
            else{
                //not valid, nothing to do.
            }

        }
        public void editVac(){
            //set isEditable to true
            this.isEditable = true;
            //transfer the current vac to vacOld, just pass through the values
            this.vacNew = new Variation_Condition__c(Name = this.vac.Name, Type__c = this.vac.Type__c, Price__c = this.vac.Price__c, Condition_Due_Date__c = this.vac.Condition_Due_Date__c, Status__c = this.vac.Status__c, Description__c = this.vac.Description__c, Opportunity__c = this.vac.Opportunity__c);
        }
        public void cancelVac(){
            //set isEditable to false
            this.isEditable = false;
            //reset vacNew
            this.vacNew = null;
            //check to see if the vac record has an id, if not then mark isDeleted
            if(this.vac.Id == null && this.vac.Name == null && this.vac.Price__c == null && this.vac.Condition_Due_Date__c == null && this.vac.Status__c == null && this.vac.Description__c == null){
                //the changed were canceled, and there was nothing in the original vac to mark as deleted
                this.isDeleted = true;
            }
        }
    }

    //list and class to display upgrades
    public upgrade[] upgradeList{get; set;}
    public class upgrade{
        public Product__c product{get; set;}
        public boolean isSelected{get; set;}
        public decimal price{get; set;}
        public string type;

        public upgrade(){
            this.type = 'Upgrade';
            this.isSelected = false;
        }

    }

    //list and class to display options
    public option[] optionList{get; set;}
    public class option{
        public string optionName{get; set;}
        public decimal price{get; set;}
        public Id productId{get; set;}
        public selectOption[] productOptions{get; set;}
        public manageItemsExtension mex;
        public string selectedValue{get; set;}
        public string type;


        public void findPrice(){
            //method is called by the change in product option and updates the price accordingly.
            if(productId != null){
                system.debug(this.productId);
                Price__c newPrice = [select Price__c, Product__r.Name from Price__c where Product__c =: this.productId and Primary_Product__c =: mex.selectedProduct.Id order by CreatedDate DESC limit 1];
                this.price = newPrice.Price__c;
                this.selectedValue = newPrice.Product__r.Name;
                system.debug(this.price);
            }
            else{
                //set the price to 0
                this.price = 0;
            }
        }
        //constructor
        public option(manageItemsExtension mex){
            this.mex = mex;
            this.type = 'Option';
        }
    }

    public manageItemsExtension(ApexPages.StandardController controller) {
        opp = (Opportunity)controller.getRecord();


        //load product record types
        //get record types from products and load into a map.
        recordTypeMap = new Map<String, Id>();
        oppRecordTypeMap = new Map<String, Id>();
        for(RecordType r: [select id, sObjectType, DeveloperName from RecordType where sObjectType = 'Product__c' or sObjectType = 'Opportunity']){
            if(r.sObjectType == 'Product__c'){
                recordTypeMap.put(r.DeveloperName, r.Id);
            }
            else if(r.sObjectType == 'Opportunity'){
                oppRecordTypeMap.put(r.DeveloperName, r.Id);
            }
        }

        //set some default values
        showForm = true;
        productSelectionList = new Item__c[]{};
        upgradeSize = 0;
        optionSize = 0;
        showNewReceipts = false;
        showResiDetails = false;
        hasTransferred = false;

        //do some checks to make sure we should render the form, and some other things
        if(opp.Id == null || opp.Project__c == null){
            showForm = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'An Opportunity related to a Project needs to be created before you can Manage Products.'));
        }
        else{

            //let continue
            //update dbStage, used to track the current status of the opportunity, regardless of what happens on the page.
            dbStage = opp.StageName;
            //check the reservation status, show the reservation area by default if there is a reservation date on the opp.
            if(opp.Reservation_Date__c != null){
                    showResiDetails = true;
            }
            //and opportunity exists, so now try and load some default records.
            //get the items
            generateItems();
            //get variations and conditions
            generateVac();
            //get receipts
            generateReceipts();

        }
    }


    public void generateReceipts(){
        //create the receipts list
        receipts = new Receipt__c[]{};
        //loop through pre existing receipts and add to list
        for(Receipt__c r: [Select Description__c, Received_From__c, Receipted_By__c, Name, Payment_Method__c, Date__c, Amount__c, Reconciled__c, Trust_A_C_Receipt__c, Customer_Ref__c, Trust_Account__c, X3rd_Party_Transaction__c From Receipt__c where Opportunity__c =: opp.Id]){
            //just check here and make sure the receipt has a trust account, if not assign the project trust account.
            if(r.Trust_Account__c == null) r.Trust_Account__c = opp.Project__r.Trust_Account__c;
            receipts.add(r);
        }
        //recalc the receipt total
        calcReceiptTotal();
    }

    public void generateVac(){
        //create a blank list
        vacList = new vac[]{};
        for(Variation_Condition__c v: [select Id, Name, Type__c, Condition_Due_Date__c, Opportunity__c, Description__c, Price__c, Status__c, Initial_Expiry_Date__c, Condition_Type__c, Extension_Days__c from Variation_Condition__c where Opportunity__c =: opp.Id]){
            vacList.add(new vac(v));
        }
    }

    public void generateItems(){
        //this method is called once at page load, and creates lists for the product selection, upgrades & options.

        //new list for previous property selections
        previousList = new Item__c[]{};
        previousListNew = new Item__c[]{};

        for(Item__c i: [select Id, Product__r.RecordTypeId, Product__r.RecordType.Name, Status__c, Product__r.Project__r.Name, Product__r.Type__c, Product__r.Name, Product__r.Bdr__c, Product__r.Bth__c, Product__r.Car_Parks__c, Product__r.Land_Price__c, Product__r.Build_Price__c, Product__r.List_Price__c, Product__r.Contract_Type__c, Product__r.Size__c, Product__r.Depth__c, Reservation_Date__c, LastModifiedDate, Price__c, Selection_Status__c, Product__r.Stage__c, Product__r.Frontage__c from Item__c where Opportunity__c =: opp.Id]){
            //process items here
            if(i.Product__r.RecordTypeId == recordTypeMap.get('Apartment') || i.Product__r.RecordTypeId == recordTypeMap.get('Land') || i.Product__r.RecordTypeId == recordTypeMap.get('Urban_Village') || i.Product__r.RecordTypeId == recordTypeMap.get('Townhouse')){
                //these are primary product types, add all cancelled ones to previous property selection list
                if(i.Status__c == 'Cancelled' || i.Status__c == 'Considered' || i.Status__c == 'Transferred'){
                    //add to the cancelled list
                    previousList.add(i);
                }
                else{
                    //add active ones to the product selection list
                    if(productSelectionList.size() < 1){
                        //there are no records in here yet, so add one.
                        productSelectionList.add(i);
                        //update the selectedProduct
                        selectedProduct = new Product__c(Id = i.Product__c, Contract_Type__c = i.Product__r.Contract_Type__c);
                    }
                }
            }
        }
        //set the list size to decide which table to load in the product selection section
        listSize = productSelectionList.size();
        //if the list is empty, generate the product and type lists
        if(listSize < 1){
            generateProducts();
            //also add a blank item to the list
            productSelectionList.add(new Item__c(Opportunity__c = opp.Id));
        }
        //check that there is a selected product with an id, and load pricing
        if(selectedProduct != null && selectedProduct.Id != null){
            loadPricing();
        }
    }

    public void validateProducts(){
        /*
        boolean vsaOverride = false;
        boolean vaOverride = false;
        opp.Salesperson_pa__r.VSA_Override__c
        //first check there are VSA\'s
        if(opp.Salesperson_pa__r.VSA_Override__c && opp.Project__r.VA_Override__c){
            //for this person both
        }
        */
    }

    public Id[] getAuthProductIds(){

        //returns a list of products that are authorised under this projects VA(s)
        Id[] authProductIds = new Id[]{};
        //if there is a va override, then pass through all products
        if(opp.Project__r.VA_Override__c){
            for(Product__c p: [select Id from Product__c where Project__c =: opp.Project__c]){
                authProductIds.add(p.Id);
            }
        }
        else{
            //No override, so build the list of available proudcts manually.
            //Query returns active va and vsa's for salesperson //if we have got this far there should be at least 1 of each.
            Vendor_Sales_Authority__c[] vsaList = [select Id, Vendor_Authority__c, (select Id, Product_Assignment__c, Product_Assignment__r.Active__c, Product_Assignment__r.Product__c from Vendor_Sales_Product_Assignments__r where Active__c = true) from Vendor_Sales_Authority__c where Account__c =: opp.Salesperson_pa__c];
            Set<Id> vaIds = new Set<Id>();
            if(!vsaList.isEmpty()){
                //we have some vendor sales authority's this is a good sign.
                boolean seeAll = false;
                //if we have at least one vsa with no vspa's then the user can see all products.
                for(Vendor_Sales_Authority__c vsa: vsaList){
                    vaIds.add(vsa.Vendor_Authority__c);
                    //check to see if there are any vspa's
                    if(vsa.Vendor_Sales_Product_Assignments__r.isEmpty()){
                        //is empty, this vsa give the user the ability to see everything.
                        seeAll = true;
                        break;
                    }
                }
                if(seeAll){
                    //user can see everything, set authProducts based on product assignments related to the vendor authority directly.
        //TODO
                    for(Product_Assignment__c pa: [select Id, Product__c from Product_Assignment__c where Vendor_Authority__c in: vaIds and Active__c = true and Product__c != null]){
                        authProductIds.add(pa.Product__c);
                    }
                }
                else{
                    //there was at least 1 vspa specified, loop through all the vspa's available and create a list of related product Ids.
                    for(Vendor_Sales_Authority__c vsa: vsaList){
                        for(Vendor_Sales_Product_Assignment__c vspa: vsa.Vendor_Sales_Product_Assignments__r){
                            if(vspa.Product_Assignment__c != null && vspa.Product_Assignment__r.Active__c && vspa.Product_Assignment__r.Product__c != null){
                                //we have a product Id add it to the list
                                authProductIds.add(vspa.Product_Assignment__r.Product__c);
                            }
                        }
                    }
                }
            }
            //otherwise it'll just be empty
        }
        return authProductIds;
    }

    public void generateProducts(){

        Id[] authProductIds = getAuthProductIds();
        //Generates the list of products and types, run if there are no products in the productSelectionList
        typeOptions = new selectOption[]{};
        productOptions = new selectOption[]{};
        stageOptions = new selectOption[]{};
        Set<String> typeSet = new Set<String>();
        Set<String> productSet = new Set<String>();
        Set<String> stageSet = new Set<String>();
        if(opp != null && opp.project__c != null){
            typeOptions.add(new selectOption('', '--Please Select--'));
            productOptions.add(new selectOption('', '--Please Select--'));
            stageOptions.add(new selectOption('', '--Please Select--'));
            //we have a project id, so loop through the products and create type and product picklists
            for(Product__c p: [select id, Name, Type__c, Stage__c, Name_Of_Stage__c, Stage_Number__c, External_Status__c 
                               from Product__c 
                               where Project__c =: opp.Project__c 
                               AND Internal_Status__c != 'Not for Sale'
                               and (RecordTypeId =: recordTypeMap.get('Apartment') 
                               OR RecordTypeId =: recordTypeMap.get('Land') 
                               OR RecordTypeId =: recordTypeMap.get('Urban_Village') 
                               OR RecordTypeId =: recordTypeMap.get('Townhouse')) 
                               AND Name != null 
                               and Qty_Balance__c > 0 
                               and Id in: authProductIds order by Name, Stage_Number__c, Name_Of_Stage__c]){
                //create the select options here
                if(!typeSet.contains(p.Type__c)){
                    typeOptions.add(new selectOption(p.Type__c, p.Type__c));
                    typeSet.add(p.Type__c);
                }
                if(!productSet.contains(p.Id)){
                    //by default don't add the display products to the list.
                    if(p.External_Status__c != 'Available as Display'){
                        productOptions.add(new selectOption(p.Id, p.Name));
                        productSet.add(p.Id);
                    }
                }
                if(!stageSet.contains(p.Stage__c) && p.Stage__c != null){
                    stageSet.add(p.Stage__c);
                    stageOptions.add(new selectOption(p.Stage__c, p.Stage__c));
                }
                //check for builder related opp and if product is display
                if(opp.Account.Type == 'Builder'  && !typeSet.contains('Available as Display') && p.External_Status__c == 'Available as Display'){
                    //aad doesn't exist in type set, so add it
                    typeSet.add('Available as Display');
                    typeOptions.add(new selectOption('Available as Display', 'Available as Display'));
                }
            }
            //if there are no types or no products, change --please select-- to --None--
            if(typeOptions.size() == 1){
                //there are no types, to change to --None--
                typeOptions[0].setLabel('--None--');
            }
            if(stageOptions.size() == 1){
                stageOptions[0].setLabel('--None--');
            }
            //sort the stage options
            stageOptions.sort();
            //select a default product type if there is one
            if(opp.Property_Type__c != null){
                //see if the product type matches a type in the typeset
                if(typeSet.contains(opp.Property_Type__c)){
                    //there is a match so set the type dropdown.
                    productType = opp.Property_Type__c;
                    //filter the products again
                    typeFilter();
                }
                //make an exception for the Land Only product type
                else if(opp.Property_Type__c == 'Land Only'){
                    productType = 'Land';
                    //filter the products again.
                    typeFilter();
                }
            }
        }
        else{
            //there is no project, so we can't load the select list details.

            //create a default option for each list that states a project should be selected
            typeOptions.add(new selectOption('', '--Select a Project--'));
            productOptions.add(new selectOption('', '--Select a Project--'));
        }
    }


    //method runs to filter down the number of products available by type.
    public void typeFilter(){
        //returns a list of authorised products
        Id[] authProductIds = getAuthProductIds();
        //recreates the product list based on the type selected.
        productOptions = new selectOption[]{};
        productOptions.add(new selectOption('', '--Please Select--'));
        /*
        if(productType != null && productType != ''){
            for(Product__c p: [select id, Name, Type__c from Product__c where Project__c =: opp.Project__c and Type__c =: this.productType and Type__c != null and Qty_Balance__c > 0 order by Name]){
                productOptions.add(new selectOption(p.Id, p.Name));
            }
        }
        else{
            //default query
            for(Product__c p: [select id, Name, Type__c from Product__c where Project__c =: opp.Project__c and (Type__c = 'Apartment' OR Type__c = 'Land' OR Type__c = 'House & Land' OR Type__c = 'Urban Village') and Qty_Balance__c > 0 order by Name]){
                productOptions.add(new selectOption(p.Id, p.Name));
            }
        }
        */
        //construct dynamic query
        string productQuery = 'select id, Name, Type__c from Product__c where Project__c = \''+opp.Project__c+'\' AND Internal_Status__c != \'Not for Sale\'';
        if(productType != null && productType != ''){
            if(productType != 'Available as Display'){
                productQuery += ' and Type__c = \''+this.productType+'\' and Type__c != null and External_Status__c != \'Available as Display\'';
            }
            else{
                //the type is available as display so get all products where external status is AaD
                productQuery  += ' and External_Status__c = \'Available as Display\'';
            }
        }
        else{
            //default product query section
            productQuery += ' and (RecordTypeId = \''+recordTypeMap.get('Apartment')+'\' OR RecordTypeId = \''+recordTypeMap.get('Land')+'\' OR RecordTypeId = \''+recordTypeMap.get('Urban_Village')+'\' OR RecordTypeId = \''+recordTypeMap.get('Townhouse')+'\') and External_Status__c != \'Available as Display\'';
        }
        if(projectStage != null & projectStage != ''){
            productQuery += ' and Stage__c = \''+projectStage+'\'';
        }
        //finish off query
        productQuery += ' and Qty_Balance__c > 0 and Id in: authProductIds order by Name';

        //run 1 query loop.
        for(Product__c p: database.query(productQuery)){
                productOptions.add(new selectOption(p.Id, p.Name));
            }

    }

    public void selectProduct(){
        //based on the chosen product id, configure the item accorgingly
        if(productId != null){
            selectedProduct = [select id, Name, List_Price__c, Rebate_Product__c, Type__c, RecordType.Name, RecordType.DeveloperName, RecordTypeId, Project__r.Name, Bdr__c, Bth__c, Car_Parks__c, Land_Price__c, Build_Price__c, Contract_Type__c, Size__c, Depth__c, Transferred_From__c, Frontage__c from Product__c where id =: productId];
            //set the item price
            productSelectionList[0].Price__c = selectedProduct.List_Price__c;
            //set the item status, should be the same as the opportunity status
            productSelectionList[0].Product__c = selectedProduct.Id;
            productSelectionList[0].Status__c = opp.StageName;
            productSelectionList[0].Product_Record_Type__c = selectedProduct.RecordType.Name;
            //reset the productSelectionList[0] value
            productSelectionList[0].Product__r = [select RecordTypeId, Project__r.Name, RecordType.Name, RecordType.DeveloperName, Type__c, Name, Bdr__c, Bth__c, Car_Parks__c, Land_Price__c, Build_Price__c, List_Price__c, Contract_Type__c, Size__c, Depth__c, Transferred_From__c, Frontage__c from Product__c where Id =: selectedProduct.Id];

            //set the primary product on the opportunity
            opp.Primary_Product__c = selectedProduct.Id;
        }
        else{
            selectedProduct = null;
            productSelectionList[0] = new Item__c(Opportunity__c = opp.Id);
        }


        //if there is a product id, try and load the options upgrades available.
        if(selectedProduct != null && selectedProduct.Id != null){
            loadPricing();
            //if this is a transfer, reservation is mandatory.
            if(hasTransferred){
                showResiDetails = true;
                //also set the stage back to reservation/reservation pending
                if(opp.RecordTypeId == oppRecordTypeMap.get('New_Communities')){
                    opp.StageName = 'Reservation';
                }
                else if(opp.RecordTypeId == oppRecordTypeMap.get('Apartments') || opp.RecordTypeId == oppRecordTypeMap.get('Apartments_Vendor')){
                    opp.StageName = 'Reservation Pending';
                }
                else{
                    opp.StageName = 'Reservation';
                }
                //set the item status
                productSelectionList[0].Status__c = opp.StageName;
                //update the transferred from , if available.
                if(transferredFrom != null){
                    selectedProduct.Transferred_From__c = transferredFrom;
                    if(productSelectionList[0].Product__r != null){
                       productSelectionList[0].Product__r.Transferred_From__c = transferredFrom;
                    }
                }

            }
        }
    }


    public void removeRecord(){

        //this is pre reservation, so reset the opportunity fields accordingly
        opp.Purchaser__c = null;
        opp.Reservation_Date__c = null;
        opp.Contract_Signing_Appointment_Date__c = null;
        opp.Appointment_Start_Time__c = null;
        opp.Appointment_End_Time__c = null;
        opp.Full_Deposit_Required_Build__c = null;
        opp.Full_Deposit_Required__c = null;
        opp.Primary_Product__c = null;
        //if the stage is reservation/reservation pending then set back to appt.
        if(opp.StageName == 'Reservation' || opp.StageName == 'Reservation Pending'){
            opp.StageName = 'Appointment';
        }
        //reset selectedProduct
        selectedProduct = null;
        productSelectionList[0].Selection_Status__c = 'Considered';
        productSelectionList[0].Status__c = 'Cancelled';
        //add the Item record to the previous selection list
        previousList.add(productSelectionList[0]);
        previousListNew.add(productSelectionList[0]);
        //reset the item in the product selection list
        productSelectionList.clear();
        productSelectionList.add(new Item__c(Opportunity__c = opp.Id));
        //generate the products and types
        generateProducts();
        //reset the list size.
        listSize = 0;
        //remove any upgrade/option items
        upgradeList = null;
        optionList = null;
        upgradeSize = 0;
        optionSize = 0;
        //reset vacList as well
        for(vac v: vacList){
            v.isDeleted = true;
        }
        //don't show reservation section
        showResiDetails = false;

    }

    public void transferRecord(){
        //set hasTransferred
        hasTransferred = true;
        transferredFrom = productSelectionList[0].Product__c;
        //reset selectedProduct
        selectedProduct = null;
        productSelectionList[0].Selection_Status__c = 'Transferred';
        productSelectionList[0].Status__c = 'Cancelled';
        //set product internal override to pending transfer
        productSelectionList[0].Product__r.Internal_Status_Override__c = 'Pending Transfer';
        //HR - 19/04/2016 - Fix for Case: 00001371
        productSelectionList[0].Product__r.Opportunity_ID__c = null;
        productSelectionList[0].Product__r.Opportunity_Name__c = null;
        //add the Item record to the previous selection list
        previousList.add(productSelectionList[0]);
        previousListNew.add(productSelectionList[0]);
        //reset the item in the product selection list
        productSelectionList.clear();
        productSelectionList.add(new Item__c(Opportunity__c = opp.Id));
        //generate the products and types
        generateProducts();
        //reset the list size.
        listSize = 0;
        //remove any upgrade/option items
        upgradeList = null;
        optionList = null;
        upgradeSize = 0;
        optionSize = 0;
        //change opportunity stage to appt.
        opp.StageName = 'Appointment';
        //remove the primary product
        opp.Primary_Product__c = null;
        //reset opportunity fields
        opp.Full_Deposit_Required__c = null;
        opp.Full_Deposit_Required_Build__c = null;
        opp.Reservation_Date__c = null;
        opp.Contract_Signing_Appointment_Date__c = null;
        opp.Appointment_Start_Time__c = null;
        opp.Appointment_End_Time__c = null;
        opp.Discount__c = null;
        opp.Discount_Build__c = null;
        //reset vacList as well
        for(vac v: vacList){
            v.isDeleted = true;
        }
        //don't show reservation section
        showResiDetails = false;
    }

    public pageReference exit(){

        return new pageReference('/'+opp.Id);
    }

    public void loadPricing(){
        //this method loads pricing for any related options/upgrades associated to the main product.  this only runs if the main product exists/has been selected.

        //new list for upgrades
        upgradeList = new upgrade[]{};
        optionList = new option[]{};
        //map to track options and related products
        Map<String, Product__c[]> optionMap = new Map<String, Product__c[]>();
        //map used to track product and names, used for error handling
        itemMap = new Map<Id, String>();
        for(Product__c p: [select Id, Name, RecordTypeId, Type__c, (Select Id from Items__r where Opportunity__c =: opp.Id and Primary_Product__c =:selectedProduct.Id), (select Id, Price__c from PricingOne__r where Primary_Product__c =: selectedProduct.Id) from Product__c where Project__c =: opp.Project__c and (RecordTypeId =: recordTypeMap.get('Option') or RecordTypeId =: recordTypeMap.get('Upgrade')) and Qty_Balance__c > 0 order by Name]){
            //returns a list of all upgrades/options for the project, also returns associated pricing for the selected product and item records for the opportunity
            //update item map, only used for error handling
            itemMap.put(p.Id, p.Name);
            if(p.RecordTypeId == recordTypeMap.get('Upgrade')){
                //is an upgrade product
                //first check there is pricing
                if(!p.PricingOne__r.isEmpty()){
                    //there is pricing, so add the upgrade
                    upgrade newUpgrade = new upgrade();
                    newUpgrade.product = p;
                    newUpgrade.price = p.PricingOne__r[0].Price__c;
                    if(!p.Items__r.isEmpty()){
                        //there are items for this product/opportunity
                        newUpgrade.isSelected = true;
                    }
                    upgradeList.add(newUpgrade);

                }
            }
            else if(p.RecordTypeId == recordTypeMap.get('Option')){
                //is an option product
                //this is an option item, so add to the option list

                if(!p.PricingOne__r.isEmpty()){
                    //has pricing, count this product
                    //check to see if the option exists in the map
                    if(optionMap.get(p.Type__c) == null){
                        //doesn't exist, so add it
                        optionMap.put(p.Type__c, new Product__c[]{});
                    }
                    //at this point the option will exsit in the map so add the product
                    optionMap.get(p.Type__c).add(p);
                }
            }
        }
        //finish off the optionList
        for(String s: optionMap.keySet()){
            //loop through the map, create an option for each type and sublist of selections
            //create a new option object
            option newOption = new option(this);
            newOption.optionName = s;
            //loop through the products and create the select list
            newOption.productOptions = new selectOption[]{};
            //add a default option
            newOption.productOptions.add(new selectOption('', '--None--'));
            for(Product__c p: optionMap.get(s)){
                newOption.productOptions.add(new selectOption(p.Id, p.Name));
                //check to see if the option is already selected
                if(!p.Items__r.isEmpty()){
                    //set the product for the option
                    newOption.productId = p.Id;
                    //set the price for the option
                    newOption.price = p.PricingOne__r[0].Price__c;
                    //set the selectedValue of the option
                    newOption.selectedValue = p.Name;
                }
            }
            optionList.add(newOption);
        }
        //set the option size value
        optionSize = optionList.size();
        //set the upgrade size value
        upgradeSize = upgradeList.size();
    }

    //class for additions
    public class addition{
        public decimal addPrice{get; set;}
        public string addName{get; set;}
        //constructor
        public addition(decimal addPrice, string addName){
            this.addPrice = addPrice;
            this.addName = addName;
        }

    }

    //property used to combine a list of options, upgrades & variations
    public addition[] combinedAdditions{
        get{
            addition[] additionList = new addition[]{};
            //reset additionsTotal;
            additionsTotal = 0;
            //loop through vac records and variations and add to a list of additions
            for(vac v: vacList){
                //if it is a variation and isn't marked as deleted add to the list
                if(!v.isDeleted && v.vac.Type__c == 'Variation' && !v.isEditable){
                    additionList.add(new addition(v.vac.Price__c, v.vac.Name));
                    additionsTotal += v.vac.Price__c;
                }
            }
            //also loop through the options and upgrades
            if(upgradeList != null){
                for(upgrade u: upgradeList){
                    if(u.isSelected){
                        //if the upgrade is selected, then add it to the list
                        additionList.add(new addition(u.price, u.product.Name));
                        additionsTotal += u.price;
                    }
                }
            }
            if(optionList != null){
                for(option o: optionList){
                    if(o.ProductId != null){
                        //add if a product is selected
                        additionList.add(new addition(o.price, o.optionName+' '+o.selectedValue));
                        additionsTotal += o.price;
                    }
                }
            }
            return additionList;
        }
        private set;

    }

    public void makeReservation(){
        //get the updated salutation in case the user has just updated it 
        Account updatedAccount = [SELECT Salutation FROM Account WHERE Id = :opp.AccountId limit 1]; 

        //jh - fix throw an error if the salutation isnt on the related account 
        if(String.isNotBlank(updatedAccount.Salutation)) {
            //show the reservation areas if there is a selected product
            if(selectedProduct != null && selectedProduct.Id != null){
                showResiDetails = true;
                //update the reservation status
                if(opp.RecordTypeId == oppRecordTypeMap.get('New_Communities_Reservation') || opp.RecordTypeId == oppRecordTypeMap.get('New_Communities')){
                    opp.StageName = 'Reservation';
                    productSelectionList[0].Status__c = 'Reservation';
                }
                else if(opp.RecordTypeId == oppRecordTypeMap.get('Apartments') || opp.RecordTypeId == oppRecordTypeMap.get('Apartments_Vendor') || opp.RecordTypeId == oppRecordTypeMap.get('Apartments_Reservation')){
                    opp.StageName = 'Reservation Pending';
                    productSelectionList[0].Status__c = 'Reservation Pending';
                }
                else{
                    opp.StageName = 'Reservation';
                    productSelectionList[0].Status__c = 'Reservation';
                }
            }
            else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must choose a product before you can make a reservation.'));
            }
        }
        else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The salutation of the person related to the opportunity must be populated before making a reservation. <a target="_blank" href=/' + opp.AccountId + '>View Person</a>'));
        }
    }

    //save method
    public pageReference saveSelections(){

        // Create a savepoint, we will return here if any of the dml attempts fail
        Savepoint sp = Database.setSavepoint();

        //update opportunity - moved to sort out field history
        try{
            update opp;
        }
        catch(dmlException d){
            //loop through exceptions and generate page messages for each.
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'opp :'+e.getMessage()));
            Database.rollback(sp);
            return null;
        }

        //before updating the opportunity check that if a reservation exists the deposit required fields are filled in
        if(showResiDetails){
            //resi details are showing so make sure the relevant deposit fields are filled in.
            if((productSelectionList[0].Product__r.Type__c == 'Apartment' || productSelectionList[0].Product__r.Type__c == 'Land') && productSelectionList[0].Product__r.Contract_Type__c != 'Split Contract'){
                if(opp.Full_Deposit_Required__c == null){
                    //add an error to the page
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Full Deposit Required is a required field.'));
                    return null;
                }
            }
            else if(productSelectionList[0].Product__r.Contract_Type__c == 'Split Contract'){
                if(opp.Full_Deposit_Required__c == null || opp.Full_Deposit_Required_Build__c == null){
                    //add an error to the page
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Full Deposit Required - Build is a required field.'));
                    return null;
                }
            }
        }
        //also do a check to make sure the product hasn't been tranferred.
        if(hasTransferred && selectedProduct == null){
            //the product has been transferred and a new one hasn't been selected!
            //add an error message to the page and return null
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'You must select a product to transfer to.'));
            return null;
        }


        //upsert items (make sure product record type is set)
        //check to see if the primary item has a related product, if it doesn't then clear the list.
        if(productSelectionList[0].Product__r == null){
            productSelectionList.clear();
        }
        for(Item__c i: productSelectionList){
            i.Product_Record_Type__c = i.Product__r.RecordType.Name;
            //make sure the item reservation reflects the opportunity if set
            if(opp.Reservation_Date__c != null){
                i.Reservation_Date__c = opp.Reservation_Date__c;
            }
        }
        //create a new list of items to manage updates.
        Item__c[] itemUpdates = new Item__c[]{};
        //add items in product selection list
        itemUpdates.addAll(productSelectionList);
        //and previousSelectionlist to product selection list
        itemUpdates.addAll(previousListNew);

        //update the options and upgrades
        Item__c[] newExtras = new Item__c[]{};
        set<Id> existingExtras = new set<Id>();
        //compile a list of option and upgrade ids that we can use to detirmine which items should exist.  if we can't find and item product id in the list, add it to the oldExtras list
        if(optionList != null){
            for(option o: optionList){
                if(o.productId != null){
                    existingExtras.add(o.productId);
                }
            }
        }
        if(upgradeList != null){
            for(upgrade u: upgradeList){
                if(u.isSelected){
                    existingExtras.add(u.product.Id);
                }
            }
        }
        //check for old upgrades and options
        Item__c[] oldExtras = new Item__c[]{};
        Map<Id, Item__c> existingMap = new Map<Id, Item__c>();
        for(Item__c i: [select id, Product__c, Product__r.Name from Item__c where Opportunity__c =: opp.Id and (Product__r.RecordTypeId =: recordTypeMap.get('Option') or Product__r.RecordTypeId =: recordTypeMap.get('Upgrade'))]){
            //does the Product__c reference the selected product, or there isn't an extra for the item
            if(selectedProduct == null || (selectedProduct != null && selectedProduct.Id != null && !existingExtras.contains(i.Product__c))){
                //there is no selected product
                oldExtras.add(i);
            }
            else{
                //there is a selected product and the ids match for the selected product
                existingMap.put(i.Product__c, i);
            }
        }

        //process new options and upgrades.
        if(optionList != null){
            for(option o: optionList){
                if(o.productId != null){
                    //there is an option selected, does an item for this exist already?
                    Item__c newItem;
                    if(existingMap.get(o.ProductId) != null){
                        newItem = existingMap.get(o.ProductId);
                    }
                    else{
                        //no item for this selection, so add a new one.
                        newItem = new Item__c(Opportunity__c = opp.Id, Product__c = o.ProductId, Product_Record_Type__c = o.type);
                    }
                    //now we have an item for our new product option, configure accordingly
                    newItem.Price__c = o.price;
                    newItem.Product_Record_Type__c = o.type;
                    newItem.Status__c = opp.StageName;
                    newItem.Primary_Product__c = selectedProduct.Id;
                    newExtras.add(newItem);
                }
            }
        }
        if(upgradeList != null){
            for(upgrade u: upgradeList){
                if(u.isSelected){
                    //the upgrade is selected, does an item exist already?
                    Item__c newItem;
                    if(existingMap.get(u.product.Id) != null){
                        newItem = existingMap.get(u.product.Id);
                    }
                    else{
                        //no item for this selection, so add a new one.
                        newItem = new Item__c(Opportunity__c = opp.Id, Product__c = u.product.Id, Product_Record_Type__c = u.type);
                    }
                    //now we have an item for the upgrade, check the price and type again
                    newItem.Price__c = u.price;
                    newItem.Product_Record_Type__c = u.type;
                    newItem.Status__c = opp.StageName;
                    newItem.Primary_Product__c = selectedProduct.Id;
                    newExtras.add(newItem);
                }
            }
        }

        /* Error Handling Here */
        //delete old extras
        try{
            //before updating, check that the records should have ids, incase of a rollback
            //query ids based on oldExtras.
            Set<Id> itemIds = new Set<Id>();
            for(Item__c i: [select Id from Item__c where Id in: oldExtras]){
                itemIds.add(i.Id);
            }
            //now loop through oldExtras
            for(Item__c i: oldExtras){
                if(!itemIds.contains(i.Id)){
                    //the id isn't in the list, so delete it.
                    i.Id = null;
                }
            }
            Database.Delete(oldExtras, true);
        }
        catch(dmlException d){
            //there were errors, loop through them and write an error to the page.
            for (Integer i = 0; i < d.getNumDml(); i++) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Deleted Extra:'+oldExtras[d.getDmlIndex(i)].Product__r.Name+': '+d.getDmlMessage(i)));
            }
            Database.rollback(sp);
            return null;
        }
        //add new extras to product selection list
        itemUpdates.addAll(newExtras);
        FOR(Item__c i: itemUpdates){
            system.debug('The Item Is: '+ i.Product__r.Name);
            system.debug('The Status Is: '+ i.Status__c);
            if(itemMap.get(i.Product__c) != null){
                itemMap.put(i.Id, itemMap.get(i.Product__c));
            }
        }


        try{
            //before updating, check that the records should have ids, incase of a rollback
            //query ids based on itemUpdates.
            Set<Id> itemIds = new Set<Id>();
            for(Item__c i: [select Id from Item__c where Id in: itemUpdates]){
                itemIds.add(i.Id);
            }
            //now loop through itemUpdates
            for(Item__c i: itemUpdates){
                if(!itemIds.contains(i.Id)){
                    //the id isn't in the list, so delete it.
                    i.Id = null;
                }
            }
            database.upsert(itemUpdates, true);
        }
        catch(dmlException d){
            //there were errors, loop through them and write an error to the page.
            for (Integer i = 0; i < d.getNumDml(); i++) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Product Selection:'+itemUpdates[d.getDmlIndex(i)].Product__r.Name+': '+d.getDmlMessage(i)));
            }
            //not all the items were successfully updated, roll back and return null
            Database.rollback(sp);
            return null;
        }


        //update any products
        Map<Id, Product__c> productUpdates = new Map<Id, Product__c>();
        if(!productSelectionList.isEmpty() && productSelectionList[0].Product__r != null){
                Product__c currentProduct = productSelectionList[0].Product__r;
                productUpdates.put(currentProduct.Id, currentProduct);
        }
        //add any previous new products that may need updating.
        for(Item__c i: previousListNew){
            //if the related product isn't null add it to the list for update
            if(i.Product__r != null){
                productUpdates.put(i.Product__r.Id, i.Product__r);
            }
        }
        //update the products
        try{
            database.update(productUpdates.values(), true);
        }
        catch(dmlException d){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'The Products could not be updated'+d));
            for (Integer i = 0; i < d.getNumDml(); i++) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Product:'+productUpdates.values()[d.getDmlIndex(i)].Name+': '+d.getDmlMessage(i)));
            }
            Database.rollback(sp);
            return null;
        }

        //upsert variations and conditiona
        Variation_Condition__c[] vacUpsert = new Variation_Condition__c[]{};
        Variation_Condition__c[] vacDelete = new Variation_Condition__c[]{};
        for(vac v: vacList){
            if(v.isEditable){
                //record has not been saved properly, throw an error back to the page.
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check that you have confirmed all Variations/Conditions before continuing.'));
                Database.rollback(sp);
                return null;
                break;
            }
            else if(v.isDeleted && v.vac.Id != null){
                //add to delete list
                vacDelete.add(v.vac);
            }
            else if(!v.isDeleted){
                //add to insert list
                vacUpsert.add(v.vac);
            }
        }
        //dml statements for both
        try{
            //before updating, check that the records should have ids, incase of a rollback
            //query ids based on vacupsert.
            Set<Id> vacIds = new Set<Id>();
            for(Variation_Condition__c v: [select Id from Variation_Condition__c where Id in: vacDelete]){
                vacIds.add(v.Id);
            }
            //now loop through vacUpsert
            for(Variation_Condition__c v: vacDelete){
                if(!vacIds.contains(v.Id)){
                    //the id isn't in the list, so delete it.
                    v.Id = null;
                }
            }
            Database.Delete(vacDelete, true);
        }
        catch(dmlException d){
            for (Integer i = 0; i < d.getNumDml(); i++) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Deleted Variation/Condition:'+vacDelete[d.getDmlIndex(i)].Name+': '+d.getDmlMessage(i)));
            }
            Database.rollback(sp);
            return null;
        }
        try{
            //before updating, check that the records should have ids, incase of a rollback

            //query ids based on vacupsert.
            Set<Id> vacIds = new Set<Id>();
            for(Variation_Condition__c v: [select Id from Variation_Condition__c where Id in: vacUpsert]){
                vacIds.add(v.Id);
            }
            //now loop through vacUpsert
            for(Variation_Condition__c v: vacUpsert){
                if(!vacIds.contains(v.Id)){
                    //the id isn't in the list, so delete it.
                    v.Id = null;
                }
            }
            Database.Upsert(vacUpsert, true);
        }
        catch(dmlException d){
            for (Integer i = 0; i < d.getNumDml(); i++) {
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Variation/Condition:'+vacUpsert[d.getDmlIndex(i)].Name+': '+d.getDmlMessage(i)));
            }
            Database.rollback(sp);
            return null;
        }


        if(newReceiptsActual.isEmpty()){
            //upsert receipts.
            try{
                //query ids based on vacupsert.
                Set<Id> rIds = new Set<Id>();
                for(Receipt__c r: [select Id from Receipt__c where Id in: receipts]){
                    rIds.add(r.Id);
                }
                //now loop through vacUpsert
                for(Receipt__c r: receipts){
                    if(!rIds.contains(r.Id)){
                        //the id isn't in the list, so delete it.
                        r.Id = null;
                    }
                }

                List<Receipt__c> onlyNewReceipts = new List<Receipt__c>();
                for (Receipt__c r : receipts) {
                    if (r.Id == null)
                        onlyNewReceipts.add(r);
                }

                Database.insert(onlyNewReceipts, true);
                //Database.Upsert(receipts, true);
            }
            catch(dmlException d){
                system.debug('Found: '+d.getNumDml()+' errors');
                String err = '';
                for (Integer i = 0; i < d.getNumDml(); i++) {
                    err += d.getDmlMessage(i) + ', ';
                    //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Receipt:'+receipts[d.getDmlIndex(i)].Name+': '+d.getDmlMessage(i)));
                }
                ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, 'Unable to save receipts. Please contact System Administrator with the following error message: ' + err));
                Database.rollback(sp);
                return null;
            }
        }
        else{
            //record have not been saved properly, throw an error back to the page.
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please check that you have confirmed all Receipts before continuing.'));
            Database.rollback(sp);
            return null;
        }

        return new pageReference('/'+opp.Id);
    }
}