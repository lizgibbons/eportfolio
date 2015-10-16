public with sharing class LPLeftPanelController {

	public String getProfilePhotoUrl() {
		String result;
		if (Schema.sObjectType.User.fields.getMap().containsKey('FullPhotoUrl')
			&& Schema.sObjectType.User.fields.getMap().get('FullPhotoUrl').getDescribe().isAccessible()) {
			Id userId = UserInfo.getUserId();
			List<User> uList = Database.query('SELECT Id, FullPhotoUrl FROM User WHERE Id = :userId');
			result = !uList.isEmpty() ? (String)uList[0].get('FullPhotoUrl') : NULL;
		}
		return result;
	}
}