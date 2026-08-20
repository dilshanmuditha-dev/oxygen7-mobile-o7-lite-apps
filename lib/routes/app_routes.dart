// ignore_for_file: constant_identifier_names

part of 'app_pages.dart';

abstract class Routes {
  static const SPLASH = '/splash';
  static const AUTH = '/auth';
  static const LOG_IN = '/log_in';

  static const HOME = '/home';
  static const PAYMENT_LIST = '/payment_list';
  static const PAYMENT_LIST_VOID = '/payment_list_void';
  static const PRIVACY = '/privacy';
  static const CHANGE_LANGUAGE = '/change_language';
  static const CREDIT_CARD = '/credit_card';
  static const CARD_READER = '/card-reader';
  static const DIGITAL_PAYMENT = '/digital_payment';
  static const PAYMENT_PAGE_QR_O7LITE = '/payment_page_qr_o7lite';
  static const TRANSACTION_HISTORY = '/transaction_history';
  static const TRANSACTION_HISTORY_DETAIL = '/transaction_history_detail';
  static const REPORT_SCREEN = '/report_screen';
  static const REFUND_SCREEN = '/refund_screen';
  static const SCAN_QR_CODE = '/scan_qr_code';
  static const FORGOT_PASSWORD = '/forgot_password';
  static const TROUBLE_SHOOTING_PAGE = '/trouble_shooting_page';
  static const PRINT_SCREEN = '/print_screen';
  static const WIFI_SCREEN = '/wifi_screen';
  static const TOUCH_SCREEN = '/touch_screen';
  static const BATTERY_SCREEN = '/battery_screen';
  static const BLUETOOTH_SCREEN = '/bluetooth_screen';
  static const SCANNER_SCREEN = '/scanner_screen';
  static const BARCODE_SCREEN = '/barcode_screen';
  static const APP_SETTING = '/app_setting';
  static const CREATE_PAYMENT_URL = '/create_payment_url';
  static const BLUETOOTH_PRINTER = '/bluetooth_printer';
  static const CLOUD_PRINT_TEST = '/cloud_print_test';
}
