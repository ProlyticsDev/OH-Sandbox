@isTest
private class TStringUtilsTest {

    static testMethod void stringUtilsTest() {
        Map<String, String> projects = new Map<String, String>();
        projects.put('Mayfield', 'Mayfield');
        Map<String,List<String>> projectToEnquiries = TStringUtils.getDependentOptions('Lead', 'Project_Picklist__c', 'Enquiry_Source__c', projects);
        System.assert(projectToEnquiries != null);
    }
}