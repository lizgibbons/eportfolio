public with sharing class LPHeaderController {
  List<Menu__c> menuItems;
  /* grabs list of records in Menu__c for display in header */
  public List<Menu__c> getMenuItems() {
    return [SELECT Id, Name, URL__c, Sort_Order__c FROM Menu__c ORDER BY Sort_Order__c]; 
  }
  /* Logo for display in internal header */
  public String getLogoUrl() {
    LP_Template_Settings__c lpts = LP_Template_Settings__c.getOrgDefaults();
    return (lpts == NULL || String.isBlank(lpts.Header_Logo__c)) ? NULL : lpts.Header_Logo__c;
  }
}