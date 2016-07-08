trigger attachmentTrigger on Attachment (after delete) {
    
    //Attachments related to 'Active' receipts are not allowed to delete.
    Map<Id, List<Attachment>> receiptToAttachments = new Map<Id, List<Attachment>>();
    for (Attachment a : Trigger.old) {
        if (((String)a.ParentId).startsWith('a06')) {
            if (receiptToAttachments.get(a.ParentId) != null) {
                receiptToAttachments.get(a.ParentId).add(a);
            } else {
                List<Attachment> attachments = new List<Attachment>();
                receiptToAttachments.put(a.ParentId, attachments);
                attachments.add(a);
            }
        }
    }
    
    List<Receipt__c> activeReceipts = new List<Receipt__c>();
    for (Receipt__c r : [SELECT Id, Trust_Account_Receipt_Status__c 
                         FROM Receipt__c WHERE Id IN :receiptToAttachments.keySet() AND Trust_Account_Receipt_Status__c = 'Active']) {
        for (Attachment a : receiptToAttachments.get(r.Id)) {
            a.addError('Deleting attachments are not allowed.');
        }
    }
    
        
}