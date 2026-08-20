import 'package:app/modules/main/app_setting/app_setting_binding.dart';
import 'package:app/modules/main/create_payment_url/create_payment_url_binding.dart';
import 'package:app/modules/main/create_payment_url/create_payment_url_page_new.dart';
import 'package:app/modules/main/tabs/select_refund_payment_method.dart';
import 'package:app/modules/main/trouble_shooting_page/trouble_item_page/print_screen.dart';
import 'package:app/modules/main/trouble_shooting_page/trouble_item_page/wifi_screen.dart';
import 'package:app/modules/main/trouble_shooting_page/trouble_shooting_binding.dart';
import 'package:get/get.dart';
import '../modules/auth/auth_binding.dart';
import '../modules/auth/login_screen.dart';
import '../modules/auth/create_account_screen.dart';
import '../modules/main/app_setting/app_setting_screen.dart';
import '../modules/main/change_language/change_language_binding.dart';
import '../modules/main/change_language/change_language_screen.dart';
import '../modules/main/credit_card_screen/credit_card_binding.dart';
import '../modules/main/credit_card_screen/credit_card_screen.dart';
import '../modules/main/card_reader_screen/card_reader_binding.dart';
import '../modules/main/card_reader_screen/card_reader_screen.dart';
import '../modules/main/digital_payment/digital_payment_binding.dart';
import '../modules/main/digital_payment/digital_payment.dart';
import '../modules/main/home_binding.dart';
import '../modules/main/home_screen.dart';
import '../modules/main/payment_page_qr_o7lite/payment_page_qr_o7lite.dart';
import '../modules/main/payment_page_qr_o7lite/payment_page_qr_o7lite_binding.dart';
import '../modules/main/refund_screen/refund_binding.dart';
import '../modules/main/refund_screen/refund_screen.dart';
import '../modules/main/report_screen/report_binding.dart';
import '../modules/main/report_screen/report_screen.dart';
import '../modules/main/scan_qr_code/scan_qr_code_biding.dart';
import '../modules/main/scan_qr_code/scan_qr_code_screen.dart';
import '../modules/main/tabs/payment_list.dart';
import '../modules/main/transaction_history/transaction_history_binding.dart';
import '../modules/main/transaction_history/transaction_history_screen.dart';
import '../modules/main/transaction_history_detail/transaction_history_detail.dart';
import '../modules/main/transaction_history_detail/transaction_history_detail_binding.dart';
import '../modules/main/trouble_shooting_page/trouble_item_page/bluetooth_screen.dart';
import '../modules/main/trouble_shooting_page/trouble_shooting_page.dart';
import '../modules/splash/splash_binding.dart';
import '../modules/splash/splash_view.dart';
import '../modules/main/bluetooth_printer/bluetooth_printer_binding.dart';
import '../modules/main/bluetooth_printer/bluetooth_printer_view.dart';
import '../modules/main/trouble_shooting_page/cloud_print_test_page.dart';
part 'app_routes.dart';

class AppPages {
  static final routes = [
    GetPage(
      name: Routes.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: Routes.HOME,
      page: () => HomeScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.PAYMENT_LIST,
      page: () => PaymentList(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.PAYMENT_LIST_VOID,
      page: () => SelectRefundPaymentMethodScreen(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: Routes.LOG_IN,
      page: () => LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.CHANGE_LANGUAGE,
      page: () => ChangeLanguage(),
      binding: ChangeLanguageBinding(),
    ),
    GetPage(
      name: Routes.CREDIT_CARD,
      page: () => CreditCard(),
      binding: CreditCardBinding(),
    ),
    GetPage(
      name: Routes.CARD_READER,
      page: () => CardReaderScreen(),
      binding: CardReaderBinding(),
    ),
    GetPage(
      name: Routes.DIGITAL_PAYMENT,
      page: () => DigitalPayment(),
      binding: DigitalPaymentBinding(),
    ),
    GetPage(
      name: Routes.PAYMENT_PAGE_QR_O7LITE,
      page: () => PaymentPageQrO7Lite(),
      binding: PaymentPageQrO7LiteBinding(),
    ),
    GetPage(
      name: Routes.TRANSACTION_HISTORY,
      page: () => TransactionHistory(),
      binding: TransactionHistoryBinding(),
    ),
    GetPage(
      name: Routes.TRANSACTION_HISTORY_DETAIL,
      page: () => TransactionHistoryDetail(),
      binding: TransactionHistoryDetailBinding(),
    ),
    GetPage(
      name: Routes.REPORT_SCREEN,
      page: () => ReportScreen(),
      binding: ReportBinding(),
    ),
    GetPage(
      name: Routes.REFUND_SCREEN,
      page: () => RefundScreen(),
      binding: RefundBinding(),
    ),
    GetPage(
      name: Routes.SCAN_QR_CODE,
      page: () => ScanQRCodeScreen(),
      binding: ScanQrCodeBinding(),
    ),
    GetPage(
      name: Routes.TROUBLE_SHOOTING_PAGE,
      page: () => TroubleShootingPage(),
      binding: TroubleShootingBinding(),
    ),
    GetPage(
      name: Routes.PRINT_SCREEN,
      page: () => PrintScreen(),
      binding: TroubleShootingBinding(),
    ),
    GetPage(
      name: Routes.WIFI_SCREEN,
      page: () => WifiScreen(),
      binding: TroubleShootingBinding(),
    ),
    GetPage(
      name: Routes.BLUETOOTH_SCREEN,
      page: () => BluetoothScreen(),
      binding: TroubleShootingBinding(),
    ),
    GetPage(
      name: Routes.APP_SETTING,
      page: () => AppSettingScreen(),
      binding: AppSettingBinding(),
    ),
    GetPage(
      name: Routes.CREATE_PAYMENT_URL,
      page: () => CreatePaymentUrlPage2(),
      binding: CreatePaymentUrlBinding(),
    ),
    GetPage(
      name: '/create_account',
      page: () => const CreateAccountScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: Routes.BLUETOOTH_PRINTER,
      page: () => BluetoothPrinterView(),
      binding: BluetoothPrinterBinding(),
    ),
    GetPage(
      name: Routes.CLOUD_PRINT_TEST,
      page: () => const CloudPrintTestPage(),
    ),
  ];
}
