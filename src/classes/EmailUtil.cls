public class EmailUtil {
    private Messaging.SingleEmailMessage singleEmailMessage;
    private final List<String> toAddresses;
    
    private List<String> ccAddresses;
    private String subject = '';
    private String htmlBody = ''; 
    private Boolean useSignature = false;
    private Boolean saveAsActivity = false;
    private Boolean useTemplateAsIs = true;
    private List<Messaging.EmailFileAttachment> fileAttachments = null;
    private String senderDisplayName = UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
    private User currentUser = [SELECT Email FROM User WHERE UserName = :UserInfo.getUserName() LIMIT 1];        
    private String replyTo = currentUser.email;
    private String plainTextBody = '';
    private EmailTemplate emailTemplate;
    private Id whatId;
    private Id targetObjectId;
    private Map<String, String> mergeFields;
	
    public EmailUtil(List<String> addresses) {
        this.toAddresses = addresses;
    }
    
    /*public EmailUtil whatId(Id whatId) {
        this.whatId = whatId;
        return this;
    }
    
    public EmailUtil targetObjectId(String targetObjectId) {
        this.targetObjectId = targetObjectId;
        return this;
    }*/
    
    public EmailUtil emailTemplate(String emailTemplateName) {
        this.emailTemplate = [SELECT Id, Body, HtmlValue, Subject FROM EmailTemplate WHERE developerName = :emailTemplateName];
        this.subject = this.emailTemplate.Subject;
        this.plainTextBody = this.emailTemplate.Body;
        this.htmlBody = this.emailTemplate.HtmlValue;
        
        return this;
    }
    
    public EmailUtil mergeFields(Map<String, String> mergeFields) {
        this.mergeFields = mergeFields;
        return this;
    }
    
    public EmailUtil ccAddresses(List<String> ccAddresses) {
        this.ccAddresses = ccAddresses;
        return this;
    }
       
    /*public EmailUtil senderDisplayName(String val) {
        senderDisplayName = val;
        return this;
    }
    
    public EmailUtil subject(String val) {
        subject = val;
        return this;
    }
    
    public EmailUtil htmlBody(String val) {
        htmlBody = val;
        return this;
    }
    
    public EmailUtil useSignature(Boolean bool) {
        useSignature = bool;
        return this;
    }
    
    public EmailUtil saveAsActivity(Boolean bool) {
        saveAsActivity = bool;
        return this;
    }*/
    
    public EmailUtil useTemplateAsIs(Boolean bool) {
        useTemplateAsIs = bool;
        return this;
    }
    
    /*public EmailUtil replyTo(String val) {
        replyTo = val;
        return this;
    }
    
    public EmailUtil plainTextBody(String val) {
        plainTextBody = val;
        return this;
    }*/
    
    public EmailUtil fileAttachments(List<Messaging.Emailfileattachment> val) {
        fileAttachments = val;
        return this;
    }
    
    private EmailUtil build() {
        singleEmailMessage = new Messaging.SingleEmailMessage();
        singleEmailMessage.setToAddresses(this.toAddresses);
        singleEmailMessage.setCcAddresses(this.ccAddresses);
        singleEmailMessage.setSenderDisplayName(this.senderDisplayName);
        singleEmailMessage.setUseSignature(this.useSignature);
        singleEmailMessage.setReplyTo(this.replyTo);
        singleEmailMessage.setFileAttachments(this.fileAttachments);
        
        if (this.mergefields != null)
        	mergefields();
        
        if (this.subject != '')
            singleEmailMessage.setSubject(this.subject);
        if (this.htmlBody != '')
            singleEmailMessage.setHtmlBody(this.htmlBody);
        if (this.plainTextBody != '')
            singleEmailMessage.setPlainTextBody(this.plainTextBody);
        
        /*if (this.useTemplateAsIs) {
            singleEmailMessage.setSubject(null);
            singleEmailMessage.setHtmlBody(null);
            singleEmailMessage.setPlainTextBody(null);
            
            singleEmailMessage.setSaveAsActivity(this.saveAsActivity);
            singleEmailMessage.setTemplateId(this.emailTemplate.Id);
        	singleEmailMessage.setWhatId(this.whatId);
            singleEmailMessage.setTargetObjectId(this.targetObjectId);
        }*/ 
        
        return this;
    }
    
    private void mergefields() {
        
        String subj = (this.subject != null) ? this.subject : '';
        String html = (this.htmlBody != null) ? this.htmlBody : '';
        String plai = (this.plainTextBody != null) ? this.plainTextBody : '';
        
        for (String mergefield : mergefields.keySet()) {
            subj = subj.replace(mergefield, mergefields.get(mergefield));
            html = html.replace(mergefield, mergefields.get(mergefield));
            plai = plai.replace(mergefield, mergefields.get(mergefield));
        }
        
        this.subject = subj;
        this.htmlBody = html;
        this.plainTextBody = plai;
    }
    
    public void sendEmail() {
        try {
            build();
            Messaging.reserveSingleEmailCapacity(1);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { singleEmailMessage });
        } catch (Exception ex) {
            throw ex;
        }                
    }    
    
}