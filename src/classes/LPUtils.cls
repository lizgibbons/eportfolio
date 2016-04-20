public with sharing class LPUtils {

	public static String getPackagePrefix() {
		return LPUtils.class.getName().substringBefore('LPUtils').replace('.','__');
	}

	public static String convertFileSize(Integer insize) {
		String result = '0 Bytes';
		if (insize != NULL) {
			if (insize < 1024) {
				result = String.valueOf(insize) + ' Bytes';
			}
			else if (insize < 1048576) {
				result = String.valueOf(Decimal.valueOf(insize).divide(1024,2)) + ' KB';
			}
			else if (insize < 1073741824) {
				result = String.valueOf(Decimal.valueOf(insize).divide(1048576,2)) + ' MB';
			}
			else {
				result = String.valueOf(Decimal.valueOf(insize).divide(1073741824,2)) + ' GB';
			}
		}
		return result;
	}

	public static String checkUrl(String inUrl) {
		if (String.isNotBlank(Site.getPathPrefix()) && !inUrl.startsWith(Site.getPathPrefix())) {
			inUrl = Site.getPathPrefix() + inUrl;
		}
		return inUrl;
	}

	public static PageReference getSiteTemplatePage() {
		LP_Template_Settings__c setting = LP_Template_Settings__c.getOrgDefaults();
		String customPage = setting != null ? setting.Site_Template_Label__c : '';
		if (String.isNotBlank(customPage)) {
			customPage = customPage.contains('__') ? customPage : 'c__' + customPage;

			String queryPrefix = customPage.contains('__') ? customPage.substringBefore('__') : '';
			String queryPage = customPage.contains('__') ? customPage.substringAfter('__') : customPage;

			List<Apexpage> lst = new List<Apexpage>();
			if (String.isNotBlank(queryPrefix) && !queryPrefix.equalsIgnoreCase('c')) {
				lst = [SELECT Id FROM Apexpage WHERE Name = :queryPage AND NamespacePrefix = :queryPrefix];
			}
			else {
				lst = [SELECT Id FROM Apexpage WHERE Name = :queryPage];
			}
			if (!lst.isEmpty()) {
				return new PageReference('/apex/' + customPage);
			}
		}
		String siteTemplatePage = Site.getTemplate().getUrl();
		if (String.isNotBlank(siteTemplatePage)) {
			siteTemplatePage = siteTemplatePage.contains('/') ? siteTemplatePage.substringAfterLast('/') : siteTemplatePage;
			siteTemplatePage = siteTemplatePage.contains('__') ? siteTemplatePage : 'c__' + siteTemplatePage;
			return new PageReference('/apex/' + siteTemplatePage);
		}
		return Site.getTemplate();
	}

}
