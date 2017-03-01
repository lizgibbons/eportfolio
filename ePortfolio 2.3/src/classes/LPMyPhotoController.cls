public with sharing class LPMyPhotoController {
  public String blobImageData { get; set; }  
  public Blob photoBody { get; set; }
  public String photoName { get; set; }
  public String photoContentType { get; set; }

  public String cropX { get; set; }
  public String cropY { get; set; }
  public String cropSize { get; set; }

  public Boolean getRegMode() {
    return System.currentPageReference().getParameters().get('reg') == 'true';
  }

  public String ctrPhotoUrl { 
    get {
      if (ctrPhotoUrl == null) {
        return [SELECT FullPhotoUrl FROM User WHERE Id = :UserInfo.getUserId()].FullPhotoUrl;
      }
      else {
        return ctrPhotoUrl;
      }
    }
    set;
  }


  public LPMyPhotoController() {
    
  }


  public String actionPhotoLabel { 
    get {
      ConnectApi.Photo photoUser = ConnectApi.ChatterUsers.getPhoto(Network.getNetworkId(), UserInfo.getUserId());
      return (String.valueOf(photoUser).contains('default') || (photoUser == null)) ? Label.LBL_Add_Photo : Label.BTN_Update;
    }
    set;
  }


  public PageReference photoaction() {
    try {
      PageReference pr = new PageReference(ApexPages.currentPage().getUrl());
      photoBody = EncodingUtil.base64Decode(blobImageData);
      if (photoBody != NULL) {
        //ConnectApi.PhotoInput pi = new ConnectApi.PhotoInput();
        //pi.cropX = Integer.valueOf(cropX);
        //pi.cropY = Integer.valueOf(cropY);
        //pi.cropSize = Integer.valueOf(cropSize)-2;
        ConnectApi.BinaryInput bi = new ConnectApi.BinaryInput(photoBody, photoContentType, photoName);
        if (!Test.isRunningTest()) {
          //ConnectApi.ChatterUsers.setPhotoWithAttributes(Network.getNetworkId(), UserInfo.getUserId(), pi, bi);
          ConnectApi.ChatterUsers.setPhoto(Network.getNetworkId(), UserInfo.getUserId(), bi);
        }
      }
      Contact photoRegContact = LPSignController.getContactRegistration(UserInfo.getUserId());
      if (photoRegContact != NULL) {
        photoRegContact.Reg_Picture_Completed__c = Datetime.now();
        upsert photoRegContact;
      }
      pr.setRedirect(true);
      System.debug('Exception: ' + photoBody);
      return pr;
    }
    catch(Exception e) {
      System.debug('Exception: ' + photoBody);
      ApexPages.addMessages(e);
      return null;
    }
    
  }
  
  public PageReference getSiteTemplatePage() {
		return LPUtils.getSiteTemplatePage();
	}
}