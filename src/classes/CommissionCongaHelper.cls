global class CommissionCongaHelper {

    webservice static Integer taxInvoicesAlreadyGenerated(LIST<ID> idArray) {
        // returns a flag value of 1 for true and 0 for false since javascript doesn't assign boolean correctly
        return [SELECT Count() FROM Commission__c WHERE Id IN :idArray AND TaxInvoiceGenerated__c = true LIMIT 1];
    }

    webservice static LIST<String> filterIDs(LIST<ID> idArray) {
        SET<String> accIdSet = new SET<String>();
        for (Commission__c c : [SELECT Account__c FROM Commission__c
                                WHERE Account__c IN :idArray
                                AND (Status__c = 'Pending' OR Status__c = 'Payable')
                                AND RecordType.Name = 'Staff'
                                AND Account__r.RecordType.Name = 'Staff Account'
                                AND Due_Date__c = THIS_FISCAL_YEAR]) {
            accIdSet.add(c.Account__c);
        }
        return new List<String>(accIdSet);
    }

    /* Email functionality no longer needed after requirement change
    webservice static LIST<String> getFormattedAttachmentIds(ID accountId) {

        MAP<ID, ID> commAttIDMap = getAttachmentIds(accountId, 15);
        LIST<ID> commIDs = new LIST<ID>(commAttIDMap.keyset());
        LIST<ID> commAttIDs = commAttIDMap.values();
        LIST<ID> firstTenIds = new LIST<ID>();
        LIST<ID> remainingIds = new LIST<ID>();
        LIST<String> retStrings = new LIST<String>();
        for (Integer i = 0; i < commAttIDs.size(); i++) {
            if (i < 10) {
                 firstTenIds.add(commAttIDs[i]);
            } else {
                 remainingIds.add(commAttIDs[i]);
            }
        }
        
        retStrings.add(String.join(commIDs,','));
        retStrings.add(String.join(firstTenIds,','));
        retStrings.add(String.join(remainingIds,','));
        return retStrings;

    }

    static MAP<ID, ID> getAttachmentIds(ID accountId, INTEGER maxRecs) {
        Set<ID> cIds = new SET<ID>();
        for (Commission__c c : [SELECT Id FROM Commission__c
                                WHERE Vendor_Solicitor__c = :accountId AND TaxInvoiceGenerated__c = True
                                AND Tax_Invoice_Sent__c = False
                                ORDER BY CreatedDate ASC
                                LIMIT :maxRecs]) {
            cIds.add(c.Id);
        }

        MAP<ID, ID> commAttMap = new MAP<ID, ID>();

        // Only select the most recent Attachment for each Commission that meets the criteria
        for (Attachment att : [SELECT Id, ParentId FROM Attachment 
                               WHERE Name LIKE 'CommissionsTaxInvoice%.pdf' 
                               AND ContentType = 'application/pdf'
                               AND ParentId IN :cIds
                               ORDER BY CreatedDate DESC]) {
            if (!commAttMap.containskey(att.ParentId)) {
                commAttMap.put(att.ParentId, att.Id);
            }
        }

        return commAttMap;
    }

    webservice static LIST<String> getComposerURL(LIST<ID> commissionIds) {
        LIST<String> urls = new LIST<String>();
        for (Commission__c comm : [SELECT Id, ComposerFormula_URL__c FROM Commission__c
                                   WHERE Id IN :commissionIds]){
            urls.add('&Id=' + comm.Id + comm.ComposerFormula_URL__c);
        }
        return urls;
    }
    */
       
}