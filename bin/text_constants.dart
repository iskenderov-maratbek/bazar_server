//Product Fields
class DbFields {
  static String productID = 'id';
  static String productNAME = 'name';
  static String productCATEGORYID = 'category_id';
  static String productUSERID = 'user_id';
  static String productDESCRIPTION = 'description';
  static String productPRICE = 'price';
  static String productPRICETYPE = 'price_type';
  static String productLOCATION = 'location';
  static String productDELIVERY = 'delivery';
  static String productPHOTO = 'photo';
  static String productSTATUS = 'status';
  static String productIDAUTH = 'product_id';
//Categories Fields
  static String categoryID = 'category_id';
  static String categoryNAME = 'name';
  static String categoryPHOTO = 'photo';

//Users Fields
  static String userID = 'id';
  static String userNAME = 'name';
  static String userEMAIL = 'email';
  static String userPROFILEPHOTO = 'profile_photo';
  static String userPHONE = 'phone';
  static String userWHATSAPP = 'whatsapp';
  static String userTOKEN = 'access_token';
  static String userLOCATION = 'location';
  static String userSTATUS = 'status';

//secret Fields
  static String secretStart = 'Bearer ';
  static String authKey = 'Authorization';
  static String contentTypeKey = 'Content-Type';
  static String applicationJson = 'application/json';
  static String multipartFormData = 'multipart/form-data';
  static String homeVersionKey = 'home_version';
  static String userProductVersionKey = 'user_product_version';

//Path of the images
  static String userPROFILEPHOTOPATH = 'users/profile_photo';
  static String productPHOTOPATH = 'products_photo';
  static String categoryPHOTOPATH = 'categories_photo';

//Requests paths

  static String getMainData = '/get_main_data';
  static String getCategories = '/get_categories';
  static String getBanners = '/get_banners';
  static String allCategories = '/all_categories';
  static String getProducts = '/get_products';
  static String authWithGoogle = '/auth_with_google';
  static String getActiveProducts = '/get_active_products';
  static String getArchiveProducts = '/get_archive_products';
  static String search = '/search';
  static String userProfileUpdate = '/user_profile_update';
  static String userProfileUpdateWithFile = '/user_profile_update_with_file';
  static String addProduct = '/add_ad';
  static String bugReport = '/bug_report';
  static String addAdWithFile = '/add_ad_with_file';
  static String editAd = '/edit_ad';
  static String editAdWithFile = '/edit_ad_with_file';
  static String archivedAd = '/archived_ad';
  static String moderateAd = '/moderate_ad';
  static String removeAd = '/remove_ad';
  static String getHomeVersion = '/get_home_version';
  static String getUserProductVersion = '/get_user_product_version';
}
