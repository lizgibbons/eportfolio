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
}