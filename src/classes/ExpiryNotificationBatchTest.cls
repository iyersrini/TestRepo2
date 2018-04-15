@isTest(SEEALLDATA = FALSE)
private class ExpiryNotificationBatchTest {
    
    public static final id licenseRecType = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('License').getRecordTypeId();
    public static final id AccntRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
    
     @isTest
    static void testDocument60DaysToExpire() {

        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        acnt.Existing_Partners_Invited__c = false;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Valid';
        prd.Document_Validity_Period__c = '60 days';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() + 60;
        prd.Expiring__c = false;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        prd.License_Name__c ='Test';
        insert prd;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=prd.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
    @isTest
    static void testDocument30DaysToExpire() {

        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Valid';
        prd.Document_Validity_Period__c = '30 days Overdue';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() + 30;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        prd.License_Name__c ='Test';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
    @isTest
    static void testDocument15DaysToExpire() {

        
        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Valid';
        prd.Document_Validity_Period__c = '30 days Overdue';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() + 15;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        prd.License_Name__c ='Test';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
    @isTest
    static void testDocumentBatchFailureRestart() {
        
 		SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Valid';
        prd.Document_Validity_Period__c = '30 days Overdue';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() + 16;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = true;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        prd.License_Name__c ='Test';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c,ExpiryBatchFailure__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
    @isTest
    static void testDocument30DaysOverdue() {

        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Expired';
        prd.Document_Validity_Period__c = '30 days Overdue';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() - 30;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
    @isTest
    static void testDocument15DaysOverdue() {
 		
        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Expired';
        prd.Document_Validity_Period__c = '15 days Overdue';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() - 15;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
     @isTest
    static void testDocument7DaysOverdue() {

  		SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Expired';
        prd.Document_Validity_Period__c = '';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() - 7;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
     @isTest
    static void testDocument0DaysOverdue() {

        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Expired';
        prd.Document_Validity_Period__c = '';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() ;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
        @isTest
    static void testDocument45DaysOverdue() {

       	SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Expired';
        prd.Document_Validity_Period__c = '';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() - 45;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
       @isTest
    static void testDocumentBatchFailureRestartOverdue() {
 		
        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Expired';
        prd.Document_Validity_Period__c = '';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() - 32;
        prd.Expiring__c = true;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = true;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        insert prd;
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('EXPIRY-BATCH');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
    @isTest
    static void testDocument30To60DaysToExpire() {

        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        acnt.Existing_Partners_Invited__c = false;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Valid';
        prd.Document_Validity_Period__c = '60 days';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() + 44;
        prd.Expiring__c = false;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        prd.License_Name__c ='Test';
        insert prd;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=prd.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('TIMER-JOB');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
     @isTest
    static void testDocument0To30DaysToExpire() {

        SPM_Division__c div = new SPM_Division__c(name='NORTHERN',	Source_Division_ID__c='NORTHERN');
        insert div;
        
        SPM_Region__c reg = new SPM_Region__c(name='GULF',SPM_Division__c=div.id,Source_Region_ID__c='GULF');
        insert reg;
        
        Account acnt = new Account();
        acnt.Name = 'TestAccount';
        acnt.AccountNumber = '12345';
        acnt.Source_Account_ID__c = '12345';
        acnt.Status__c ='Active Compliant';
        acnt.Line_of_Business__c = 'CORE';
        acnt.Service_Programs__c ='Bath';
        acnt.BillingStateCode = 'TX' ;
        acnt.BillingCity = 'Dallas';
        acnt.BillingCountryCode = 'US';
        acnt.RecordTypeId = AccntRecordTypeId;
        acnt.Division__c = div.id;
        acnt.Region__c = reg.id;
        acnt.Existing_Partners_Invited__c = false;
        insert acnt;
        
        //system.assert();
        Contact cntct = TestUtility.createContact(acnt.Id);
        Partner_Document__c prd =  new Partner_Document__C();
        prd.account_cancelled_terminated__c = true;
        prd.Partner_Owner__c = acnt.id;
        prd.Document_Type__c = 'Business';
        prd.Document_Status__c = 'Valid';
        prd.Document_Validity_Period__c = '30 days';
        prd.Effective_Date__c = system.today() - 365;
        prd.Expiration_Date__c = system.today() + 20;
        prd.Expiring__c = false;
        prd.Has_Attachment__c = true;
        prd.Renewal_Started__c = false;
        prd.account_cancelled_terminated__c = false;
        prd.ExpiryBatchFailure__c = false;
        prd.RecordTypeId = licenseRecType;
        prd.SendSingleEmail__c = false;
        prd.License_Number__c = '3434';
        prd.License_Name__c ='Test';
        insert prd;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        //content.LinkedEntityId=sub.id;
        content.origin = 'H';
        insert content;
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=prd.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;
        
        
        Partner_Document__C prd1 =[select id, name, Expiration_Countdown_days__c from Partner_Document__c LIMIT 1 ];
        system.debug('Before: prd1--expCount:' + prd1.Expiration_Countdown_days__c);
         update prd1;
        Test.startTest();
        system.debug('After : prd1--expCount:' + prd1.Expiration_Countdown_days__c);
        
        ExpiryNotificationBatch expiryBatch = new ExpiryNotificationBatch('TIMER-JOB');
        Database.executeBatch(expiryBatch,100);
        Test.stopTest();
       
    }
    
}