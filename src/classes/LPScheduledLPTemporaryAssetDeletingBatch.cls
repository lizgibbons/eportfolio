global class LPScheduledLPTemporaryAssetDeletingBatch implements Schedulable {

	global void execute(SchedulableContext SC) {
		LPTemporaryAssetDeletingBatch bc = new LPTemporaryAssetDeletingBatch();
		database.executeBatch(bc);
	}

}