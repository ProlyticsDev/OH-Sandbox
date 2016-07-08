trigger vendorAuthorityTrigger on Vendor_Authority__c (after update) {

/*    
When a VA’s Exclusive period expires, we need to establish if the VA is finished, or if it going to default 
to a General period. If there will be a General period, then no action should be taken.

If there isn’t going to be a General period, then all Product Assignment records covered by the VA need to 
have their ‘Active’ field set to FALSE.

When the General period expires, then all Product Assignment records covered by the VA need to have their 
‘Active’ field set to FALSE.

*/

	if(trigger.isUpdate){
		//pass through new records directly.
		vendorAuthorityUtility.updateProductAsignment(trigger.newMap, trigger.oldMap);
	}
}