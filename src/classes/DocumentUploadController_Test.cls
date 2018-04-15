@isTest 
private class DocumentUploadController_Test {

    static testMethod void DocumentUploadController() {

        Account Acc = TestUtilityOnboarding.createAccount('TestAccount');
        //insert Acc;

        User Portal = TestUtilityOnboarding.createPortalUser(Acc);

        Contact c;

        Id MainContactrecId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Main Contact').getRecordTypeId();

        c =  [Select Id,
                     Account.Id,
                     Name,
                     is_Primary_Contact__c
                from Contact
                Where Account.Id = :Acc.id];

        c.is_Primary_Contact__c = True;
        //c.isSALmsgAcknowledged__c = True;
        c.recordtypeId = MainContactrecId;
        upsert c;

        //Contact cnct = TestUtilityOnboarding.createContact(acc.Id, 'TestContact Last Name');

        //Acc = [select Id,Name from Account limit 1];
        
        id PDLId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('License').getRecordTypeId();
        id PDIId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId();
        id PDBId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Business Documents').getRecordTypeId();
        id PDEnvId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Environmental License').getRecordTypeId();

/*        id PDSPAId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Service Provider Agreement').getRecordTypeId();
 
        Partner_Document__c prdspana = TestUtilityOnboarding.createProviderDocument(Acc.Id, PDSPAId, 'Service Provider Agreement');
        prdspana.Document_Status__c= 'Requested';
        prdspana.Comments__c = 'test';
        insert prdspana;
        Partner_Document__c prdspaa = TestUtilityOnboarding.createProviderDocument(Acc.Id, PDSPAId, 'Service Provider Agreement');
        prdspaa.Document_Status__c= 'Valid';
        prdspaa.Comments__c = 'test';
        insert prdspaa; */

        Partner_Document__c prbdna = TestUtilityOnboarding.createProviderDocument(Acc.Id, PDBId, 'Business Documents');
        prbdna.Document_Status__c= 'Expired';
        prbdna.has_attachment__c = true;
        prbdna.Comments__c = 'test';
        insert prbdna;

        Partner_Document__c prbda = TestUtilityOnboarding.createProviderDocument(Acc.Id, PDBId, 'Business Documents');
        prbdna.Document_Status__c= 'Approved';
        prbdna.has_attachment__c = true;
        prbdna.Comments__c = 'test';
        insert prbda;

        Partner_Document__c prd = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDLId, 'License');
        prd.Document_Status__c= 'Needs Revision';
        prd.has_attachment__c = true;
        prd.Comments__c = 'test';
        prd.Licensing_Authority_State__c = 'GA';
        insert prd;

        Partner_Document__c prda = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDLId, 'License');
        prda.Document_Status__c= 'Valid';   //Approved
        prda.has_attachment__c = true;
        prda.Comments__c = 'test';
        prda.Licensing_Authority_State__c = 'GA';

        insert prda;

        Partner_Document__c prdb = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDLId, 'License');
        prdb.Document_Status__c= 'Submitted';   //Approved
        prdb.Document_Name__c = 'Electrical';
        prdb.has_attachment__c = true;
        prdb.Comments__c = 'test';
        prdb.Licensing_Authority_State__c = 'GA';

        insert prdb;



        Partner_Document__c iPrd = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDIId, 'Insurance');
        iprd.Document_Status__c= 'Valid';
        iprd.has_attachment__c = true;
        iprd.Comments__c = 'test';
        iprd.Document_Type__c = 'Workers Compensation Insurance';
        iprd.Licensing_Authority_State__c = 'GA';
        iprd.Renewal_Started__c = false;

        insert iPrd;

        Partner_Document__c iPrdSub = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDIId, 'Insurance');
        iprdSub.Document_Status__c= 'Submitted';
        iprdSub.has_attachment__c = true;
        iprdSub.Comments__c = 'test';
        iprdSub.Document_Type__c = 'General Liability';
        iprdSub.Licensing_Authority_State__c = 'GA';
        iprdSub.Renewal_Started__c = false;

        insert iprdSub;



        Partner_Document__c iPrda = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDIId, 'Insurance');
        iprda.Document_Status__c= 'Approved';
        iprda.has_attachment__c = true;
        iprda.Comments__c = 'test';
        insert iPrda;

        //Added for Environmental story..
        Partner_Document__c prdEnv = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDEnvId, 'Environmental License');
        prdEnv.Document_Status__c= 'Requested';  //Needs Revision
        prdEnv.has_attachment__c = true;
        prdEnv.Comments__c = 'test';
        prdEnv.EPA_Certification_Number__c = 'TEST1';
        prdEnv.License_Name__c = 'EnvLic001';
        prdEnv.License_Holder_Type__c = 'SP company name';
        insert prdEnv;

        Partner_Document__c prdEnvA = TestUtilityOnboarding.createProviderDocument(Acc.Id,PDEnvId, 'Environmental License');
        prdEnvA.Document_Status__c= 'Valid';
        prdEnvA.has_attachment__c = true;
        prdEnvA.Comments__c = 'test';
        prdEnvA.EPA_Certification_Number__c = 'TEST2';
        prdEnvA.License_Name__c = 'EnvLic002';
        prdEnvA.License_Holder_Type__c = 'SP company name';
        prdEnvA.Effective_Date__c = system.today()-1;
        prdEnvA.Expired_Date__c = system.today();
        insert prdEnvA;
        // End of Environemntal story..


        system.runAs(Portal){
            
            Test.StartTest();
                PageReference pageRef = Page.DocumentUpload;
                //pageRef.getParameters().put('p_userValue1', '100000');
                Test.setCurrentPage(pageRef);
                
                DocumentUploadController controller = new DocumentUploadController();

                controller.documentIdSelected = iprd.Id;

                controller.upDateSALmsgAcknowledgement();
                controller.UploadFile();

                DocumentUploadController.getPartnerAttach(prd.Id);

                controller.showPopup();   
                controller.closePopup();     
 
            Test.StopTest();
        }        
    }
}