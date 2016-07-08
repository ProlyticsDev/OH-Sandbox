global class TASingleReceiptGeneratorController {
    
    private static final Integer MAX_ATTEMPTS = 3;
    private static String sfdcURL = URL.getSalesforceBaseUrl().toExternalForm() + '/'; 
    
    webservice static String generateReceipt(Id receiptId) {
        Integer attempts = MAX_ATTEMPTS;

        Receipt__c receipt = [SELECT Id
                              , Name
                              , Product__c
                              , Trust_Account_Receipt_Status__c
                              , Trust_Account_Receipt_No2__c
                              , Trust_Account__r.TA_Receipt_Number__c
                              , Opportunity__r.Id
                              , Opportunity__r.Name
                              , Opportunity__r.Account.Id
                              , Opportunity__r.Account.IsPersonAccount
                              , Opportunity__r.Account.PersonEmail
                              , Opportunity__r.Account.Name
                              , Opportunity__r.Account.LastName
                              , Opportunity__r.OwnerId
                              , Opportunity__r.Owner.Email
                              , Opportunity__r.Owner.Name
                              , Opportunity__r.Owner.Title
                              , Product__r.Project__r.Name
                              , Product__r.Name 
                              FROM Receipt__c WHERE Id = :receiptId];

        //if (receipt.Trust_Account_Receipt_Status__c != 'Cancelled') {
            Product_Assignment__c pa = getProductAssignment(receipt.Product__c);
            //Product_Assignment__c pa = [SELECT CreatedDate, Active__c, Vendor_Authority__r.Vendor__c 
            //                            FROM Product_Assignment__c WHERE Active__c = true AND Product__c = :receipt.Product__c ORDER BY CreatedDate DESC LIMIT 1];
            Trust_Account__c trustAccount;
            
            Trust_Account_Receipt_Number__c objTaReceiptNo;
            
            Attachment att = new Attachment();
            
            att.ContentType = 'application/pdf';
            att.ParentId = receipt.Id;
            Attachment existingReceipt;
            
            try {
                existingReceipt = [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId = :receipt.Id LIMIT 1];
            } catch (Exception e) {
                //No attachments found
            }
            
            String fileNameSource = ''; 
            fileNameSource += (receipt.Opportunity__r.Account.IsPersonAccount) ? receipt.Opportunity__r.Account.LastName : receipt.Opportunity__r.Account.Name;
            fileNameSource += ' - ' + receipt.Product__r.Name + ' - ' + receipt.Product__r.Project__r.Name + '_Trust Account Receipt_';
            
            if (existingReceipt != null) {
                String amendedFileName = '%Amended%';
                String q = 'SELECT Id, ParentId, Name FROM Attachment WHERE Name LIKE \'' + amendedFileName + '\' AND ParentId = \'' + receipt.Id + '\' ORDER BY Name DESC';
                
                List<Attachment> existingAmendmentReceipts = (List<Attachment>)Database.query(q); 
                fileNameSource += receipt.Trust_Account_Receipt_No2__c;
                receipt.Receipted_Date__c = Date.today();
                if (existingAmendmentReceipts.isEmpty()) {
                    att.Name = fileNameSource + '-(Amended1).pdf';
                } else {
                    att.Name = fileNameSource + '-(Amended' + (existingAmendmentReceipts.size() + 1) + ').pdf';
                }
            } else {
                trustAccount = [SELECT Id, TA_Receipt_Number__c FROM Trust_Account__c WHERE Id = :receipt.Trust_Account__c];
                objTaReceiptNo = [SELECT Id, TA_Receipt_Number__c, Trust_Account__c FROM Trust_Account_Receipt_Number__c WHERE Trust_Account__c = :receipt.Trust_Account__c FOR UPDATE];
                
                Decimal taReceiptNo = (objTaReceiptNo.TA_Receipt_Number__c == null) ? 100000 : objTaReceiptNo.TA_Receipt_Number__c;
            
                receipt.Trust_Account_Receipt_No2__c = ++taReceiptNo;
                receipt.Trust_Account_Receipt_Status__c = 'Active';
                receipt.Receipted_Date__c = Date.today();
                objTaReceiptNo.TA_Receipt_Number__c = taReceiptNo;
                att.Name = fileNameSource + receipt.Trust_Account_Receipt_No2__c + '.pdf';
            }
    
        	
                    
                    
            if (verify(receipt, objTaReceiptNo)) {
                Savepoint sp = Database.setSavepoint();
                while(attempts > 0){
                    try {
                        attempts--;
                        if (objTaReceiptNo != null) //This will be null when there is an existing receipt.pdf
                            update objTaReceiptNo;
                        update receipt;
                        attempts = 0;
                    } catch (System.DmlException e) {
                        if (!e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                            attempts = 0;
                            throw e;
                        }
                        
                    }
                }
                
                PageReference pdf = Page.trustAccountSingleReceipt;
                pdf.getParameters().put('id', receipt.Id);
                pdf.getParameters().put('num', String.valueof(receipt.Trust_Account_Receipt_No2__c));
                pdf.getParameters().put('va', pa.Vendor_Authority__r.Vendor__c);
                pdf.getParameters().put('processedDate', Datetime.now().format('yyyy-MM-dd'));
                Blob data = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.GetContentAsPDF();
                att.Body = data;
                
                try {
                    insert att;
                } catch (Exception e) {
                    Database.rollback(sp);
                }
                
                try {
                    String profileName = [SELECT Name FROM Profile WHERE Id = :UserInfo.getProfileId()].Name;
                    if (profileName == 'Sales Administration Manager')
                    	email(att, receipt);    
                } catch (Exception e) {
                    throw e;
                }
                
                return pdf.getUrl();
            }
        //} else {
        //    return 'Trust Account Receipts cannot be generated for cancelled receipts.';
        //}
        return null;
    }
    
    private static void email(Attachment attachment, Receipt__c receipt) {
        try {
            if (receipt.Opportunity__r.Account.IsPersonAccount) {
                List<String> to = new List<String>();
                EmailUtil emailCustomer = new EmailUtil(to);
                List<Messaging.EmailFileAttachment> emailAttachments = new List<Messaging.EmailFileAttachment>();
                Messaging.EmailFileAttachment fileToAttach = new Messaging.EmailFileAttachment();
                fileToAttach.setFileName(attachment.Name);
                fileToAttach.setBody(attachment.Body);
                emailAttachments.add(fileToAttach);
                
                Map<String, String> mergefields = new Map<String, String>();
                    
                if (receipt.Opportunity__r.Account.PersonEmail != null) {
                    List<String> cc = new List<String>();
                    to.add(receipt.Opportunity__r.Account.PersonEmail);
                    cc.add(receipt.Opportunity__r.Owner.Email);
                    
                    //mergefields.put('{!User.Name}', receipt.Opportunity__r.Owner.Name);
                    //mergefields.put('{!User.Title}', (receipt.Opportunity__r.Owner.Title != null) ?  receipt.Opportunity__r.Owner.Title : '');
                    User u = [SELECT Id, Title FROM User WHERE Id = :UserInfo.getUserId()];
                    
                    mergefields.put('{!User.Name}', UserInfo.getName());
                    mergefields.put('{!User.Title}', (u.Title != null)? u.Title : '' ) ;
                    
                    emailCustomer.ccAddresses(cc)
                        		 .emailTemplate('Trust_Account_Receipt_Customer')
                        		 .fileAttachments(emailAttachments)
                        		 .useTemplateAsIs(false)
                        		 .mergefields(mergefields)
                        		 .sendEmail();
                
                } else {
                    to.add(receipt.Opportunity__r.Owner.Email);
                                        
                    mergefields.put('{!Opportunity.Name}', receipt.Opportunity__r.Name);
                    mergefields.put('{!Receipt__c.Name}', receipt.Name);
                    mergefields.put('{!Account.Name}', receipt.Opportunity__r.Account.Name);
                    mergefields.put('{!Opportunity.Link}', sfdcURL + receipt.Opportunity__r.Id);
                    mergefields.put('{!Receipt__c.Link}', sfdcURL + receipt.Id);
                    mergefields.put('{!Account.Link}', sfdcURL + receipt.Opportunity__r.Account.Id);
                    
                    emailCustomer.emailTemplate('Trust_Account_Receipt_Opportunity_Owner')
                        		 .fileAttachments(emailAttachments)
                        		 .useTemplateAsIs(false)
                        		 .mergefields(mergefields)
                        		 .sendEmail();
                }
            }
        } catch (Exception e) {
            throw e;
        }
    }
    
    private static Product_Assignment__c getProductAssignment(Id productId) {
        Product_Assignment__c pa;
        try {
			pa = [SELECT CreatedDate, Active__c, Vendor_Authority__r.Vendor__c 
                                    FROM Product_Assignment__c 
                                    WHERE Active__c = true AND Product__c = :productId ORDER BY CreatedDate DESC LIMIT 1];            
        } catch (Exception e) {
            System.debug('@Exception when retrieving Product Assignment: ' + e);
        }
        return pa;
    }
    
    webservice static String cancelTrustAccountReceipt(Id receiptId, Id remainingAttachmentId) {
        Receipt__c receipt = [SELECT Id, Trust_Account_Receipt_No2__c, Product__c, Receipted_Date__c, Trust_Account_Receipt_Status__c FROM Receipt__c WHERE Id = :receiptId];
        Attachment remainingAttachment = [SELECT Id, Name, ParentId FROM Attachment WHERE Id = :remainingAttachmentId];
        Attachment attachment;
        
        if (remainingAttachment != null) {
            attachment = new Attachment();
            attachment.ContentType = 'application/pdf';
            attachment.ParentId = receipt.Id;
            attachment.Name = remainingAttachment.Name;
            PageReference pdf = Page.trustAccountSingleReceipt;
            pdf.getParameters().put('id', receipt.Id);
            pdf.getParameters().put('num', String.valueof(receipt.Trust_Account_Receipt_No2__c));
            pdf.getParameters().put('va', getProductAssignment(receipt.Product__c).Vendor_Authority__r.Vendor__c);
            Date dt = receipt.Receipted_Date__c;
            Datetime dtime = Datetime.newInstance(dt.year(), dt.month(),dt.day());
            pdf.getParameters().put('processedDate', dtime.format('yyyy-MM-dd'));
            Blob data = Test.IsRunningTest() ? Blob.ValueOf('Fake data') : pdf.getContent();
            attachment.Body = data;
            
           try {
               insert attachment; 
            } catch (Exception e) {
            	return e.getMessage();    
            }
        }
        
        return null;
    }
    
    webservice static Id deleteAllReceiptAttachmentsExceptCurrent(Id receiptId) {
        List<Attachment> attachmentsToDelete = new List<Attachment>();
        Id remainingAttachmentId;
        for (List<Attachment> attachments : [SELECT Id, ParentId, Name, Body FROM Attachment WHERE ParentId = :receiptId ORDER BY CreatedDate DESC]) {
            //We should keep the very latest attachment
            if (attachments != null && !attachments.isEmpty()) {
                if (Test.isRunningTest()) { //Please refer back to the test
                    Integer count = 0;
                    while (attachments.get(count).Name == 'XXX') {
                        count++;
                    }
                    attachments.remove(count);
                    remainingAttachmentId = attachments.get(0).Id;
                } else {
            		remainingAttachmentId = attachments.remove(0).Id;
                }
                attachmentsToDelete.addAll(attachments);
            } else {
                return null;
            }
        }
        
        try {
            if (!attachmentsToDelete.isEmpty())
                delete attachmentsToDelete;
        } catch (Exception e) {
            System.debug('#Error when deleting attachments: ' + e);
        }
        
        return remainingAttachmentId;
    }
    
    /*private static Map<Receipt__c, Attachment> deleteAllReceiptAttachmentsExceptCurrent(List<Receipt__c> receipts) {
        List<Attachment> attachmentsToDelete = new List<Attachment>();
        Map<Receipt__c, Attachment> latestAttachments = new Map<Receipt__c, Attachment>();
        Map<Id, Receipt__c> receiptIdsToReceipt = new Map<Id, Receipt__c>();
        Set<Id> receiptIds = new Set<Id>();
        if (receipts != null && !receipts.isEmpty()) {
            for (Receipt__c r : receipts) {
                if (r.Trust_Account_Receipt_Status__c == 'Cancelled')
                	receiptIds.add(r.Id);
                	receiptIdsToReceipt.put(r.Id, r);
            }
            
            for (List<Attachment> attachments : [SELECT Id, ParentId, Name, Body FROM Attachment WHERE ParentId IN :receiptIds ORDER BY CreatedDate DESC]) {
                //We should keep the very latest attachment
                Attachment latestAttachment = attachments.remove(0);
                latestAttachments.put(receiptIdsToReceipt.get(latestAttachment.ParentId), latestAttachment);
                attachmentsToDelete.addAll(attachments);
            }
            
            try {
                if (!attachmentsToDelete.isEmpty())
                	delete attachmentsToDelete;
            } catch (Exception e) {
                System.debug('#Error when deleting attachments: ' + e);
            }
        }
        return latestAttachments;
    }*/
    
    private static boolean verify(Receipt__c r, Trust_Account_Receipt_Number__c t) {
        boolean isValid = true;
        try {
            if (t != null) {
            	Receipt__c rOld = [SELECT Trust_Account_Receipt_No2__c, Trust_Account__c FROM Receipt__c 
                               	   WHERE Trust_Account_Receipt_No2__c = :r.Trust_Account_Receipt_No2__c AND Trust_Account__c = :t.Trust_Account__c LIMIT 1];
            	isValid = !(rOld != null);
                Trust_Account__c tOld = [SELECT Id, TA_Receipt_Number__c FROM Trust_Account__c
                                         WHERE TA_Receipt_Number__c = :t.TA_Receipt_Number__c AND Id = :t.Trust_Account__c LIMIT 1];
            	isValid = !(tOld != null);
            }
        } catch (Exception e) {
            	
        }
        
        return isValid;
    }
}