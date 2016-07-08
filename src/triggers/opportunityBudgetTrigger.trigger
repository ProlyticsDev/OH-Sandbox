trigger opportunityBudgetTrigger on Opportunity (after insert, after update, before delete) {
	
	//Marketing Budgets Code
	Opportunity[] budgetOpps = new Opportunity[]{};
	String[] uniqueIds = new String[]{};
	Opportunity[] deleteBudgetOpps = new Opportunity[]{};
	if(trigger.isInsert){
		//this is a new opportunity, so as long as there is a project and Date of Enquiry, add it to a list for processing.
		for(Opportunity o: trigger.new){
			//check that the opps have the right vals
			if(o.Project__c != null && o.Date_of_Enquiry__c != null){
				//add to list for update, create unique id and add to list.
				uniqueIds.add(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c));
				budgetOpps.add(o);
			}
		}
	}
	else if(trigger.isUpdate){
		for(Opportunity o: trigger.new){
			if(o.Project__c != null && o.Date_of_Enquiry__c != null && (o.Project__c != trigger.oldMap.get(o.Id).Project__c || o.Date_of_Enquiry__c != trigger.oldMap.get(o.Id).Date_of_Enquiry__c)){
				//add to list for update, create unique id and add to list.
				uniqueIds.add(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c));
				//also include the unique id for the old budget.
				if(trigger.oldMap.get(o.Id).Project__c != null && trigger.oldMap.get(o.Id).Date_of_Enquiry__c != null){
					uniqueIds.add(utility.uniqueId(trigger.oldMap.get(o.Id).Project__c, trigger.oldMap.get(o.Id).Date_of_Enquiry__c));
				}
				budgetOpps.add(o);
			}
		}
	}
	else if(trigger.isDelete){
		for(Opportunity o: trigger.old){
			//add to list for delete, and create unique id
			uniqueIds.add(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c));
			deleteBudgetOpps.add(o);
		}
	}
	
	//run query to return all valid budgets.
	// m for marketing
	Map<String, Budget__c> mBudgetMap;
	try{
		Budget__c[] mBudgetList = [select Id, Lead_Actual__c, Project__c, Type__c, Unique_Id__c from Budget__c where Unique_Id__c in: uniqueIds and Type__c = 'Actual'];
		//system.debug('Found matching budget records: '+mBudgetList.size());
		mBudgetMap = new Map<String, Budget__c>();
		for(Budget__c b: mBudgetList){
			mBudgetMap.put(b.Unique_Id__c, b);
		}
	}
	catch(queryException q){
		//problem returning budgets
		system.debug('There was a problem returning the budgets: '+  q);
	}
	
	//cross reference and work out/create any that are missing.
	//only worth doing if it's not a delete trigger
	if(!trigger.isDelete){
		Budget__c[] newBudgets = new Budget__c[]{};
		for(Opportunity o: budgetOpps){
			//check to see if we have a budget for this opportunity.ABN__c
			if(mBudgetMap.get(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c)) == null){
				//we don't have a budget record, and we need one so create it here.
				newBudgets.add(utility.createBudget(o));
				
			}
		}
		//insert any new budgets.
		if(!newBudgets.isEmpty()){
			insert newBudgets;
			//after they have been inserted, add them back to the budget list
			for(Budget__c b: newBudgets){
				mBudgetMap.put(utility.uniqueId(b.Project__c, b.Start_Date__c), b);
			}
		}
		
		
		//process all non deletes first, where is is an update, do additional processing to modify any existing records.
		for(Opportunity o: budgetOpps){
			//get the relevant budget from the list (it should exist) and add one to the marketing actuals.
			//system.debug(mBudgetMap);
			if(mBudgetMap.get(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c)).Lead_Actual__c == null){
				mBudgetMap.get(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c)).Lead_Actual__c = 1;
			}
			else{
				mBudgetMap.get(utility.uniqueId(o.Project__c, o.Date_of_Enquiry__c)).Lead_Actual__c++;
			}
			//if this is an update, check and see if there is an old budget we need to ammend.
			
			//if it is the same as the new budget, these actions will cancel themselves out.
			if(trigger.isUpdate && trigger.oldMap.get(o.Id).Project__c != null && trigger.oldMap.get(o.Id).Date_of_Enquiry__c != null){
				//is there a budget for the old version?
				String uid = utility.uniqueId(trigger.oldMap.get(o.Id).Project__c, trigger.oldMap.get(o.Id).Date_of_Enquiry__c);
				if(mBudgetMap.get(uid) != null && mBudgetMap.get(uid).Lead_Actual__c > 0){
					mBudgetMap.get(uid).Lead_Actual__c--;
				}
			}
		} 
	}
	else if(trigger.isDelete){
		//this is running because of a delete trigger, all budgets in the map are from trigger old.  update any budgets if avalaible.
		for(Opportunity o: deleteBudgetOpps){
			//calc the unique id
			String uid = utility.uniqueId(trigger.oldMap.get(o.Id).Project__c, trigger.oldMap.get(o.Id).Date_of_Enquiry__c);
			if(mBudgetMap.get(uid) != null && mBudgetMap.get(uid).Lead_Actual__c > 0){
				mBudgetMap.get(uid).Lead_Actual__c--;
			}
		}
	}
	
	
	//update the budget records.
	update mBudgetMap.values();
	
	//default lists
	Opportunity[] newOpps = new Opportunity[]{};
	Opportunity[] updatedOpps = new Opportunity[]{};
	Opportunity[] cancelledOpps = new Opportunity[]{};
	Opportunity[] allOpps = new Opportunity[]{};
	Budget_Item__c[] newBudgetItems = new Budget_Item__c[]{};
	Budget__c[] newBudgets = new Budget__c[]{};
	Set<Id> itemIdSet = new Set<Id>();
	Id LandbookId;
	//Trigger detirmines which opportunities should get processed by the budgetsUtility Class
	if(!trigger.isDelete){
		//check to make sure there are opps to process before querying.
		for(Opportunity op: trigger.new){
			if(op.Salesperson_pa__c != null || op.Channel_Account__c != null){
				//run the code, break the loop
				//loop through the opportunities to see which ones need processing
				for(Opportunity o: [select id, Registered_File__c, Registered_File_Date__c, Project__c, Project__r.Name, OwnerId, Owner.Name, Salesperson_pa__c, Salesperson_pa__r.Name, Salesperson__r.Name, CloseDate, Amount, Channel_Account__c, Channel_Account__r.Name, isWon, StageName from Opportunity where id in: trigger.new and (Salesperson_pa__c != null or Channel_Account__c != null)]){
					//check to make sure we haven't processed this already.
		    		if(!utility.budgetOppAlreadyProcessed(o.Id)){
						if((trigger.isInsert && o.Registered_File__c) || (trigger.isUpdate && !trigger.OldMap.get(o.Id).Registered_File__c && o.Registered_File__c)){
							//process if it's a inserted opp and is won, or an updated opportunity only recently marked as isWon.
							newOpps.add(o);
							allOpps.add(o);
						}
						else if(trigger.isUpdate && o.Registered_File__c && (o.Registered_File_Date__c != trigger.oldMap.get(o.Id).Registered_File_Date__c || o.Amount != trigger.oldMap.get(o.Id).Amount || o.Salesperson_pa__c != trigger.oldMap.get(o.Id).Salesperson_pa__c || o.Channel_Account__c != trigger.oldMap.get(o.Id).Channel_Account__c)){
							//process if it's an update opportunity and was already won, but there have been some critical field changes (Amount/Owner/Close Date)
							updatedOpps.add(o);
							allOpps.add(o);
						}
						else if(trigger.isUpdate && !o.Registered_File__c && trigger.oldMap.get(o.Id).Registered_File__c){
							//process if the opportunity has been cancelled, or deleted.
							cancelledOpps.add(o);
							allOpps.add(o);
						}
		    		}
				}
				break;			
			}
		}
	}
	else{
		//check that there are opps to process before querying.
		for(Opportunity op: trigger.old){
			if(op.Salesperson_pa__c != null || op.Channel_Account__c != null){
				//run the code and break the loop.
				for(Opportunity o: [select id, Registered_File__c, Registered_File_Date__c, Project__c, Project__r.Name, OwnerId, Owner.Name, Salesperson_pa__c, Salesperson_pa__r.Name, Salesperson__r.Name, CloseDate, Amount, Channel_Account__c, Channel_Account__r.Name, isWon from Opportunity where id in: trigger.old and (Salesperson_pa__c != null or Channel_Account__c != null)]){
					cancelledOpps.add(o);
					allOpps.add(o);
				}
				break;
			}
		}
	}
	
	
	Opportunity[] changedOpps = new Opportunity[]{};
	changedOpps.addAll(newOpps);
	changedOpps.addAll(updatedOpps);
	
	//init code for budget items
	//for all the opportunities we have, work out a list of projects and a total timespan and construct the correct query.
	Date startDate = date.today();
	Date endDate = date.today();
	//budget item map, used to hold budget items by project, owner and date.
	Map<Id, Map<Id, Map<Date, Budget_Item__c>>> budgetItemMap = new Map<Id, Map<Id, Map<Date, Budget_Item__c>>>();
	Map<Id, Map<Id, Map<Date, Budget_Item__c>>> lBudgetItemMap = new Map<Id, Map<Id, Map<Date, Budget_Item__c>>>();
	//budget map, used to hold the budgets by project and date.
	Map<Id, Map<Date, Budget__c>> budgetMap = new Map<Id, Map<Date, Budget__c>>();
	Set<String> projectSet = new Set<String>();
	for(Opportunity o: allOpps){
		projectSet.add(o.Project__c);
		if(startDate == null || o.Registered_File_Date__c < startDate){
			startDate = o.Registered_File_Date__c;
		}
		if(endDate == null || o.Registered_File_Date__c > endDate){
			endDate = o.Registered_File_Date__c;
		}
		//if it's an update, check we have the old item info referenced by this opportunity
		if(trigger.isUpdate){
			projectSet.add(trigger.OldMap.get(o.Id).Project__c);
			if(startDate == null || trigger.OldMap.get(o.Id).Registered_File_Date__c < startDate){
				startDate = trigger.OldMap.get(o.Id).Registered_File_Date__c;
			}
			if(endDate == null || trigger.OldMap.get(o.Id).Registered_File_Date__c > endDate){
				endDate = trigger.OldMap.get(o.Id).Registered_File_Date__c;
			}	
		}
	}

	for(Budget__c b: [select id, Start_Date__c, End_Date__c, (select id, Agent__c, Salesperson_pa__c, Start_Date__c, End_Date__c, Landbook__c from Budget_Items__r where Type__c = 'Actual'), Project__c, Project__r.Name from Budget__c where Type__c = 'Actual' and (Project__c in: projectSet or Project__r.Name = 'Landbook') and Start_Date__c <=:endDate and End_Date__c >=:startDate]){
		//put the budget item in a map, by project, then owner, then date.
		if(budgetMap.get(b.Project__c) == null){
			//not in map, so initialise
			budgetMap.put(b.Project__c, new Map<Date, Budget__c>());
		}
		//at this point will exist in the map, add the budget for the relevant start date
		budgetMap.get(b.Project__c).put(b.Start_Date__c.toStartOfMonth(), b);
		
		for(Budget_Item__c bi: b.Budget_Items__r){
			//if(!bi.Landbook__c){
				id ownerId;
				//build up the budget items map.
				if(budgetItemMap.get(b.Project__c) == null){
					//not in map, so initialise
					budgetItemMap.put(b.Project__c, new Map<Id, Map<Date, Budget_Item__c>>());
				}
				//now exists in the map, try and find the owner
				if(bi.Agent__c != null){
					ownerId = bi.Agent__c;
					//try and find by agent
					if(budgetItemMap.get(b.Project__c).get(bi.Agent__c) == null){
						//can't find so initialise
						budgetItemMap.get(b.Project__c).put(bi.Agent__c, new Map<Date, Budget_Item__c>());
					}
				}
				else{
					ownerId = bi.Salesperson_pa__c;
					//try and find by owner
					if(budgetItemMap.get(b.Project__c).get(bi.Salesperson_pa__c) == null){
						//can't find so initialise
						budgetItemMap.get(b.Project__c).put(bi.Salesperson_pa__c, new Map<Date, Budget_Item__c>());
					}
				}
				//at this point the user level map will be created, now just add the budget item
				budgetItemMap.get(b.Project__c).get(ownerId).put(bi.Start_Date__c.toStartOfMonth(), bi);
			
			
		}
		//is the project called Landbook?
		if(b.Project__r.Name == 'Landbook'){
			landbookId = b.Project__c;
		}
		else{
			try{
				landbookId = [select Id from Project__c where Name = 'Landbook' limit 1].Id;
			}
			catch(exception e){
				Project__c landbookProject = new Project__c(Name = 'Landbook',
															City__c = 'Test', 
						                                    Description__c = 'Sample Description', 
						                                    Region__c = 'Melbourne', 
						                                    Street_Address__c = '12 Test', 
						                                    Zip_Postal_Code__c = 'Victoria',
						                                    Status__c = 'Planned');
				insert landbookProject;
				landbookId = landbookProject.Id;
			}
		}
	}
	
	//check to make sure there is a proect called landbook, if not create one.
	/*
	if(landBookId == null){
		Project__c landBookProject = new Project__c(Name = 'Landbook');
		insert landBookProject;
		landBookId = landBookProject.Id;
		//update budgetMap
		budgetMap.put(landBookProject.Id, new Map<Date, Budget__c>());
		//update budgetItemMap
		budgetItemMap.put(landBookProject.Id, new Map<Id, Map<Date, Budget_Item__c>>());
	}
	*/
	
	//generate the junction map
	
	Map<String, Budget_Junction__c> junctionMap = new Map<String, Budget_Junction__c>();
	//build the map, string is a combo of the budget item and the opp id
	for(Budget_Junction__c j: [select id, Opportunity__c, Budget_Item__c from Budget_Junction__c where Opportunity__c in: allOpps]){
		junctionMap.put(string.valueOf(j.Opportunity__c)+j.Budget_Item__c, j);
	}
	
	Budget_Junction__c[] budgetJunctions = new Budget_Junction__c[]{};
	Budget_Junction__C[] junctionsDelete = new Budget_Junction__c[]{};
	
	
	
	//for each opportunity, check first to make sure the right budget records exist and update them
	for(Opportunity o: changedOpps){
		//find the relevant budget item from the list.
		//double check that the project exits in the budget map.
		if(budgetMap.get(o.Project__c) == null){
			budgetMap.put(o.Project__c, new Map<Date, Budget__c>());
		}
		//also check that it exists in the budget item map
		if(budgetItemMap.get(o.Project__c) == null){
			//can't find in the map, so add
			budgetItemMap.put(o.Project__c, new Map<Id, Map<Date, Budget_Item__c>>());
		}
		if(budgetMap.get(o.Project__c).get(o.Registered_File_Date__c.toStartOfMonth()) == null){
			//budget doesn't exist and it should do as we will need to add items to it.
			Budget__c newBudget = new Budget__c();
			newBudget.Project__c = o.Project__c;
			newBudget.Type__c = 'Actual';
			newBudget.Start_Date__c = o.Registered_File_Date__c.toStartOfMonth();
			newBudget.End_Date__c = o.Registered_File_Date__c.addMonths(1).toStartOfMonth().addDays(-1);
			newBudget.Name = o.Project__r.Name+' '+newBudget.Start_Date__c.Month()+'-'+newBudget.Start_Date__c.year();
			newBudgets.add(newBudget);
			//add the budget back to the map, as techincallly now it exists.
			budgetMap.get(o.Project__c).put(o.Registered_File_Date__c.toStartOfMonth(), newBudget);
		}
		//actual project is updated.
		
		//No budget item for landbooks, if there isn't an item/budget item we assume they aren't on the landbook for that period.
		
	}
	//update the budgets, these are now all budgets that should need to be accessed during this transaction
	insert newBudgets;
	/*
	//update budgetMap/budgetItemMap?
	for(Budget__c b: newBudgets){
		budgetMap.get(b.Project__c).put(b.Start_Date__c, b);
		//budgetItemMap.get(b.Project__c).put(b.Id, new Map<Date, Budget_Item__c>());
		//lBudgetItemMap.get(b.Project__c).put(b.Id, new Map<Date, Budget_Item__c>());
	}
	*/
	//now all maps are updated with all budgets that may be needed, now fill in any missing budget items.
	for(Opportunity o: changedOpps){
		Id ownerID;
		String ownerName;
		if(o.Channel_Account__c != null){
			ownerId = o.Channel_Account__c;
			ownerName = o.Channel_Account__r.Name;
		}
		else{
			ownerId = o.Salesperson_pa__c;
			ownerName = o.Salesperson_pa__r.Name;
		}
		//does the budget item exist for this project/user/timeframe
		if(budgetItemMap.get(o.Project__c).get(ownerId) == null){
			//owner not found in this map for project, so add them
			budgetItemMap.get(o.Project__c).put(ownerId, new Map<Date, Budget_Item__c>());
		}
		if(budgetItemMap.get(o.Project__c).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth()) == null){
			//didn't find the budget item, so add one here
			Budget_Item__c newBudgetItem = new Budget_Item__c();
			newBudgetItem.Budget__c = budgetMap.get(o.Project__c).get(o.Registered_File_Date__c.toStartOfMonth()).Id;
			newBudgetItem.Budget__r = budgetMap.get(o.Project__c).get(o.Registered_File_Date__c.toStartOfMonth());
			newBudgetItem.Start_Date__c = o.Registered_File_Date__c.toStartOfMonth();
			newBudgetItem.End_Date__c = o.Registered_File_Date__c.addMonths(1).toStartOfMonth().addDays(-1);
			//mark as as landbook, if a landbook version of the budget item exists
			if(budgetItemMap.get(landBookId) != null && budgetItemMap.get(landBookId).get(ownerId) != null && budgetItemMap.get(landBookId).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth()) != null){
				newBudgetItem.Landbook__c = true;
			}
			//set the agent/salesperson accordingly
			if(o.Channel_Account__c != null){
				//this is a channel deal
				//set the Agent
				newBudgetItem.Agent__c = o.Channel_Account__c;
				//remove any salesperson
				newBudgetItem.Salesperson_pa__c = null;
			}
			else{
				//is an internal sale
				newBudgetItem.Salesperson_pa__c = o.Salesperson_pa__c;
				//remove any agent
				newBudgetItem.Agent__c = null;	
			}
			newBudgetItem.Name = o.Project__r.Name+' '+ownerName+' '+newBudgetItem.Start_Date__c.Month()+'-'+newBudgetItem.Start_Date__c.year();
			newBudgetItem.Type__c = 'Actual';
			//add to list for insert.
			newBudgetItems.add(newBudgetItem);
			//update the map here
			//system.debug('Budget Map Val: '+ownerId);
			BudgetItemMap.get(o.Project__c).get(ownerId).put(o.Registered_File_Date__c.toStartOfMonth(), newBudgetItem);
			
		}
	}
	insert newBudgetItems;
	
	//all budget items up to date here!!!!!!!!!!! 
	/*
	//update the budgetItemMap and (landbook) lBudgetItemMap
	for(Budget_Item__c b: newBudgetItems){
		Id ownerID;
		if(b.Agent__c != null){
			ownerId = b.Agent__c;
		}
		else{
			ownerId = b.Salesperson_pa__c;
		}
		system.debug('Budget Map Val: '+ownerId);
		BudgetItemMap.get(b.Budget__r.Project__c).get(ownerId).put(b.Start_Date__c, b);
	}
	*/
	//all maps up to date here, when creating new junction objects, all related records will exist in the maps.
	//now we'll loop through the opportunities and make sure there is a relevant junction object 
	//for each opportunity, check first to see which budget item it should be linked to
	for(Opportunity o: changedOpps){
		Budget_Item__c newBudget;
		Budget_Item__c oldBudget;
		Id ownerID;
		if(o.Channel_Account__c != null){
			ownerId = o.Channel_Account__c;
		}
		else{
			ownerId = o.Salesperson_pa__c;
		}
		//find the relevant budget item from the list.
		if(budgetItemMap.get(o.Project__c).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth()) != null){
			//found the budget item, set new budget, also flag that the item needs recalculating
			newBudget = budgetItemMap.get(o.Project__c).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth());
			ItemIdSet.add(newBudget.Id);
			//check to see if the junction exists already
			if(junctionMap.get(string.valueOf(o.Id)+newBudget.Id) == null){
				//a new junction is required.
				budgetJunctions.add(new Budget_Junction__c(Opportunity__c = o.Id, Budget_Item__c = newBudget.Id));
			}
			//if what we just updated was marked landbook, then update the primary landbook version
			if(newBudget.Landbook__c){
				if(budgetItemMap.get(landBookId).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth()) != null){
					Budget_Item__c landBookITem = budgetItemMap.get(landBookId).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth());
					//flag the item as needing recalculating
					ItemIdSet.add(landBookItem.Id);
					//the landbook project budget item exists
					//see if there is a junction object already.
					if(junctionMap.get(string.valueOf(o.Id)+landBookItem.Id) != null){
						//nothing to do, the correct relationship exists
					}
					else{
						//a new junction is required.
						budgetJunctions.add(new Budget_Junction__c(Opportunity__c = o.Id, Budget_Item__c = landBookItem.Id));
					}
				}
			}
		
		
		}
		//reset oldBudget
		oldBudget = null;
		//check trigger.old to see if there are any junction objects that need removing, the old budget should exist in the map
		if(trigger.isUpdate){
			Id oldOwner;
			//it's an update, work out who the old owner is
			if(trigger.oldMap.get(o.Id).Channel_Account__c != null){
				oldOwner = trigger.oldMap.get(o.Id).Channel_Account__c;
			}
			else{
				oldOwner = trigger.oldMap.get(o.Id).Salesperson_pa__c;
			}
			
			if(oldOwner != null && trigger.OldMap.get(o.Id).Registered_File_Date__c != null && budgetItemMap.get(trigger.OldMap.get(o.Id).Project__c).get(oldOwner).get(trigger.OldMap.get(o.Id).Registered_File_Date__c.toStartOfMonth()) != null){
				//found a budget item, check to see if it is the same as the new budget item.
				oldBudget = budgetItemMap.get(trigger.OldMap.get(o.Id).Project__c).get(oldOwner).get(trigger.OldMap.get(o.Id).Registered_File_Date__c.toStartOfMonth());
				//flag the item to show that it needs updating
				ItemIdSet.add(oldBudget.Id);
				if(oldBudget.Id != newBudget.Id){
					//the budget item the old version of the opp references is different, so needs removing.
					if(junctionMap.get(string.valueOf(o.Id)+oldBudget.Id) != null){
						junctionsDelete.add(junctionMap.get(string.valueOf(o.Id)+oldBudget.Id));
					}
					//we have detirmined that the budget item has changed, so if it is a landBook related item, try and remove that version too.
					if(oldBudget.Landbook__c){
						//is was created due to a landbook, so try and remove that one too, should exist in the map
						if(budgetItemMap.get(landBookId).get(oldOwner).get(trigger.OldMap.get(o.Id).Registered_File_Date__c.toStartOfMonth()) != null){
							Budget_Item__c oldLandBookItem = budgetItemMap.get(landBookId).get(oldOwner).get(trigger.OldMap.get(o.Id).Registered_File_Date__c.toStartOfMonth());
							//flag that the item needs recalculating
							ItemIdSet.add(oldLandBookItem.Id);
							//if a junction exists for this landbook item, then remove it.
							if(junctionMap.get(string.valueOf(o.Id)+oldBudget.Id) != null){
								junctionsDelete.add(junctionMap.get(string.valueOf(o.Id)+oldLandbookItem.Id));
							}
						}
					}
				}
			}
		}
	}
	for(Opportunity o: cancelledOpps){
		//these opportunities have been deleted or cancelled. remove their related junction objects if they exist.
		Id ownerID;
		if(o.Channel_Account__c != null){
			ownerId = o.Channel_Account__c;
		}
		else{
			ownerId = o.Salesperson_pa__c;
		}
		//find the relevant budget item from the list.
		if(budgetItemMap.get(o.Project__c) != null && budgetItemMap.get(o.Project__c).get(ownerId) != null && budgetItemMap.get(o.Project__c).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth()) != null){
			//there is a budget item for this old/deleted opportunity, see if there is a junction object.
			Budget_Item__c tempItem = budgetItemMap.get(o.Project__c).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth());
			//flag the item that it needs to be recalculated
			ItemIdSet.add(tempItem.Id);
			if(junctionMap.get(string.valueOf(o.Id)+tempItem.Id) != null){
				//delete junction!
				junctionsDelete.add(junctionMap.get(string.valueOf(o.Id)+tempItem.Id));
			}
		}
		//also look in the landbook just in case there is one to remove there as well.
		if(budgetItemMap.get(landBookId) != null && budgetItemMap.get(landBookId).get(ownerId) != null && budgetItemMap.get(landBookId).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth()) != null){
			//there is a budget item for this old/deleted opportunity in the landbook, see if there is a junction object.
			Budget_Item__c tempItem = budgetItemMap.get(landBookId).get(ownerId).get(o.Registered_File_Date__c.toStartOfMonth());
			//flag the item that it needs to be recalculated
			ItemIdSet.add(tempItem.Id);
			if(junctionMap.get(string.valueOf(o.Id)+tempItem.Id) != null){
				//junction found, so delete it as well!
				junctionsDelete.add(junctionMap.get(string.valueOf(o.Id)+tempItem.Id));
			}
		}
		
	}

	upsert budgetJunctions;
	delete junctionsDelete;
	
	//At this point all junction objects are up to date, now run an async method that runs through all Juntion Objects and Related Opportunities and Calculates The Amount Fields.
	if(!itemIdSet.isEmpty()){
		budgetUtility.updateItems2(itemIdSet);
	}
	
}