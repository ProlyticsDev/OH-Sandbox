/**
 * @author      HR
 * @date        16/02/2016
 * @description Utility class
**/
public without sharing class UtilClass {

    /**
    * @author  JH  
    * @date 06/04/2016
    * @description builds a map of the orgs record types keyed by sobjectype_developerName with the ID as the value. 
    * stores these record types in the orgRecordTypes static for caching purposes (means only one query for record type per transaction). 
    **/
    public static Map<String, RecordType> orgRecordTypeMap {
        get {
            if(orgRecordTypeMap != null) {
                return orgRecordTypeMap; 
            }
            else {
                orgRecordTypeMap = getRecordTypes(); 
                return orgRecordTypeMap; 
            }
        } 
        set;
    }

     /** 
     * @author JH 
     * @date 29/04/2016
     * @description Gets all the active projects that are available 
     */
     public static Map<String, Project__c> activeProjectMap {
        get {
            if(activeProjectMap != null) {
                return activeProjectMap; 
            }
            else {
                activeProjectMap = getActiveProjects(); 
                return activeProjectMap; 
            }
        } 
        set;
    }

    public static Map<String, RecordType> getRecordTypes() {
        List<RecordType> recordTypes = [SELECT Id, DeveloperName, sObjectType FROM RecordType WHERE IsActive = true]; 
        Map<String, RecordType> recordTypeMap = new Map<String, RecordType>(); 
        for(RecordType rType :recordTypes) {
            recordTypeMap.put(rType.sObjectType.toLowerCase() + '_' + rType.DeveloperName.toLowerCase(), rType); 
        }
        return recordTypeMap; 
    }

    public static Map<String, Project__c> getActiveProjects() {
        List<Project__c> activeProjects = [SELECT Id, Name FROM Project__c]; 
        Map<String, Project__c> activeProjMap = new Map<String, Project__c>(); 
        for(Project__c proj :activeProjects) {
            activeProjMap.put(proj.Name, proj); 
        }
        return activeProjMap; 
    }
    
    /**
    * @author       HR
    * @date         08/03/2016
    * @description  Get all accessible fields for passed object. <br/>
                    Sample success {Objectname=Id,IsDeleted,Name,Project__c} <br/>  
                    Sample fail {Exception=Invalid object name}
    * @param        API Name of the object  
    * @return       Map of Object name and comma seperated string of field API names 
    **/
    public static Map<String, String> getAllFields(String sobjectname){
        if(!Schema.getGlobalDescribe().containsKey(sobjectname)) return new Map<String, String>{'Exception' => 'Invalid object name'};
        Map<String, Schema.SObjectField> fields = Schema.getGlobalDescribe().get(sobjectname).getDescribe().SObjectType.getDescribe().fields.getMap();
  
        List<String> accessiblefields = new List<String>();
  
        for(Schema.SObjectField field : fields.values()){
            if(field.getDescribe().isAccessible())
                accessiblefields.add(field.getDescribe().getName());
        }
  
        String allfields='';
  
        for(String fieldname : accessiblefields)
            allfields += fieldname+',';
  
        allfields = allfields.subString(0,allfields.length()-1);
    
        return new Map<String, String>{sobjectname => allfields};
    }
    
        
    /**
    * @author       HR / JH
    * @date         23/03/2016
    * @description  filter sobject list to specific record types 
    * @param        List of sobject
    * @param        Name of the sobject
    * @return       Return map keyed by record type developer name with list of applicable records  
    * HISTORY: 
    * JH 12/04/2016 - refactored method to return a map with lists of records keyed by record type 
    */
    public static Map<String, List<sObject>> filterObjectsByRecordType(List<sObject> objects, String objectName){
        if(objects==null || objects.isEmpty() || objectName==null || objectName=='') return null;
        
        List<RecordType> rTypesForObject = [SELECT DeveloperName, Id FROM RecordType WHERE sObjectType = :objectName AND IsActive = true]; 
        
        Map<String, List<sObject>> filteredsObjects = new Map<String, List<sObject>>(); 
        for (RecordType rType :rTypesForObject) {
            List<sObject> sobjRtype = new List<sObject>(); 
            for(sObject obj : objects){
                
                if(String.valueOf(obj.get('RecordTypeId')) == rType.Id) {
                    sobjRtype.add(obj);
                }
            }

            filteredsObjects.put(rType.DeveloperName, sobjRtype); 


        }
        
        return filteredsObjects.isEmpty() ? null : filteredsObjects;
    }

    /**
    * @author       HR
    * @date         24/06/2016
    * @description  Query the ApexError
    **/
    public static List<Apex_Error__c> getApexErrors(){
        List<Apex_Error__c> errors = [SELECT Id, Line_Number__c, Message__c, Num_Dml__c, Stack_Trace_String__c, Type_Name__c,
                                        (SELECT Dml_Field_Name__c, Dml_Id__c, Dml_Index__c, Dml_Message__c, Dml_Type__c
                                        FROM DML_Email_Exceptions__r)
                                        FROM Apex_Error__c];
        return errors;
    }
}