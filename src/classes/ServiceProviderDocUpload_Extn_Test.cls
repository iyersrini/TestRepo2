/*----------------------------------------------------------------------------------------------------------------------------------*/
/* Class Name    : Test_ServiceProviderDocUpload_Extn
* Purpose        : This test class to used for code coverage of the Apex class ServiceProviderDocUpload_Extension
*                  
* Created By     : Revathy C; TCS; 31-JAN-2017
* Modified By    : 
* Modified Log: 
* Date            Developer Name                Comments
*
*-----------------------------------------------------------------------------------------------------------------------------------*/
@isTest
public class ServiceProviderDocUpload_Extn_Test {

    
    static testMethod void ServiceProvider_Onboarding_Method1() {
    
        
        
        profile p = [SELECT ID FROM Profile WHERE Name='Partner SP Portal Profile'];
        
        //Create Account
        Account acnt = TestUtility.createAccount();
        
        //Create Contact
        Contact cntct = TestUtility.createContact(acnt.Id);
        
        //Create Provider Document 
        id prd_RTId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('License').getRecordTypeId();
        id BusDocPRD_RTId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Business Documents').getRecordTypeId();
        id InsPRD_RTId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId();
        id SPAPRD_RTId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Service Provider Agreement').getRecordTypeId();
        //Partner_Document__c prd = TestUtility.createProviderDocumentLicenseType(acnt.Id);
        /*Partner_Document__c BusDocPRD = TestUtilityOnboarding.createProviderDocument(acnt.Id,BusDocPRD_RTId);
        Partner_Document__c InsPRD = TestUtilityOnboarding.createProviderDocument(acnt.Id,InsPRD_RTId);
        Partner_Document__c SPAPRD = TestUtilityOnboarding.createProviderDocument(acnt.Id,SPAPRD_RTId); */
        
        Partner_Document__c prd = new Partner_Document__c();
        prd.Partner_Owner__c = acnt.Id ;
        prd.Document_Type__c = 'Home Improvement License/Certificate';
        prd.License_Number__c = '1234556';
        prd.Effective_Date__c = system.today();
        prd.Expiration_Date__c = system.today()+ 250;
        prd.Workers_Compensation_Waiver__c = false;
        prd.License_Holder_Name__c = 'testjsjsk';
        prd.Policy_Number__c = 'Test PL';
        prd.RecordTypeId = prd_RTId;
        prd.License_Name__c = 'Rev';
        prd.State_Select__c = 'Illinois';
        prd.License_Holder_Type__c = 'sp company Name';
        prd.License_Number__c = 'dsdsds';
        prd.License_Level1__c = 'State';
        prd.Classification1__c = 'Commercial';
        prd.Issuing_Authority__c ='IL';
        prd.License_Company_Name__c = 'Comp';
        prd.License_Holder_First_Name__c = 'Test';
        
        insert prd;
        
        Partner_Document__c InsPRD = new Partner_Document__c();
        InsPRD.Partner_Owner__c = acnt.Id ;
        InsPRD.Document_Type__c = 'Workers Compensation Insurance';
        InsPRD.License_Number__c = '1234556';
        InsPRD.Effective_Date__c = system.today();
        InsPRD.Expiration_Date__c = system.today()+ 250;
        InsPRD.Workers_Compensation_Waiver__c = false;
        InsPRD.License_Holder_Name__c = 'testjsjsk';
        InsPRD.Policy_Number__c = 'Test PL';
        InsPRD.RecordTypeId = InsPRD_RTId;
        insert InsPRD;
        
        Partner_Document__c SPAPRD = new Partner_Document__c();
        SPAPRD.Partner_Owner__c = acnt.Id ;
        SPAPRD.Document_Type__c = 'SPA';
        SPAPRD.License_Number__c = '1234556';
        SPAPRD.Effective_Date__c = system.today();
        SPAPRD.Expiration_Date__c = system.today()+ 250;
        SPAPRD.Workers_Compensation_Waiver__c = false;
        SPAPRD.License_Holder_Name__c = 'testjsjsk';
        SPAPRD.Policy_Number__c = 'Test PL';
        SPAPRD.RecordTypeId = SPAPRD_RTId;
        insert SPAPRD;
        
        //Create Test portal user
        User user = new User(alias = 'tc', email='testcommunity@hd.com',
                emailencodingkey='UTF-8', lastname=cntct.lastname, languagelocalekey='en_US',
                localesidkey='en_US', profileid = p.id, country='United States',IsActive =true,
                ContactId = cntct.Id,
                timezonesidkey='America/Los_Angeles', username='testcommunity@hd.com');
        insert user;
        
        //Create ContentVersion
       /* Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        String inpbase64Data=EncodingUtil.base64Encode(bodyBlob);
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob1=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob1; 
        content.origin = 'H';
        insert content;
        
        //Create ContentDocumentLink
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId=prd.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'V';
        insert contentlink;*/
     
        //Create Document 
        Document d = new Document(); 
        d.Name = 'Partner Document Templates'; 
        String myContent = 'aabbcc'; 
        d.Body = Blob.valueOf(myContent); 
        d.ContentType = 'text/plain';
        d.Type = 'txt';
        d.AuthorId = user.Id;
        d.FolderId = user.Id;
        insert d;       
        
        test.startTest();
            
            //system.assertNotEquals(null,contentlink.Id);
            
            acnt.Status__c = 'Document Ready for Upload';
            update acnt;
           system.runAs(user) {
                PageReference pageRef = page.ServiceProviderDocumentsUpload;
                test.setCurrentPage(pageRef);
                
                ApexPages.currentPage().getParameters().put('pp','1');
                ApexPages.currentPage().getParameters().put('pDocId',prd.Id);
                ApexPages.currentPage().getParameters().put('DocType','License');
                ApexPages.currentPage().getParameters().put('SrcPage','DocumentUpload');
                ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();  
                controller.inpfileName = 'Test';
                controller.file = Blob.valueof('XXXXXXXXXXXXXXX Test content');
                controller.inpfilesize = 123;
                controller.getProviderDoc();
                controller.upload();
                controller.validateDate(system.today());
                controller.Cancel();
                controller.upload();
                controller.done();
                
            }
            system.runAs(user) {
                PageReference pageRef = page.ServiceProviderDocumentsUpload;
                test.setCurrentPage(pageRef);
                
                ApexPages.currentPage().getParameters().put('pp','2');
                ApexPages.currentPage().getParameters().put('pDocId',prd.Id);
                ApexPages.currentPage().getParameters().put('DocType','License');
                ApexPages.currentPage().getParameters().put('SrcPage','LicenseValidationdefault');
                ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();  
                controller.inpfileName = 'Test';
                controller.file = Blob.valueof('XXXXXXXXXXXXXXX Test content');
                controller.inpfilesize = 123;

                controller.getProviderDoc();
                controller.upload();

                controller.validateDate(system.today());
                //controller.Cancel();
                controller.upload();
                controller.done();

            }

            //Added for Environmental License Story
            system.runAs(user) {
            PageReference pageRef = page.ServiceProviderDocumentsUpload;
            test.setCurrentPage(pageRef);

            ApexPages.currentPage().getParameters().put('pp','1');
            ApexPages.currentPage().getParameters().put('pDocId',prd.Id);
            ApexPages.currentPage().getParameters().put('DocType','Environmental License');
            ApexPages.currentPage().getParameters().put('SrcPage','DocumentUpload');

            ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();
            controller.inpfileName = 'Test';
            //controller.file = Blob.valueof('XXXXXXXXXXXXXXX Test content');
            controller.file = null;
            controller.inpfilesize = 123;
            controller.myProviderDoc.Expiration_Date__c = system.today();
            controller.myProviderDoc.Effective_Date__c = system.today()-1;
            controller.myProviderDoc.EPA_Certification_Number__c = 'Env001';
            controller.myProviderDoc.Document_Status__c  = 'Submitted';

            controller.getProviderDoc();
            controller.upload();
            controller.validateDate(system.today());
            controller.Cancel();
            controller.upload();
            controller.done();

        }


            //End of Environmental License Story
             system.runAs(user) {

               try {
                   PageReference pageRef = page.ServiceProviderDocumentsUpload;
                   test.setCurrentPage(pageRef);

                   ApexPages.currentPage().getParameters().put('pp','3');
                   ApexPages.currentPage().getParameters().put('pDocId',prd.Id);
                   ApexPages.currentPage().getParameters().put('DocType','License');
                   ApexPages.currentPage().getParameters().put('SrcPage','ServiceProviderActiveForm');
                   ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();
                   controller.inpfileName = 'Test';
                   controller.file = Blob.valueof('XXXXXXXXXXXXXXX Test content');
                   controller.inpfilesize = 123;
                   controller.getProviderDoc();
                   controller.upload();
                   controller.validateDate(system.today());
                   controller.Cancel();
                   controller.upload();
                   controller.done();

               }
               catch(Exception e){
                  system.debug('Inside catch errror');
             }
            }
            system.runAs(user) {
                PageReference pageRef = page.ServiceProviderDocumentsUpload;
                test.setCurrentPage(pageRef);
                
                ApexPages.currentPage().getParameters().put('pp','1');
                ApexPages.currentPage().getParameters().put('DocType','Dispute License');
                ApexPages.currentPage().getParameters().put('pDocId',prd.Id);
                ApexPages.currentPage().getParameters().put('SrcPage','DocumentUpload');
                ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();  
                controller.selectedDisputeReason = 'Test';
                controller.getProviderDoc();
                controller.upload();
                controller.selectedDisputeReason = '';
                controller.getProviderDoc();
                controller.upload();
                controller.validateDate(system.today());
                controller.Cancel();
                controller.upload();
                controller.done();
            }   

            system.runAs(user) {
                PageReference pageRef = page.ServiceProviderDocumentsUpload;
                test.setCurrentPage(pageRef);
                
                ApexPages.currentPage().getParameters().put('pp','1');
                ApexPages.currentPage().getParameters().put('DocType','Insurance');
                ApexPages.currentPage().getParameters().put('pDocId',InsPRD.Id);
                ApexPages.currentPage().getParameters().put('SrcPage','DocumentUpload');
                ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();  
                controller.inpfileName = 'Test';
                controller.file = Blob.valueof('XXXXXXXXXXXXXXX Test content');
                controller.inpfilesize = 123;
                controller.getProviderDoc();
                controller.upload();
                controller.inpfileName = '';
                controller.file = Blob.valueof('');
                controller.inpfilesize = 59045556;
                controller.getProviderDoc();
                controller.upload();
                controller.validateDate(system.today());
                controller.Cancel();
                controller.upload();
                controller.done();
                
                controller.upload();
            }
            system.runAs(user) {
                PageReference pageRef = page.ServiceProviderDocumentsUpload;
                test.setCurrentPage(pageRef);
                
                ApexPages.currentPage().getParameters().put('pp','1');
                ApexPages.currentPage().getParameters().put('DocType','Service Provider Agreement');
                ApexPages.currentPage().getParameters().put('pDocId',SPAPRD.Id);
                ApexPages.currentPage().getParameters().put('SrcPage','DocumentUpload');
                ServiceProviderDocUpload_Extension controller = new ServiceProviderDocUpload_Extension();  
                controller.getProviderDoc();
                controller.validateDate(system.today());
                controller.Cancel();
                controller.upload();
                controller.done();
            }               
        test.stopTest();
        
    }
}