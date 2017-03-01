global with sharing class LPHeadDORController {
  public LPHeadDORController() {
    
  }
  
  private Contact coReg {
    get {
      if (UserInfo.getUserType() != 'Guest' && coReg == NULL) {
        coReg = LPSignController.getContactRegistration(UserInfo.getUserId());
      }
      return coReg;
    }
    set;
  }
  
  public Boolean needAboutMe {
    get {
      if (needAboutMe == NULL && UserInfo.getUserType() != 'Guest' && coReg != NULL) {
        needAboutMe = LPSignController.needGenInfoComplete(coReg);
      }
      return needAboutMe;
    }
    set;
  }

  public Boolean needTerms {
    get {
      if (needTerms == NULL && UserInfo.getUserType() != 'Guest' && coReg != NULL) {
        needTerms = LPSignController.needTermsComplete(coReg, LPSignController.getActualLPAdmin()) == true;
      }
      return needTerms;
    }
    set;
  }


 public Boolean getAllowRedirect() {
    return UserInfo.getUserType() != 'Guest'
        && coReg != NULL
        && !currentPage(Page.LPAboutMe.getUrl())
        && !currentPage(Page.LPTermsAndConditions.getUrl())
        && !currentPage(Page.LPMyPhoto.getUrl())
        && !currentPage(Page.LPSignIn.getUrl())
        && !currentPage(Page.LPPickNewPassword.getUrl())
        && !currentPage(Page.LPRegistration.getUrl())
        && !currentPage(Page.LPSignIn.getUrl())
        && !currentPage(Page.LPRegistration.getUrl())
        && !currentPage(Page.LP404.getUrl());
  } 
  

   private static Boolean currentPage(String urlToCompare) {
    String currentPageName = ApexPages.currentPage().getUrl().replace('/apex',''); 
    urlToCompare = urlToCompare.replace('/apex','');
   // String pp = LPUtils.getPackagePrefix();
   // 	if (String.isNotBlank(pp)) {
   // 	  urlToCompare = urlToCompare.replace(pp, '' );
   // 	  currentPageName = currentPageName.replace(pp, '');
   // }
    return currentPageName.containsIgnoreCase(urlToCompare); 
  } 
  
  /*public static List<Menu__c> getMenuRecords() {
    return [SELECT Id, Name, URL__c, Sort_Order__c FROM Menu__c ORDER BY Sort_Order__c];
  } 
  
  public static List<Map<String, String>> getMapMenuRecords(List<Menu__c> menuRecords) {
    List<Map<String, String>> listMenuItems = new List<Map<String, String>>();
    for (Menu__c menuRecord : menuRecords) {
      Map<String, String> mapMenuItems = new Map<String, String>();
      mapMenuItems.put('name', menuRecord.Name);
      mapMenuItems.put('URL', menuRecord.URL__c);
      listMenuItems.add(mapMenuItems);
    }
    return listMenuItems;
  }*/
  
  /*@RemoteAction
  public static String serializeMenuRecords() {
    return '123';//JSON.serialize(getMapMenuRecords(getMenuRecords()));
  }*/
  
}