public with sharing class vendorAuthoritySchedule implements Schedulable{
	
	public void execute(SchedulableContext sc) {
      vendorAuthorityBatch b = new vendorAuthorityBatch('select Id, (select Id, Vendor_Authority__r.Project__c, Vendor_Authority__r.Project__r.Name, Role__c from Vendor_Sales_Authorities__r where Active__c = true and (Role__c = \'Host\' or Role__c = \'Cadet\' or Role__c = \'Sales Consultant\')), (select Id, Name, Project__c, Type__c, Validated__c, Active__c, Expiry_Date__c from Documents__r where Active__c = true and Validated__c = true) from Account where VSA_Override__c = false and isPersonAccount = true and (RecordType.DeveloperName = \'Staff_Account\')'); 
      database.executebatch(b);
   }
   
   /* Run Adhoc:  database.executebatch(new vendorAuthorityBatch('select Id, (select Id, Vendor_Authority__r.Project__c, Vendor_Authority__r.Project__r.Name, Role__c from Vendor_Sales_Authorities__r where Active__c = true and (Role__c = \'Host\' or Role__c = \'Cadet\' or Role__c = \'Sales Consultant\')), (select Id, Name, Project__c, Type__c, Validated__c, Active__c, Expiry_Date__c from Documents__r where Active__c = true and Validated__c = true) from Account where VSA_Override__c = false and isPersonAccount = true and (RecordType.DeveloperName = \'Staff_Account\')'));*/

}