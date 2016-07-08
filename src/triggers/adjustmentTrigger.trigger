trigger adjustmentTrigger on Adjustment__c (after insert, after update) 
{
	if(trigger.isAfter)
	{
		if(trigger.isInsert || trigger.isUpdate)
		{
			map<Id, Receipt__c> mapAdjustmentReceipts = new map<Id, Receipt__c>();
			map<Id, list<Adjustment__c>> mapAdjustmentAdjustments = new map<Id, list<Adjustment__c>>();
			list<Adjustment__c> listAdjustmentsToUpsert = new list<Adjustment__c>();
			map<Id, Opportunity> mapOpportunities = new map<Id, Opportunity>();
			
			
			for(Adjustment__c objAdjustment : trigger.new)
			{
				if(objAdjustment.Opportunity__c != null && 
					ohHelper.NormalizeDecimal(objAdjustment.Transaction_Amount__c) != 0 &&
					objAdjustment.Status__c == 'Unassigned')
				{
					if(objAdjustment.Transaction__c == null)
					{
						mapOpportunities.put(objAdjustment.Opportunity__c, null);
						if(objAdjustment.Transaction_Amount__c == objAdjustment.Amount__c)
						{
							ohHelper.AdjustEqualAmountCaseWithoutTransaction(objAdjustment, mapAdjustmentReceipts, mapAdjustmentAdjustments);
						}
						else if(ohHelper.NormalizeDecimal(objAdjustment.Transaction_Amount__c) < ohHelper.NormalizeDecimal(objAdjustment.Amount__c))
						{
							ohHelper.AdjustLessAmountCaseWithoutTransaction(objAdjustment, mapAdjustmentReceipts, mapAdjustmentAdjustments);
						}
					}
					else
					{
						if(objAdjustment.Transaction_Amount__c == objAdjustment.Amount__c)
						{
							ohHelper.AdjustEqualAmountCaseWithTransaction(objAdjustment, mapAdjustmentAdjustments, mapAdjustmentReceipts);
						}
						else if(ohHelper.NormalizeDecimal(objAdjustment.Transaction_Amount__c) < ohHelper.NormalizeDecimal(objAdjustment.Amount__c))
						{
							ohHelper.AdjustLessAmountCaseWithTransaction(objAdjustment, mapAdjustmentAdjustments, mapAdjustmentReceipts);
						}
					}
				}
			}
			
			if(mapOpportunities.size() > 0)
			{
				mapOpportunities = new map<Id, Opportunity>([
					Select Id, Primary_Product__c
					From Opportunity
					Where Id =: mapOpportunities.keySet()]);
				
				for(Id adjustmentId : mapAdjustmentReceipts.keySet())
				{
					if(mapAdjustmentReceipts.get(adjustmentId).Id == null)
					{
						if(mapOpportunities.get(mapAdjustmentReceipts.get(adjustmentId).Opportunity__c).Primary_Product__c != null)
						{
							mapAdjustmentReceipts.get(adjustmentId).Product__c = mapOpportunities.get(mapAdjustmentReceipts.get(adjustmentId).Opportunity__c).Primary_Product__c;
						}
						else
						{
							trigger.newMap.get(adjustmentId).addError('Unable to create Transaction. Primary Product for the Opportunity is not defined.');
							mapAdjustmentReceipts.remove(adjustmentId);
						}
					}
				}
			}
			upsert mapAdjustmentReceipts.values();
			
			for(Id adjustmentId : mapAdjustmentReceipts.keySet())
			{
				Receipt__c objReceipt = mapAdjustmentReceipts.get(adjustmentId);
				for(Adjustment__c objAdjustment : mapAdjustmentAdjustments.get(adjustmentId))
				{
					if(objAdjustment.Id != null)
					{
						objAdjustment.Transaction__c = objReceipt.Id;
					}
					listAdjustmentsToUpsert.add(objAdjustment);
				}
			}
			upsert listAdjustmentsToUpsert;
		}
	}
}