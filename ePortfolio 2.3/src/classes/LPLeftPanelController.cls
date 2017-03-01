global with sharing class LPLeftPanelController {

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

  public Contact getUsersContact() {
    String contactId = [SELECT ContactId FROM User WHERE id = :UserInfo.getUserId()][0].ContactId;
    List<Contact> contactList  = [SELECT Id, FirstName, LastName FROM Contact WHERE id = :contactId];
    if (contactList.size() > 0) {
      return contactList[0];
    } else {
      return NULL;
    }
  }
}