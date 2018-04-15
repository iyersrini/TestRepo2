/*
@name: DocumentUploadController_c1
@author:Sri Harsha Ala
@date: Jan 8, 2016
@description: This is Controller for DocumentUpload Page 
@
@ Modified by : Revathy Chithamalai
@ Modified Date : 12-Jan-2017
@ Modified Reason : To include the below functionlities 
@                 * View button
@                 * upload document
@                 * Show the count of no.of documents uploaded for the requested ones;
*/

//global without Sharing class DocumentUploadController_c1 {
  public class DocumentUploadController {
    // Variables
    Public boolean isSALmsgAcknowledged {get; set;}
    Public Account accntDetails {get; set;}
    Public String AssignedSPRC {get; set;}
    Public String userName{get;set;}
    Public List<Contact> listContact {get; set;}
    Public Contact  primaryContact {get; set;}
    Public Contact complianceContact {get; set;}
    
    //Start: EPA Story
    Public List<Partner_Document__c> listCurrentEnvironmentalLicenseDocuments{get; set;}
	Public List<Partner_Document__c> listNAEnvironmentalLicenseDocuments{get; set;}
    public List<Partner_Document__c> listEnvironmenttalLicenseDocuments{get; set; }
    //End: Story #

    Public List<Partner_Document__c> listAllPartnerDocs{get; set;}
    Public List<Partner_Document__c> listBDandSPADocuments{get; set;}
    Public List<Partner_Document__c> listNABDandSPADocuments{get; set;}
    Public List<Partner_Document__c> listNABDandSPADocuments_CurrDoc{get;set;}
    Public List<Partner_Document__c> listInsuranceDocuments{get; set;}
    Public List<Partner_Document__c> listNAInsuranceDocuments{get; set;}
    Public List<Partner_Document__c> listNAInsuranceDocuments_CurrDoc{get;set;}
    
    Public List<Partner_Document__c> listLicenseDocuments{get; set;}
    Public List<Partner_Document__c> listLicenseNeedAttentionDocuments{get; set;}
    Public List<Partner_Document__c> listLicenseCurrentDocuments{get; set;}
    public map<String,List<Partner_Document__c>> mapStateLicensedocuments{get; set;}
    public map<String,List<Partner_Document__c>> mapStateLicenseNeedsAttendocuments{get; set;}
    public map<String,List<Partner_Document__c>> mapStateLicenseNeedsAttendocuments_CurrDoc{get; set;}
    public set<string> statekeys {get; set;}
    Public String[] selectedValues {get; set;}

    public string downloadDocTemplates {get;set;}
    public string documentIdSelected {get;set;}
    public string businessDocCount  {get;set;}
    public string insuranceDocCount  {get;set;}
    public string licenseDocCount  {get;set;}
    public string licenseNeedAttentionDocCount  {get;set;}
    public string InsuranceNeedAttentionDocCount  {get;set;}
    public string BDandSPANeedAttentionDocCount  {get;set;}
    Public String pDocId{get;set;}
    Public String pDocType{get;set;}
    Public String pDocExpirationDate{get;set;}
    Public String pDocEffectiveDate{get;set;}
    
    //Boolean flag variables
    public boolean isInactiveComplianceHold{get;set;}
    
    public blob file {get;set;}
      

    User userDetail;
    Contact UserContactRecord;
    User loggedInUser;
    
    public string InstanceURL{get;set;}
    
    // Constructor
    public DocumentUploadController() {
        InstanceURL =  URL.getSalesforceBaseUrl().toExternalForm();
        isInactiveComplianceHold=  false;
        //isSALmsgAcknowledged=false;
        // This is to get the zip of Partner Document Template
        List<Document> lstDocument = [SELECT Id, Name FROM Document WHERE Name = 'Partner Document Templates' LIMIT 1];
        if(lstDocument.size()>0)
        downloadDocTemplates = '/servlet/servlet.FileDownload?file=' + lstDocument[0].Id;

        userDetail = [Select id, 
                                    Name, 
                                    ContactId, 
                                    Contact.AccountId, 
                                    Email 
                                    from User 
                                    where id =: userinfo.getuserId()];
                                    
        userName = userDetail.Name;
        
        System.debug('User Logged in: ' + userName);
        
        accntDetails = [Select id, 
                                Name, 
                                Phone, 
                                Status__c, 
                                BillingStreet, 
                                BillingCity, 
                                BillingState, 
                                BillingCountry,
                                BillingPostalCode, 
                                Service_Programs__c, 
                                Business_Form_Filled__c, 
                                Contact_Information_Form_Filled__c, 
                                Doing_Business_As_DBA__c, 
                                Dun_Bradstreet_Number_DUNS__c, 
                                Years_in_Business__c, 
                                Website, 
                                Number_of_Employees__c,
                                Principal_1_Business_Phone__c,
                                Principal_1_Cell_Phone__c,
                                Principal_1_Email__c,
                                Principal_1_Fax_Number__c,
                                Principal_1_Name__c,
                                Principal_1_Percent_of_ownership__c,
                                Principal_2_Business_Phone__c,
                                Principal_2_Cell_Phone__c,
                                Principal_2_Email__c,
                                Principal_2_Fax_Number__c,
                                Principal_2_Name__c,
                                Principal_2_Percent_of_ownership__c,
                                Principal_3_Business_Phone__c,
                                Principal_3_Cell_Phone__c,
                                Principal_3_Email__c,
                                Principal_3_Fax_Number__c,
                                Principal_3_Name__c,
                                Principal_3_Percent_of_ownership__c,
                                First_time_logged__c,
                                Existing_Partners_Invited__c,
                                Assigned_SPRC__c,
                                Assigned_SPRC__r.Name,
                                Assigned_SPRC__r.Email,
                                Assigned_SPRC__r.Phone,
                                Compliant_Status__c ,
                                Compliance_Contact_Phone__c ,
                                AccountNumber,
                                Line_of_Business__c,
                                Compliance_Contact_Last_Name__c,
                                Compliance_Contact_First_Name__c,
                                Compliance_Contact_Email__c,
                                Primary_Contact_Name__c     ,    
                                Primary_Contact_Email__c     ,       
                                Primary_Contact_Phone__c
                                from Account 
                                where id =: userDetail.Contact.AccountId]; /// dynamic : real 
        if (accntDetails.Status__c == 'Inactive Compliance Hold') isInactiveComplianceHold = true;
        if (accntDetails.Assigned_SPRC__c == null )
            AssignedSPRC='Not Assigned';
        else
            AssignedSPRC=accntDetails.Assigned_SPRC__r.Name; 
    
        Id MainContactrecId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Main Contact').getRecordTypeId();                              
        listContact = [Select id, 
                                Name, 
                                Email, 
                                Phone,
                                isSALmsgAcknowledged__c,
                                MobilePhone ,
                                Type__c,
                                Background_Status__c,
                                is_Primary_Contact__c ,
                                Compliance_Contact__c,Compliant_Status__c ,
                                Background_Expiry_Date__c ,
                                Badge_Expiry_Date__c,
                                Badge_Number__c
                                from Contact 
                                where  (is_Primary_Contact__c = true or Compliance_Contact__c= true ) 
                                and recordtypeId = : MainContactrecId and   AccountId =: userDetail.Contact.AccountId];
                   system.debug('listContact:'  + listContact);
 
        if (listContact.size() > 0) {
            for(Contact c : listContact) {
               if (c.is_Primary_Contact__c == true)    primaryContact = c;
               if (c.Compliance_Contact__c == true)    complianceContact = c;
                system.debug('Conatct: '  + c);
                system.debug('userName: ' + userName);
                if (c.Name == userName) {
                    UserContactRecord = c;
                    isSALmsgAcknowledged=c.isSALmsgAcknowledged__c;
                    System.debug('isSALmsgAcknowledged ' + isSALmsgAcknowledged);
                }
            }
        }           
        listAllPartnerDocs = [Select id, 
                                        Name,
                                        RecordType.Name, 
                                        Document_Type__c, 
                                        Expiration_Date__c,
                              			has_attachment__c,
                                        EPA_Certification_Number__c,
                                        Formatted_Expiration_Date__c,
                                        Document_Status__c, 
                                        Master_Document__c,
                                        Comments__c,
                                        Limits__c,
                                        License_Name__c,
                                        Licensing_Authority_State__c,
                                        License_Holder_Type__c,
                                        License_Level1__c,
                                        State_Select__c ,
                                        Classification1__c,
                                        Reason_for_Change__c,
                                        Renewal_Started__c,
                                        License_Number__c,
                                        Policy_Number__c
                                        from Partner_Document__c 
                                        where Partner_Owner__c =:userDetail.Contact.AccountId];
        
        String providerDocObj = 'Partner_Document__c';
        String picklistLimitField = 'Limits__c';
        String picklistLicenseLevel = 'License_Level1__c';
        String picklistClassification = 'Classification1__c';
        
        //Start: Stroy #
   	    listCurrentEnvironmentalLicenseDocuments = new List<Partner_Document__c>();
		listNAEnvironmentalLicenseDocuments = new List<Partner_Document__c>();
        listEnvironmenttalLicenseDocuments  = new List<Partner_Document__c>();
        //End: Story #
        
        listBDandSPADocuments = new List<Partner_Document__c>();
        listInsuranceDocuments = new List<Partner_Document__c>();
        listNAInsuranceDocuments = new List<Partner_Document__c>();
        listNAInsuranceDocuments_CurrDoc = new List<Partner_Document__c>();
        listNABDandSPADocuments = new List<Partner_Document__c>();
        listNABDandSPADocuments_CurrDoc = new List<Partner_Document__c>();
        
        listLicenseDocuments = new List<Partner_Document__c>();
        listLicenseNeedAttentionDocuments = new List<Partner_Document__c>();
        listLicenseCurrentDocuments = new List<Partner_Document__c>();
        mapStateLicensedocuments = new map<string, List<Partner_Document__c>>();
        mapStateLicenseNeedsAttendocuments = new map<string, List<Partner_Document__c>>();
        mapStateLicenseNeedsAttendocuments_CurrDoc = new map<string, List<Partner_Document__c>>();
        
        integer BusinessSubmittedDocCount = 0;
        integer InsuranceSubmittedDocCount = 0;
        integer LicenseSubmittedDocCount = 0;
        integer LicenseNeedsAttentionSubmittedDocCount = 0;
        
        set<string> setNeedAttention = new set<string>();
        setNeedAttention.add('Expired');
        setNeedAttention.add('Submitted');
        setNeedAttention.add('Requested');
        setNeedAttention.add('Needs Revision');
        setNeedAttention.add('Not Approved');
        setNeedAttention.add('Invalid');
        
        set<string> setCurrentDocument = new set<string>();
        setCurrentDocument.add('Approved');
        setCurrentDocument.add('Valid');
        
        for(Partner_Document__c prtnrDoc : listAllPartnerDocs) {
             
                if (prtnrDoc.RecordType.Name == 'Insurance') {
                    if (prtnrDoc.Document_Type__c == 'Workers Compensation Insurance') {
                        prtnrDoc.Document_Type__c = prtnrDoc.Document_Type__c.replace(' Insurance','');
                        
                        if (prtnrDoc.Licensing_Authority_State__c <> null) {
                           prtnrDoc.Document_Type__c += ' - ' + prtnrDoc.Licensing_Authority_State__c; 
                        }
                    }
                    listInsuranceDocuments.add(prtnrDoc);           
                    if (prtnrDoc.Document_Status__c == 'Submitted') InsuranceSubmittedDocCount = InsuranceSubmittedDocCount + 1; 
                    if (setNeedAttention.contains(prtnrDoc.Document_Status__c) && prtnrDoc.Renewal_Started__c == false) {
                        listNAInsuranceDocuments.add(prtnrDoc);
                    }
                    if (setCurrentDocument.contains(prtnrDoc.Document_Status__c) ) {
                        listNAInsuranceDocuments_CurrDoc.add(prtnrDoc);
                    }
                } else if(prtnrDoc.RecordType.Name == 'License') {
                    string st = 'Others';
                    if (prtnrDoc.Licensing_Authority_State__c <> null && prtnrDoc.Licensing_Authority_State__c <> '') {
                        st = prtnrDoc.Licensing_Authority_State__c;
                        system.debug('### st : ' + st);
                    }
                    listLicenseDocuments.add(prtnrDoc);
                    list<Partner_Document__c> PD = new List<Partner_Document__c> ();

                    if (mapStateLicensedocuments.containskey(st)) {
                        PD = mapStateLicensedocuments.get(st);
                    }   
                    PD.add(prtnrDoc);
                    mapStateLicensedocuments.put(st,PD);

                    //*** License which needs attention for LicenseValidationdefault VF page ***
                    if (setNeedAttention.contains(prtnrDoc.Document_Status__c) && prtnrDoc.Renewal_Started__c == false) {
                        list<Partner_Document__c> PDNA = new List<Partner_Document__c> ();
                        listLicenseNeedAttentionDocuments.add(prtnrDoc);

                        if (mapStateLicenseNeedsAttendocuments.containskey(st)) {
                            PDNA = mapStateLicenseNeedsAttendocuments.get(st);
                        }   
                        PDNA.add(prtnrDoc);
                        mapStateLicenseNeedsAttendocuments.put(st,PDNA);
                    }
                    if (setCurrentDocument.contains(prtnrDoc.Document_Status__c) ) {
                        list<Partner_Document__c> PDNA_l2 = new List<Partner_Document__c> ();
                        listLicenseCurrentDocuments.add(prtnrDoc);
                        
                        if (mapStateLicenseNeedsAttendocuments_CurrDoc.containskey(st)) {
                            PDNA_l2 = mapStateLicenseNeedsAttendocuments_CurrDoc.get(st);
                        }   
                        PDNA_l2.add(prtnrDoc);
                        mapStateLicenseNeedsAttendocuments_CurrDoc.put(st,PDNA_l2);
                    }
                    if (prtnrDoc.Document_Status__c == 'Submitted') {
                    LicenseSubmittedDocCount = LicenseSubmittedDocCount + 1;
                    LicenseNeedsAttentionSubmittedDocCount = LicenseNeedsAttentionSubmittedDocCount + 1;
                    }
                }
            	//Start: Story #
            	else if (prtnrDoc.RecordType.Name == 'Environmental License') {
                     if (prtnrDoc.Licensing_Authority_State__c <> null) {
                           prtnrDoc.Document_Type__c += ' - ' + prtnrDoc.Licensing_Authority_State__c; 
                    }
                    //for Invited Partner
                    listEnvironmenttalLicenseDocuments.add(prtnrDoc);  
                    System.debug('prtnrDoc: ' + prtnrDoc);
                    //For Existing Partner
                    //if (prtnrDoc.Document_Status__c == 'Submitted') InsuranceSubmittedDocCount = InsuranceSubmittedDocCount + 1; 
                    if (setNeedAttention.contains(prtnrDoc.Document_Status__c) && prtnrDoc.Renewal_Started__c == false) {
                        listNAEnvironmentalLicenseDocuments.add(prtnrDoc);
                    }
                    if (setCurrentDocument.contains(prtnrDoc.Document_Status__c) ) {
                        listCurrentEnvironmentalLicenseDocuments.add(prtnrDoc);
                    }
                }
            	//End: Story #
            else {
                    listBDandSPADocuments.add(prtnrDoc);
                    if (prtnrDoc.Document_Status__c == 'Submitted') 
                        BusinessSubmittedDocCount = BusinessSubmittedDocCount + 1;
                    if (setNeedAttention.contains(prtnrDoc.Document_Status__c) && prtnrDoc.Renewal_Started__c == false) {
                        listNABDandSPADocuments.add(prtnrDoc);
                    }
                    if (setCurrentDocument.contains(prtnrDoc.Document_Status__c)) {
                        listNABDandSPADocuments_CurrDoc.add(prtnrDoc);
                    }
            }
            
        }
        
        if (listBDandSPADocuments.size() > 0) businessDocCount = String.valueof(BusinessSubmittedDocCount) + '/' + String.valueof(listBDandSPADocuments.size());
        else businessDocCount = '0/0';
        if (listInsuranceDocuments.size() > 0) insuranceDocCount = String.valueof(InsuranceSubmittedDocCount) + '/' + String.valueof(listInsuranceDocuments.size());
        else insuranceDocCount = '0/0';
        if (listLicenseDocuments.size() > 0)  licenseDocCount = String.valueof(LicenseSubmittedDocCount) + '/' + String.valueof(listLicenseDocuments.size());
        else licenseDocCount = '0/0';
        if (listLicenseNeedAttentionDocuments.size() > 0)  licenseNeedAttentionDocCount = String.valueof(LicenseNeedsAttentionSubmittedDocCount) + '/' + String.valueof(listLicenseNeedAttentionDocuments.size());
        else licenseNeedAttentionDocCount = '0/0';
        if (listNABDandSPADocuments.size() > 0)  BDandSPANeedAttentionDocCount = String.valueof(BusinessSubmittedDocCount) + '/' + String.valueof(listNABDandSPADocuments.size());
        else BDandSPANeedAttentionDocCount = '0/0';
        if (listNAInsuranceDocuments.size() > 0)  InsuranceNeedAttentionDocCount = String.valueof(InsuranceSubmittedDocCount) + '/' + String.valueof(listNAInsuranceDocuments.size());
        else InsuranceNeedAttentionDocCount = '0/0';
        
        statekeys= mapStateLicensedocuments.keySet();
        system.debug('### : statekeys : ' + statekeys);
        system.debug('### : mapStateLicensedocuments: ' + mapStateLicensedocuments);
    }
    

    public void UploadFile(){
        Partner_Document__c selectedDocument = [Select id, 
                                        Name,
                                        RecordType.Name, 
                                        Document_Type__c, 
                                        Expiration_Date__c, 
                                        Document_Status__c, 
                                        Master_Document__c,
                                        Comments__c,
                                        Limits__c,
                                        License_Name__c,
                                        Licensing_Authority_State__c,
                                        License_Holder_Type__c,
                                        License_Level1__c,
                                        Classification1__c,
                                        Reason_for_Change__c
                                        from Partner_Document__c WHERE Id =: documentIdSelected];
        
        Set<Id> contentIds = new Set<Id>();
        for(ContentDocumentLink files : [select id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId = :documentIdSelected AND ContentDocumentId != NULL]) {
            contentIds.add(files.ContentDocumentId);
        }
        
        List<ContentDocument> contentDocs = new List<ContentDocument>([Select Id from ContentDocument where Id = :contentIds ]);
        if(contentDocs != null && contentDocs.size() > 0) {
            Delete contentDocs;
        }   

        ContentVersion c = new ContentVersion();
        c.Title=selectedDocument.Document_Type__c;
        c.PathOnClient='/' + c.Title;
        system.debug('########## file : ' + file);
    
        c.origin = 'H';
        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId=selectedDocument.Id;
        contentlink.ShareType = 'V';
        try{
            insert c;
            contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: c.id].contentdocumentid;
            insert contentlink;              
        }catch(Exception e){system.debug('you do not have permission');}
        displayPopup = false;
        selectedDocument.Document_Status__c = 'Submitted';
        update selectedDocument;
    }
    
    public boolean displayPopup{get;set;}
    public String docIdDispute{get;set;}
    public void closePopup(){
        displayPopup = false;
    }
    
    @RemoteAction
    public static Id getPartnerAttach(Id PartnerDocId) {
        
        system.debug('#1:'+PartnerDocId);
        Id partDocAttachId;
        
        List<ContentDocumentLink> partnerDoc = [Select ContentDocumentId from ContentDocumentLink where LinkedEntityId =: PartnerDocId order by SystemModstamp desc  limit 1];
        system.debug('#2:'+partnerDoc );
        List<ContentVersion> partnerVersion = new List<ContentVersion>();
        if(partnerDoc <> null && partnerDoc.size() > 0 && partnerDoc[0].ContentDocumentId <> null)
        {
             partnerVersion = [Select Id From ContentVersion where ContentDocumentId =:partnerDoc[0].ContentDocumentId ];
             partDocAttachId = partnerVersion[0].Id;
        }
        system.debug('#3:'+partnerVersion+'-'+partDocAttachId  );
        
        return partDocAttachId;
    }
    
      public void upDateSALmsgAcknowledgement() {
          System.debug('isSALmsgAcknowledged: ' + isSALmsgAcknowledged);
          if (isSALmsgAcknowledged) {
              UserContactRecord.isSALmsgAcknowledged__c=isSALmsgAcknowledged;
              update UserContactRecord;
              System.debug('UserContactRecord:' + UserContactRecord);

          }
      }
      
    public void showPopup(){
        displayPopup = true;     
    }   
}