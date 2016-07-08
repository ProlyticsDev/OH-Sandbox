trigger productAssignmentTrigger on Product_Assignment__c (after update) 
{
	if(trigger.isAfter)
	{
		if(trigger.isUpdate)
		{
			list<Product__c> listProducts = new list<Product__c>();
			list<Product__c> listProductsToUpdate = new list<Product__c>();
			boolean isChildActive = false;
			
			for(Product_Assignment__c objProductAssignment : trigger.new)
			{
				if(objProductAssignment.Active__c == false && trigger.oldMap.get(objProductAssignment.Id).Active__c == true)
				{
					listProducts.add(new Product__c(Id = objProductAssignment.Product__c));
				}
			}
			
			listProducts = [
				Select Id, 
					(Select Id From Product_Assignments__r Where Active__c = true and Id Not IN : trigger.new)
				From Product__c
				Where Id =: listProducts
					and Active_VA__c = true];
			
			for(Product__c objProduct : listProducts)
			{
				isChildActive = false;
				for(Product_Assignment__c objProductAssignment : objProduct.Product_Assignments__r)
				{
					isChildActive = true;
					break;
				}
				if(!isChildActive)
				{
					objProduct.Active_VA__c = false;
					listProductsToUpdate.add(objProduct);
				}
			}
			update listProductsToUpdate;
		}
	}
}