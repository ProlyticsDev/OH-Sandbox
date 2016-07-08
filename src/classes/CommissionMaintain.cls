public with sharing class CommissionMaintain {

    /****
        10 Mar 16 mark.townsend@coroma.com.au 
        Related to: Commissions Project - Sprint 6, Item 6.28
        Changed to use Ex GST
    ***/
    
        public static void GenerateRevenue( List<string> opportunities ){
    
            List<Commission__c> channelList = [SELECT Opportunity__c, Category__c, Payment_Type__c, Sequence__c, Revenue__c, Id, Amount_Excl__c
                                            FROM     Commission__c 
                                            WHERE    Status__c NOT IN ('Void - Cancellation',' Void - Other') AND
                                                     Category__c IN ('Channel','House','Oliver Hume') AND
                                                     Opportunity__c in :opportunities
                                            ORDER BY Opportunity__c, Payment_Type__c, Category__c, Sequence__c, Amount__c desc  ];
       
            //Walk the tree in reverse - if the opportunity changes or the Payment type then reset the PaidAmount to 0;
            Id opportunityId = null;
            string paymentType = null;
            double PaidAmount = 0;
            
            for(integer i = channelList.size()-1; i>=0; i--){
                 if (channelList[i].Opportunity__c != opportunityId || channelList[i].Payment_Type__c != paymentType ){
                     PaidAmount = 0;
                     opportunityId = channelList[i].Opportunity__c;
                     paymentType = channelList[i].Payment_Type__c;
                     if ( channelList[i].Category__c == 'Oliver Hume' ) channelList[i].Revenue__c = (channelList[i].Amount_Excl__c == null ? 0 : channelList[i].Amount_Excl__c)- PaidAmount;
                 } else {
                     channelList[i].Revenue__c = (channelList[i].Amount_Excl__c == null ? 0 : channelList[i].Amount_Excl__c) - PaidAmount;
                 }
                 PaidAmount = (channelList[i].Amount_Excl__c == null ? 0 : channelList[i].Amount_Excl__c);
            }
            update channelList;
        }
    
}