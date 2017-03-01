global class LPTemporaryAssetDeletingBatch implements Database.Batchable<sObject> {
	/* Deletes the temp assets created by the drag and drop feature */
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM ' + LPUtils.getPackagePrefix() + 'Asset__c WHERE Name = \'Temporary Asset\'';
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List<Asset__c> scope) {
		try {
			delete scope;
		} catch (Exception e) {
			System.debug('Deleting error| ' + e);
		}
	}

	global void finish(Database.BatchableContext BC) {

	}

}