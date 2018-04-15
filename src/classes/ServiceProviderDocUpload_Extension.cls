/*----------------------------------------------------------------------------------------------------------------------------------*/
/* Class Name    : ServiceProviderDocUpload_Extension
* Purpose        : This controller is being used in the Service Provider Document Upload VF Page.
*                  
* Created By     : .Revathy C; TCS; 11-JAN-2017
* Modified By    : 
* Modified Reason: 
*                  
*-----------------------------------------------------------------------------------------------------------------------------------*/
/*** Controller ***/

 public with sharing class ServiceProviderDocUpload_Extension {
  
  public String SrcPage { get; set; }
  
  public Partner_Document__c myProviderDoc{get;set;}
  public boolean closeWindow{get;set;}
  public boolean WaiverFlag{get;set;}
  public Id pDocId{get;set;}
  public string DocType{get;set;}
  //public ContentVersion c {get;set;}
  public string inpfileName {get;set;}
  public integer inpfilesize {get;set;}
  public transient  blob file {get;set;}
  
  public String selectedDisputeReason{get;set;}
  public string pageHeader{get; set;}
  public boolean WorkersCompensationInsurance {get;set;}
 
  public String spaSignedDateError {get; set;}
  public String InputDocError {get; set;}
  public String InsEffectiveDateError {get; set;}
  public String InsExpirationDateError {get; set;}
  public String InsIssuingAuthorityError {get; set;}
  
  public String InsCompanyNameError {get; set;}
  public string InsPolicyNumberError{get;set;}
  
  public String LicLevelError {get; set;}
  //public String LicIssuingAuthorityError {get; set;}
  public String LicClassificationError {get; set;}
  public String LicEffectiveDateError {get; set;}
  public String LicExpirationDateError {get; set;}
  public String LicDisputeReasonError {get; set;}
  public String LicNumError {get;set;}
  public string pp{get;set;}
  public String EPALicExpirationDateError {get; set;}
  public String EPALicEffectiveDateError {get; set;}
  public String EPACertificationNumberError {get; set;}

  
     // constructor
  public ServiceProviderDocUpload_Extension()
    {
    
    WorkersCompensationInsurance = false;
       // get parameters
        pp = ApexPages.currentPage().getParameters().get('pp');
        pDocId = ApexPages.currentPage().getParameters().get('pDocId');
        DocType = ApexPages.currentPage().getParameters().get('DocType');
        SrcPage = ApexPages.currentPage().getParameters().get('SrcPage');
        if (DocType == 'Dispute License')   pageHeader = DocType;
        else if (DocType == 'Environmental License') pageHeader = DocType + ' Update' ;
        else   pageHeader = DocType + ' Upload' ;
       // c = new ContentVersion();
       WaiverFlag=false;
      myProviderDoc = [SELECT Document_Status__c, Licensing_Authority_State__c,Document_Type__c, 
                                                               Policy_Number__c,
                                                                Expiration_Date__c, 
                                                                Effective_Date__c, 
                       											EPA_Certification_Number__c,
                                                                License_Number__c, 
                                                                Description__c, 
                                                                License_Holder_Name__c,
                                                                Workers_Compensation_Waiver__c,
                                                                Limits__c,
                                                                Issuing_Authority__c,
                                                                License_Company_Name__c,
                                                                License_Level1__c,
                                                                License_Name__c,
                                                                State_Select__c, 
                                                                License_Holder_Type__c,
                                                                Classification1__c,
                                                                RecordType.Name,
                                                                SPA_Signed_Date__c,
                                                                Insured_Company_Name__c,
                                                                License_Holder_First_Name__c,
                                                                License_Holder_Middle_Name__c,
                                                                License_Holder_Last_Name__c,
                                                                License_Holder_Address1__c,
                                                                License_Holder_Address2__c,
                                                                License_Holder_City__c,
                                                                License_Holder_State__c,
                                                                License_Holder_Zipcode__c,
                                                                Partner_Owner__c,
                                                                Partner_Owner__r.Status__c
                                                                FROM Partner_Document__c 
                                                                WHERE Id =: pDocId LIMIT 1];
        if(myProviderDoc.Document_Type__c =='Workers Compensation Insurance')WorkersCompensationInsurance = true;
       closeWindow = false;  
    }
  

   public Partner_Document__c getProviderDoc() {
        return myProviderDoc;
    }
  
  public Document document {
    get {
      if (document == null)
        document = new Document();
      return document;
    }
    set;
  }
  @TestVisible private string validateDate(Date dt) {
     string errorMsg='';
     if (dt == null ) {
            errorMsg =   'Please complete the required information';    
        } else {
          try{
              dt = dt.addDays(1);
          }catch(Exception e){
              errorMsg =   'Please enter valid date';  
                return errorMsg;
          }
            
       }
     return   errorMsg;
       
  }
  public pagereference cancel(){
     system.debug('######## Cancel : ' + srcPage);
     PageReference pageRef;
     if (SrcPage == 'ServiceProviderActiveForm')  pageRef = Page.ServiceProviderActiveForm;
     else {
     if (SrcPage == 'LicenseValidationdefault')  pageRef = Page.LicenseValidationdefault;
        else   pageRef = Page.DocumentUpload;
     }
     pageRef.setRedirect(true);
     
     return pageRef;

  }    

  public boolean isEnableToParent{get;set;}
  public PageReference upload() {
          system.debug('inside Upload method>>>');
        isEnableToParent = false;
        spaSignedDateError = '';
        InsExpirationDateError = '';
        InsIssuingAuthorityError = '';
        InsCompanyNameError = '';
        InsPolicyNumberError = '';
        InsEffectiveDateError = '';
        LicExpirationDateError = '';
        LicEffectiveDateError = '';
        LicLevelError = '';
        //LicIssuingAuthorityError = '';
        LicClassificationError = '';
        LicDisputeReasonError = '';        
        InputDocError='';
        LicNumError ='';
      	EPALicExpirationDateError='';
        EPALicEffectiveDateError='';
      	EPACertificationNumberError='';
        
       try { 
        //ContentVersion c = new ContentVersion();
        if (DocType == 'Service Provider Agreement') {
           spaSignedDateError = validateDate(myProviderDoc.SPA_Signed_Date__c);
        }
        
        if (DocType == 'Insurance') {
            
            //Harsha : Start
           /* if(myProviderDoc.Effective_Date__c <> null &&  myProviderDoc.Expiration_Date__c <> null && myProviderDoc.Effective_Date__c > myProviderDoc.Expiration_Date__c){
                InsExpirationDateError = 'Expiration Date should be more then or equals to Effective date';
            } */
            //Harsha : End
            
            //Waiver check box is checked and expiration date is not entered - Still user will be able to save the document...
           /* if ((myProviderDoc.Workers_Compensation_Waiver__c == false) || (myProviderDoc.Workers_Compensation_Waiver__c == true && (myProviderDoc.Expiration_Date__c <> null)) {
               InsExpirationDateError = validateDate(myProviderDoc.Expiration_Date__c);   
            } */
            if (myProviderDoc.Workers_Compensation_Waiver__c == false && WorkersCompensationInsurance ) {
                InsExpirationDateError = validateDate(myProviderDoc.Expiration_Date__c);   
            }
            if (myProviderDoc.Workers_Compensation_Waiver__c == true && WorkersCompensationInsurance)  
                myProviderDoc.Expiration_Date__c =date.parse('12/31/4000');//defaul value when user check checkbox
            
               //InsEffectiveDateError = validateDate(myProviderDoc.Effective_Date__c);
            if ( myProviderDoc.Effective_Date__c == null ) InsEffectiveDateError='Effective date is a required field';
            
            if ( myProviderDoc.Expiration_Date__c == null ) InsExpirationDateError='Expiration date is a required field';
            
            if (InsEffectiveDateError.length() == 0 && InsExpirationDateError.length() ==0) {
                if (myProviderDoc.Effective_Date__c > myProviderDoc.Expiration_Date__c) 
                    InsExpirationDateError = 'Please enter the date greater than or equals to its Effective date';
            }
            
            if(myProviderDoc.Licensing_Authority_State__c == null &&  (myProviderDoc.Document_Type__c == 'Workers Compensation Waiver' || myProviderDoc.Document_Type__c == 'Workers Compensation Exemption') ){
                InsIssuingAuthorityError = 'Please enter Issuing Authority State';
            }
            if((myProviderDoc.Insured_Company_Name__c == null || (myProviderDoc.Insured_Company_Name__c).trim() == '' )&& myProviderDoc.Document_Type__c == 'Workers Compensation Exemption'){
                InsCompanyNameError = 'Company name is a required field';
            }
            if((myProviderDoc.Policy_Number__c == null || (myProviderDoc.Policy_Number__c).trim() == '' )&& myProviderDoc.Document_Type__c == 'Workers Compensation Exemption'){
                InsPolicyNumberError = 'Policy number is a required field';
            }
            
        }
        if (DocType == 'License') {
            if (myProviderDoc.License_Level1__c == null)   LicLevelError = 'Please complete the required information';
            //if (myProviderDoc.Issuing_Authority__c == null || myProviderDoc.Issuing_Authority__c == '') LicIssuingAuthorityError = 'Please complete the required information';
            if (myProviderDoc.Classification1__c == null)  LicClassificationError = 'Please complete the required information';
            if (myProviderDoc.License_Number__c == null || myProviderDoc.License_Number__c == '') LicNumError='Please complete the required information';
            LicExpirationDateError = validateDate(myProviderDoc.Expiration_Date__c);   
            LicEffectiveDateError = validateDate(myProviderDoc.Effective_Date__c);
            if (LicEffectiveDateError.length() == 0 && LicExpirationDateError.length() ==0) {
                if (myProviderDoc.Effective_Date__c > myProviderDoc.Expiration_Date__c) LicExpirationDateError = 'Please enter the date greater than or equals to its Effective date';
            }
        }
   
        //Start: Story 
        if (DocType == 'Environmental License') {
            System.debug('before updating PD rec in UI-  EPA_Certification_Number__c >>> ' + myProviderDoc.EPA_Certification_Number__c);
            if (myProviderDoc.EPA_Certification_Number__c == null)   EPACertificationNumberError = 'Please complete the required information';
            EPALicExpirationDateError = validateDate(myProviderDoc.Expiration_Date__c);   
            EPALicEffectiveDateError = validateDate(myProviderDoc.Effective_Date__c);
            if (EPALicEffectiveDateError.length() == 0 && EPALicExpirationDateError.length() ==0) {
                if (myProviderDoc.Effective_Date__c >= myProviderDoc.Expiration_Date__c) EPALicExpirationDateError = 'Please enter the date greater than Effective date';                
            }
            if (EPALicExpirationDateError.length() > 0 || EPALicEffectiveDateError.length() > 0 || EPACertificationNumberError.length() > 0 ) return null;

            if (file == null)
            {
                myProviderDoc.Document_Status__c  = 'Submitted';
                System.debug('before updating PD rec >>> ' + myProviderDoc);
                update  myProviderDoc;
                System.debug('after updating PD rec >>> ' + myProviderDoc);

                return cancel(); // This is to redirect to the calling Page after successful update.
            }

         }
   		//End: Story
        if (DocType == 'Dispute License') {
           if (selectedDisputeReason == Null || selectedDisputeReason == '')  {
              LicDisputeReasonError = 'Please complete the required information';
              isEnableToParent = true;
              return null;
            }
            else {
              myProviderDoc.Comments__c = selectedDisputeReason != Null  && selectedDisputeReason != '' ? selectedDisputeReason : '';
              myProviderDoc.Document_Status__c  = 'Under Review';
              myProviderDoc.Is_Disputed__c  = TRUE;  
              System.debug('before updating PD rec >>> ' + myProviderDoc);                          
              update  myProviderDoc;
              System.debug('after updating PD rec >>> ' + myProviderDoc);
             // ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Updated Successfully'));
            }
            closeWindow = true;
            return null;
        }
        else {
            
           if (file == null ) {
              InputDocError =   'Please select the input file';    
             }
           
           if (inpfilesize > 10485760) InputDocError = 'File size is greater than the 10 MB limit. Please email the document to your Service Provider Research Coordinator (SPRC).';
           if (spaSignedDateError.length() > 0 || InputDocError.length() > 0 || 
               InsExpirationDateError.length() > 0 || InsEffectiveDateError.length() > 0 || InsIssuingAuthorityError.length() > 0 || 
               LicExpirationDateError.length() > 0 || LicEffectiveDateError.length() > 0 || InsCompanyNameError.length() > 0 || 
               LicClassificationError.length() > 0 || LicLevelError.length() > 0 || InsPolicyNumberError.length() > 0 || 
               LicNumError.length() > 0)
             return null;
            
           Set<Id> contentIds = new Set<id>();
           Database.SaveResult result;
        
       
           for(ContentDocumentLink file : [select id, ContentDocumentId, LinkedEntityId from ContentDocumentLink where LinkedEntityId = :pDocId AND ContentDocumentId != NULL]) {
              contentIds.add(file.ContentDocumentId);
           }
        
           List<ContentDocument> contentDocs = new List<ContentDocument>([Select Id from ContentDocument where Id = :contentIds ]);
           if(contentDocs != null && contentDocs.size() > 0) {
              Delete contentDocs;
            }        
        
           ContentVersion content=new ContentVersion(); 
           content.Title=inpfileName; 
           content.PathOnClient='/' + content.Title;
           content.VersionData=EncodingUtil.base64Decode(EncodingUtil.Base64Encode(file)); 
            system.debug('***DEBUG*** - Attachment Body : '+ file);
           //system.debug('***DEBUG*** - Attachment Body Decode : '+ EncodingUtil.base64Decode(file.tostring()));
           content.origin = 'H';
           insert content;
           system.debug('############# : ' + content);
        
           ContentDocumentLink contentlink = new ContentDocumentLink();
            contentlink.LinkedEntityId=pDocId;
            contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
            contentlink.ShareType = 'V';

            result = Database.insert(contentlink);
        
           system.debug('######## result : ' + result);
           if (result.isSuccess()) {
            // if (DocType == 'License' && myProviderDoc.Document_Status__c == 'Needs revision' ) myProviderDoc.Comments__c = '';
             myProviderDoc.Comments__c = '';
             myProviderDoc.Document_Status__c              = 'Submitted'; 
             update myProviderDoc;
             ApexPages.addmessage(new ApexPages.message(ApexPages.severity.INFO,'Document uploaded Successfully'));
             if (myProviderDoc.Partner_Owner__r.Status__c == 'Document Ready for Upload') {
                 //Account PartnerAcc = new Account();
                 //PartnerAcc.Id = myProviderDoc.Partner_Owner__c;
                 //PartnerAcc.Status__c = 'Document Upload In Progress';
                 //update Account;
                 myProviderDoc.Partner_Owner__r.Status__c = 'Document Upload In Progress';
                 update myProviderDoc.Partner_Owner__r;
                }
            }
          }     
        } catch(DMLException excp) {  
            system.debug('######## error : ' + excp);
          } 

          if(pp != '1'){
/*                PageReference pageRef;
                if (SrcPage == 'ServiceProviderActiveForm')  pageRef = Page.ServiceProviderActiveForm;
                else {
                if (SrcPage == 'LicenseValidationdefault')  pageRef = Page.LicenseValidationdefault;
                else   pageRef = Page.DocumentUpload;
                }
                pageRef.setRedirect(true);
                return pageRef;*/

              return cancel();   // Commented the above lines and replaced with this cancel method to return to the previous page.
          }else{
              return null;
          }

  }
  public Pagereference done()
    {     
        closeWindow= true;
        return null;
    }
 
}