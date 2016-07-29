public with sharing class LPMyPhotoController {
    public String blobImageData { get; set; }   
    public Blob photoBody { get; set; }
    public String photoName { get; set; }
    public String photoContentType { get; set; }

    public String cropX { get; set; }
    public String cropY { get; set; }
    public String cropSize { get; set; }

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
                ConnectApi.BinaryInput bi = new ConnectApi.BinaryInput(photoBody, photoContentType, photoName);
                if (!Test.isRunningTest()) {
                    ConnectApi.ChatterUsers.setPhoto(Network.getNetworkId(), UserInfo.getUserId(), bi);
                }
                pr.setRedirect(true);
            }
            return pr;
        }
        catch(Exception e) {
            System.debug('Exception: ' + photoBody);
            ApexPages.addMessages(e);
            return null;
        }    
    }
}