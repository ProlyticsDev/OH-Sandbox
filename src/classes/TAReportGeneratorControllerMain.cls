public class TAReportGeneratorControllerMain {

    public Trust_Account__c trustAccount {get; set;}
    public String month {
        get {
            if (month == null)
                return String.valueOf(System.today().toStartOfMonth().addDays(-1).month());
            return month;
        }
        set;
    }
    public String year {
        get {
            if (year == null)
                return String.valueOf(System.today().year());
            return year;
        }
        set;
    }
    public static Map<String, String> monthsMap = new Map<String, String>();
    static {
        monthsMap.put('1', 'January');
        monthsMap.put('2', 'February');
        monthsMap.put('3', 'March');
        monthsMap.put('4', 'April');
        monthsMap.put('5', 'May');
        monthsMap.put('6', 'June');
        monthsMap.put('7', 'July');
        monthsMap.put('8', 'August');
        monthsMap.put('9', 'September');
        monthsMap.put('10', 'October');
        monthsMap.put('11', 'November');
        monthsMap.put('12', 'December');
    }
    
    public static Map<String, String> yearsMap = new Map<String, String>();
    static {
        yearsMap.put('2015', '2015');
        yearsMap.put('2016', '2016');
        yearsMap.put('2017', '2017');
        yearsMap.put('2018', '2018');
        yearsMap.put('2019', '2019');
        yearsMap.put('2020', '2020');
        yearsMap.put('2021', '2021');
        yearsMap.put('2022', '2022');
        yearsMap.put('2023', '2023');
        yearsMap.put('2024', '2024');
        yearsMap.put('2025', '2025'); 
    }
    
    public TAReportGeneratorControllerMain(ApexPages.StandardController stdController) {
        this.trustAccount = (Trust_Account__c)stdController.getRecord();
    }
    
    public List<SelectOption> getMonths() {
        List<SelectOption> options = new List<SelectOption>();
        for (String i : monthsMap.keySet()) {
            options.add(new SelectOption(''+i, monthsMap.get(i)));
        }
        return options;
    }
    
    public List<SelectOption> getYears() {
        List<SelectOption> options = new List<SelectOption>();
        for (String i : yearsMap.keySet()) {
            options.add(new SelectOption(''+i, yearsMap.get(i)));
        }
        return options;
    }
    
    public PageReference getReportIFrameUrl() {
        PageReference pg = Page.trustAccountSalesLedger;
        pg.getParameters().put('id', trustAccount.Id);
        pg.getParameters().put('m', month);
        pg.getParameters().put('y', year);
        
        return pg;
    }
    
    public PageReference getReportIFrameUrlCreditorLedger() {
        PageReference pg = Page.trustAccountCreditorLedger;
        pg.getParameters().put('id', trustAccount.Id);
        pg.getParameters().put('m', month);
        pg.getParameters().put('y', year);
        
        return pg;
    }
    
    public PageReference getReportIFrameUrlSalesTrialBalance() {
        PageReference pg = Page.trustAccountSalesTrialBalance;
        pg.getParameters().put('id', trustAccount.Id);
        pg.getParameters().put('m', month);
        pg.getParameters().put('y', year);
        
        return pg;
    }
    
    public PageReference getReportIFrameUrlCreditorsTrialBalance() {
        PageReference pg = Page.trustAccountCreditorsTrialBalance;
        pg.getParameters().put('id', trustAccount.Id);
        pg.getParameters().put('m', month);
        pg.getParameters().put('y', year);
        
        return pg;
    }
    
    public PageReference saveSaleLedgerReport() {
        String fileName = 'Sale Ledger - ' + monthsMap.get(month) + ' - ' + yearsMap.get(year);
        return saveReport(Page.trustAccountSalesLedger, fileName);
    }
    
    public PageReference saveCreditorLedgerReport() {
        String fileName = 'Creditor Ledger - ' + monthsMap.get(month) + ' - ' + yearsMap.get(year);
        return saveReport(Page.trustAccountCreditorLedger, fileName);
    }
    
    public PageReference saveSalesTrialBalanceReport() {
        String fileName = 'Sales Trial Balance - ' + monthsMap.get(month) + ' - ' + yearsMap.get(year);
        return saveReport(Page.trustAccountSalesTrialBalance, fileName);
    }
    
    public PageReference saveCreditorsTrialBalanceReport() {
        String fileName = 'Creditors Trial Balance - ' + monthsMap.get(month) + ' - ' + yearsMap.get(year);
        return saveReport(Page.trustAccountCreditorsTrialBalance, fileName);
    }
    
    public PageReference saveReport(PageReference page, String fileName) {
        PageReference taPage = new PageReference('/' + trustAccount.id);
        try {
            PageReference pdf = page;
            pdf.getParameters().put('id', trustAccount.Id);
            pdf.getParameters().put('m', month);
            pdf.getParameters().put('y', year);
            
            Attachment a;
            try {
            	a = [SELECT Id, Name, ContentType, ParentId, Body FROM Attachment WHERE Name = :fileName AND ParentId = :trustAccount.Id];
            } catch (Exception e) {
                a = new Attachment();
                a.Name = fileName;
                a.ContentType = 'application/pdf';
        		a.ParentId = trustAccount.Id;	
            }
        	a.Body = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.getContentAsPdf();
        	
            upsert a;
        } catch (Exception e) {
            
        }
        taPage.setRedirect(true);
        return taPage;
    }
}