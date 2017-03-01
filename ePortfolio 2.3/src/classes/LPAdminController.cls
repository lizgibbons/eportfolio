public with sharing class LPAdminController {

	public LP_Template_Settings__c ts { get; set; }
	public Boolean tsEdit { get { return tsEdit == true; } set; }

	public LPAdminController() {
		ts = LP_Template_Settings__c.getOrgDefaults();
	}

	public List<String> getFieldsTS() {
		List<String> fieldList = new List<String>();
		for (Schema.SObjectField df : SObjectType.LP_Template_Settings__c.fields.getMap().values()) {
			Schema.DescribeFieldResult dfr = df.getDescribe();
			if (dfr.getName().endsWith('__c')) {
				fieldList.add(dfr.getName());
			}
		}
		fieldList.sort();
		return fieldList;
	}

	public void editTS() {
		ts = (LP_Template_Settings__c)cleganeHound(ts,SObjectType.LP_Template_Settings__c);
		tsEdit = true;
	}

	public void saveTS() {
		try {
			upsert ts;
			tsEdit = false;
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
	}

	public void cancelTS() {
		ts = (LP_Template_Settings__c)cleganeHound(LP_Template_Settings__c.getOrgDefaults(), SObjectType.LP_Template_Settings__c);
		tsEdit = false;
	}

	// Populates empty custom setting with default values
	private SObject cleganeHound(SObject incs, Schema.DescribeSObjectResult dsor) {
		if (incs.get('Id') == NULL) {
			Savepoint sp = Database.setSavepoint();
			try {
				insert incs;
				List<String> flds = new List<String>();
				for (Schema.SObjectField df : dsor.fields.getMap().values()) {
					Schema.DescribeFieldResult dfr = df.getDescribe();
					if (dfr.getName().endsWith('__c')) {
						flds.add(dfr.getName());
					}
				}
				incs = Database.query('SELECT ' + String.join(flds, ', ') + ' FROM ' + dsor.getName() + ' WHERE Id = \'' + (String)incs.get('Id') + '\'');
				incs.put('Id', NULL);
			}
			catch (Exception e) {}
			Database.rollback(sp);
		}
		return incs;
	}
}