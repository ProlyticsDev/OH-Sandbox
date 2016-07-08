/**
 * @author			HR
 * @date			18/02/2016
 * @description		See the Apex Language Reference for more information about Testing and Code Coverage.
**/
@isTest
private class UtilClassTest {
	/**
    * @description	Validate the number of record types
	* @author		HR
	* @date			09/03/2016
    **/
	static testMethod void RecordTypeIdTest() {
		Map<String, RecordType> allOrgRTypes = UtilClass.orgRecordTypeMap; 
		system.assert(allOrgRTypes != null && !allOrgRTypes.isEmpty()); 
    }
    
    /**
    * @description	FieldDefinition not working, known bug https://success.salesforce.com/issues_view?id=a1p30000000eNxN <br/> 
    				when fixed will update the test coverage
	* @author		HR
	* @date			18/02/2016
    **/
    static testMethod void AllFieldsTest(){
		String sobjectname = 'Account';
		String customfields1='';
		
		for(String s : UtilClass.getAllFields(sobjectname).get(sobjectname).split(',')){
			if(s.right(3)=='__c')
				customfields1 += s + ',';
		}
		
		String customfields2='';
		
		List<FieldDefinition> fdef = [SELECT QualifiedApiName FROM FieldDefinition WHERE EntityDefinition.DeveloperName =: sobjectname];
		for(FieldDefinition fd : fdef){
			if(fd.QualifiedApiName.right(3)=='__c')
				customfields2 += fd.QualifiedApiName + ',';
		}
		
		System.debug(customfields1.length());
		System.debug(customfields2.length());
		
		//Uncomment when FieldDefinition is working
		//System.assert(customfields1.length()==customfields2.length(), 'Custom fields different to FieldDefinition.');    	
    }
    
    /**
    * @description	Code coverage for filterObjectsByRecordType method in the UtilClass
	* @author		HR
	* @date			18/02/2016
	* HISTORY: 
	* 07/04/2016 jh - updated util call to use new method, updated unit test to compare that the objs returned from the method are 
	* the same as the objs created.  
    **/
    static testMethod void filterObjectsByRecordTypeTest(){
    	Map<String, RecordType> leadRecordTypes = UtilClass.orgRecordTypeMap;
    	
    	List<Lead> leads = TestData.createLeads(leadRecordTypes.size(), null);
    	for(Lead l : leads){
    		l.RecordTypeId = leadRecordTypes.get(LeadFramework.LEAD_APARTMENT_RECORDTYPE).Id;
    	}
    	
    	//jh - should always be record types for lead 
    	system.assert(leadRecordTypes != null && !leadRecordTypes.isEmpty()); 
    	//List<sObject> filteredObjs = UtilClass.filterObjectsByRecordType(leads, 'Lead', 'apartment');
    	//system.assertEquals(leadRecordTypes.size(), filteredObjs.size());
    }
    
}