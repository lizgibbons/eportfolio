public without sharing class LPSignController {
	public class LPSignException extends Exception {}

	public LPSignController() {}

	public String username { get; set; }
	public String firstname { get; set; }
	public String lastname { get; set; }
	public String password { get; set { password = value == null ? value : value.trim(); } }
	public String email { get; set; }
	public Id accountId { get; set; }
	public Id profileId { get; set; }
	public Integer resetPasswordMode { get { return resetPasswordMode == NULL ? 0 : resetPasswordMode; } set; }
	public String emailToReset { get; set; }
	public String oldPassword { get; set; }
	public String verifyPassword { get; set; }

	public PageReference login() {
		String startUrl = System.currentPageReference().getParameters().get('startURL');
		return Site.login(username, password, startUrl);
	}

	public void initFromRegistration() {
		try {
			accountId = Id.valueOf(System.currentPageReference().getParameters().get('code'));
			accountId = [SELECT Id FROM Account WHERE Id =:accountId].Id;
		}
		catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LBL_Sign_up_Account_Error));
		}
		try {
			profileId = [
				SELECT Id FROM Profile WHERE Name = 'Learner Profile Community User'
				AND Id IN (SELECT ParentId FROM NetworkMemberGroup WHERE NetworkId = :Network.getNetworkId())
				LIMIT 1
			].Id;
		}
		catch (Exception e) {
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, Label.LBL_Sign_up_Profile_Error));
		}
	}

	public String getTemplate() {
		return LPUtils.getTemplate();
	}

	public PageReference createUser() {
		PageReference pr;
		Savepoint sp = Database.setSavepoint();
		try {
			List<User> existEmailUsers = [SELECT Id FROM User WHERE Email = :email AND isActive = true];
			if (existEmailUsers.size() > 0) {
				throw new LPSignException(Label.LBL_Sign_up_Email_Error);
			}
			String createAlias = String.isNotBlank(firstname) ? firstname.substring(0,1) : '';
			createAlias += lastname.length() > 4 ? lastname.substring(0,4) : lastname.substring(0,lastname.length());
			User resu = new User(
				Email = email,
				LastName = lastname,
				FirstName = firstname,
				CommunityNickname = createAlias.toLowerCase() + '.' + generateRandomString(8),
				ProfileId = profileId,
				UserName = email
			);
			Id userId = Site.createPortalUser(resu, accountId, password);
			if (userId != NULL) {
				List<User> uList = [SELECT ContactId, Contact.Id, Contact.Registration_Completed__c FROM User WHERE Id = :userId];
				if (uList.size() > 0 && uList[0].ContactId != NULL) {
					Contact contactToUpdate = uList[0].Contact;
					contactToUpdate.Registration_Completed__c = Datetime.now();
					update contactToUpdate;
				}
				pr = Site.login(email, password, NULL);
			}
		}
		catch (Exception e) {
			Database.rollback(sp);
			ApexPages.addMessages(e);
		}
		return pr;
	}

	public void resetPasswordAction() {
		if (resetPasswordMode == 2 && String.IsNotBlank(emailToReset)) {
			List<User> userList = [SELECT Id, Username FROM User WHERE Email = :emailToReset AND isActive = true AND IsPortalEnabled = true LIMIT 1];
			if (userList.size() > 0) {
				System.resetPassword(userList[0].Id, true);
			}
		}
	}

	public PageReference changePassword() {
		return Site.changePassword(password, verifyPassword, oldPassword);	
	}

	private static String generateRandomString(Integer len) {
		final String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789abcdefghijklmnopqrstuvwxyz';
		String randStr = '';
		while (randStr.length() < len) {
			Integer idx = Math.mod(Math.abs(Crypto.getRandomInteger()), chars.length());
			randStr += chars.substring(idx, idx+1);
		}
		return randStr; 
	}
}