global without sharing class LPSignController {
  public class LPSignException extends Exception {}

  public LPSignController() {}

  public String username { get; set; }
  public String firstname { get; set; }
  public String lastname { get; set; }
  public String password { get; set { password = value == null ? value : value.trim(); } }
  public String confirmpassw { get; set { confirmpassw = value == null ? value : value.trim(); } }
  public String email { get; set; }
  public Id accountId { get; set; }
  public Id profileId { get; set; }
  public Boolean editMode { get { return editMode == NULL ? false : editMode; } set; }
  public Integer resetPasswordMode { get { return resetPasswordMode == NULL ? 0 : resetPasswordMode; } set; }
  public String emailToReset { get; set; }
  public String oldPassword { get; set; }
  public String verifyPassword { get; set; }
  public String pageErrors { get; set; } 

  public Contact co { get; set; }
  public List<LPFieldLayout.Field> flds { get; set; }
  private List<String> fieldNames { get; set; }
  public Contact aboutmeRegContact { get; set; }
  public Boolean aboutmeIsFinished { get { return aboutmeIsFinished == NULL ? false : aboutmeIsFinished; } set; }
  public Boolean aboutMeSubmit { get { return aboutMeSubmit == NULL ? false : aboutMeSubmit; } set; }

  @TestVisible 
  private LPFieldLayout colayout { get; set; }

  //terms and conditions page
  public Contact termsRegContact { get; set; }
  public DOR_LP_Admin__c termsLPAdmin { get; set; }
  public Boolean termsIsAccepted { get; set; }

  public Boolean getRegMode() {
    return System.currentPageReference().getParameters().get('reg') == 'true';
  }

  public final static Map<String, String> CUSTOM_LABELS = new Map<String, String> {
    //'HomePhone' => Label.LBL_Home_Phone,
    'MobilePhone' => Label.LBL_Cell_Phone,
    'MailingStreet' => Label.LBL_Address,
    'MailingCity' => Label.LBL_City,
    'MailingState' => Label.LBL_State,
    'MailingPostalCode' => Label.LBL_Zip,
    //'Alternate_Email__c' => Label.LBL_Alternate_Email,
    'Highest_Education__c' => Label.LBL_Highest_Level_Education,
   // 'Library_Card_Number__c' => Label.LBL_Library_Card_Number,
    'Educational_Status__c' => Label.LBL_Student_Status,
    'Employment_Status__c' => Label.LBL_Employment_Status
  };


  public PageReference login() {
    Boolean isRedirectPage = false;
    String startUrl = System.currentPageReference().getParameters().get('startURL');
    List<User> userList = [SELECT Id, Username FROM User WHERE Email = :username AND isActive = true AND IsPortalEnabled = true LIMIT 1];
    if (userList.size() > 0) {
      PageReference registerStepPage = getRegistrationPage(userList[0].Id, false);
      if (registerStepPage != NULL) {
        startUrl = registerStepPage.getUrl();
      }
    }
    PageReference pr = Site.login(username, password, startUrl);
    if (pr == null) {
      String loginUser;
      if (userList.size() > 0) {
        List<UserLogin> userLoginInfo = [SELECT IsPasswordLocked FROM UserLogin WHERE UserId = :userList[0].Id LIMIT 1];
        if (userLoginInfo.size() > 0) {
          Boolean isLockedUser = userLoginInfo[0].IsPasswordLocked;
          if (isLockedUser) {
            pageErrors = Label.LBL_Locked_Account;
            return null;
          }      
        }        
      }
      List<ApexPages.Message> apexPageErrors = ApexPages.getMessages();
      for (ApexPages.Message apexMessage : apexPageErrors) {
        pageErrors = apexMessage.getDetail();
        break;
      }
      return null;
    }
    return pr;
  }


  public void resetPasswordAction() {
    if (resetPasswordMode == 2 && String.IsNotBlank(emailToReset)) {
      List<User> userList = [SELECT Id, Username FROM User WHERE Email = :emailToReset AND isActive = true AND IsPortalEnabled = true LIMIT 1];
      if (userList.size() > 0) {
        System.resetPassword(userList[0].Id, true);
      }
    }
  }


  public PageReference changePassword() {
    return Site.changePassword(password, verifyPassword, oldPassword);
  }


  public void initFromRegistration() {
    loadInputRows(true);
    try {
      if (accountId == null) {
        accountId = Id.valueOf(System.currentPageReference().getParameters().get('code'));
        accountId = [SELECT Id FROM Account WHERE Id =:accountId].Id;
      }
    }
    catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LBL_Sign_up_Account_Error));
    }
    try {
      profileId = [
        SELECT Id FROM Profile WHERE Name = 'Learner Profile Community User'
        AND Id IN (SELECT ParentId FROM NetworkMemberGroup WHERE NetworkId = :Network.getNetworkId())
        LIMIT 1
      ].Id;
    }
    catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LBL_Sign_up_Profile_Error));
    }
  }

  public Boolean getIsMathPasswords() {
    return password == confirmpassw;
  }
  public PageReference createCustomerUser() {
    PageReference pr;
    Savepoint sp = Database.setSavepoint();
    try {
      List<User> existEmailUsers = [SELECT Id FROM User WHERE Email = :email AND isActive = true];
      if (existEmailUsers.size() > 0) {
        throw new LPSignException(Label.LBL_Sign_up_Email_Error);
      }
      if (!getIsMathPasswords()) {
        throw new LPSignException(Label.ERR_Passwords_Mismatch);
      }
      String createAlias = String.isNotBlank(firstname) ? firstname.substring(0,1) : '';
      createAlias += lastname.length() > 4 ? lastname.substring(0,4) : lastname.substring(0,lastname.length());
      User resu = new User(
        Email = email,
        LastName = lastname,
        FirstName = firstname,
        CommunityNickname = createAlias.toLowerCase() + '.' + generateRandomString(8),
        ProfileId = profileId,
        UserName = email
      );
		
      Id userId = Site.createPortalUser(resu, accountId, password);
      
      if (userId != NULL) {
        List<User> uList = Database.query('SELECT ContactId, Contact.Id, Contact.' + String.join(fieldNames, ', Contact.') + ' FROM User WHERE Id = :userId');
        if (uList.size() > 0 && uList[0].ContactId != NULL) {
          Contact contactToUpdate = uList[0].Contact;
          
          for (LPFieldLayout.Field fld : flds) {
            if (fld.ftype == 'email') {
              String emailadr = (String)co.get(fld.name);
              if (String.isNotBlank(emailadr) && !emailIsValid(emailadr)) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, fld.label + ': invalid email address: ' + emailadr));
                throw new LPSignException(fld.label + ': invalid email address: ' + emailadr);
              }
            }
            if (co.get(fld.name) != null) {
              contactToUpdate.put(fld.name, co.get(fld.name));
            }
          }
          contactToUpdate.Reg_General_Info_Completed__c = Datetime.now();
          update contactToUpdate;
        }
        PageReference registerStepPage = getRegistrationPage(uList[0].Id, true);
        pr = Site.login(email, password, registerStepPage.getUrl());
      }
     
    }
    
    catch (Exception e) {
      Database.rollback(sp);
      ApexPages.addMessages(e);
    }
    return pr;
  }


  public void initFromAboutMe() {
    loadInputRows(false);
    if (co.Id == NULL) {
      throw new LPSignException();
    }
    aboutmeRegContact = (aboutmeRegContact == NULL) ? getContactRegistration(UserInfo.getUserId()) : aboutmeRegContact;
    aboutmeIsFinished = !needGenInfoComplete(aboutmeRegContact);
    if (!aboutmeIsFinished) {
      editMode = true;
    }
    aboutMeSubmit = !needTermsComplete(getContactRegistration(UserInfo.getUserId()), getActualLPAdmin());
  }


  public PageReference editAboutMe() {
    PageReference pr;
    editMode = true;
    return pr;
  }


  public PageReference updateAboutMe() {
    PageReference pr;
    
    if (co.Id == NULL) {
      throw new LPSignException();
    }
    else {
      Savepoint sp = Database.setSavepoint();
      try {
        for (LPFieldLayout.Field fld : flds) {
          if (fld.ftype == 'email') {
            String emailadr = (String)co.get(fld.name);
            if (String.isNotBlank(emailadr) && !emailIsValid(emailadr)) {
              ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, fld.label + ': invalid email address: ' + emailadr));
              throw new LPSignException(fld.label + ': invalid email address: ' + emailadr);
              return pr;
            }
          }
        }
        co.Reg_General_Info_Completed__c = Datetime.now();
        upsert co;
        if (!getRegMode()) {
          editMode = false;
          pr = Page.LPAboutMe;
          pr.setRedirect(true);
        }
        aboutmeRegContact.Reg_General_Info_Completed__c = co.Reg_General_Info_Completed__c;
        aboutmeIsFinished = true;

        if (getRegMode()) {
          if (aboutMeSubmit) {
            pr = Page.LPAssets;
          }
          else {
            pr = Page.LPMyPhoto;
            pr.getParameters().put('reg', 'true');
          }
        }
      }
      catch (Exception e) {
        Database.rollback(sp);
        ApexPages.addMessages(e);
        pr = null;
      }
    }
    return pr;
  }


  public PageReference cancelAboutMe() {
    initFromAboutMe();
    editMode = false;
    return null;
  }


  public void loadInputRows(Boolean isReg) {
    Set<String> ignoredFields = new Set<String> { 'Reg_General_Info_Completed__c' };
    if (isReg) {
      co = new Contact();
      ignoredFields.addAll(new Set<String> { 'FirstName', 'LastName', 'Email' });
    }
    else {
      List<User> uList = [SELECT ContactId, Contact.Id FROM User WHERE Id = : UserInfo.getUserId()];
      if (uList.size() > 0 && uList[0].ContactId != NULL) {
        co = uList[0].Contact;
      }
    }

    List<String> hardFields = new List<String> { 'Id', 'Highest_Education__c'};
    hardFields.addAll(ignoredFields);

    colayout = new LPFieldLayout(
      co.Id,
      SObjectType.Contact.FieldSets.LPRegBioDemo,
      SObjectType.Contact,
      hardFields,
      ''//LPUtils.getPackagePrefix()
    );

    if (isReg != true) {
      co = (Contact)colayout.getRecord();
    }
    
    flds = new List<LPFieldLayout.Field>();
    fieldNames = new List<String>();
    for (LPFieldLayout.Field fld : colayout.flds) {
      fieldNames.add(fld.name);
      if (!ignoredFields.contains(fld.name)) {
        if (CUSTOM_LABELS.containsKey(fld.name)) {
          fld.label = CUSTOM_LABELS.get(fld.name);
        }
        flds.add(fld);
      }
    }
  }


  public void initFromTerms() {
    termsRegContact = getContactRegistration(UserInfo.getUserId());
    termsLPAdmin = getActualLPAdmin();
    termsIsAccepted = !needTermsComplete(termsRegContact, termsLPAdmin);
  }


  public PageReference acceptTerms() {
    PageReference pr;
    if (termsRegContact == NULL) {
      throw new LPSignException();
    }
    termsRegContact.Reg_T_C_Completed__c = Datetime.now();
    upsert termsRegContact;
    termsIsAccepted = true;
    if (getRegMode()) {
      pr = Page.LPAssets;
    }
    return pr;
  }


  public static DOR_LP_Admin__c getActualLPAdmin() {
    List<DOR_LP_Admin__c> aList = [  SELECT   Terms_Body__c, 
                        Terms_Status__c, 
                        Terms_Published_Date__c,
                        Terms_Archived_Date__c, 
                        Terms_Req_New_Signature__c,
                        Name, 
                        Id 
                    FROM DOR_LP_Admin__c 
                    WHERE Terms_Status__c = 'Published' 
                      AND Terms_Published_Date__c != NULL 
                    ORDER BY Terms_Published_Date__c DESC LIMIT 1];
    return (!aList.isEmpty()) ? aList[0] : null;
  }


  public static Contact getContactRegistration(Id userId) {
    List<User> uList = [SELECT 
                ContactId, 
                Contact.Id, 
                Contact.Registration_Completed__c, 
                Contact.Reg_General_Info_Completed__c, 
                Contact.Reg_Picture_Completed__c, 
                Contact.Reg_T_C_Completed__c 
              FROM User 
              WHERE Id = :userId];
    return (uList.size() > 0 && uList[0].ContactId != NULL) ? uList[0].Contact : null;
  }


  public Boolean emailIsValid(String emailAddress) {
    //String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
    String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]\\.[a-z]\\.[a-z]\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,30}|[0-9])';
    return Pattern.compile(emailRegex).matcher(emailAddress).matches();
  }


  public static Boolean needGenInfoComplete(Contact coReg) {
    return coReg.Reg_General_Info_Completed__c == NULL;
  }


  public static Boolean needPhotoComplete(Contact coReg) {
    return coReg.Reg_Picture_Completed__c == NULL;
  }


  public static Boolean needTermsComplete(Contact coReg, DOR_LP_Admin__c actualLpA) {
    if (actualLpA == NULL) {
      return false;
    }
    if (coReg.Reg_T_C_Completed__c == NULL) {
      return true;
    }
    if (!actualLpA.Terms_Req_New_Signature__c) {
      return false;
    }
    if (coReg.Reg_T_C_Completed__c < actualLpA.Terms_Published_Date__c) {
      return true;
    }
    return false;
  }


  public static PageReference getRegistrationPage(Id userId, Boolean regProcces) {
    PageReference pr;
    Contact coReg = getContactRegistration(userId);
    if (coReg != NULL) {
      if (needGenInfoComplete(coReg)) {
        pr = Page.LPAboutMe;
        pr.getParameters().put('reg', 'true');
      }
      else if (regProcces == true && needPhotoComplete(coReg)) {
        pr = Page.LPMyPhoto;
        pr.getParameters().put('reg', 'true');
      }
      else if (needTermsComplete(coReg, getActualLPAdmin())) {
        pr = Page.LPTermsAndConditions;
        pr.getParameters().put('reg', 'true');
      }
      return pr;
    }
    return null;
  }
  
  public String getLogoUrl() {
    LP_Template_Settings__c lpts = LP_Template_Settings__c.getOrgDefaults();
    return (lpts == NULL || String.isBlank(lpts.Header_Logo__c)) ? NULL : lpts.Header_Logo__c;
  }


  @TestVisible 
  private static String generateRandomString(Integer len) {
    final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
    String randStr = '';
    while (randStr.length() < len) {
      Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
      randStr += chars.substring(idx, idx+1);
    }
    return randStr; 
  }
}