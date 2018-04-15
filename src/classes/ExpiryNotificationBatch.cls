/**
1. Get the List of Insurance & License Provider Documents whose  Difference of Current Date & Expiration Date are 
0 Days, 15 days, 30 days , -7 days, -15 days, -30 days
2. Check for the conditions as per workflow rules for the corresponding days. 
3. Prepare Email Notifications & Send to the Service provider.
4. Update necessary fields for Provider Document objects as per workflow rules. 

This Class will make the following Workflow Rules & Process Builder to RETIRE :
WorkFlow Rules :
Expiration notice 00 days Insurance
Expiration notice 00 days License
Expiration notice 15 days Insurance
Expiration notice 30 days Insurance
Expiration notice 30 days License
Expiration notice post 15 days License
Expiration notice post 30 days Insurance
Expiration notice 15 days License
Expiration notice post 15 days Insurance
Expiration notice post 30 days License
Expiration notice post 7 days Insurance
Expiration notice post 7 days License
Renewal Template Creation pre 60 days Insurance
Renewal Template Creation pre 60 days License

Process Builder :
Document Expiration Notification post 45 days
**/
global class ExpiryNotificationBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    public List<Integer> coutdownDaysList = new List<Integer>();
    
    Expired_Provider_Document__c expDoc = null;        
    Partner_Document__c renewalDoc = null;
    ContentDocumentLink expDocLink = null;
    ContentDocumentLink orgDocLink = null;
    Account updAcc = null;
    
    //Id mainContactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Main Contact').getRecordTypeId();
    List<EmailTemplate> templateList = new List<EmailTemplate>();
    EmailTemplate insuranceTemp = null;
    EmailTemplate licenseTemp = null;
    OrgWideEmailAddress owa = null;
    
    /** Batch Status Variables **/
    public Integer totalDocuments = 0;
    public Integer successUpdates = 0;
    public Integer failedUpdates =0;
    public Integer emailFailure=0;
    public List<String> errMsgs;
    public List<String> emailErrors;
    public List<String> dmlErrors;
    public List<String> expDocErrors;
    public List<String> docRenewalErrors;
    public List<String> existPartnerActErrors;
    public List<String> docLinkNotPresentErrors;
    
    /** Record Type Variables **/
    public Id expiredLicenseRecId = null;
    public Id expiredInsuranceRecId = null;
    public Id expiredEnvLicenseRecId = null;
    public Id EnvLicenseRecId = null;
    public Id LicenseRecId = null;
    public Id InsuranceRecId = null;
    public Id invPartner = null;
    public Id partner = null;
    
    public String execType;
    
    /**
     * Constructor - executionType - "EXPIRY-BATCH" or "TIMER-JOB" 
     **/
    global ExpiryNotificationBatch(String executionType){        
        System.debug('Inside the constructor for ExpiryNotificationBatch');
        this.execType = executionType;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        
        system.debug('*********************************Inside STARTTTTTTTTTTTTTTTTTTTTTTTTT***********************');
        
        /** Initialize Error message List Variables **/
        errMsgs = new List<String>();
        emailErrors = new List<String>();
        dmlErrors = new List<String>();
        expDocErrors = new List<String>();
        docRenewalErrors = new List<String>();
        existPartnerActErrors = new List<String>();
        docLinkNotPresentErrors = new List<String>();
        
        String query = null;
        
        coutdownDaysList.add(-45);
        coutdownDaysList.add(-30);
        coutdownDaysList.add(-15);
        coutdownDaysList.add(-7);
        coutdownDaysList.add(0);
        coutdownDaysList.add(15);
        coutdownDaysList.add(30);
        coutdownDaysList.add(60);
        
        InsuranceRecId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId();
        LicenseRecId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('License').getRecordTypeId();
        EnvLicenseRecId = Schema.SObjectType.Partner_Document__c.getRecordTypeInfosByName().get('Environmental License').getRecordTypeId();
        system.debug('EnvLicenseRecId: ' + EnvLicenseRecId);
        
        invPartner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Invited Partner').getRecordTypeId();
        partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        
        expiredInsuranceRecId = Schema.SObjectType.Expired_Provider_Document__c.getRecordTypeInfosByName().get('Insurance').getRecordTypeId();
        expiredLicenseRecId = Schema.SObjectType.Expired_Provider_Document__c.getRecordTypeInfosByName().get('License').getRecordTypeId();
        expiredEnvLicenseRecId = Schema.SObjectType.Expired_Provider_Document__c.getRecordTypeInfosByName().get('Environmental License').getRecordTypeId();
        
        templateList = [select id, name, developername, Subject, HtmlValue, Body from EmailTemplate where developername IN ('Notification_Email_Insurance_for_the_SPs','Notification_Email_License_for_the_SPs')];
        for(EmailTemplate tempEml: templateList) 
        {
            if(tempEml.developerName == 'Notification_Email_Insurance_for_the_SPs') insuranceTemp = tempEml;
            else if (tempEml.developerName == 'Notification_Email_License_for_the_SPs') licenseTemp = tempEml;
        }
        
        owa = [select id, DisplayName, Address from OrgWideEmailAddress where DisplayName = 'Service Provider' limit 1];
        
        
        if(execType == 'TIMER-JOB')
        {
            query = queryForTimerJob();
        }
        else
        {
            query = queryForExpiryBatch();
        }
       
        system.debug('query :' + query);
        
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Partner_Document__c> scope) {
        system.debug('*********************************Inside EXECUTEEEEEEEEEEEEEEEEEEE***********************');
        /** Variable Declaration per thread **/
        List<Partner_Document__c>  updateDocList = new List<Partner_Document__C>();
        List<Partner_Document__c> renewalDocList = new List<Partner_Document__c>();
        List <Expired_Provider_Document__c> expiredDocList = new List<Expired_Provider_Document__c>();
        List <Expired_Provider_Document__c> finalExpiredDocList = new List<Expired_Provider_Document__c>();
        List<ContentDocumentLink> expDocLinkList = new List<ContentDocumentLink>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> finalEmailList = new List<Messaging.SingleEmailMessage>();
        List<Account> updAccountList = new List<Account>();
        
        List<Id> pdLinkedEntityId = new List<Id>();
        List<Database.SaveResult> saveResults = null;
        
        Set<Id> accIdForDocs = new Set<Id>();
        Set<Id> issueRaisedForPD = new Set<Id>();
        Set<Id> dbIssueForPD = new Set<Id>();
        Set<Id> pdIdEmailNotSent = new Set<Id>();
        Set<Id> issueRelatedtoAccount = new Set<Id>();
        
        
        Map<Id,List<Contact>> accContactMap = new Map<Id,List<Contact>>();
        Map<Id,String> pdocMapForMsg = new Map<Id,String>();
        Map<Id,ContentDocumentLink> pdCntDocLinkMap = new Map<Id,ContentDocumentLink>();
        Map<Id,String> accMsgForFailure = new Map<Id,String>();
        Map<id,Account> accountMap = new Map<id,Account>();
        Map<Id,Id> expiredPDSavedMap = new Map<Id,Id>();
        
        
        //Get the list of Account Ids. 
        system.debug('Size of Scope :' + scope.size());  
        system.debug('Scope Documents:' + scope);             

        for (Partner_Document__c pDoc : scope) {
            accIdForDocs.add(PDoc.Partner_Owner__c);
            system.debug('pDoc.Expiration_Countdown_days__c:' + pDoc.Expiration_Countdown_days__c);
            //Check for Pre Doc Expiry
            if (!pDoc.SendSingleEmail__c) {
                if (pDoc.Document_Status__c == 'Valid' || pDoc.Document_Status__c == 'Approved') {
                    if(pDoc.Expiration_Countdown_days__c <= 60 && pDoc.Expiration_Countdown_days__c > 30)  updateProviderDocument(pdoc,'60 days', true,false,false, updateDocList, renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if(pDoc.Expiration_Countdown_days__c <= 30 && pDoc.Expiration_Countdown_days__c > 15) updateProviderDocument(pdoc,'30 days', true,false,true,updateDocList, renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if (pDoc.Expiration_Countdown_days__c <= 15 && pDoc.Expiration_Countdown_days__c > 0 ) updateProviderDocument(pdoc,'15 days', true,false,true,updateDocList, renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if (pDoc.ExpiryBatchFailure__c) {
                        if (pDoc.Expiration_Countdown_days__c < 30) updateProviderDocument(pdoc,null, true,false,true,updateDocList, renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                        else updateProviderDocument(pdoc,null,true,false,false,updateDocList, renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList); // No Email
                    }
                }
                else if (pDoc.Document_Status__c == 'Expired') {
                    if (pDoc.Expiration_Countdown_days__c == 0 || pDoc.Expiration_Countdown_days__c == -7 ) updateProviderDocument(pdoc,'0 days',true,false,true,updateDocList,renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if (pDoc.Expiration_Countdown_days__c == -15) updateProviderDocument(pdoc,'15 days overdue',true,false,true,updateDocList,renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if (pDoc.Expiration_Countdown_days__c == -30) updateProviderDocument(pdoc,'30 days overdue',true,false,true,updateDocList,renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if (pDoc.Expiration_Countdown_days__c == -45 && pDoc.Partner_Owner__r.RecordTypeId == partner) updateProviderDocument(pdoc,'45 days overdue',true,false,true,updateDocList,renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                    else if (pDoc.ExpiryBatchFailure__c) {
                        if(pDoc.Expiration_Countdown_days__c < -15 && !pDoc.Expiring__c) updateProviderDocument(pdoc,'0 days',true,false,true,updateDocList,renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);
                        else updateProviderDocument(pdoc,'0 days',null,false,false,updateDocList,renewalDocList,expiredDocList,pdLinkedEntityId,pdIdEmailNotSent,updAccountList,accMsgForFailure,accountMap,emailList);  
                    }
 
                } 
            }
        }
        
        emailFailure+=pdIdEmailNotSent.size();  //Count of Documents doesn't have proper email.
        
        system.debug('updateDocList:' + updateDocList);
        system.debug('expiredDocList:' + expiredDocList);
        system.debug('pdLinkedEntityId:' + pdLinkedEntityId);
        system.debug('renewalDocList:' + renewalDocList);
        system.debug('updAccountList:' + updAccountList);

        if(updateDocList != null && updateDocList.size() >0)
        {  
           saveProviderDocuments(updateDocList,dbIssueForPD,pdocMapForMsg,pdIdEmailNotSent);
        }
        
        if(pdLinkedEntityId != null && pdLinkedEntityId.size() >0)
        {
            getContentDocLinkForPD(pdCntDocLinkMap, pdLinkedEntityId);
            system.debug('pdCntDocLinkMap:' + pdCntDocLinkMap.size());
        }
        
        if(expiredDocList!=null && expiredDocList.size()>0)
        {
            filterExpiredDocList(expiredDocList,finalExpiredDocList,pdCntDocLinkMap,issueRelatedtoAccount,issueRaisedForPD);
        }
        
        if(finalExpiredDocList != null && finalExpiredDocList.size()>0)
        {
            insertExpiredDocs(finalExpiredDocList);
            prepareContentDocLinkForExpPD(finalExpiredDocList,pdCntDocLinkMap,issueRaisedForPD,issueRelatedtoAccount,expDocLinkList,expiredPDSavedMap);
            insertContentDocLinkForExpPD(expDocLinkList);
        }
           
        if(renewalDocList != null && renewalDocList.size()>0)
        {
            filterAndInsertRenewalDocuments(renewalDocList,issueRaisedForPD,issueRelatedtoAccount,expiredPDSavedMap);
        }
        
        if(updAccountList != null && updAccountList.size()>0)
        {
            existingPartnerInvitedQueue(updAccountList,issueRelatedtoAccount,accMsgForFailure);
        }
        
        if(emailList != null && emailList.size()>0)  
        {
            sendEmailNotificaitions(emailList,issueRaisedForPD,dbIssueForPD);
        }
       
        if(updateDocList != null & updateDocList.size()>0)
        {
            revertDocUdpatesForFailure(updateDocList, issueRaisedForPD);
        }
        
        //Clear List & Map
        if(updateDocList!=null) updateDocList.clear();
        if(pdLinkedEntityId!=null) pdLinkedEntityId.clear();
        if(expiredDocList!=null) expiredDocList.clear();
        if(finalExpiredDocList!=null) finalExpiredDocList.clear();
        if(renewalDocList!=null) renewalDocList.clear();
        if(expiredPDSavedMap!=null) expiredPDSavedMap.clear();
        if(emailList!=null) emailList.clear();
    }    
    
    global void finish(Database.BatchableContext bc){
        
        system.debug('*********************************Inside FINISHHHHHHHHHHHHHHH***********************');
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
        system.debug('Job Status :' + job.Status);
        
        String finalMsg='';
        finalMsg = 'Please find summary below - \n #TotalParnterDocuments: '+totalDocuments;
        finalMsg += '\n SuccessUpdates: '+successUpdates + '\n FailedUpdates: '+failedUpdates ;
        finalMsg += '\n Email Failure: ' + emailFailure;
        finalMsg += '\n Expired Docs Update Failure: ' + expDocErrors.size();
        finalMsg += '\n Doc Renewal Failure: ' + docRenewalErrors.size();
        finalMsg +='\n Attachment Missing for Docs: ' + docLinkNotPresentErrors.size();
        finalMsg +='\n ------------------------------------------------------------------------------------- ' ;
        
        
        //Errors : No Email/Email framing issues.
        if(emailErrors != null && emailErrors.size()>0)
        {
            finalMsg += '\n Email Issues: \n';
            for(String errStr : emailErrors)
            {
                finalMsg += '\t'+ errStr +'\n';
            }
        }
        // Errors : Failure while updating Provider Document object.
        if(dmlErrors != null && dmlErrors.size()>0)
        {
            finalMsg += '\n PD Update Issues: \n';
            for(String errStr : dmlErrors)
            {
                finalMsg += '\t'+ errStr +'\n';
            }
        }
        
        // Errors : Failure while Inserting Expired Provider Document object.
        if(expDocErrors != null && expDocErrors.size()>0)
        {
            finalMsg += '\n Expired PD Insert Issues: \n';
            for(String errStr : expDocErrors)
            {
                finalMsg += '\t'+ errStr +'\n';
            }
        }
        
        // Errors : Failure while Inserting Document Renewal entries.
        if(docRenewalErrors != null && docRenewalErrors.size()>0)
        {
            finalMsg += '\n Doc Renewal Insert Issues: \n';
            for(String errStr : docRenewalErrors)
            {
                finalMsg += '\t'+ errStr +'\n';
            }
        }
        
        // Errors : No Attachments for the Master documents. Which will not create Expired Docs.
        if(docLinkNotPresentErrors != null && docLinkNotPresentErrors.size()>0)
        {
            finalMsg += '\n Attachment not available for the Provider Docs : : \n';
            for(String errStr : docLinkNotPresentErrors)
            {
                finalMsg += '\t'+ errStr +'\n';
            }
        }
        
        System.debug('Final msg: '+finalMsg);
        //send email with msg
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();        
        String[] toAddresses = new String[]{'krishnaiah_pallamreddy@homedepot.com','Senthilkumar_arulkumar@homedepot.com'};  
        email.setPlainTextBody(finalMsg);
        email.setToAddresses(toAddresses);
        email.setSubject('SALESFORCE: Partner Document :' + execType);
        email.setSenderDisplayName('HD SPM - PD Email Notifier - ' + execType);
        Messaging.SendEmailResult[] result = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        System.debug('Result of email sending is '+result);
    } 
    
    /**
* This method is used to update ProviderDocument and docsForRenewal
**/
    
    private void updateProviderDocument(Partner_Document__C pdoc, String DocumentValidityPeriod,  boolean Expiring, boolean ExpiryBatchFailure, 
                                        boolean sendEmail, List<Partner_Document__c> updateDocList, List<Partner_Document__c> renewalDocList,
                                       List <Expired_Provider_Document__c> expiredDocList,List<Id> pdLinkedEntityId, Set<Id> pdIdEmailNotSent,
                                       List<Account> updAccountList,Map<Id,String> accMsgForFailure,Map<id,Account> accountMap, List<Messaging.SingleEmailMessage> emailList) 
    {
        System.debug('Inside updateProviderDocument ' + '- DocumentValidityPeriod: ' + DocumentValidityPeriod + ' - ' + 'pDoc.Expiring__c: ' + pDoc.Expiring__c + ' - ' + 'pDoc.Name ' + pDoc.Name);
        totalDocuments += 1;
        //Push the doc to a list to create renewal doc if the expiring flag is false.
        if(!pDoc.Expiring__c) {
            providerDocumentRenewal(pDoc,renewalDocList);
            ExpiredproviderDocument(pdoc,expiredDocList,pdLinkedEntityId);
            prepareAccountForUpdate(pDoc,updAccountList,accMsgForFailure,accountMap);
        }
        if (Expiring != null) pDoc.Expiring__c =  Expiring;
        pDoc.ExpiryBatchFailure__c = ExpiryBatchFailure;
        if (DocumentValidityPeriod != null)  pDoc.Document_Validity_Period__c = DocumentValidityPeriod;
        if (sendEmail) generateEmailContent(pDoc,pdIdEmailNotSent,emailList);
        updateDocList.add(pDoc); 
    }
    
   
    /**
* This method is used to create the Expiry Document, Renewal Document and update the Account with the Existing Partners Invited flag to true.  
**/
    //if(!pDoc.Expiring__c) docsForRenewal.add(pDoc)
    public void ExpiredproviderDocument(Partner_Document__c pd,List <Expired_Provider_Document__c> expiredDocList,List<Id> pdLinkedEntityId) 
    {
        system.debug('Inside ExpiredproviderDocument :&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& : ' +  pd);
        expDoc = new Expired_Provider_Document__c();
        expDoc.Document_Type__c = pd.Document_Type__c;
        expDoc.Expiration_Date__c = pd.Expiration_Date__c;
        expDoc.Provider_Document__c = pd.id;
        expDoc.Effective_Date__c = pd.Effective_Date__c;
        expDoc.Limits__c = pd.Limits__c;
        expDoc.Account__c = pd.Partner_Owner__c;
        
        if(pd.RecordTypeId == InsuranceRecId){ 
            //Insurance
            expDoc.Policy_Number__c = pd.Policy_Number__c;
            expDoc.Insured_Company_Name__c = pd.Insured_Company_Name__c;
            expDoc.Submitted_Date__c = pd.Submitted_Date__c;
            expDoc.RecordTypeId = expiredInsuranceRecId;
            pdLinkedEntityId.add(pd.Id); 
        }
        else {
            //License or Environmental License
            if (pd.RecordTypeId == EnvLicenseRecId) {
                expDoc.RecordTypeId = expiredEnvLicenseRecId;
                expDoc.EPA_Certification_Number__c=pd.EPA_Certification_Number__c;
                if (pd.Has_Attachment__c == true) pdLinkedEntityId.add(pd.Id);
            }
            else if (pd.RecordTypeId == LicenseRecId){
                expDoc.RecordTypeId = expiredLicenseRecId;
                pdLinkedEntityId.add(pd.Id);
            }
            expDoc.Description__c = pd.Description__c;
            expDoc.License_Holder_Name__c = pd.License_Holder_Name__c;
            expDoc.License_Number__c = pd.License_Number__c;
            expDoc.Classification__c = pd.Classification1__c;
            
            expDoc.Issuing_Authority__c = pd.Issuing_Authority__c;
            expDoc.License_Company_Name__c = pd.License_Company_Name__c;
            expDoc.License_Holder_Type__c = pd.License_Holder_Type__c;
            expDoc.License_Level__c = pd.License_Level1__c;
            expDoc.License_Name__c = pd.License_Name__c;
            expDoc.State__c = pd.Licensing_Authority_State__c;
        }
        expiredDocList.add(expDoc);
        system.debug('expDoc: ' + expDoc);
    }
    
    /**
* This method is used to create the Provider Document, Renewal Document and update the Account with the Existing Partners Invited flag to true.  
**/
    //if(!pDoc.Expiring__c) docsForRenewal.add(pDoc)
    public void providerDocumentRenewal(Partner_Document__c pd, List<Partner_Document__c> renewalDocList) 
    {
        system.debug('Inside providerDocumentRenewal :&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& : ' +  pd);
        //Create Renewal Document
        renewalDoc = new Partner_Document__c();
        renewalDoc.Partner_Owner__c = pd.Partner_Owner__c;
        renewalDoc.Description__c = pd.Description__c;
        renewalDoc.Document_Status__c = 'Requested';
        renewalDoc.Document_Type__c = pd.Document_Type__c;
        renewalDoc.External_Document_ID__c = pd.External_Document_ID__c;
        renewalDoc.External_Document_Source__c = pd.External_Document_Source__c;
        renewalDoc.License_Holder_Type__c = pd.License_Holder_Type__c;
        renewalDoc.EPA_Certification_Number__c=pd.EPA_Certification_Number__c;
        renewalDoc.License_Name__c = pd.License_Name__c;
        renewalDoc.License_Number__c = pd.License_Number__c;
        renewalDoc.State__c = pd.Licensing_Authority_State__c;
        renewalDoc.Master_Document__c = pd.id;
        renewalDoc.RecordTypeId = pd.RecordTypeId;
        system.debug('renewalDoc: ' + renewalDoc);
        renewalDocList.add(renewalDoc);
    }                
    
    /**
* This method is used to create the Expiry Document, Renewal Document and update the Account with the Existing Partners Invited flag to true.  
**/
    public void prepareAccountForUpdate(Partner_Document__c pd,List<Account> updAccountList,Map<Id,String> accMsgForFailure,Map<id,Account> accountMap) 
    {
        system.debug('Inside AccountUpdate :&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& : ' +  pd);
        //Create Account object for Update.                
        if(!pd.Partner_Owner__r.Existing_Partners_Invited__C && pd.Partner_Owner__r.RecordTypeId == partner)
        {
            if(!accountMap.containsKey(pd.Partner_Owner__c))
            {
                updAcc = new Account();
                updAcc.id = pd.Partner_Owner__c;
                updAcc.Existing_Partners_Invited__c = TRUE;
                updAcc.Business_Form_Filled__c = TRUE;
                updAcc.Contact_Information_Form_Filled__c = TRUE;
                updAccountList.add(updAcc);
                accountMap.put(pd.Partner_Owner__c,updAcc);
                //Partner_Owner__r.Primary_Contact_Email__c,Partner_Owner__r.Compliance_Contact_Email__c
                accMsgForFailure.put(pd.Partner_Owner__c,'Account: ' + pd.Partner_Owner__c +' | ' + 'Primary email: '+ pd.Partner_Owner__r.Primary_Contact_Email__c + 
                                     ' | ' + 'Compliance Email :' +  pd.Partner_Owner__r.Compliance_Contact_Email__c);
            }
        } 
    }
   
    
    public static void getContentDocLinkForPD(Map<Id,ContentDocumentLink> pdCntDocLinkMap, List<Id> pdLinkedEntityId)
    {
        List<ContentDocumentLink> cntDocLinkList =  [SELECT Id, LinkedEntityId, ContentDocumentId, ShareType, Visibility 
                                                     FROM ContentDocumentLink where LinkedEntityId IN :pdLinkedEntityId ];
        
        for(ContentDocumentLink cntDocLink: cntDocLinkList)
        {
            pdCntDocLinkMap.put(cntDocLink.LinkedEntityId,cntDocLink);
        } 
    }
    
    public void saveProviderDocuments(List<Partner_Document__c>  updateDocList, Set<Id> dbIssueForPD, Map<Id,String> pdocMapForMsg,Set<Id> pdIdEmailNotSent)
    {
        List<Database.SaveResult> saveResults = null;
        system.debug('updateDocList: ' + updateDocList);
        for(Partner_Document__c pdoc : updateDocList)
        {
            pdocMapForMsg.put(pdoc.id,'PartnerDocId: '+pdoc.id +'|' +'Document Name: '+ pdoc.Name +'|' + 'Document Validity: '+ pdoc.Document_Validity_Period__c);
            dbIssueForPD.add(pdoc.id);
            if(pdIdEmailNotSent.contains(pdoc.id))
            {
                pdoc.ExpiryBatchFailure__c = true;
            }
        }
        
        saveResults = Database.update(updateDocList, false);
        for (Database.SaveResult sr : saveResults)
        {
            if (!sr.isSuccess()){
                failedUpdates++;
            } else {
                successUpdates++;
                pdocMapForMsg.remove(sr.getId());
                dbIssueForPD.remove(sr.getId());
            }
        } 
        
        if(pdocMapForMsg.size() > 0)
        {
            dmlErrors.addAll(pdocMapForMsg.values());
        }
        
        if(saveResults!=null) saveResults.clear();
    }
    
    public void filterExpiredDocList(List <Expired_Provider_Document__c> expiredDocList, List <Expired_Provider_Document__c> finalExpiredDocList,
                                     Map<Id,ContentDocumentLink> pdCntDocLinkMap,Set<Id> issueRelatedtoAccount, Set<Id> issueRaisedForPD)
    {
        system.debug('expiredDocList: ' + expiredDocList);
        for(Expired_Provider_Document__c expDocfinal: expiredDocList)
        {
           // if(expDocfinal.RecordTypeId != expiredEnvLicenseRecId)
           // {
                system.debug('expiredEnvLicenseRecId: ' + expiredEnvLicenseRecId + 'expDocfinal: ' + expDocfinal);
                if(pdCntDocLinkMap.containsKey(expDocfinal.Provider_Document__c)){
                    finalExpiredDocList.add(expDocfinal);
                } 
           		else if (expDocfinal.RecordTypeId == expiredEnvLicenseRecId ) {
                    finalExpiredDocList.add(expDocfinal);
                }
                else{
                    issueRaisedForPD.add(expDocfinal.Provider_Document__c );
                    issueRelatedtoAccount.add(expDocfinal.Account__c);
                    docLinkNotPresentErrors.add('PartnerDocId: '+expDocfinal.Provider_Document__c +'|' +'Document Type: '+ expDocfinal.Document_Type__c +'|' + 'Account: '+ expDocfinal.Account__c);
                }
            //}
            //else
            //{
            //    system.debug('Filter Expired Documents-In Else condition for Environmental License Documents');
            //    finalExpiredDocList.add(expDocfinal);
            //}
        }
    }
    
    public void insertExpiredDocs(List<Expired_Provider_Document__c> finalExpiredDocList)
    {
        system.debug('finalExpiredDocList: ' + finalExpiredDocList);
        List<Database.SaveResult> saveResults = null;
        saveResults = Database.insert(finalExpiredDocList,false);
        for(Database.SaveResult res: saveResults)
        {
            if(!res.isSuccess())
            {
                system.debug('Error:' + res.getErrors().get(0).getStatusCode() + ':'+res.getErrors().get(0).getMessage());
            }
        }
        if(saveResults!=null) saveResults.clear();
    }
    
    private void prepareContentDocLinkForExpPD(List<Expired_Provider_Document__c> finalExpiredDocList,Map<Id,ContentDocumentLink> pdCntDocLinkMap,
                                               Set<Id> issueRaisedForPD,Set<Id> issueRelatedtoAccount, 
                                               List<ContentDocumentLink> expDocLinkList,Map<Id,Id> expiredPDSavedMap)
    {
        system.debug('finalExpiredDocList: ' + finalExpiredDocList);
        for(Expired_Provider_Document__c expDocSaved : finalExpiredDocList)
        {
            if(expDocSaved.Id != null)
            {
                //if(expDocSaved.RecordTypeId == expiredInsuranceRecId || expDocSaved.RecordTypeId == expiredLicenseRecId)
                //{
                    orgDocLink = pdCntDocLinkMap.get(expDocSaved.Provider_Document__c);
                    if(orgDocLink != null )
                    {
                        expDocLink = new ContentDocumentLink();
                        expDocLink.ContentDocumentId = orgDocLink.ContentDocumentId;
                        expDocLink.LinkedEntityId = expDocSaved.Id;
                        expDocLink.ShareType = orgDocLink.ShareType;
                        expDocLink.Visibility = orgDocLink.Visibility;
                        expDocLinkList.add(expDocLink);
                    } 
                    else if (expDocSaved.RecordTypeId == expiredEnvLicenseRecId ) {
                        expiredPDSavedMap.put(expDocSaved.Provider_Document__c,expDocSaved.Provider_Document__c);
                        continue;
                    }
                    else
                    {
                        issueRaisedForPD.add(expDocSaved.Provider_Document__c);
                        issueRelatedtoAccount.add(expDocSaved.Account__c);
                        docLinkNotPresentErrors.add('PartnerDocId: '+expDocSaved.Provider_Document__c +'|' +'Document Type: '+ expDocSaved.Document_Type__c +'|' + 'Account: '+ expDocSaved.Account__c);
                    }
                }
                expiredPDSavedMap.put(expDocSaved.Provider_Document__c,expDocSaved.Provider_Document__c);
            //}
            //else
            //{
            //    issueRaisedForPD.add(expDocSaved.Provider_Document__c);
            //    issueRelatedtoAccount.add(expDocSaved.Account__c);
            //    expDocErrors.add('PartnerDocId: '+expDocSaved.Provider_Document__c +'|' +'Document Type: '+ expDocSaved.Document_Type__c +'|' + 'Account: '+ expDocSaved.Account__c);
            //}
        }
    }
    
    private void insertContentDocLinkForExpPD(List<ContentDocumentLink> expDocLinkList)
    {
        system.debug('expDocLinkList: '  + expDocLinkList);
        List<Database.SaveResult> saveResults = null;
        if(expDocLinkList!= null && expDocLinkList.size()>0)
        {
            saveResults = Database.insert(expDocLinkList,false);
            for(Database.SaveResult res: saveResults)
            {
                if(!res.isSuccess())
                {
                    system.debug('Error:' + res.getErrors().get(0).getStatusCode() + ':'+res.getErrors().get(0).getMessage());
                }
            }
        }
    }
    
    private void filterAndInsertRenewalDocuments(List<Partner_Document__c> renewalDocList,Set<Id> issueRaisedForPD,
                                                 Set<Id> issueRelatedtoAccount,Map<Id,Id> expiredPDSavedMap)
    {
        List<Database.SaveResult> saveResults = null;
        List<Partner_Document__c> finalRenewalDocList = new List<Partner_Document__c>();
        
        system.debug('renewalDocList:' + renewalDocList);
        
        for(Partner_Document__c pdRen : renewalDocList)
        {
            if(expiredPDSavedMap.containsKey(pdRen.Master_Document__c))
            {
                finalRenewalDocList.add(pdRen);
            }
        }
        
        saveResults = Database.insert(finalRenewalDocList,false);
        for(Database.SaveResult res: saveResults)
        {
            if(!res.isSuccess())
            {
                system.debug('Error:' + res.getErrors().get(0).getStatusCode() + ':'+res.getErrors().get(0).getMessage());
            }
        }
        
        for(Partner_Document__c renDoc : finalRenewalDocList)
        {
            if(renDoc.id == null)
            {
                issueRaisedForPD.add(renDoc.Master_Document__c);
                issueRelatedtoAccount.add(renDoc.Partner_Owner__c);
                docRenewalErrors.add('PartnerDocId: '+renDoc.Master_Document__c +'|' +'Document Type: '+ renDoc.Document_Type__c +'|' + 'Account: '+ renDoc.Partner_Owner__c);
            }
        }
    }
    
    private void existingPartnerInvitedQueue(List<Account> updAccountList,Set<Id> issueRelatedtoAccount,Map<Id,String> accMsgForFailure)
    {
        List<Account> finalUpdAccList = new List<Account>(); 
        if(updAccountList!= null && updAccountList.size() >0)
        {
            for(Account accVal :  updAccountList)
            {
                if(!issueRelatedtoAccount.contains(accVal.id))
                {
                    finalUpdAccList.add(accVal);
                    accMsgForFailure.remove(accVal.id);
                }
                
            }
            
            if(finalUpdAccList!=null && finalUpdAccList.size()>0)
            {
                system.enqueueJob(new InviteExistingPartnerQueue(finalUpdAccList,accMsgForFailure)); 
            }
        }
    }
    
    private void generateEmailContent(Partner_Document__C relatedTo, Set<Id> pdIdEmailNotSent, List<Messaging.SingleEmailMessage> emailList)
    {
        EmailTemplate emlTemp = null;
        String formattedDate = null;
        
        Messaging.SingleEmailMessage email = null;
        Contact ctForTaskCreation = null;
        List<String> eList = new List<String>(); 
        Account relatedAcc = null;
        List<String> emailsFromAccount = new List<String>();
        List<String> emailsContactType = new List<String>();
        
        try
        {
            /* SENTHIL : Commented the below Section to hold on Multiple primary email notification for 25th Jan release. - STARTS
            for(Contact ct : accContactMap.get(accId))
            {
                if(ct.is_primary_contact__C)
                {
                    ctForTaskCreation = ct;
                    eList.add(ct.Email);
                }
                else if(ct.compliance_contact__C)
                {
                    eList.add(ct.Email);
                }
            }
            SENTHIL : Commented the below Section to hold on Multiple primary email notification for 25th Jan release. - ENDS */
             
            if(relatedTo.Partner_Owner__r.Primary_Contact_Email__c != null && relatedTo.Partner_Owner__r.Primary_Contact_Email__c != '') 
             {
                //eList.add(relatedTo.Partner_Owner__r.Primary_Contact_Email__c); 
                emailsFromAccount.add(relatedTo.Partner_Owner__r.Primary_Contact_Email__c);
                emailsContactType.add('Primary');
             }
             
             if(relatedTo.Partner_Owner__r.Compliance_Contact_Email__c != null && relatedTo.Partner_Owner__r.Compliance_Contact_Email__c !='')
             {
                 //eList.add(relatedTo.Partner_Owner__r.Compliance_Contact_Email__c);
                 emailsFromAccount.add(relatedTo.Partner_Owner__r.Compliance_Contact_Email__c);
                 emailsContactType.add('Compliance');
             }
            
            system.debug('eList' + eList);
            system.debug('relatedTo.RecordType.Name: ' + relatedTo.RecordType.Name);
            if(relatedTo.RecordType.Name == 'License' || relatedTo.RecordType.Name == 'Environmental License')
            {
                emlTemp = licenseTemp;
            }
            else
            {
                emlTemp = insuranceTemp;
            }
            system.debug('emlTemp: ' + emlTemp);
            
            String processingEmail = null;
            String processingEmailType = null;
            if(emailsFromAccount!= null && emailsFromAccount.size() >0)
            {
                for(integer i=0; i<emailsFromAccount.size();i++)
                {
                    processingEmail = emailsFromAccount.get(i);
                    processingEmailType = emailsContactType.get(i);
                    
                    email = new Messaging.SingleEmailMessage();
                    eList = new List<String>();
                    email.setorgWideEmailAddressId(owa.id);
                    email.setTemplateId(emlTemp.Id);
                    email.setSaveAsActivity(true); 
                    email.setTreatBodiesAsTemplate(true);
                    email.setSubject(emlTemp.Subject);
                    email.setWhatId(relatedTo.Id);
                    
                    String htmlVal = emlTemp.HtmlValue;
                    
                    if(relatedTo.Expiration_Date__c != null)
                    {
                        Date expDt = relatedTo.Expiration_Date__c;
                        //formattedDate = expDt.month()+'/'+ expDt.day()+'/'+expDt.year();
                        formattedDate = DateTime.newInstance(expDt.year(),expDt.month(),expDt.day()).format('MM/dd/yy');
                    }
                    htmlVal = htmlVal.replace('{will expire on/has expired on}',
                                              (relatedTo.Expiration_Date__c!=null && relatedTo.Expiration_Date__c > Date.today())?'will expire on':'has expired on');       
                    htmlVal = htmlVal.replace('{!relatedTo.Document_Type__c}', relatedTo.Document_Type__c);
                    htmlVal = htmlVal.replace('{!relatedTo.Expiration_Date__c}', formattedDate!= null?formattedDate:'');
                    htmlVal = htmlVal.replace('{!relatedTo.License_Number__c}', relatedTo.License_Number__c!=null?String.valueOf(relatedTo.License_Number__c):'');
                    htmlVal = htmlVal.replace('{!relatedTo.Licensing_Authority_State__c}',relatedTo.Licensing_Authority_State__c!=null?relatedTo.Licensing_Authority_State__c:'');
                    //system.debug('htmlVal:' + htmlVal);  
                    
                    
                    if(processingEmailType == 'Primary')
                    {
                        htmlVal = htmlVal.replace('{!relatedTo.Partner_Owner__r.Primary_Username__c}',
                                                  relatedTo.Partner_Owner__r.Primary_Username__c!=null?relatedTo.Partner_Owner__r.Primary_Username__c:'');
                    }
                    else if (processingEmailType == 'Compliance')
                    {
                        htmlVal = htmlVal.replace('{!relatedTo.Partner_Owner__r.Primary_Username__c}', 
                                                  relatedTo.Partner_Owner__r.Compliance_Username__c!=null?relatedTo.Partner_Owner__r.Compliance_Username__c:'');
                    }
                    email.setHtmlBody(htmlVal);
                    eList.add(processingEmail);
                    email.setToAddresses(eList);
                    emailList.add(email);
                }
            }
            else
            {
                emailErrors.add('Error - Account Email Missing :: Account: ' + relatedTo.Partner_Owner__C + ' | PartnerDoc Id: ' + relatedTo.id + ' | PartnerDoc Name: ' + relatedTo.Name);
                pdIdEmailNotSent.add(relatedTo.Id);
            }
             
        }
        catch(Exception e)
        {
            system.debug('Exception:' + e.getMessage());  
            system.debug('Error occured while preparing the Email List for Expiry Notification :Account:' + relatedTo.Partner_Owner__C + ':PartnerDoc:' + relatedTo);
            emailErrors.add('Error occured during Email Preparation :: Account: ' + relatedTo.Partner_Owner__C + ' | PartnerDoc Id: ' + relatedTo.id + ' | PartnerDoc Name: ' + relatedTo.Name);
            pdIdEmailNotSent.add(relatedTo.Id);
         }
      }
    
    public void sendEmailNotificaitions(List<Messaging.SingleEmailMessage> emailList,Set<Id> issueRaisedForPD, Set<Id> dbIssueForPD)
    {
        List<Messaging.SingleEmailMessage> finalEmailList =  new List<Messaging.SingleEmailMessage>();
            
        if(emailList != null && emailList.size() >0)
        {
            for(Messaging.SingleEmailMessage eml : emailList)
            {
                if(!issueRaisedForPD.contains(eml.getWhatId()) && !dbIssueForPD.contains(eml.getWhatId()))
                {
                    finalEmailList.add(eml);
                }
                
            }
        }
        
        if(finalEmailList != null && finalEmailList.size() >0)
        {
            system.debug('Final Email List:' + finalEmailList.size());
           try
            {
                Messaging.sendEmail(finalEmailList);
                
            }
            catch(EmailException ee)
            {
                system.debug('Exception occured while sending Email Notificaitons:' + ee.getMessage());
                emailErrors.add('Error occured while sending email to the service providers: '+ ee.getMessage());                
            }
            
        }
    }
    
    /**
    *  This method will update the Provider Document as failure. 
    **/
    public void revertDocUdpatesForFailure(List<Partner_Document__c>  updateDocList, Set<Id> issueRaisedForPD )
    {
        List<Database.SaveResult> saveResults = null;
        List<Partner_Document__c> revertPDExpiryFlag = new List<Partner_Document__c>();
        
        if(updateDocList != null && updateDocList.size() >0)
        {
            system.debug('updateDocList:' + updateDocList.size());
            for(Partner_Document__c pdoc : updateDocList)
            {
                if(issueRaisedForPD.contains(pdoc.id))
                {
                    pdoc.Expiring__c = false;
                    pdoc.ExpiryBatchFailure__c = true;  
                    revertPDExpiryFlag.add(pdoc);
                }
                
            }
            
            if(revertPDExpiryFlag != null && revertPDExpiryFlag.size()>0)
            {
                saveResults = Database.update(revertPDExpiryFlag, false);
                for (Database.SaveResult sr : saveResults){
                    if (!sr.isSuccess()){
                        errMsgs.add('Error found attempting to update: '+ sr.getErrors().get(0));
                    } 
                    else{
                        failedUpdates++;
                        successUpdates--;
                    }
                } 
            }
        }
    }
    
    public String queryForExpiryBatch()
    {
        String query = 'SELECT Id, Name, Partner_Owner__c, Document_Name__c, Document_Status__c, Document_Type__c,'+
            'Document_Validity_Period__c, Effective_Date__c, EPA_Certification_Number__c, Expiration_Countdown_days__c, '+ 
            'Expiration_Date__c, Expiring__c, Has_Attachment__c, Insurance_Type__c, Requester__c, SendSingleEmail__c, '+ 
            'RecordType.Name, License_Number__c, Licensing_Authority_State__c,Submitted_Date__c,Description__c,'+
            'License_Holder_Name__c,Classification1__c,Issuing_Authority__c,License_Company_Name__c,License_Holder_Type__c,'+
            'CreatedById, RecordTypeId, Limits__c,Policy_Number__c,Insured_Company_Name__c,License_Level1__c,License_Name__c, '+
            'Renewal_Started__c, account_cancelled_terminated__c,ExpiryBatchFailure__c,External_Document_ID__c,External_Document_Source__c,' +
            'Partner_Owner__r.Primary_Contact_Email__c,Partner_Owner__r.Compliance_Contact_Email__c, '+
            'Partner_Owner__r.Primary_Username__c,Partner_Owner__r.Compliance_Username__c, '+
            'Partner_Owner__r.Existing_Partners_Invited__c,Partner_Owner__r.RecordTypeId, Partner_Owner__r.status__C '+
            'FROM Partner_Document__c '+
            'where ((RecordTypeId IN ('+ '\''+ InsuranceRecId + '\',\''+ LicenseRecId +'\') and Has_Attachment__c = TRUE) OR RecordTypeId =' + '\''+ EnvLicenseRecId + '\') '+ 
            'and Renewal_Started__c = FALSE ' +
            'and ( Expiration_Countdown_days__c IN '+ coutdownDaysList + '  OR  ExpiryBatchFailure__c = TRUE ) and Expiration_Date__c != null ' +
            ' and Partner_Owner__r.RecordTypeId IN ('+ '\''+ invPartner + '\',\''+ partner +'\') and Document_Status__c IN (\'Expired\',\'Approved\',\'Valid\') ' +
            ' and  Partner_Owner__r.status__C not in (\'Terminated\',\'Onboarding Canceled\')' +
            ' and Test_Account__c = FALSE and Partner_Owner__r.Type != \'MVendor\'';
        return query;
    }
    
    public String queryForTimerJob()
    {
        String query = 'SELECT Id, Name, Partner_Owner__c, Document_Name__c, Document_Status__c, Document_Type__c,'+
            'Document_Validity_Period__c, Effective_Date__c, EPA_Certification_Number__c, Expiration_Countdown_days__c, '+ 
            'Expiration_Date__c, Expiring__c, Has_Attachment__c, Insurance_Type__c, Requester__c, SendSingleEmail__c, '+ 
            'RecordType.Name, License_Number__c, Licensing_Authority_State__c,Submitted_Date__c,Description__c,'+
            'License_Holder_Name__c,Classification1__c,Issuing_Authority__c,License_Company_Name__c,License_Holder_Type__c,'+
            'CreatedById, RecordTypeId, Limits__c,Policy_Number__c,Insured_Company_Name__c,License_Level1__c,License_Name__c, '+
            'Renewal_Started__c, account_cancelled_terminated__c,ExpiryBatchFailure__c,External_Document_ID__c,External_Document_Source__c,' +
            'Partner_Owner__r.Primary_Contact_Email__c,Partner_Owner__r.Compliance_Contact_Email__c, '+
            'Partner_Owner__r.Primary_Username__c,Partner_Owner__r.Compliance_Username__c, '+
            'Partner_Owner__r.Existing_Partners_Invited__c,Partner_Owner__r.RecordTypeId, Partner_Owner__r.status__C '+
            'FROM Partner_Document__c '+
            'where ((RecordTypeId IN ('+ '\''+ InsuranceRecId + '\',\''+ LicenseRecId +'\') and Has_Attachment__c = TRUE) OR RecordTypeId =' + '\''+ EnvLicenseRecId + '\') '+ 
            'and Renewal_Started__c = FALSE ' +
            'and (Expiration_Countdown_days__c >=0 and Expiration_Countdown_days__c <=60) and Expiration_Date__c != null ' +
            ' and Partner_Owner__r.RecordTypeId IN ('+ '\''+ invPartner + '\',\''+ partner +'\') and Document_Status__c IN (\'Approved\',\'Valid\') ' +
            ' and  Partner_Owner__r.status__C not in (\'Terminated\',\'Onboarding Canceled\')' + 
            ' and Expiring__c = false and Test_Account__c = FALSE and Partner_Owner__r.Type != \'MVendor\'';
        return query;
    }
   
}