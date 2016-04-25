public without sharing class LPAssetController {

	public LPAssetController() {
	}

	private ApexPages.StandardController stdctrl;
	public LPAssetController(ApexPages.StandardController stdController) {
		stdctrl = stdController;
	}

	// COMMON

	public Schema.PicklistEntry getCategoryParam() {
		Schema.PicklistEntry result;
		String cParam = ApexPages.currentPage().getParameters().get('c');
		if (String.isNotBlank(cParam)) {
			String categoryNotFiltred = cParam.toLowerCase();
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				if(pe.getValue().toLowerCase() == categoryNotFiltred) {
					result = pe;
					break;
				}
			}
		}
		return result;
	}

	// EDIT/VIEW MODE

	public Asset__c tesla { get; set; }
	public Blob imgBody { get; set; }
	public String imgFileName { get; set; }
	public String imgContentType { get; set; }
	public String linkText { get; set; }
	public LPFieldLayout flayout { get; set; }
	public Boolean isDel { get { return isDel == true; } set; }
	public String attachmentId { get; set; }
	public Boolean fileIndicator { get; set; }
	public String LBL_Welcome_to_Portfolio {
		get {
			return string.format(Label.LBL_Welcome_to_Portfolio_c, new List<String>{PortfolioOwnerName});
		}
	}

	public void initFromEdit() {
		init();
	}

	public LPLearnerProfileController.EliforpPage efp { get; set; }

	public void initFromView() {
		init();
		efp = new LPLearnerProfileController.EliforpPage(tesla);
	}

	private void init() {
		lpMode = String.isNotBlank(ApexPages.currentPage().getParameters().get('lp'));
		
		List<Asset__c> check = [SELECT Id, IsDeleted FROM Asset__c WHERE Id = :stdctrl.getId() ALL ROWS];
		isDel = (!check.isEmpty() && check[0].IsDeleted == false) ? false : true;
		tesla = isDel ? new Asset__c() : (Asset__c)stdctrl.getRecord();

		List<String> hardFields = new List<String> {'Id', 'Name', 'Link__c', 'Category__c', 'Status__c', 
			'(SELECT Id, IsNote, Title FROM NotesAndAttachments WHERE IsNote = false ORDER BY CreatedDate DESC LIMIT 1)'
		};

		flayout = new LPFieldLayout(
			tesla.Id,
			SObjectType.Asset__c.FieldSets.Edit_Assets,
			SObjectType.Asset__c,
			hardFields,
			LPUtils.getPackagePrefix()
		);

		if (tesla.Id != NULL) {
			tesla = (Asset__c)flayout.getRecord();
		}
		else {
			Schema.PicklistEntry pe2 = getCategoryParam();
			if (pe2 != NULL) {
				tesla.Category__c = pe2.getValue();
			}
		}
	}

	public String getDelRedirectParam() {
		String c = (tesla == NULL) ? '' : tesla.Category__c;
		String lp = lpMode ? ApexPages.currentPage().getParameters().get('lp') : '';
		return ((String.isNotBlank(c)) ? 'c='+c : '') + ((String.isNotBlank(lp) && String.isNotBlank(lp)) ? '&' : '') + ((String.isNotBlank(lp)) ? 'lp='+lp : '');
	}


	public PageReference saveAsset() {
		PageReference pr;
		system.debug('Anydatatype_msg!!!!11');
		if (tesla.Id == NULL && tesla.User__c == NULL) {
			tesla.User__c = UserInfo.getUserId();
		}
		try {
			if (String.isNotBlank(linkText)) {
				tesla.Link__c = (!linkText.startsWith('http://') && !linkText.startsWith('https://')) ? ('http://' + linkText) : linkText;
				upsert tesla;
			}
			else if (imgBody != NULL && String.isNotBlank(imgFileName)) {
				tesla.Link__c = NULL;
				upsert tesla;
				Attachment aTemp = new Attachment(Name=imgFileName, Body=imgBody, ParentId=tesla.Id, ContentType=imgContentType, Description='CreatedByAsset');
				insert aTemp;
			} else if (attachmentId != 'false' && attachmentId != NULL && String.isNotBlank(attachmentId)) {
				tesla.Link__c = NULL;
				upsert tesla;
				List<Attachment> attachContactList = [SELECT Id, Name, Body, ContentType, ParentId FROM Attachment WHERE id= :attachmentId];
				if (attachContactList.size() > 0) {
					Attachment attachContact = attachContactList[0];
					Attachment attachAsset = new Attachment(Name=attachContact.Name, Body=attachContact.Body, ParentId=tesla.Id, ContentType=attachContact.ContentType, Description='CreatedByAsset');
					insert attachAsset;

					//LP-87 ----->
					System.debug('ParentId ' + attachContact.ParentId);
					List<Asset__c> temporaryAsset = [SELECT id FROM Asset__c WHERE id = :attachContact.ParentId];
					System.debug('tempAsset ' + temporaryAsset);
					try {
						delete temporaryAsset;
					} catch(Exception e) {
						System.debug('Delete problem!');
					}
					//LP-87 <-----
				}
			} else if (fileIndicator) {
				tesla.Link__c = NULL;
				upsert tesla;
			} else {
				upsert tesla;
			}
			pr = Page.LPAssetDetail;
			pr.getParameters().put('id', tesla.Id);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public PageReference clearAttach() {
		//LP-87 ----->
		Cookie assetCook = ApexPages.currentPage().getCookies().get('AssetIdToDelete');
		String cookieValue = assetCook.getValue();
		
		List<Asset__c> temporaryAsset = [SELECT id FROM Asset__c WHERE id = :cookieValue];
		try {
			delete temporaryAsset;
		} catch(Exception e) {
			System.debug('Delete problem!');
		}
		
		String retURLParametr = ApexPages.currentPage().getParameters().get('retURL');
		if (retURLParametr != NULL) {
			PageReference pr = new PageReference(retURLParametr);
			pr.setRedirect(true);
			System.debug('url1 ' + tesla.Link__c);
			return pr;
		} else {
			return null;
		}
		//LP-87 <-----
	}
	
	public void clearAttachSave() {
		clearAttachContact();
		clearAttachAsset(false);
	}

	public void clearAttachContact() {
		String contactId = [SELECT ContactId FROM User WHERE id = :UserInfo.getUserId()][0].ContactId;
		List<Attachment> attachToDelete = [SELECT id FROM Attachment WHERE Description = 'CreatedByAsset' AND ParentId = :contactId];
		if (attachToDelete.size() > 0) {
			delete attachToDelete;
		}
	}

	public void clearAttachAsset(Boolean cancel) {
		List<Attachment> attachToDelete;
		Attachment attachWithDescription;
		attachToDelete = [SELECT id FROM Attachment WHERE Description = 'CreatedByAsset' AND ParentId = :tesla.Id ORDER BY CreatedDate desc];
		if (attachToDelete.size() > 0) {
			if ((!cancel) && (String.isBlank(linkText))) {
				attachWithDescription = attachToDelete[0];
				attachWithDescription.description = '';
				update attachWithDescription;
				attachToDelete.remove(0);
			}
			delete attachToDelete;
		}
	}

	public static String getHeroImageId() {
		return LP_Template_Settings__c.getInstance().Hero_Image__c;
	}
	public static Boolean getHasCustomHeroImage() {
		return String.isNotBlank(LP_Template_Settings__c.getInstance().Hero_Image__c);
	}

	public PageReference saveAndAddAsset() {
		Boolean createMode = getShowCreateAddBtn();
		PageReference pr = saveAsset();
		if (createMode && tesla.Status__c != 'Inactive') {
			Id lpParamId = Id.valueOf(ApexPages.currentPage().getParameters().get('lp'));
			insert new Asset_Learner_Profile__c(Asset__c = tesla.Id, Learner_Profile__c = lpParamId);
			String ruParam = ApexPages.currentPage().getParameters().get('retUrl');
			if (String.isBlank(ruParam)) {
				pr = Page.LPAssets;
				pr.getParameters().put('lp', lpParamId);
				pr.setRedirect(true);
			}
			else {
				pr = new PageReference(ruParam);
			}
		}
		return pr;
	}

	public void submitAddRemoveLP() {
		Set<Id> deleteAssetProfile = new Set<Id>();
		List<Asset_Learner_Profile__c> createAssetProfile = new List<Asset_Learner_Profile__c>();
		for (LPLearnerProfileController.Eliforp elItem : efp.lps) {
			if (elItem.initialyChecked != elItem.checked) {
				if (elItem.checked) {
					createAssetProfile.add(new Asset_Learner_Profile__c(Asset__c = tesla.Id, Learner_Profile__c = elItem.Id));
				}
				else {
					deleteAssetProfile.add(elItem.Id);
				}
			}
		}
		if (createAssetProfile.size() > 0) {
			insert createAssetProfile;
		}
		if (deleteAssetProfile.size() > 0) {
			delete [SELECT Id FROM Asset_Learner_Profile__c WHERE Asset__c = :tesla.Id AND Learner_Profile__c IN :deleteAssetProfile];
		}
		initFromView();
	}

	public Boolean getShowMyLPbtn() {
		return SObjectType.Asset_Learner_Profile__c.isCreateable() && tesla.Status__c != 'Inactive';
	}

	public String getLearnerProfileName() {
		return getShowCreateAddBtn() ? [SELECT Name FROM Learner_Profile__c WHERE Id = :ApexPages.currentPage().getParameters().get('lp')].Name : '';
	}

	public Boolean getShowCreateAddBtn() {
		return lpMode && tesla.Id == NULL;
	}

	public List<String> getAssetLink() {
		List<String> resultList = new List<String> {'','','fa-file-o'};
		if (String.isNotBlank(tesla.Link__c)) {
			resultList = new List<String> {tesla.Link__c, tesla.Link__c,'fa-link'};
		}
		else if (tesla.NotesAndAttachments.size() > 0) {
			String[] parts = tesla.NotesAndAttachments[0].Title.split('\\.');
			String ext = parts[parts.size() - 1].toLowerCase();
			//ext = !CommunitySearchController.AWESOME_FILE_TYPES.containsKey(ext) ? 'fa-file-o' : CommunitySearchController.AWESOME_FILE_TYPES.get(ext);
			resultList = new List<String> {
					tesla.NotesAndAttachments[0].Title,
					LPUtils.checkUrl('/servlet/servlet.FileDownload?file=' + tesla.NotesAndAttachments[0].Id),
					'fa-file-o'
						};
		}
		return resultList;
	}

	public PageReference deleteAsset() {
		PageReference pr;
		try {
			delete tesla;
			pr = Page.LPAssets;
			if (lpMode) {
				pr.getParameters().put('lp', Id.valueOf(ApexPages.currentPage().getParameters().get('lp')));
			}
			pr.getParameters().put('c', tesla.Category__c);
			pr.setRedirect(true);
		}
		catch (Exception e) {
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public String getDeleteConfirmMessage() {
		Boolean acdc = false;
		for (LPLearnerProfileController.Eliforp eleItem : efp.lps) {
			acdc = (eleItem.checked == true) ? true : acdc;
		}
		return acdc ? Label.LBL_Delete_Asset : Label.LBL_Delete_Asset_message;
	}

	public Boolean getInitialActiveStatus() {
		return tesla.Status__c == 'Active';
	}

	// LIST MODE

	private Boolean listMode;
	private Boolean categoryMode;
	private final static String ALIAS_PARAM_DIVIDER = '?u=';

	public Boolean lpMode { get { return lpMode == NULL ? false : lpMode; } set; }
	public Boolean wrongProfile { get { return wrongProfile == NULL ? false : wrongProfile; } set; }
	public transient Learner_Profile__c currentLearnerProfile { get; set; }

	public void initFromList() {
		listMode = getCategoryParam() == NULL;
		categoryMode = !listMode;
		String lpParam = ApexPages.currentPage().getParameters().get('lp');
		lpMode = String.isNotBlank(lpParam);
		currentLearnerProfile = new Learner_Profile__c();
		if (lpMode) {
			String escapedParam = String.escapeSingleQuotes(lpParam);
			List<Learner_Profile__c> checkLPlist = [
				SELECT Id, Status__c, Name, Description__c FROM Learner_Profile__c
				WHERE Id = :String.escapeSingleQuotes(lpParam)
				AND OwnerId = :UserInfo.getUserId()
					];
			wrongProfile = checkLPlist.size() == 0;
			currentLearnerProfile = wrongProfile ? new Learner_Profile__c() : checkLPlist[0];
		}
		
	}

	public Boolean getInactiveProfile() {
		Set<String> activeProfileSet = new Set<String> { 'Active', 'Draft' };
		return lpMode && !activeProfileSet.contains(currentLearnerProfile.Status__c);
	}

	public String getLPStatusColorStyle() {
		Map<String,String> tm = new Map<String,String> { 'Active' => 'text-success', 'Draft' => 'text-warning', 'Inactive' => 'text-danger' };
		return tm.get(currentLearnerProfile.Status__c);
	}

	public String getLearnerProfilePageLink() {
		return LPLearnerProfileController.BASE_LP_LINK + currentLearnerProfile.Id;
	}

	public Boolean getShowLPbtns() {
		return lpMode && !categoryMode;
	}

	public Boolean getAddFromCategoryBtn() {
		return lpMode && categoryMode && SObjectType.Asset_Learner_Profile__c.isCreateable();
	}

	public String getUrlForAddFromCategory() {
		return prepareUrl(Page.LPMyAssets.getUrl()) + addCategoryLPParam('?');
	}

	public String getUrlForNewAsset() {
		return prepareUrl(Page.LPAssetEdit.getUrl())
				+ '?retURL=' + EncodingUtil.urlEncode(prepareUrl(Page.LPAssets.getUrl() + addCategoryLPParam('?')), 'UTF-8')
				+ addCategoryLPParam('&');
	}

	public String getUrlForEditAsset() {
		return prepareUrl(Page.LPAssetEdit.getUrl())
				+ '?id=' + tesla.Id
				+ '&retURL=' + EncodingUtil.urlEncode(prepareUrl(Page.LPAssetDetail.getUrl()) + '?id=' + tesla.Id, 'UTF-8');
	}

	public String getUrlForEditLearnerProfile() {
		String lpId = ApexPages.currentPage().getParameters().get('lp');
		return prepareUrl(Page.LPLearnerProfileEdit.getUrl())
				+ '?id=' + lpId
				+ '&retURL=' + EncodingUtil.urlEncode(prepareUrl(Page.LPAssets.getUrl()) + '?lp=' + lpId, 'UTF-8');
	}

	public String getLearnerProfileLink() {
		return lpMode ? ('&lp=' + String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('lp'))) : '';
	}

	private static String prepareUrl(String inUncouthUrl) {
		return inUncouthUrl.replace('/apex/', Site.getPathPrefix() + '/');
	}

	private String addCategoryLPParam(String inGlue) {
		String result = '';
		String cp = ApexPages.currentPage().getParameters().get('c');
		if (String.isNotBlank(cp)) {
			result += inGlue +'c=' + EncodingUtil.urlEncode(cp, 'UTF-8');
			inGlue = '&';
		}
		String lpp = ApexPages.currentPage().getParameters().get('lp');
		if (String.isNotBlank(lpp)) {
			result += inGlue +'lp=' + lpp;
		}
		return result;
	}

	public List<Yrogetac> getCategories() {
		List<Yrogetac> resultList = new List<Yrogetac>();
		if (listMode == true && !wrongProfile) {
			String yQuery = 'SELECT COUNT(Id) Counter, Category__c Cat FROM Asset__c WHERE User__c =\'' + UserInfo.getUserId() + '\'';
			if (lpMode) {
				yQuery += ' AND Id IN (SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = \'';
				yQuery += String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('lp')) + '\')';
			}
			yQuery += 'GROUP BY Category__c ORDER BY Category__c';
			Map<String, Yrogetac> filledCategoriesMap = new Map<String, Yrogetac>();
			for (AggregateResult arItem : Database.query(yQuery)) {
				String tc = (String)arItem.get('Cat');
				filledCategoriesMap.put((String.isBlank(tc) ? 'none' : tc.toLowerCase()), new Yrogetac(arItem));
			}
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				String tc2 = pe.getValue().toLowerCase();
				resultList.add(filledCategoriesMap.containsKey(tc2) ? filledCategoriesMap.get(tc2) : new Yrogetac(pe.getValue()));
			}
		}
		return resultList;
	}

	public List<Tessa> getAssets() {
		List<Tessa> resultList = new List<Tessa>();
		if (categoryMode == true && !wrongProfile) {
			String aQuery = 'SELECT Id, Name, Link__c, Description__c, Type__c, Status__c, CreatedDate, (SELECT Id, Name, BodyLength From Attachments ORDER BY CreatedDate DESC LIMIT 1)';
			aQuery += ' FROM Asset__c WHERE Category__c = \'' + String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('c')) + '\'';
			aQuery += ' AND User__c =\'' + UserInfo.getUserId() + '\'';
			if (lpMode) {
				aQuery += ' AND Id IN (SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = \'';
				aQuery += String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('lp')) + '\')';
			}
			for (Asset__c aItem : Database.query(aQuery)) {
				resultList.add(new Tessa(aItem));
			}
		}
		return resultList;
	}

	private static Map<String, String> AWESOME_FILE_TYPES = new Map<String, String> {
		'link' => 'fa-link', 'xls' => 'fa-file-excel-o', 'xlsx' => 'fa-file-excel-o', 'pdf' => 'fa-file-pdf-o',
		'doc' => 'fa-file-word-o', 'docx' => 'fa-file-word-o', 'ppt' => 'fa-file-pdf-o', 'pptx' => 'fa-file-pdf-o',
		'txt' => 'fa-file-text-o', 'png' => 'fa-file-image-o', 'gif' => 'fa-file-image-o', 'jpeg' => 'fa-file-image-o',
		'jpg' => 'fa-file-image-o', 'bmp' => 'fa-file-image-o'
	};

	// PAGE MODE

	public Boolean portfolioFound { get; set; }
	public String portfolioOwnerName { get; set; }
	public String portfolioDescription { get; set; }

	public void initFromPage() {
		try {
			Learner_Profile__c checklp = [
				SELECT Id, Description__c, Owner.Id, Owner.Name FROM Learner_Profile__c
				WHERE Id = :ApexPages.currentPage().getParameters().get('lp')
				AND (Status__c = 'Active' OR (Status__c = 'Draft' AND OwnerId = :UserInfo.getUserId()))
					];
			String contactId = [SELECT ContactId FROM User WHERE id = :UserInfo.getUserId()][0].ContactId;
			List<Contact> contactList  = [SELECT Id, FirstName, LastName FROM Contact WHERE id = :contactId];
			if (contactList.size() > 0) {
				portfolioOwnerName = contactList[0].FirstName + ' ' + contactList[0].LastName;
			} else {
				portfolioOwnerName = checklp.Owner.Name;
			}
			portfolioDescription = checklp.Description__c;
			portfolioFound = true;
		}
		catch (Exception e) {
			portfolioFound = false;
		}
	}

	public List<Yrogetac> getCategoriesWithAssets() {
		List<Yrogetac> resultList = new List<Yrogetac>();
		if (portfolioFound) {
			Map<String, Yrogetac> assemblyCategoryMap = new Map<String, Yrogetac>();
			for (Asset__c aItem : [
								SELECT Id, Name, Link__c, Description__c, Type__c, Status__c, Category__c, CreatedDate,
									(SELECT Id, Name, BodyLength From Attachments ORDER BY CreatedDate DESC LIMIT 1)
								FROM Asset__c
								WHERE Id IN (SELECT Asset__c FROM Asset_Learner_Profile__c WHERE Learner_Profile__c = :ApexPages.currentPage().getParameters().get('lp'))
									]) {
				String catUnique = String.isBlank(aItem.Category__c) ? 'none' : aItem.Category__c;
				catUnique = catUnique.replace(' ', '').toLowerCase();
				if (!assemblyCategoryMap.containsKey(catUnique)) {
					assemblyCategoryMap.put(catUnique, new Yrogetac(aItem.Category__c, catUnique));
				}
				assemblyCategoryMap.get(catUnique).assets.add(new Tessa(aItem));
			}
			for (Schema.PicklistEntry pe : SObjectType.Asset__c.fields.Category__c.getPicklistValues()) {
				String tc3 = pe.getValue().replace(' ','').toLowerCase();
				if (assemblyCategoryMap.containsKey(tc3)) {
					resultList.add(assemblyCategoryMap.get(tc3));
				}
			}
		}
		return resultList;
	}

	public String getLogoUrl() {
		LP_Template_Settings__c lpts = LP_Template_Settings__c.getOrgDefaults();
		return (lpts == NULL || String.isBlank(lpts.Header_Logo__c)) ? NULL : lpts.Header_Logo__c;
	}

	public PageReference getSiteTemplatePage() {
		return LPUtils.getSiteTemplatePage();
	}

	// WRAPPER CLASSES

	public class Tessa {
		public String id { get; set; }
		public String name { get; set; }
		public String atype { get; set; }
		public String link { get; set; }
		public String description { get; set; }
		public String icon { get; set; }
		public String size { get; set; }
		public String file { get; set; }
		public String status { get; set; }
		public String dshot { get; set; }

		public Tessa(Asset__c ina) {
			id = ina.Id;
			name = ina.Name;
			atype = ina.Type__c;
			description = ina.Description__c;
			dshot = String.isBlank(description) ? '' : description.abbreviate(32);
			file = ina.Status__c == 'Inactive' ? 'f-txt' : 'f-docx';
			status = ina.Status__c;
			if (String.isNotBlank(ina.Link__c)) {
				icon = 'fa-link';
				link = ina.Link__c;
			}
			else if (ina.Attachments.size() > 0) {
				String[] parts = ina.Attachments[0].Name.split('\\.');
				String ext = parts[parts.size() - 1].toLowerCase();
				icon = !AWESOME_FILE_TYPES.containsKey(ext) ? 'fa-file-o' : AWESOME_FILE_TYPES.get(ext);
				size = LPUtils.convertFileSize(ina.Attachments[0].BodyLength);
				link = LPUtils.checkUrl('/servlet/servlet.FileDownload?file=' + ina.Attachments[0].Id);
			}
			else {
				link = '#';
				icon = 'fa-file-o';
			}
		}
	}

	public class Yrogetac {
		public String name { get; set; }
		public Integer counter { get; set; }
		public List<Tessa> assets { get; set; }
		public String catid { get; set; }

		public Yrogetac(AggregateResult inar) {
			name = (String)inar.get('Cat');
			counter = (Integer)inar.get('Counter');
		}

		public Yrogetac(String inc) {
			name = inc;
			counter = 0;
		}

		public Yrogetac(String inc, String inid) {
			name = inc;
			catid = inid;
			assets = new List<Tessa>();
		}

		public String getItemString() {
			List<String> parts = Label.LBL_Item_Items.split(';');
			String single = parts[0];
			String plural = parts.size() > 1 ? parts[1] : parts[0];
			return String.valueOf(counter) + ' ' + (counter == 1 ? single : plural);
		}
	}

}
