/**
* @author		Haider
* @date 		21/04/2016
* @description	Handler for the handled class to store the exception in the ApexError object
**/
public with sharing class ApexError {
	public static void AddException(Exception ex){
		final String UniqueId = Datetime.now()+' '+Math.round(Math.random()*100990);        
        List<DML_Email_Exception__c> dmlemailexceptions = new List<DML_Email_Exception__c>();
        
        if(ex.getTypeName() == 'System.EmailException' || ex.getTypeName() == 'System.DMLException'){
            Apex_Error__c apexerror_temp = new Apex_Error__c(Unique_Id__c = UniqueId);
	        for(Integer i=0; i<ex.getNumDml(); i++){
				DML_Email_Exception__c dmlemailexception = new DML_Email_Exception__c(
										            Dml_Field_Name__c	= ex.getDmlFieldNames(i).isEmpty() ? null : ex.getDmlFieldNames(i)[0],
										            Dml_Id__c 			= ex.getDmlId(i),
										            Dml_Index__c 		= ex.getDmlIndex(i),
										            Dml_Message__c 		= ex.getDmlMessage(i),
										            Dml_Type__c 		= String.valueOf(ex.getDmlType(i)),
                									Apex_Error__r 		= apexerror_temp);
				dmlemailexceptions.add(dmlemailexception);
	        }
	    }        
		
        Apex_Error__c apexerror = new Apex_Error__c(
	    											Line_Number__c 			= ex.getLineNumber(),
													Message__c				= ex.getMessage(),
	    											Stack_Trace_String__c	= ex.getStackTraceString(),
	    											Type_Name__c			= ex.getTypeName(),
													Num_Dml__c				= (ex.getTypeName() == 'System.EmailException' || ex.getTypeName() == 'System.DMLException') ? ex.getNumDml() : null,
													Unique_Id__c 			= UniqueId);

		List<SObject> objs = new List<SObject>();
		objs.add(apexerror);
        
        for(DML_Email_Exception__c e : dmlemailexceptions){
            objs.add(e);
        }

        try{
        	Database.SaveResult[] results = Database.insert(objs, false);                	
        }catch(Exception e){
        	throw new NotImplementedException('Unable to store the exception due to: '+e);
        }
	}
}