trigger opportunityCommissionTrigger on Opportunity (after update)  {
    
    set<string> NetPriceOpps = new set<string>(), DateOpps=new Set<string>();
    Set<string> cancelledOppIds = new Set<string>();

    for(Opportunity opp : Trigger.New){

        if (opp.StageName != Trigger.oldMap.get(opp.Id).StageName && 
            (opp.StageName == 'Reservation Cancelled' || opp.StageName == 'Contract Cancelled')) {
            cancelledOppIds.add(opp.Id);
        }

        if(opp.Net_Price__c != Trigger.oldMap.get(opp.Id).Net_Price__c) NetPriceOpps.add(opp.id);

        if(opp.Unconditional_Due_Date__c != Trigger.oldMap.get(opp.Id).Unconditional_Due_Date__c
            || opp.Expected_Settlement_Date__c != Trigger.oldMap.get(opp.Id).Expected_Settlement_Date__c
            || opp.Forecast_Unconditional_Date__c != Trigger.oldMap.get(opp.Id).Forecast_Unconditional_Date__c)
            DateOpps.add(opp.Id);
    }

    // Don't perform any further updates on commissions of cancelled opportunities
    NetPriceOpps.removeAll(cancelledOppIds);
    DateOpps.removeAll(cancelledOppIds);

    // For cancelled opportunities => update status of related commissions
    LIST<Commission__c> commsToUpdate = new LIST<Commission__c>();
    for (Commission__c c : [SELECT Id, Opportunity__c, Vendor_Authority__c,Vendor_Authority__r.Commission_Paid_on_Cancellations__c
                            FROM Commission__c 
                            WHERE Opportunity__c IN :cancelledOppIds]) {
       if (c.Vendor_Authority__c != null && c.Vendor_Authority__r.Commission_Paid_on_Cancellations__c == true) {
            c.Status__c = 'Cancelled - Payable';
       } else {
            c.Status__c = 'Void - Cancellation';
       }
       commsToUpdate.add(c);
    }
    Database.Update(commsToUpdate, false);

    // Update the Settlement Date or Unconditional Date for Commissions for the opp
    System.Debug( 'Recalc Commissions: ' + DateOpps + NetPriceOpps);
    if(!NetPriceOpps.IsEmpty()|| !DateOpps.IsEmpty())
        CommissionDetail_Helper.RecalcCommission(NetPriceOpps,DateOpps);

}