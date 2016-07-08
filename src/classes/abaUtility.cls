public with sharing class abaUtility {
  //Utility class that handles the heavy lifting of aba generation.
   
  /*
  public static aba[] createABAS(Journal__c[] journals, string description){
    //method takes a list of journal entries and returns a series aba objects.
    aba[] abas = new aba[]{};
    //Sort the journals into groups based on the trust account they are associated to
    Map<Id, Journal__c[]> journalMap = new Map<Id, Journal__c[]>();
    for(Journal__c j: journals){
      if(journalMap.get(j.Trust_Account__c) == null){
        //doesn't exist in the journal map, so add it.
        journalMap.put(j.Trust_Account__c, new Journal__c[]{});
      }
      //at this point the trust account entry exists in the map, add the journal entry.
      journalMap.get(j.Trust_Account__c).add(j);
      
    }
    //we now have a map of journals by trust account. For each of these, generate an aba.
    for(Journal__c[] js: journalMap.values()){
      aba newAba = createABA(js, description);
      //newAba.abaString = createABAString(js, description);
      //take the name from the first journal trust account name.
      //string abaName = js[0].Trust_Account__r.Name + date.today().format();
      //newAba.abaName = abaName;
      //add the aba to a list
      abas.add(newAba);
    }
    return abas;
  }
  */

    /*public static aba[] createABAReceipts(Receipt__c[] journals, Map<Id, Bank_Account__c> bulkPaymentToBankAccount, Map<Id, createJournalTransactionsExtension.TrustAccountWrapper> trustAccounts, boolean isPreview){
    aba[] abas = new aba[]{};
    Map<Trust_Account__c, Receipt__c[]> journalMap = new Map<Trust_Account__c, Receipt__c[]>();
    for(Receipt__c j: journals){
      if(journalMap.get(trustAccounts.get(j.Trust_Account__c).trustAccount) == null){
        journalMap.put(trustAccounts.get(j.Trust_Account__c).trustAccount, new Receipt__c[]{});
      }
      journalMap.get(trustAccounts.get(j.Trust_Account__c).trustAccount).add(j);
      
    }

    for(Trust_Account__c ta: journalMap.keySet()){
      aba newAba = createABAForReceipts(journalMap.get(ta), bulkPaymentToBankAccount, ta, trustAccounts.get(ta.Id).abaReference, isPreview);
      abas.add(newAba);
    }
    return abas;
  }*/
    
    public static aba[] createABAReceipts2(Map<createJournalTransactionsExtension.TrustAccountWrapper, List<createJournalTransactionsExtension.PaymentWrapper>> transactions, Map<Id, Bank_Account__c> bulkPaymentToBankAccount, boolean isPreview){
    aba[] abas = new aba[]{};
    Map<Trust_Account__c, Receipt__c[]> journalMap = new Map<Trust_Account__c, Receipt__c[]>();
    /*for(Receipt__c j: journals){
      if(journalMap.get(trustAccounts.get(j.Trust_Account__c).trustAccount) == null){
        journalMap.put(trustAccounts.get(j.Trust_Account__c).trustAccount, new Receipt__c[]{});
      }
      journalMap.get(trustAccounts.get(j.Trust_Account__c).trustAccount).add(j);
      
    }*/

    for(createJournalTransactionsExtension.TrustAccountWrapper tw: transactions.keySet()){
      aba newAba = createABAForReceipts2(transactions.get(tw), bulkPaymentToBankAccount, tw.trustAccount, tw.abaReference, isPreview);
      abas.add(newAba);
    }
        
        
    return abas;
  }
    
    public static aba createABAForReceipts2(List<createJournalTransactionsExtension.PaymentWrapper> payments, Map<Id, Bank_Account__c> bulkPaymentToBankAccount, Trust_Account__c trustAccount, string description, boolean isPreview){
    //set some vars
    aba newAba = new aba();
        newAba.trustAccount = trustAccount;
        String[] errorLogs = new String[]{};
        String[] detailRecords = new String[]{};
        integer totalAmount = 0;
        integer recordCount = 0;
        string abaString;
        
    string abaName = trustAccount.Name+' '+date.today().format();
    Receipt__c[] updatedPayments = new Receipt__c[]{};
    //This aba will be processed from 1 specific trust account.
    //Build the header
    string bankCode = trustAccount.Bank_Code__c;
    string nos = trustAccount.Name_of_Use_Text__c;
    string nosn =  trustAccount.Name_of_Use_Number__c;
        //TODO: Validate that we have the right data to generate the header.
    if(bankCode != null && nos != null && nosn != null){
      //continue as we have the description details
      string descString = descPartOne()+descPartTwo(bankCode)+descPartThree()+descPartFour(nos)+descPartFive(nosn)+descPartSix(description)+descPartSeven(date.today())+descPartEight();
          //must be 120 characters
          system.assertEquals(120, descString.length(), descString);
          //loop through the journals and generate the entries.
          for(createJournalTransactionsExtension.PaymentWrapper p: payments){
                //first check the account has the relevant details.
              boolean isValid = true;
              string errorString = '';
              string bsb;
              string accNo;
              integer xAmount;
              string xReference;
              string accName;
              string traceBsb;
              string traceAccNo;
              string traceAccName;
              
                
                //check trace record and account number
        //Receipt__c paymentWithBankDetalis = bulkPaymentToBankAccount.get(j.Bulk_Payment__c);   
        Bank_Account__c bankAccount =  bulkPaymentToBankAccount.get(p.payment.Id);
              if(/*trustAccount != null && trustAccount.Bank_Account__r != null*/ /*paymentWithBankDetalis != null && paymentWithBankDetalis.Bank_Account__r != null*/bankAccount != null){
                 //trace record found
                 if(/*trustAccount.Bank_Account__r.BSB_Number__c != null*//*paymentWithBankDetalis.Bank_Account__r.BSB_Number__c != null*/bankAccount.BSB_Number__c != null){
                      bsb = bankAccount.BSB_Number__c;//paymentWithBankDetalis.Bank_Account__r.BSB_Number__c;//trustAccount.Bank_Account__r.BSB_Number__c;
                      //there is a bsb check it is in the right format.
                      if(bsb.length() == 7 && bsb.substring(3,4) == '-' && bsb.substring(0,3).isNumeric() && bsb.substring(4,7).isNumeric()){
                          //the traceBSB is the correct format so continue
                      }
                      else if(bsb.length() == 6  && bsb.isNumeric()){
                        //we have a 6 digit bsb number, so add the - in the right place.
                         bsb = bsb.subString(0, 3)+'-'+bsb.subString(3,6);
                        //bsb is now in the correct format so continue.
                    }
                      else{
                          isValid = false;
                          errorString += 'The Trust Account BSB is not the correct format: '+bsb+'\n';
                      }
                  }
                  else{
                      isValid = false;
                      errorString += 'Trust Account BSB has not been supplied \n';
                  }
                  //check account number
                  if(/*trustAccount.Bank_Account__r.Bank_Account_Number__c != null*//*paymentWithBankDetalis.Bank_Account__r.Bank_Account_Number__c != null*/bankAccount.Bank_Account_Number__c != null){
                      accNo = bankAccount.Bank_Account_Number__c;//paymentWithBankDetalis.Bank_Account__r.Bank_Account_Number__c;//trustAccount.Bank_Account__r.Bank_Account_Number__c;
                      //check it is in the right format.
                      if(accNo.length() <= 9){
                      
                      }
                      else{
                          isValid = false;
                          errorString += 'Trust Account Number is too long: '+accNo+'\n';
                      }
                  }
                  else{
                      //no account number
                      isValid = false;
                      errorString += 'No Trust Account Number specified\n';
                  }
                  //check that the account name is valid
                  if(/*trustAccount.Bank_Account__r.Name != null*//*paymentWithBankDetalis.Bank_Account__r.Name != null*/bankAccount.Name != null){
                      accName = bankAccount.Name.left(32).toUpperCase(); //paymentWithBankDetalis.Bank_Account__r.Name.left(32).toUpperCase();//trustAccount.Bank_Account__r.Name.left(32).toUpperCase();
                  }
                  else{
                      //no account name
                      isValid = false;
                      errorString +='No Trust Account Name supplied\n';
                  }
                 
              }
              else{
                  isValid = false;
                  errorString += 'Cannot find Trust Account details\n';
              } 
                
                
                
              //check the amount is valid
              if(p.sumAmount != null){
                  //the amount is in cents, so *100
                  xAmount = (p.sumAmount *100).intValue();
                  if(string.valueOf(xAmount).length() <= 10){
                      //ok to continue
                  }
                  else{
                      //too long
                      isValid = false;
                      errorString += 'Transaction Amount value is too large: '+p.sumAmount+'\n';
                  }
              }
              else{
                  //there is no amount to process
                  isValid = false;
                  errorString += 'No Journal Amount provided.';
              }
              //check that the account name is valid
              /*if(trustAccount.Bank_Account__r.Name != null){
                  accName = trustAccount.Bank_Account__r.Name.left(32).toUpperCase();
              }
              else{
                  //no account name
                  isValid = false;
                  errorString +='No Bank Account Name supplied\n';
              }*/
              
              //check there is a reference.
              
              if(p.reference != null){
                  xReference = p.reference.toUpperCase();
              }
              else{
                if(trustAccount.Bank_Account__r.Name != null && trustAccount.Bank_Account__r.BSB_Number__c != null){
                  xReference = 'EFT '+trustAccount.Bank_Account__r.Name.toUpperCase()+' '+trustAccount.Bank_Account__r.BSB_Number__c.toUpperCase().replaceAll('-','');
                }
                else{
                    xReference = 'EFT PAYMENT';
                }
              }
              xReference = xReference.left(18);
              //check the reference has valid characters
              if(!xReference.isAlphanumericSpace()){
                  //invalid characters
                  isValid = false;
                  errorString += 'The Reference: '+xReference+' contains invalid characters' ;
              }
             
                //check bsb
              if(trustAccount.Bank_Account__r.BSB_Number__c != null){
                  traceBsb = trustAccount.Bank_Account__r.BSB_Number__c;
                  //there is a bsb check it is in the right format.
                  if(traceBsb.length() == 7 && traceBsb.substring(3,4) == '-' && traceBsb.substring(0,3).isNumeric() && traceBsb.substring(4,7).isNumeric()){
                      //the BSB is the correct format so continue
                  }
                  else if(traceBsb.length() == 6  && traceBsb.isNumeric()){
                    //we have a 6 digit bsb number, so add the - in the right place.
                    traceBsb = traceBsb.subString(0, 3)+'-'+traceBsb.subString(3,6);
                    //bsb is now in the correct format so continue.
                  }
                  else{
                      isValid = false;
                      errorString += 'The BSB is not the correct format: '+traceBsb+'\n';
                  }
              }
              else{
                  isValid = false;
                  errorString += 'BSB has not been supplied \n';
              }
              //check account number
              if(trustAccount.Bank_Account__r.Bank_Account_Number__c != null){
                  traceAccNo = trustAccount.Bank_Account__r.Bank_Account_Number__c;
                  //check it is in the right format.
                  if(traceAccNo.length() <= 9){
                  
                  }
                  else{
                      isValid = false;
                      errorString += 'Bank Account Number is too long: '+traceAccNo+'\n';
                  }
              }
              else{
                  //no account number
                  isValid = false;
                  errorString += 'No Bank Account Number specified\n';
              }
                    //check that the account name is valid
                  if(trustAccount.Bank_Account__r.Name != null){
                      traceAccName = trustAccount.Bank_Account__r.Name.left(32).toUpperCase();
                  }
                  else{
                      //no account name
                      isValid = false;
                      errorString +='No Trust Account Name supplied\n';
                  }
          
                
                
              //all checks are complete, if the entry is valid then construct the record.
              if(isValid){
                  //use the detail methods to produce the correct formats.
                  string lineItem = detailPartOne(bsb, accNo)+detailPartTwo(string.valueOf(xAmount))+detailPartThree(accName)+detailPartFour(xReference)+detailPartFive(traceBsb, traceAccNo, traceAccName)+detailPartSix();
                  detailRecords.add(lineItem);
                  //must be 120 characters
                  system.assertEquals(120, lineItem.length());
                  
                  //update the totals
                  totalAmount += xAmount;
                  recordCount ++;
                  //update the remittance status, only set if it's not a preview
                  if(!isPreview){
                    //j.Remittance_Advice_Status__c = 'Due';
                  }
                  updatedPayments.add(p.payment);
                  
              }
              else{
                  //not valid, so add error string to a list.
                  errorString = 'Transaction could not be processed for: '+trustAccount.Bank_Account__r.Name+': '+p.payment.Name+'\n' +errorString;
                  errorLogs.add(errorString);
              }
          }
          //compile the body
          string bodyString = '';
          
          if(detailRecords != null && !detailRecords.isEmpty()){
              for(String s: detailRecords){
                  bodyString +='\r\n'+s;
              }
              //generate the file total record.
              string valueString = string.valueOf(totalAmount);
              string totalsString = totalPartOne()+totalPartTwo(valueString)+totalPartThree(valueString)+totalPartFour()+totalPartFive()+totalPartSix(recordCount)+totalPartSeven();
              //must be 120 characters
              system.assertEquals(120, totalsString.length());
              //create aba
              abaString = descString+bodyString+'\r\n'+totalsString;
                         
          }
          newAba.abaString = abaString;
          newAba.paymentlReceipts = updatedPayments;
    }
    else{
      //didn't have the correct descriptive details.
          errorLogs.add('The Trust Account doesn\'t have the correct ABA information');
      
    }
    newAba.abaName = abaName;
    if(!errorLogs.isEmpty()){
      newAba.errors = errorLogs;
      //otherwise the list remains null
    }
    return newAba;
    
  }
    
    public class aba{
    //contains all the information required to create an ABA document
    public string abaString{get; set;}
    public string abaName{get; set;}
        
        //TODO: Depricated
    public Journal__c[] journals;
        
        public Receipt__c[] journalReceipts;
        public Receipt__c[] paymentlReceipts;
        public Trust_Account__c trustAccount;
        
    public String[] errors{get; set;}
    
    public aba(){
      journals = new Journal__c[]{};
            journalReceipts = new Receipt__c[]{};
            paymentlReceipts = new Receipt__c[]{};
      errors = new String[]{};
    }
  }
  
  /*Descriptive part methods */
    public static string descPartOne(){
        string partOne = '0                 01';
        //make sure we are returning the right number of characters
        system.assertEquals(20, partOne.length());
        return partOne;
    }
    
    //part two is the financial institution
    public static string descPartTwo(string bankCode){
        string fi = bankCode;
        fi = fi.toUpperCase();
        //check that the financial institution is 3 characters long.
        system.assertEquals(3, fi.length());
        return fi;
    }
    
    //part three is a blank section
    public static string descPartThree(){
        string partThree = '       ';
        system.assertEquals(7, partThree.length());
        return partThree;
    }
    
    //part four is name of use characters
    public static string descPartFour(string nos){
        string partFour = nos;
        partFour = partFour.toUpperCase();
        //blank fill to 26 chars
        if(partFour.length() < 26){
            integer blankFill = 26 - partFour.length();
            for(integer i = 0; i < blankFill; i++){
                partFour +=' ';
            }
        }
        //check that it is 26 characters long
        system.assertEquals(26, partFour.length());
        
        return partFour;
    }
    
    //part five is name of use numbers
    public static string descPartFive(string nosn){
        string partFive = nosn;
        //must be numeric
        system.assertEquals(true, nosn.isNumeric());
        //must be right justified and zero filled.
        if(partFive.length() < 6){
            integer zeroFill = 6 - partFive.length();
            for(integer i = 0; i < zeroFill; i++){
                partFive = '0'+partFive;
            }
        }
        //check that it is 6 characters long
        system.assertEquals(6, partFive.length());
        return partFive;
    }
    
    //part six is the description
    public static string descPartSix(string description){
        string partSix = description;
        if(partSix != null && partSix.trim() != ''){
            //must be uppercase.
            partSix = partSix.toUpperCase();
            //must be 12 characters long
            if(partSix.length() < 12){
                integer blankFill = 12 - partSix.length();
                for(integer i = 0; i < blankFill; i++){
                    partSix += ' ';
                }
            }
            else if(partSix.length() > 12){
                //trim to 12 characters.
                partSix = partSix.left(12);
            }
            //assert string is 12 characters
            system.assertEquals(12, partSix.length());
            return partSix;
        }
        else{
//TODO            //add error message to page, description is required.
            return null;
        }
    
    }
    
    //part seven is the date the transactions are to be processed.
    public static string descPartSeven(date abaDate){
        date processDate = abaDate;
         if(processDate != null){
             //convert the date into the right format DDMMYY
             dateTime processTime = dateTime.newInstance(processDate, time.newInstance(0,0,0,0));
             string partSeven = processTime.format('ddMMyy');
             //must be six characters
             system.assertEquals(6, partSeven.length());
             return partSeven;
         }
         else{
             //add error to page
             return null;
         }
    }
    
    //final blank fill characters
    public static string descPartEight(){
        string partEight = '                                        ';
        //must be 40 characters
        system.assertEquals(40, partEight.length());
        return partEight;
    }
    
    /* End Descriptive Methods  */


/* Detail Part Methods */
    
    //returns the account bsb number to be credited.
    public static string detailPartOne(string bsb, string accNo){
        string partOne = '1';
        //add the bsb
        partOne += bsb;
        //format the account number if required.
        if(accNo.length() < 9){
            integer accDiff = 9 - accNo.length();
            for(integer i = 0; i < accDiff; i++){
                accNo = ' '+accNo;
            }
        }
        //add the account number
        partOne += accNo;
        //check that it is the right length before returning
        system.assertEquals(17, partOne.length());
        return partOne;
    }
    
    //returns the amount being credited.
    public static string detailPartTwo(string xAmt){
        string partTwo = ' ';
        //add the Transaction code
        partTwo += '50';
        //add the amount
        if(xAmt.length() < 10){
            integer amtFill = 10 - xAmt.length();
            for(integer i = 0; i < amtFill; i++){
                xAmt = '0'+xAmt;
            }
        }
        //add xAmt to partTwo
        partTwo += xAmt;
        //check that it's the right length
        system.assertEquals(13, partTwo.length());
        return partTwo;
    
    }
    
    //returns the account title being credited
    public static string detailPartThree(string aName){
        string partThree = aName.left(32);
        //make sure it's the correct length
        if(partThree.length() < 32){
            integer nameFill = 32 - partThree.length();
            for(integer i = 0; i < nameFill; i++){
                partThree +=' ';
            }
        }
        //check part three is thr right length
        system.assertEquals(32, partThree.length());
        return partThree;
    }
    
    //returns the lodgement reference
    public static string detailPartFour(string xRef){
        string partFour = xRef.left(18);
        //make sure it's the correct length
        if(partFour.length() < 18){
            integer refFill = 18 - partFour.length();
            for(integer i = 0; i < refFill; i++){
                partFour +=' ';
            }
        }
        //check part three is thr right length
        system.assertEquals(18, partFour.length());
        return partFour;
    }
    
    //returns the trace account information (ESPs account details)
    public static string detailPartFive(string bsb, string accNo, string remName){
        string partFive = bsb;
        //format the account number if required.
        if(accNo.length() < 9){
            integer accDiff = 9 - accNo.length();
            for(integer i = 0; i < accDiff; i++){
                accNo = ' '+accNo;
            }
        }
        //add the account number
        partFive += accNo;
        //make sure it's not too long
        remName = remName.left(16);
        //blank fill if needed
        if(remName.length() < 16){
            integer remFill = 16 - remName.length();
            for(integer i = 0; i < remFill; i++){
                remName +=' ';
            }
        }
        partFive += remName;
        //check that it is the right length before returning
        system.assertEquals(32, partFive.length());
        return partFive;
    }
    
    //returns the amount of witholding tax
    public static string detailPartSix(){
        string partSix = '00000000';
        system.assertEquals(8, partSix.length());
        return partSix;
    }
    
    /* End Detail Part Methods  */
    
    
    /* Total Part Methods  */
    
    
    //returns first default set of characters
    public static string totalPartOne(){
        string partOne = '7999-999            ';
        //check partOne is the right length
        system.assertEquals(20, partOne.length());
        return partOne;
    
    }
    
    //returns the net total amount
    public static string totalPartTwo(string totalAmount){
        if(totalAmount.length() < 10){
            integer totalFill = 10 - totalAmount.length();
            for(integer i = 0; i < totalFill; i++){
                totalAmount = '0'+totalAmount;
            }
        }
        //check it's the right length
        system.assertEquals(10, totalAmount.length());
        return totalAmount;
    }
    
    //returns the credit total
    public static string totalPartThree(string totalAmount){
        if(totalAmount.length() < 10){
            integer totalFill = 10 - totalAmount.length();
            for(integer i = 0; i < totalFill; i++){
                totalAmount = '0'+totalAmount;
            }
        }
        //check it's the right length
        system.assertEquals(10, totalAmount.length());
        return totalAmount;
    }
    
    //returns the debit total
    public static string totalPartFour(){
        string partFour = '0000000000';
        //check it's the right length
        system.assertEquals(10, partFour.length());
        return partFour;
    }
    
    //returns default blank fill section
    public static string totalPartFive(){
        string partFive = '                        ';
        //check it's the right length
        system.assertEquals(24, partFive.length());
        return partFive;
    }
    
    //returns the detail record count
    public static string totalPartSix(integer recordCount){
        string partSix = string.valueOf(recordCount);
        if(partSix.length() < 6){
            integer countFill = 6 - partSix.length();
            for(integer i = 0; i < countFill; i++){
                partSix = '0'+partSix;
            }
        }
        //check it's the right length
        system.assertEquals(6, partSix.length());
        return partSix;
    }
    
    //returns blank fill to end the row.
    public static string totalPartSeven(){
        string partSeven = '                                        ';
        //check it's the right length
        system.assertEquals(40, partSeven.length());
        return partSeven;
    }
    
}