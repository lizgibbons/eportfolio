trigger DORLPAdmin on DOR_LP_Admin__c (before insert, before update, after undelete) {

    if (trigger.isBefore) {
        Set<Id> triggerPublishIds = new Set<Id>();
        if (trigger.isInsert) {
          for (DOR_LP_Admin__c na : trigger.new) {
            if (na.Terms_Status__c == 'Published') {
              na.Terms_Published_Date__c = Datetime.now();
              triggerPublishIds.add(na.Id);
            }
            else if (na.Terms_Status__c == 'Archived') {
              na.Terms_Archived_Date__c = Datetime.now();
            }
          }
        }
        else if (trigger.isUpdate) {
          Map<Id, DOR_LP_Admin__c> oldMap = trigger.oldMap;
          for (DOR_LP_Admin__c na : trigger.new) {
            if (na.Terms_Status__c == 'Published') {
              if (oldMap.containsKey(na.Id) && oldMap.get(na.Id).Terms_Status__c != 'Published') {
                na.Terms_Published_Date__c = Datetime.now();
                triggerPublishIds.add(na.Id);
              }
            }
            else if (na.Terms_Status__c == 'Archived') {
              if (oldMap.containsKey(na.Id) && oldMap.get(na.Id).Terms_Status__c != 'Archived') {
                na.Terms_Archived_Date__c = Datetime.now();
              }
            }
          }
        }
        if (!triggerPublishIds.isEmpty()) {
          Set<Id> ignoredIds = (trigger.isUpdate) ? trigger.newMap.keySet() : new Set<Id>();
          List<DOR_LP_Admin__c> archived = [SELECT Id, SystemModstamp, Terms_Status__c, Terms_Published_Date__c, Terms_Archived_Date__c FROM DOR_LP_Admin__c WHERE Terms_Status__c = 'Published' AND Id NOT IN : ignoredIds];
          if (archived!= null && !archived.isEmpty()) {
            for (DOR_LP_Admin__c na : archived) {
              na.Terms_Status__c = 'Archived'; 
              na.Terms_Archived_Date__c = Datetime.now(); 
            }
            update archived;
          }
        }
      }
    
      if (trigger.isAfter && trigger.isUndelete) {
        List<DOR_LP_Admin__c> undeleted = [SELECT Id, SystemModstamp, Terms_Status__c, Terms_Published_Date__c, Terms_Archived_Date__c FROM DOR_LP_Admin__c WHERE Id IN : trigger.newMap.keySet()];
    
        if (undeleted!= null && !undeleted.isEmpty()) {
          for (DOR_LP_Admin__c na : undeleted) {
            na.Terms_Status__c = 'Archived'; 
            na.Terms_Archived_Date__c = Datetime.now(); 
          }
          update undeleted;
        }
      }
    
    

}