public with sharing class LPLearnerProfileController {

	public LPLearnerProfileController() {
	}

	private ApexPages.StandardController stdctrl;
	public LPLearnerProfileController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
	}

	// EDIT/VIEW MODE

	public Learner_Profile__c lp { get; set; }
	public LPFieldLayout lplayout { get; set; }
	public Boolean allCheckboxState { get; set; }

	public void initFromEdit() {
		lp = (Learner_Profile__c)stdctrl.getRecord();
		List<String> hardFields = new List<String> { 'Id' };
		lplayout = new LPFieldLayout(
			lp.Id,
			SObjectType.Learner_Profile__c.FieldSets.Edit_Learner_Profiles,
			SObjectType.Learner_Profile__c,
			hardFields,
			LPUtils.getPackagePrefix()
		);
		if (lp.Id != NULL) {
			lp = (Learner_Profile__c)lplayout.getRecord();
		}
	}

	public PageReference saveLearnerProfile() {
		PageReference pr;
		try {
			upsert lp;
			pr = Page.LPAssets;
			pr.getParameters().put('lp', lp.Id);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	// LIST MODE

	public EliforpPage getLPcrowd() {
		String fp = ApexPages.currentPage().getParameters().get('f');
		return new EliforpPage(String.isBlank(fp) ? '' : String.escapeSingleQuotes(fp));
	}

	public class EliforpPage {
		public List<Eliforp> lps { get; set; }
		public Boolean showURL { get; set; }
		public Boolean showStatus { get; set; }

		public EliforpPage(String inMode) {
			init(inMode);
		}

		public EliforpPage(Asset__c ina) {
			init('');
			Set<Id> checkedLPs = new Set<Id>();
			for (Asset_Learner_Profile__c alpItem : [SELECT Learner_Profile__c FROM Asset_Learner_Profile__c WHERE Asset__c = :ina.Id]) {
				checkedLPs.add(alpItem.Learner_Profile__c);
			}
			List<Eliforp> firstQueue = new List<Eliforp>();
			//List<Eliforp> secondQueue = new List<Eliforp>();
			for (Eliforp eleItem : lps) {
				eleItem.initializeCheckbox(checkedLPs.contains(eleItem.Id));
				if (eleItem.getShowLink()) {
					firstQueue.add(eleItem);
				}
				/*this second queue for inactive items
					else {
					secondQueue.add(eleItem);
				}*/
			}
			lps = firstQueue;
			//lps.addAll(secondQueue);
		}

		private void init(String inMode) {
			showURL = true;
			showStatus = SObjectType.Learner_Profile__c.fields.Status__c.isAccessible();
			String eQuery = 'SELECT Id, Name, Status__c, LastModifiedDate FROM Learner_Profile__c';
			eQuery += ' WHERE OwnerId =\'' + UserInfo.getUserId() + '\'';
			eQuery += String.isNotBlank(inMode) ? (' AND Status__c = \'' + inMode + '\''): '';
			eQuery += ' ORDER BY Name ASC';
			lps = new List<Eliforp>();
			for (Learner_Profile__c lpItem : Database.query(eQuery)) {
				lps.add(new Eliforp(lpItem));
			}
		}
	}

	public class Eliforp {
		public String name { get; set; }
		public String id { get; set; }
		public String status { get; set; }
		public String lmdate { get; set; }
		public Boolean checked { get; set; }
		public Boolean initialyChecked;

		public Eliforp(Learner_Profile__c inlp) {
			name = inlp.Name;
			id = inlp.Id;
			status = inlp.Status__c;
			lmdate = inlp.LastModifiedDate.format('MMM d, YYYY');
		}

		public void initializeCheckbox(Boolean inc) {
			checked = inc;
			initialyChecked = checked;
		}

		public String getRowColor() {
			String result = String.isBlank(status) ? '' : STATUS_TO_COLOR.get(status);
			return String.isBlank(result) ? '' : result;
		}

		public String getPublicLink() {
			return (status == 'Active' || status == 'Draft') ? (BASE_LP_LINK + id) : '';
		}

		public Boolean getShowLink() {
			return (status == 'Active' || status == 'Draft');
		}

	}

	private static Map<String, String> STATUS_TO_COLOR = new Map<String, String> {
		'Active' => 'success',
		'Draft' => 'warning',
		'Inactive' => 'danger'
	};

	public static String BASE_LP_LINK = Site.getBaseUrl() + Page.LearnerProfile.getUrl().replace('/apex/','/') + '?lp=';

	// ADD/REMOVE ASSET TO LP MODE

	public List<CategoryAsset> categories { get; set; }
	public transient String lpName { get; set; }
	public Boolean withoutCategory { get { return withoutCategory == NULL ? true : withoutCategory; } set; }

	public void initFromAddRemove() {
		String arparam = ApexPages.currentPage().getParameters().get('lp');
		Schema.PicklistEntry categoryParam = checkCategoryParameter();
		List<Learner_Profile__c> checkLPlist = [
			SELECT Id, Name FROM Learner_Profile__c
			WHERE Id = :String.escapeSingleQuotes(arparam)
			AND OwnerId = :UserInfo.getUserId()
			AND Status__c IN ('Active', 'Draft')
				];
		categories = new List<CategoryAsset>();
		if (checkLPlist.size() > 0) {
			Id lpId = checkLPlist[0].Id;
			lpName = checkLPlist[0].Name;
			Set<Id> checkedAssets = new Set<Id>();
			for (Asset_Learner_Profile__c alpItem : [SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = :lpId]) {
				checkedAssets.add(alpItem.Asset__c);
			}
			Map<String, CategoryAsset> assemblyCategoryMap = new Map<String, CategoryAsset>();
			for (Asset__c aItem : [SELECT Id, Name, Category__c, LastModifiedDate FROM Asset__c WHERE Status__c = 'Active' AND User__c = :UserInfo.getUserId() ORDER BY Name ASC]) {
				String catUnique = String.isBlank(aItem.Category__c) ? 'none' : aItem.Category__c;
				catUnique = catUnique.replace(' ', '').toLowerCase();
				if (!assemblyCategoryMap.containsKey(catUnique)) {
					assemblyCategoryMap.put(catUnique, new CategoryAsset(aItem.Category__c, catUnique));
				}
				assemblyCategoryMap.get(catUnique).assets.add(new AssetProfile(aItem, checkedAssets.contains(aItem.Id)));
			}
			withoutCategory = categoryParam == NULL;
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				String tc3 = pe.getValue().replace(' ','').toLowerCase();
				if (assemblyCategoryMap.containsKey(tc3) && (withoutCategory || pe.getValue() == categoryParam.getValue())) {
					categories.add(assemblyCategoryMap.get(tc3));
				}
			}
		}
	}

	public PageReference submitAddRemove() {
		Set<Id> deleteAssetProfile = new Set<Id>();
		List<Asset_Learner_Profile__c> createAssetProfile = new List<Asset_Learner_Profile__c>();
		Id lpId = ApexPages.currentPage().getParameters().get('lp');
		for (CategoryAsset caItem : categories) {
			for (AssetProfile apItem : caItem.assets) {
				if (apItem.initialyChecked != apItem.checked) {
					if (apItem.checked) {
						createAssetProfile.add(new Asset_Learner_Profile__c(Asset__c = apItem.aId, Learner_Profile__c = lpId));
					}
					else {
						deleteAssetProfile.add(apItem.aId);
					}
				}
			}
		}
		if (createAssetProfile.size() > 0) {
			insert createAssetProfile;
		}
		if (deleteAssetProfile.size() > 0) {
			delete [SELECT Id FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = :lpId AND Asset__c IN :deleteAssetProfile];
		}
		return createRetUrl(lpId);
	}

	public PageReference cancelAddRemove() {
		Id lpId = ApexPages.currentPage().getParameters().get('lp');
		return createRetUrl(lpId);
	}

	public void ChangeAllCheckbox() {
		for (CategoryAsset caItem : categories) {
			for (AssetProfile apItem : caItem.assets) {
				apItem.checked = allCheckboxState;
			}
		}
	}


	private PageReference createRetUrl(Id inLpId) {
		PageReference pr = Page.LPAssets;
		pr.getParameters().put('lp', inLpId);
		Schema.PicklistEntry cp = checkCategoryParameter();
		if (cp != NULL) {
			pr.getParameters().put('c', cp.getValue());
		}
		pr.setRedirect(true);
		return pr;
	}

	private Schema.PicklistEntry checkCategoryParameter() {
		LPAssetController bro = new LPAssetController();
		return bro.getCategoryParam();
	}

	public class CategoryAsset {
		public List<AssetProfile> assets { get; set; }
		public String name { get; set; }
		public String unique { get; set; }

		public CategoryAsset(String inn, String inu) {
			assets = new List<AssetProfile>();
			name = inn;
			unique = inu;
		}
	}

	public class AssetProfile {
		public Boolean checked { get; set; }
		public String name { get; set; }
		public String lmdate { get; set; }
		public Id aId;
		public Boolean initialyChecked;

		public AssetProfile(Asset__c ina, Boolean inic) {
			checked = inic;
			initialyChecked = inic;
			name = ina.Name;
			lmdate = ina.LastModifiedDate.format('MMM d, YYYY');
			aId = ina.Id;
		}
	}

}
