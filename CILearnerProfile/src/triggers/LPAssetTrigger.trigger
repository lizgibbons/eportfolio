trigger LPAssetTrigger on Asset__c (after update) {

	Set<Id> deactivatedAssets = new Set<Id>();
	for (Asset__c aItem : Trigger.new) {
		if (aItem.Status__c == 'Inactive' && Trigger.oldMap.get(aItem.Id).Status__c != 'Inactive') {
			deactivatedAssets.add(aItem.Id);
		}
	}

	if (deactivatedAssets.size() > 0) {
		delete [SELECT Id FROM Asset_Learner_Profile__c WHERE Asset__c IN :deactivatedAssets];
	}

}