global class LPScheduledLPTemporaryAssetDeletingBatch implements Schedulable {
	/* Allows scheduling for delete the temp assets created by the drag and drop feature */
	global void execute(SchedulableContext SC) {
		LPTemporaryAssetDeletingBatch bc = new LPTemporaryAssetDeletingBatch();
		database.executeBatch(bc);
	}

}