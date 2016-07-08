/*
* Author: Jimmy Hesketh
* Summary: Used to pass either a standard or set controller into custom visualforce components  
* Date: 23/02/2016
*/ 
public with sharing class StandardController {
   	public ApexPages.StandardSetController stdSetController { get; set; }
   	public ApexPages.StandardController stdController { get; set; }

    public StandardController(ApexPages.StandardSetController standardController) {
        this.stdSetController = standardController;
    }

    public StandardController(ApexPages.StandardController standardController) {
        this.stdController = standardController;
    }
}