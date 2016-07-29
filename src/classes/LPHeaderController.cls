public class LPHeaderController {
	public String getLogoUrl() {
		LP_Template_Settings__c lpts = LP_Template_Settings__c.getOrgDefaults();
		return (lpts == NULL || String.isBlank(lpts.Header_Logo__c)) ? NULL : lpts.Header_Logo__c;
	}
}