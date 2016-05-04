global class LPTemporaryAssetDeletingBatch implements Database.Batchable<sObject> {

	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT id FROM Asset__c WHERE Name=\'Temporary Asset\'';
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