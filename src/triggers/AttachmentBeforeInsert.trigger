trigger AttachmentBeforeInsert on Attachment (before insert) {

    // This trigger creates private attachment records for storing the Conga Commission Tax Invoices

    LIST<ID> accIds = new LIST<ID>();
    SET<ID> staffAccIds = new SET<ID>();
    MAP<ID, ID> attParentIdMap = new MAP<ID, ID>();
    LIST<Private_Attachments__c> pAs = new LIST<Private_Attachments__c>();
  
    // Get list of parent accounts for attachments that meet filter criteria
    for (Attachment a : Trigger.new) {
        if (string.valueof(a.parentId).startsWith('001') && a.ContentType == 'application/pdf' && a.Name.startsWith('Commissions Statement')) {
            accIds.add(a.parentId);
            attParentIdMap.put(a.id, a.parentId);
        }
    }

    // Filter account list by Staff Account record type
    if (accIds.size() > 0) {
        Id staffRTId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Staff Account').getRecordTypeId();
    
        for (Account acc : [SELECT Id FROM Account WHERE Id IN :accIds AND RecordTypeId = :staffRTId]) {
            staffAccIds.add(acc.Id);
        }
    }

    // Create Private Attachment container records
    for (Attachment a : Trigger.new) {
        if (attParentIdMap.containskey(a.id) && staffAccIds.contains(a.parentId)) {
            pAs.add(new Private_Attachments__c(Account__c = attParentIdMap.get(a.Id)));
        }
    }
    
    if (pAs.size() > 0) {
        insert pAs;

        Integer i = 0;
        for (Attachment a : Trigger.new) {
            if (attParentIdMap.containskey(a.id) && staffAccIds.contains(a.parentId)) {
                a.parentId = pAs[i].id;
                i++;
            }
        }
    }

}