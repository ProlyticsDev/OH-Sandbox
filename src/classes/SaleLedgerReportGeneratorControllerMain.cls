public class SaleLedgerReportGeneratorControllerMain {

    public Opportunity o {get; set;}
    
    public SaleLedgerReportGeneratorControllerMain(ApexPages.StandardController stdController) {
        this.o = (Opportunity)stdController.getRecord();
    }
    
    public PageReference getReportIFrameUrl() {
        PageReference pg = Page.saleLedger;
        pg.getParameters().put('id', o.Id);
        
        return pg;
    }
    
    public PageReference saveSaleLedgerReport() {
        String fileName = 'Sale Ledger';
        return saveReport(Page.saleLedger, fileName);
    }
    
    public PageReference saveReport(PageReference page, String fileName) {
        PageReference taPage = new PageReference('/' + o.id);
        try {
            PageReference pdf = page;
            pdf.getParameters().put('id', o.Id);
            
            Attachment a;
            try {
            	a = [SELECT Id, Name, ContentType, ParentId, Body FROM Attachment WHERE Name = :fileName AND ParentId = :o.Id];
            } catch (Exception e) {
                a = new Attachment();
                a.Name = fileName;
                a.ContentType = 'application/pdf';
        		a.ParentId = o.Id;	
            }
        	a.Body = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.getContentAsPdf();
        	
            upsert a;
        } catch (Exception e) {
            
        }
        taPage.setRedirect(true);
        return taPage;
    }
}