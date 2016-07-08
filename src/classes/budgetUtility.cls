public with sharing class budgetUtility{

	//used by the budget utiliy trigger to update all budget item records that have changed due to opportunity updates.
	
	@future
	public static void updateItems2(Set<Id> itemIds){
		Map<Id, Budget_Junction__c[]> budgetMap = new Map<Id, Budget_Junction__c[]>();
		Budget_Item__c[] itemsForUpdate = new Budget_Item__c[]{};
		for(Budget_Item__c b: [select id,(select id, Opportunity__c, Opportunity__r.Amount from Budget_Junctions__r) from Budget_Item__c where id in: itemIds]){
			if(budgetMap.get(b.Id) == null){
				budgetMap.put(b.Id, new Budget_Junction__c[]{});
			}
			//put any sub junction items in the map.
			for(Budget_Junction__c j: b.Budget_Junctions__r){
				budgetMap.get(b.Id).add(j);
			}
		}
		//now the map is built, loop through and calculate the new item amounts.
		for(Id i: budgetMap.keySet()){
			//create the new item
			Budget_Item__c newItem = new Budget_Item__c(Id = i);
			//Initialise amount fields
			Integer qty = 0;
			Decimal dollar = 0;
			//loop through the list of budget items and calculate the 2 fields.
			for(Budget_Junction__c b: budgetMap.get(i)){
				//add one to the quantity
				qty ++;
				//add the amount to the dollar
				dollar += b.Opportunity__r.Amount;
			}
			//update the relevant fields
			newItem.Actual_Dollar__c = dollar;
			newItem.Actual_Qty__c = qty;
			//add the item for update
			itemsForUpdate.add(newItem);
		}
		//update the budget items
		update itemsForUpdate;
	}
	
	
	public static void recalcAll(){
		//utility method used primarily for testing
		Set<Id> itemSet = new Set<Id>();
		for(Budget_Item__c b: [select id from Budget_Item__c where Type__c = 'Actual']){
			itemSet.add(b.Id);
		}
		updateItems2(itemSet);
	}
	
	
	//method that processes a batch of budget records
	public static void processBudgets(Budget__c[] budgets){
		//all the budgets will have unique id records that will match opportunities. save these unique ids in a list, and use it to query the opps.
		String[] uniqueIds = new String[]{};
		for(Budget__c b: budgets){
			if(b.Project__c != null && b.Start_Date__c != null){
				uniqueIds.add(b.Unique_Id__c);
			}
		}
		
		Map<String, Integer> oppCountMap = new Map<String, Integer>();
		
		for(Opportunity o: [select Id, Unique_Id__c, Date_of_Enquiry__c from Opportunity where Unique_Id__c in: uniqueIds]){
			//build out a map by unique Id, and a list of opportunities. or just count integer?
			if(oppCountMap.get(o.Unique_Id__c) == null){
				//doesn't exist, so add it
				oppCountMap.put(o.Unique_Id__c, 1);
			}
			else{
				//exists in the map, and will already have a value, so just add one.
				oppCountMap.put(o.Unique_Id__c, oppCountMap.get(o.Unique_Id__c)+1);
			}
		}
		//re loop through budget records and update the actuals based on the opportunity values
		Budget__c[] budgetUpdates = new Budget__c[]{};
		for(Budget__c b: budgets){
			if(oppCountMap.get(b.Unique_Id__c) != null){
				//we have a value for this in the oppCountMap, so update the lead actual
				b.Lead_Actual__c = oppCountMap.get(b.Unique_Id__c);
				//add to the map for update.
				budgetUpdates.add(b);
			}
		}
		//update the budgets
		try{
			update budgetUpdates;
		}
		catch(dmlException d){
			system.debug('There was a problem updating the budgets: '+d);
		}
	}
	
	
	public static void createMissingBudgets(Budget__c[] budgets){
		//checks and creates any missing budget records based on the lead start/end times passed in the scope budget records.
		//build a list of split a and split b ids, we will use these to run a query
		Set<String> uniqueIds = new Set<String>();
		Map<String, Budget__c> budgetMap = new Map<String, Budget__c>();
		for(Budget__c b: budgets){
			uniqueIds.add(b.Split_A_Id__c);
			uniqueIds.add(b.Split_B_Id__c);
		}
		//query all budgets that have a unique id in the list generated
		for(Budget__c b: [select Id, Unique_Id__c from Budget__c where Unique_Id__c in: uniqueIds and Type__c = 'Actual']){
			//add to map for reference later
			budgetMap.put(b.Unique_Id__c, b);
		}
		Budget__c[] newBudgets = new Budget__c[]{};
		//re loop through original list, check there is a budget for both split a and split b.
		for(Budget__c b: budgets){
			//only add missing budgets for a/b if there are budget qty's specified.
			if(b.Vendor_Budget_Qty__c != null || b.OH_Budget_Qty__c != null){
				if(budgetMap.get(b.Split_A_Id__c) == null){
				//there is a budget missing, so create it.
				Budget__c newBudget = utility.createBudgetA(b); 
				newBudgets.add(newBudget);
				//add the missing budget back to the map with the relevant id.
				budgetMap.put(b.Split_A_Id__c, newBudget);
				}
				if(budgetMap.get(b.Split_B_Id__c) == null){
					//there is a budget missing, so create it.
					Budget__c newBudget = utility.createBudgetB(b);
					newBudgets.add(newBudget);
					//add the missing budget back to the map with the relvant id.
					budgetMap.put(b.Split_B_Id__c, newBudget);
				}
			}
		}
		//insert new budgets
		insert newBudgets;
	}
	
	
	public static void updateBudgetForecasts(Budget__c[] budgets){
		//takes a list of budgets, and updates their lead forecast values based on the sales forecast values
		
		//list to hold all budget unique ids.
		Set<String> uniqueIds = new Set<String>();
		
		for(Budget__c b: budgets){
			// these are the budgets that need calculating, work out a list of all related budgets that need returning.
			/*
			Date splitADate = b.Lead_Start_Date__c;
			Date splitBDate = b.Lead_End_Date__c;
			String uniqueIdA = utility.uniqueId(b.Project__c, splitADate);
			String uniqueIdB = utility.uniqueId(b.Project__c, splitBDate);
			uniqueIds.add(uniqueIdA);
			uniqueIds.add(uniqueIdB);
			*/
			//build a list of unique ids, we will then look for these ids in any realted records (Split A Id / Split B Id)
			uniqueIds.add(b.Unique_Id__c);
			
		}
		
		//Map to store budget records queried by Unique Id
		Map<String, Budget__c[]> budgetMap = new Map<String, Budget__c[]>();
		//re-query all budgets based on unique id. These are the budgets that will need updating.
		for(Budget__c b: [select Id, Split_A_Id__c, Split_B_Id__c, Project__c, Unique_Id__c, Vendor_Budget_Qty__c, Lead_Start_Date__c, Lead_End_Date__c, OH_Budget_Qty__c, Vendor_Lead_Target__c, Vendor_Lead_Target_Q1__c, Vendor_Lead_Target_Q2__c, Vendor_Lead_Target_Q3__c, OH_Lead_Target__c, OH_Lead_Target_Q1__c, OH_Lead_Target_Q2__c, OH_Lead_Target_Q3__c from Budget__c where (Split_A_Id__c in: uniqueIds or Split_B_ID__c in: uniqueIds) and Type__c = 'Actual']){
			//add them to a map by unique Id so they are easily accessibe.
			if(budgetMap.get(b.Split_A_Id__c) == null){
				//we don't have a list for this id, so create one.
				budgetMap.put(b.Split_A_Id__c, new Budget__c[]{});
			}
			if(budgetMap.get(b.Split_B_Id__c) == null){
				//we don't have a list for this id, so create one.
				budgetMap.put(b.Split_B_Id__c, new Budget__c[]{});
			}
			//at this point there is a sublist for the A and B ids, so add the budgets to the list.
			budgetMap.get(b.Split_A_Id__c).add(b);
			budgetMap.get(b.Split_B_Id__c).add(b);
		}
		
		//now looping through the original budgets, calculate the forecast values.
		
		for(Budget__c b: budgets){
			
			//integer to store lead budgets to be calculated.
			integer vendorLB = 0;
			integer vendorLBQ1 = 0;
			integer vendorLBQ2 = 0;
			integer vendorLBQ3 = 0;
			//
			integer ohLB = 0;
			integer ohLBQ1 = 0;
			integer ohLBQ2 = 0;
			integer ohLBQ3 = 0;
			
			
			//set the influencing budget records.
			
			//retreive the related records from the map.
			Budget__c[] relatedBudgets = budgetMap.get(b.Unique_Id__c);
			Budget__c budgetA;
			Budget__c budgetB;
			//only worth proceeding if there are some influencing records
			if(relatedBudgets != null){
				//loop through the context records and assign to budget a/b accordingly.
				for(Budget__c rb: relatedBudgets){
					//if the context budget Id matches the related records split a id
					if(b.Unique_Id__c == rb.Split_A_Id__c){
						budgetA = rb;
					}
					else if(b.Unique_Id__c == rb.Split_B_Id__c){
						//if the context budget Id matches the related records split b id
						budgetB = rb;
					}
				}
			}
			
			//work out how many leads from each budget we need.
			if(budgetA != null){
				//set the number of lead budget days
				integer leadBudgetDays = budgetA.Lead_Start_Date__c.daysBetween(budgetA.Lead_End_Date__c)+1;
				//how many leads to we want from Budget A?
				vendorLB += calcALeads(budgetA.Vendor_Lead_Target__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				vendorLBQ1 += calcALeads(budgetA.Vendor_Lead_Target_Q1__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				vendorLBQ2 += calcALeads(budgetA.Vendor_Lead_Target_Q2__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				vendorLBQ3 += calcALeads(budgetA.Vendor_Lead_Target_Q3__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				//
				ohLB += calcALeads(budgetA.OH_Lead_Target__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				ohLBQ1 += calcALeads(budgetA.OH_Lead_Target_Q1__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				ohLBQ2 += calcALeads(budgetA.OH_Lead_Target_Q2__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				ohLBQ3 += calcALeads(budgetA.OH_Lead_Target_Q3__c, budgetA.Lead_Start_Date__c, leadBudgetDays);
				
			}
			if(budgetB != null){
				//set the number of lead budget days
				integer leadBudgetDays = budgetB.Lead_Start_Date__c.daysBetween(budgetB.Lead_End_Date__c)+1;
				//how many leads do we want from Budget B?
				vendorLB += calcBLeads(budgetB.Vendor_Lead_Target__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				vendorLBQ1 += calcBLeads(budgetB.Vendor_Lead_Target_Q1__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				vendorLBQ2 += calcBLeads(budgetB.Vendor_Lead_Target_Q2__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				vendorLBQ3 += calcBLeads(budgetB.Vendor_Lead_Target_Q3__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				//
				ohLB += calcBLeads(budgetB.OH_Lead_Target__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				ohLBQ1 += calcBLeads(budgetB.OH_Lead_Target_Q1__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				ohLBQ2 += calcBLeads(budgetB.OH_Lead_Target_Q2__c, budgetB.Lead_End_Date__c, leadBudgetDays);
				ohLBQ3 += calcBLeads(budgetB.OH_Lead_Target_Q3__c, budgetB.Lead_End_Date__c, leadBudgetDays);
			}
			//update the relevant budget fields on the budget record
			b.Vendor_Lead_Budget__c = vendorLB;
			b.Vendor_Lead_Budget_Q1__c = vendorLBQ1;
			b.Vendor_Lead_Budget_Q2__c = vendorLBQ2;
			b.Vendor_Lead_Budget_Q3__c = vendorLBQ3;
			//
			b.OH_Lead_Budget__c = ohLB;
			b.OH_Lead_Budget_Q1__c = ohLBQ1;
			b.OH_Lead_Budget_Q2__c = ohLBQ2;
			b.OH_Lead_Budget_Q3__c = ohLBQ3;
			
			
		}
		//update the new budgets.
		update budgets;
	}
	
	//this method takes a number of leads and a date, returns a percentage of those leads based on the date supplied.
	public static integer calcALeads(decimal allLeads, date startDate, integer leadBudgetDays){
		decimal allLeadsNoNull;
		if(allLeads == null){
			allLeadsNoNull = 0;
		}
		else{
			allLeadsNoNull = allLeads;
		}
		integer aLeads = 0;
		//we have a budget a, so work out how many leads we need from this record
		date mDate = startDate.addMonths(1).toStartOfMonth().addDays(-1);
		decimal aDays = startDate.daysBetween(mDate)+1;
		system.debug('DAYS BETWEEN A: '+ aDays);
		system.debug('DAYS IN PERIOD: '+ leadBudgetDays);
		//percentage that represents the number of leads taken from this budget period.
		decimal leadPercentage = (aDays/leadBudgetDays);
		
		aLeads = integer.valueOf(math.round(leadPercentage*allLeadsNoNull));
	
	 	
	 	
		return aLeads;
	
	}
	//B Version
	public static integer calcBLeads(decimal allLeads, date endDate, integer leadBudgetDays){
		decimal allLeadsNoNull;
		if(allLeads == null){
			allLeadsNoNull = 0;
		}
		else{
			allLeadsNoNull = allLeads;
		}
		integer bLeads = 0;
		//date monthEndDate = endDate.addMonths(1).toStartOfMonth().addDays(-1);
		//we have a budget b, so work out how many leads we need from this record
		date mDate = endDate.toStartOfMonth();
		decimal bDays = mDate.daysBetween(endDate)+1;
		system.debug('DAYS BETWEEN B: '+ bDays);
		system.debug('DAYS IN PERIOD: '+ leadBudgetDays);
		//percentage that represents the number of leads taken from this budget period.
		decimal leadPercentage = (bDays/leadBudgetDays);
		
		bLeads = integer.valueOf(math.round(leadPercentage*allLeadsNoNull));
	 
		return bLeads;
	
	}
	
	
	//method processes all budgets hourly and recalcs the vendor quantities.
	public static void updateVendorBudgets(Budget__c[] budgets){
		//passed a list of budgets from a batch class.
		
		//Map to store matched opportunities.
		Map<String, Opportunity[]> budgetOppMap = new Map<String, Opportunity[]>();
		//List of budgets that need updating
		Budget__c[] budgetUpdates = new Budget__c[]{};
		//first create a list of unique ids, this will be used to create a list of opportunities that need processing.
		Set<String> uniqueIdSet = new Set<String>();
		for(Budget__c b: budgets){
			if(b.Project__c != null && b.Start_Date__c != null){
				//if these fields are null we will have a unique id.
				uniqueIdSet.add(b.Unique_Id__c);
			}
		}
		//these ids will also match ids on opportunities for this project. return these for processing.
		for(Opportunity o: [select Id, Vendor_Unique_Id__c, Amount, StageName, CloseDate from Opportunity where Vendor_Unique_Id__c in: uniqueIdSet and isWon = true]){
			//add the opportunity to the map, by it's unique id, which will sort it by project and month.
			//does the budgets unique id already exist in the map?
			if(budgetOppMap.get(o.Vendor_Unique_Id__c) == null){
				//doesn't exist in the map so initialise it
				budgetOppMap.put(o.Vendor_Unique_Id__c, new Opportunity[]{});
			}
			//at this point the map will always be initialised for the value.
			budgetOppMap.get(o.Vendor_Unique_Id__c).add(o);
		}
		
		//now the map is built, loop through the budgets and calculate the figures
		for(Budget__c b: budgets){
			//check that we do have opps in the map for this budget.
			if(budgetOppMap.get(b.Unique_Id__c) != null){
				//we have at least an initialised list, update the vendor quanities.
				//reset the vendor fields
				b.Actual_Dollar_Vendor__c = 0;
				b.Actual_Qty_Vendor__c = 0;
				for(Opportunity o: budgetOppMap.get(b.Unique_Id__c)){
					if(o.Amount != null) b.Actual_Dollar_Vendor__c += o.Amount;
					b.Actual_Qty_Vendor__c ++;
				}
				
			}
			//add the budget to list for update.
			budgetUpdates.add(b);
		}
		update budgetUpdates;
		
	}
	

}