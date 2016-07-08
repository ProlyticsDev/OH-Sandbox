@isTest
private class ApexErrorTest {
	
	@isTest static void AddExceptionTest() {
		Lead l = new Lead(FirstName = 'Test');
		try{
			insert l;
			}catch(Exception ex){
				ApexError.AddException(ex);
				List<Apex_Error__c> errors = [	SELECT Id, Num_Dml__c,
												(SELECT Dml_Field_Name__c FROM DML_Email_Exceptions__r)
												FROM Apex_Error__c];
				system.assertEquals(errors.size(),1);
			}
		
	}	
	
}