class ApiConstants {
  // [GW2] MCPayment
  static const API_DEV = 'https://gw2.dev.mcpayment.net/api';
  static const API_PRO = 'https://gw2.mcpayment.net/api';

  static const BASE_API_URL = API_PRO;
  static String RETURN_URL = '$BASE_API_URL/v6/returnUrl';
  static String STATUS_URL = '$BASE_API_URL/v6/statusUrl';

  // [GW3] OxPay
  static const API_GW3_DEV =
      'https://api.dev.oxpayfinancial.com'; // Downtime daily from 2AM - 8AM
  static const API_GW3_PRO = 'https://api.oxpayfinancial.com';

  static const BASE_API_URL_GW3 = API_GW3_PRO; // CHANGE TO PRO FOR PRODUCTION
  static String SUCCESS_URL = '$BASE_API_URL_GW3/terminal/returnUrl';
  static String FAILURE_URL = '$BASE_API_URL_GW3/terminal/failure';
  static String NOTIFICATION_URL = '$BASE_API_URL_GW3/terminal/notify';
}
