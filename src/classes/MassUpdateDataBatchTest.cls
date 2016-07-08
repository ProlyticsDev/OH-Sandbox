@isTest
public class MassUpdateDataBatchTest {

	static testMethod void massUpdateDataBatchPostiveTest() {
		List<Account> accs = TestData.createPersonAccounts(1); 
		system.assert(String.isNotBlank(accs[0].PersonEmail)); 
		MassUpdateDataBatch massUpdate = new MassUpdateDataBatch();
		massUpdate.fieldName = 'PersonEmail'; 
		massUpdate.replaceWith = 'test@'; 
		massUpdate.query = 'SELECT PersonEmail FROM Account';  
		Database.executeBatch(massUpdate); 

		Account updatedAcc = [SELECT PersonEmail FROM Account limit 1];
		system.assert(updatedAcc.PersonEmail.contains('test@'));  
	}

}