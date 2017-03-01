@isTest
private class DORLPAdminTriggerTest
{
  @isTest
  static void DORLPAdminTest()
  {
    DOR_LP_Admin__c first = new DOR_LP_Admin__c (
        Terms_Body__c = 'Body',
        Terms_Status__c = 'Published'
      );
    insert first;
    List<DOR_LP_Admin__c> firstL = getDORLPAdmin(first.Id);
    System.assert(firstL[0].Terms_Published_Date__c != null);

    DOR_LP_Admin__c second = new DOR_LP_Admin__c (
        Terms_Body__c = 'Body',
        Terms_Status__c = 'Published'
      );
    insert second;
    firstL = getDORLPAdmin(first.Id);
    System.assert(firstL[0].Terms_Status__c == 'Archived');
    System.assert(firstL[0].Terms_Archived_Date__c != null);

    DOR_LP_Admin__c third = new DOR_LP_Admin__c (
        Terms_Body__c = 'Body',
        Terms_Status__c = 'Archived'
      );
    insert third;
    List<DOR_LP_Admin__c> thirdL = getDORLPAdmin(third.Id);
    System.assert(thirdL[0].Terms_Archived_Date__c != null);
    
    List<DOR_LP_Admin__c> secondL = getDORLPAdmin(second.Id);
    secondL[0].Terms_Status__c = 'Archived';
    update secondL;
    secondL = getDORLPAdmin(secondL[0].Id);
    System.assert(secondL[0].Terms_Archived_Date__c != null);

    thirdL[0].Terms_Status__c = 'Published';
    update thirdL;
    thirdL = getDORLPAdmin(thirdL[0].Id);
    System.assert(thirdL[0].Terms_Published_Date__c != null);
    
    List<DOR_LP_Admin__c> delL = new List<DOR_LP_Admin__c> ();
    delL.addAll(firstL);
    delL.addAll(secondL);
    delL.addAll(thirdL);
    delete delL;
    
    undelete delL;
    thirdL = getDORLPAdmin(third.Id);
    System.assert(thirdL[0].Terms_Status__c == 'Archived');
    System.assert(thirdL[0].Terms_Archived_Date__c != null);
  }

  public static List<DOR_LP_Admin__c> getDORLPAdmin(Id theId) {
    return (List<DOR_LP_Admin__c>)[SELECT Terms_Status__c, Terms_Published_Date__c, Terms_Archived_Date__c, Id FROM DOR_LP_Admin__c WHERE Id =: theId];
  }
}