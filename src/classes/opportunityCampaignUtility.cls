public without sharing class opportunityCampaignUtility {
	
	//Method detirmines if inserted records need processing
	public static void associateCampaign(Opportunity[] newOpps){
		Opportunity[] opps = new Opportunity[]{};
		for(Opportunity o: newOpps){
			//do we need to process the opportunity?
			if(o.Project_Picklist__c != null && o.Date_of_Enquiry__c != null && o.Enquiry_Source__c != null){
				opps.add(o);
			}
		}
		if(!opps.isEmpty()){
			opportunityCampaignUtility.associateCampaignGeneric(opps);
		}
	}
	
	//Method determines if updated records need processing
	public static void associateCampaign(Opportunity[] newOpps, Opportunity[] oldOpps){
		Opportunity[] opps = new Opportunity[]{};
		Map<Id, Opportunity> oldMap = new Map<Id, Opportunity>(oldOpps);
		for(Opportunity o: newOpps){
			if(o.Project_Picklist__c != null && o.Date_of_Enquiry__c != null && o.Enquiry_Source__c != null && (o.Project_Picklist__c != oldMap.get(o.Id).Project_Picklist__c || o.Date_of_Enquiry__c != oldMap.get(o.Id).Date_of_Enquiry__c || o.Enquiry_Source__c != oldMap.get(o.Id).Enquiry_Source__c)){
				opps.add(o);
			}
		}
		if(!opps.isEmpty()){
			opportunityCampaignUtility.associateCampaignGeneric(opps);
		}
	
	}
	
	//Method takes a list of records that need the campaign details updating.
	public static void associateCampaignGeneric(Opportunity[] opps){
		//all opportunities passed to this method need the originating campaign updating.
		//opportunities passed in are from a before trigger, so no need to run dml to update.
		Set<String> enquirySet = new Set<String>();
		Set<String> projectSet = new Set<String>();
		Map<Id, Id> personContactMap = new Map<Id, Id>();
		Id[] accIds = new Id[]{};
		//loop through opportunities and build a list of distinct Enquiry Source.
		for(Opportunity o: opps){
			if(o.Enquiry_Source__c != null){
				enquirySet.add(o.Enquiry_Source__c);
			}
			if(o.Project_Picklist__c != null){
				projectSet.add(o.Project_Picklist__c);
			}
			if(o.AccountId != null){
				accIds.add(o.AccountId);
			}
		}
		
		//use dynamic query 
		String camQuery = 'select Id, Name, ParentId, Channels__c, StartDate, EndDate, Project__c, Project__r.Name from Campaign where isActive = true and Project__r.Name in: projectSet and Channels__c includes (';
		for(String s: enquirySet){
			camQuery += '\''+s+'\',';
		}
		//remove last instance of ' or'
		camQuery = camQuery.removeEnd(',');
		camQuery += ') order by StartDate, createdDate asc';
		
		//try and locate any campaigns relevant to the opportunities passed in.
		system.debug('camQuery: '+camQuery);
		Campaign[] allCams = database.query(camQuery);
		for(Campaign c: allCams){
			system.debug('Campaign Name:  '+c.Name);
		}
		//build a map to store campaigns by project and enquiry source.  one campaign may exist in many enquiry source categories 
		//Project: Channel/Campaign[]
		Map<String, Map<String, Campaign[]>> childCampaignMap = new Map<String, Map<String, Campaign[]>>();
		Map<String, Map<String, Campaign>> parentCampaignMap = new Map<String, Map<String, Campaign>>();
		//loop through the campaigns and build up the map.
		for(Campaign c: allCams){
			if(c.ParentId != null){
				//is a child campaign
				//does the project for this campaign exist in the map?
				if(childCampaignMap.get(c.Project__r.Name) == null){
					//doesn't exist in the map, create the submap
					childCampaignMap.put(c.Project__r.Name, new Map<String, Campaign[]>());
				}
				//at this point the parent map element exists, check to see if a submap exists for each channel
				for(String s: c.Channels__c.split(';')){
					//does the channel exist for this project in the Map.
					if(childCampaignMap.get(c.Project__r.Name).get(s) == null){
						//doesn't exist, so initialise submap
						childCampaignMap.get(c.Project__r.Name).put(s, new Campaign[]{});
					}
					//at this point, the channel does exist in the Map, add the campaign.
					childCampaignMap.get(c.Project__r.Name).get(s).add(c);
				}	
			}
			else{
				//potentially is a parent campaign, so add to the campaign to the parent map.
				//does an element exist in the map for this project?
				if(parentCampaignMap.get(c.Project__r.Name) == null){
					//no it doesn't so create it.
					parentCampaignMap.put(c.Project__r.Name, new Map<String, Campaign>());	
				}
				//at this point, the project does exist in the map with the project key.
				//add a new row to the submap for each channel
				for(String s: c.Channels__c.split(';')){
					parentCampaignMap.get(c.Project__r.Name).put(s, c);
				}
			}
		}
		
		//do a quick check to see which opportunities we are missing campaigns for.
		for(Opportunity o: opps){	
			if(childCampaignMap.get(o.Project_Picklist__c) != null && childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c) != null){
				//found campaigns relevant to the project and channel, loop through campaigns returned to see if there is a match.
				Campaign[] sourceCampaigns = childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c);
				Campaign[] newChildCampaigns = new Campaign[]{};
				boolean hasFound = false;
				for(Campaign c: sourceCampaigns){
					//start working back from 8 weeks to find a match.
					//Set the initial date of enquiry.
					Date enqDate = o.Date_of_Enquiry__c;
					//boolean hasFound = false;
					for(Integer i = 0; i <8; i++){
						if(c.StartDate<= enqDate && c.EndDate >= enqDate){
							//there is a match, so populate the originating campaign.
							o.Originating_Campaign__c = c.Id;
							o.CampaignId = c.Id;
							//no need to continue
							hasFound = true;
							break;	
						}
						else{
							//didn't find a match using this date, roll back a week and try again.
							enqDate = enqDate.addDays(-7);
						}
					}
				}
				//SalesFix : Change Request from Carrie Hallman - no need to create any new campaigns - link to most recent child campaign in the list
				if(!hasFound){
					Campaign lastCampaign = sourceCampaigns[sourceCampaigns.size()-1];
					o.Originating_Campaign__c = lastCampaign.Id;
					o.CampaignId = lastCampaign.Id;	
				}
				//now we have checked all campaigns, check to see if we found a match.
				//SalesFix : Change Request from Carrie Hallman - no need to create any new campaigns
				/*
				if(!hasFound){
					//no child campaign was found, see if there is at least a parent campaign.
					if(parentCampaignMap.get(o.Project_Picklist__c) == null && parentCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c) == null){
						//no parent campaign found for project/channel, so create one.
						Campaign newParent = new Campaign(Name = o.Project_Picklist__c+' - '+o.Enquiry_Source__c, Channels__c = o.Enquiry_Source__c, Project__c = o.Project__c, isActive = true);
						//add back to the parent map.
						//check to see if there is an element for the project in the map
						if(parentCampaignMap.get(o.Project_Picklist__c) == null){
							//doesn't exist so create it
							parentCampaignMap.put(o.Project_Picklist__c, new Map<String, Campaign>());
						}
						//at this point the project will exist in the map, so just add the campaign to the submap with the enquiry source as the key.
						parentCampaignMap.get(o.Project_Picklist__c).put(o.Enquiry_Source__c, newParent);
					}
					//at this point the parent will exist, albeit potentially not inserted, create the child campaign.
					
					//parent will get populated later
					//logical thing to do would be to put the child in the Map
					newChildCampaigns.add(createNewChild(o));
					//childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c).add(newChild);
				}
				
				//outside the loop add the new child campaigns back to the sourceCampaign list
				childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c).addAll(newChildCampaigns);
				*/
			}
			else{
				//we couldn't find a match against existing campaigns, try and match a parent campaign
				if(parentCampaignMap.get(o.Project_Picklist__c) != null && parentCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c) != null){
					//SalesFix : Change Request from Carrie Hallman - no need to create child campaigns - link to matching parent campaign
					Campaign matchingParentCampaign = parentCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c);
					o.Originating_Campaign__c = matchingParentCampaign.Id;
					o.CampaignId = matchingParentCampaign.Id;	

					//we have the parent campaign for the project
					//create child
					//does the project exist in the map
					//SalesFix : Change Request from Carrie Hallman - no need to create any new campaigns
					/*
					if(childCampaignMap.get(o.Project_Picklist__c) == null){
						//doesn't exist so add it and init submap
						childCampaignMap.put(o.Project_Picklist__c, new Map<String, Campaign[]>());
					}
					//at this point, the project will always exist in the map.
					//does a list of Campaigns exist for the enquiry source?
					if(childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c) == null){
						//doesn't so add it
						childCampaignMap.get(o.Project_Picklist__c).put(o.Enquiry_Source__c, new Campaign[]{});
					}
					//at this point, it is safe to add the new child to the map
					childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c).add(createNewChild(o));
					*/
				}
				/*
				else{
					//SalesFix : Change Request from Carrie Hallman - no need to create any new campaigns
					//create parent
					Campaign newParent = new Campaign(Name = o.Project_Picklist__c+' - '+o.Enquiry_Source__c, Channels__c = o.Enquiry_Source__c, Project__c = o.Project__c, isActive = true);
					//check to see if there is an element for the project in the map
					if(parentCampaignMap.get(o.Project_Picklist__c) == null){
						//doesn't exist so create it
						parentCampaignMap.put(o.Project_Picklist__c, new Map<String, Campaign>());
					}
					//at this point the project will exist in the map, so just add the campaign to the submap with the enquiry source as the key.
					parentCampaignMap.get(o.Project_Picklist__c).put(o.Enquiry_Source__c, newParent);
					//create child
					//does the project exist in the map
					if(childCampaignMap.get(o.Project_Picklist__c) == null){
						//doesn't exist so add it and init submap
						childCampaignMap.put(o.Project_Picklist__c, new Map<String, Campaign[]>());
					}
					//at this point, the project will always exist in the map.
					//does a list of Campaigns exist for the enquiry source?
					if(childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c) == null){
						//doesn't so add it
						childCampaignMap.get(o.Project_Picklist__c).put(o.Enquiry_Source__c, new Campaign[]{});
					}
					//at this point, it is safe to add the new child to the map
					childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c).add(createNewChild(o));
				}
				*/
			}
		}
		//update any parent campaigns.
		//SalesFix : Change Request from Carrie Hallman - no need to create any new campaigns
		/*
		Campaign[] parentsInsert = new Campaign[]{};
		for(Map<String, Campaign> cMap: parentCampaignMap.values()){
			for(Campaign c: cMap.values()){
				if(c.Id == null){
					//must be new, so add to list for insert.
					parentsInsert.add(c);
				}
			}
		}
		//insert the new parent campaigns
		insert parentsInsert;
		system.debug('Inserted '+parentsInsert.size()+' parent campaigns');
		//loop through parentsInsert, and build a list of related project ids
		Id[] projectIds = new Id[]{};
		for(Campaign c: parentsInsert){
			projectIds.add(c.Project__c);
		}

		//return the projects and the related marketing notification information
		Map<Id, Project__c> projectMap = new Map<Id, Project__c>([select Id, Name, Marketing_Notifications__c from Project__c where Id in: projectIds]);
		
		//generate a task for each new campaign, and assign to the marketing notifications user on the related project record.
		Task[] taskList = new Task[]{};
		for(Campaign c: parentsInsert){
			if(projectMap.get(c.Project__c) != null && projectMap.get(c.Project__c).Marketing_Notifications__c != null){
				//owner found, so create task.
				Task t = new Task();
				t.Subject = 'No Matching Parent Campaign – Please Review';
				String tBody = 'The Opportunity to Campaign auto-association failed to find a matching Parent Campaign for the following Opportunity: \n\n';
				//tBody +='Date of Enquiry: '+
				tBody += 'Project: '+projectMap.get(c.Project__c).Name+'\n';
				tBody+=  'New Campaign: '+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+c.Id+'\n\n';
				tBody+= 'The new Parent Campaign above has been automatically created. Please review the details of this record and update as required. You should also proceed to create any related Child Campaigns to improve Campaign ROI reporting.\n\n';
				tBody+='This is an automated task created from the CRM. For further details please contact your System Administrator.';
				t.OwnerId = projectMap.get(c.Project__c).Marketing_Notifications__c;
				t.Status = 'In Progress';
				t.WhatId = c.Id;
				t.ActivityDate = date.today();
				taskList.add(t);
			}
		}
		
		//insert those tasks.
		if(!taskList.isEmpty()){
            Database.DMLOptions dmlo = new Database.DMLOptions();
            dmlo.EmailHeader.triggerUserEmail = true;
            database.insert(taskList, dmlo);
        }
		
		//double check that the associated map campaigns get updated.
		for(Map<String, Campaign> cMap: parentCampaignMap.values()){
			for(Campaign c: cMap.values()){
				system.assert(c.Id != null);
			}
		}
		
		//list of child campaigns for insert
		Campaign[] childInsert = new Campaign[]{};
		//update the new child campaigns with the parent id, and insert them.
		for(String projectName: childCampaignMap.keySet()){
			//return the submap for the projectname
			Map<String, Campaign[]> submap = childCampaignMap.get(projectName);
			for(Campaign[] cam: subMap.values()){
				for(Campaign c: cam){
					if(c.Id == null){
						c.ParentId = parentCampaignMap.get(projectName).get(c.Channels__c).Id;
						childInsert.add(c);
					}
				}
			}
		}
		//insert the new child campaigns
		insert childInsert;
		*/
		//check that the campaign map has had it's ids updated, add the campaign Id to a list for querying later
		Id[] allCamIds = new Id[]{};
		//SalesFix : Change Request from Carrie Hallman - create all ids from already assigned opportunity campaign ids
		for(Opportunity o: opps){
			if(String.isNotBlank(o.CampaignId))
				allCamIds.add(o.CampaignId);	
		}
		/*
		for(String projectName: childCampaignMap.keySet()){
			//return the submap for the projectname
			Map<String, Campaign[]> submap = childCampaignMap.get(projectName);
			for(Campaign[] cam: subMap.values()){
				for(Campaign c: cam){
					system.assert(c.Id != null);
					allCamIds.add(c.Id);
				}
			}
		}
		*/
		//make one final pass of the opps and update the originating source.
		//we'll need some person account contact ids as well to create the campaign members
		if(!accIds.isEmpty()){
			for(Account a: [select Id, PersonContactId from Account where Id in: accIds]){
				if(a.PersonContactId != null){
					personContactMap.put(a.Id, a.PersonContactId);
				}
			}
		}
		
		//Also build a map of campaigns and there members
		Map<Id, Set<Id>> memberMap = new Map<Id, Set<Id>>();
		if(!allCamIds.isEmpty()){
			//we have some campaigns to process, so build out the map.
			for(CampaignMember c: [select Id, CampaignId, ContactId from CampaignMember where CampaignId in: allCamIds and ContactId in: personContactMap.values()]){
				//check to see if the outer map exists.
				if(memberMap.get(c.CampaignId) == null){
					//doesn't exist so create.
					memberMap.put(c.CampaignId, new Set<Id>());
				}
				//at this point the outer value will exist in the map.
				//add the member to the map for that campaign
				memberMap.get(c.CampaignId).add(c.ContactId);
			}
		}
		
		CampaignMember[] campaignMembers = new CampaignMember[]{};
		//SalesFix : Change Request from Carrie Hallman - no need to loop & match again. create the missing campaign members
		for(Opportunity o: opps){
			if(personContactMap.get(o.AccountId) != null){
				Id cId = o.Originating_Campaign__c;
				//we have a contact id for them, check that they don't exist for this campaign already.
				if(String.isNotBlank(cId) && (memberMap.get(cId) == null || !memberMap.get(cId).contains(personContactMap.get(o.AccountId)))){
					//don't exist for the campaign, so add them
					CampaignMember newMember = new CampaignMember(CampaignId = cId, ContactId = personContactMap.get(o.AccountId), Status = 'Responded');
					campaignMembers.add(newMember);
					//add the member to the map to prevent further errors.
					if(memberMap.get(cId) == null){
						//create the outer map member
						memberMap.put(cId, new Set<Id>());
					}
					//at this point, the outer map will exist, just add the member id
					memberMap.get(cId).add(personContactMap.get(o.AccountId));
				}
			}
		}
		/*
		//SalesFix : Change Request from Carrie Hallman - no need to loop & match again
		for(Opportunity o: opps){
			//debug the opp account id and the campaign id.
			system.debug('Opp Account is: '+o.AccountId);
			if(childCampaignMap.get(o.Project_Picklist__c) != null && childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c) != null){
				//found campaigns relevant to the project and channel, loop through campaigns returned to see if there is a match.
				for(Campaign c: childCampaignMap.get(o.Project_Picklist__c).get(o.Enquiry_Source__c)){
					system.debug('Opp Campaign is: '+c.Id);
					//start working back from 8 weeks to find a match.
					//Set the initial date of enquiry.
					Date enqDate = o.Date_of_Enquiry__c;
					for(Integer i = 0; i <7; i++){
						if(c.StartDate<= o.Date_of_Enquiry__c && c.EndDate >= o.Date_of_Enquiry__c){
							//there is a match, so populate the originating campaign.
							o.Originating_Campaign__c = c.Id;
							o.CampaignId = c.Id;
							//set a campaign member here.
							if(personContactMap.get(o.AccountId) != null){
								//we have a contact id for them, check that they don't exist for this campaign already.
								if(memberMap.get(c.Id) == null || !memberMap.get(c.Id).contains(personContactMap.get(o.AccountId))){
									//don't exist for the campaign, so add them
									CampaignMember newMember = new CampaignMember(CampaignId = o.Originating_Campaign__c, ContactId = personContactMap.get(o.AccountId), Status = 'Responded');
									campaignMembers.add(newMember);
									//add the member to the map to prevent further errors.
									if(memberMap.get(c.Id) == null){
										//create the outer map member
										memberMap.put(c.ID, new Set<Id>());
									}
									//at this point, the outer map will exist, just add the member id
									memberMap.get(c.Id).add(personContactMap.get(o.AccountId));
								}
							}
							//no need to continue
							break;	
						}
						else{
							//didn't find a match using this date, roll back a week and try again.
							enqDate.addDays(-7);
						}
					}
				}
			}
		}
		*/
		//insert the Campaign Members
		if(!campaignMembers.isEmpty()){
			Database.insert(campaignMembers,false);
		}
	}
	
	public static Campaign createNewChild(Opportunity o){
		Campaign newChild = new Campaign();
		newChild.Name = o.Project_Picklist__c+' - '+o.Enquiry_Source__c+' - '+o.Date_of_Enquiry__c.Year()+'-'+o.Date_of_Enquiry__c.Month();
		system.debug('New Child Campaign Created with Name: '+newChild.Name);
		newChild.StartDate = o.Date_of_Enquiry__c.toStartofMonth();
		newChild.EndDate = o.Date_of_Enquiry__c.addMonths(1).toStartOfMonth().addDays(-1);
		newChild.Channels__c = o.Enquiry_Source__c;
		newChild.Project__c = o.Project__c;
		newChild.isActive = true;
		
		return newChild;
	}
	
}