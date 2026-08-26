// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';
import 'package:app/api/api_provider.dart';
import 'package:app/app_controller.dart';
import 'package:app/models/response/route.dart' as payment_route;
import 'package:app/models/response/termnial_detail.dart';
import 'package:app/shared/secure_shared_preferences/sharepreference.dart';
import 'package:app/shared/services/services.dart';
import 'package:app/shared/utils/app_flavor_helper.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../api/api_repository.dart';
import '../../models/request/donation_terminal_detail_request/donation_terminal_detail_request.dart';
import '../../models/route_payment_model.dart';
import '../../shared/constants/colors.dart';
import '../../shared/constants/common.dart';
import '../../shared/constants/constants_o7lite.dart';
import '../../shared/constants/image_constant.dart';
import '../../shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../../shared/services/printer.dart';
import 'components/tabIcon_data.dart';
import 'tabs/tabs.dart';
import 'package:app/shared/utils/log_utils.dart';

bool isCardPaymentBrand(String brand) {
  final normalizedBrand = brand.toLowerCase();
  return normalizedBrand.contains('visa') ||
      normalizedBrand.contains('mastercard');
}

bool isValidGw3WalletRoute(payment_route.Route route) {
  return !route.brand.contains(RegExp(r'[^\w\s\-]')) &&
      !route.host.toLowerCase().contains('grabpay-online') &&
      route.isActive &&
      !isCardPaymentBrand(route.brand);
}

bool shouldEnableWizarPosCardPayment(
  Iterable<payment_route.Route> routes, {
  required bool isWizarPos,
}) {
  return isWizarPos &&
      routes.any(
        (route) =>
            route.isActive &&
            !route.host.toLowerCase().contains('grabpay-online') &&
            isCardPaymentBrand(route.brand),
      );
}

class HomeController extends GetxController with GetTickerProviderStateMixin {
  final ApiRepository apiRepository;

  final ApiProvider apiProvider = Get.find();

  HomeController({required this.apiRepository});

  final ScrollController scrollController = ScrollController();
  final AppController appController = Get.find<AppController>();

  RxBool isDonationPressed = false.obs;
  RxBool isDonationActive = false.obs;
  bool isAlipayActivated = false;
  bool isWechatPayActivated = false;
  bool isGrabPayActivated = false;
  bool isNetspayActivated = false;
  RxBool isCreditCardActivated = false.obs;
  bool isAtomeActivated = false;
  bool isThaiQRActivated = false;
  bool isPayNowActivated = false;
  bool isDashActivated = false;
  bool isBootTouchNGoActivated = false;
  bool isShopeeActivated = false;
  bool isIouPayActivated = false;
  bool isTouchNGoActivated = false;

  var currentTab = MainTabs.home.obs;
  int tabIndex = 0;
  List<TabIconData> tabIconsList = TabIconData.tabIconsList;
  RxInt bottomNavIndex = 0.obs;
  RxInt currentPage = 0.obs;
  late final Timer timer;
  PageController pageController = PageController();
  late TabController tabController;
  final RxInt isCheckDrawer = 0.obs;

  final List<String> bottomNavSelectedIconPaths = [
    ImageConstant.iconDashboardHome,
    ImageConstant.iconDashboardHistory,
  ];
  final List<String> imagePaths = [
    ImageConstant.iconDashboardHome,
    ImageConstant.iconDashboardHistory,
  ];
  final List<String> listImagePaths = [
    // Ads images removed to reduce app size
  ];

  late List<String> routeList;
  RxList<RoutePaymentModel> listWalletType = <RoutePaymentModel>[].obs;
  RxList<RoutePaymentModel> listWalletTypePayNow = <RoutePaymentModel>[].obs;
  final RxBool hasEnabledCardPayment = false.obs;

  Map<String, List<String>> mRouteList = {};

  var scaffoldKey = GlobalKey<ScaffoldState>();
  DateTime? currentBackPressTime;

  // Add debounce for navigation clicks
  DateTime? _lastNavigationTime;
  static const _navigationDebounceMs = 300;

  String stringRouteList = '';
  String mCreditCardCurrency = '';
  String mCreditCardHost = '';
  RxString getMerchantName = ''.obs;
  RxString deviceModel = ''.obs;
  RxString getCarplaceNumber = ''.obs;
  RxInt getServiceChargeRate = 0.obs;

  RxString terminalID = '-'.obs;
  RxString userID = ''.obs;

  // Add loading state
  final isLoading = true.obs;

  // Add refreshing state for pull-to-refresh
  final isRefreshing = false.obs;

  // Add time and date variables
  RxString currentTime = ''.obs;
  RxString currentDate = ''.obs;
  RxString currentSeconds = '00'.obs;
  RxDouble secondsOpacity = 1.0.obs;
  late Timer _timeTimer;

  // Add version information
  RxString versionCode = ''.obs;
  RxString versionName = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();

    await initializeData();
  }

  Future<void> initializeData() async {
    try {
      isLoading.value = true;

      // Initialize core components in parallel with timeout to prevent hang
      await Future.wait<void>([
        getUserLimoApp(),
        getDevice(),
        getVersionCode(),
      ]).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          LogUtils.debugLog('initializeData: parallel init timed out');
          return <void>[];
        },
      );

      setupTabs();
      _configureEnvironment();

      if (StorageService.isGw3) {
        await _initializeGw3().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            LogUtils.debugLog('initializeData: _initializeGw3 timed out');
          },
        );
      } else {
        await _initializeGw2().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            LogUtils.debugLog('initializeData: _initializeGw2 timed out');
          },
        );
      }
    } catch (e) {
      LogUtils.debugLog('initializeData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _configureEnvironment() {
    // Configure environment based on gateway version
    final environment =
        StorageService.isGw3 ? AppFlavor.productionGW3 : AppFlavor.production;
    apiProvider.updateEnvironment(environment);
  }

  Future<void> _initializeGw3() async {
    final terminalId = await SecureSharedPreferences.instance.getTID();
    final terminalDetail =
        await apiRepository.getTerminalDetail(terminalId ?? '');

    if (terminalDetail == null) return;

    // Configure terminal details
    terminalDetail.terminalId = terminalId;

    // Update observable values
    getMerchantName.value = terminalDetail.merchant.name;
    terminalID.value = SharedPrefManager.terminalID;
    userID.value = terminalDetail.merchant.name;

    // Setup wallet types and save details
    setListWalletTypeGw3(terminalDetail);
    await SharedPrefManager.instance.setTerminalDetail(terminalDetail);
  }

  /// Refresh terminal data - called by pull-to-refresh
  /// Fetches latest terminal details from API and updates local storage
  Future<void> refreshTerminalData() async {
    if (isRefreshing.value) return; // Prevent multiple refresh calls

    try {
      isRefreshing.value = true;

      if (StorageService.isGw3) {
        final terminalId = await SecureSharedPreferences.instance.getTID();
        final terminalDetail =
            await apiRepository.getTerminalDetail(terminalId ?? '');

        if (terminalDetail != null) {
          // Configure terminal details
          terminalDetail.terminalId = terminalId;

          // Update observable values
          getMerchantName.value = terminalDetail.merchant.name;
          terminalID.value = SharedPrefManager.terminalID;
          userID.value = terminalDetail.merchant.name;

          // Setup wallet types and save updated details to local storage
          setListWalletTypeGw3(terminalDetail);
          await SharedPrefManager.instance.setTerminalDetail(terminalDetail);
        }
      } else {
        // For GW2, refresh donation and route data
        getMerchantName.value =
            await SecureSharedPreferences.instance.getMerchantShorName() ??
                'Oxygen7';
        terminalID.value = SharedPrefManager.terminalID;
        userID.value =
            await SecureSharedPreferences.instance.getMerchantName() ??
                'Unknown';
        await initDonation();
      }
    } finally {
      isRefreshing.value = false;
    }
  }

  Future<void> _initializeGw2() async {
    getMerchantName.value =
        await SecureSharedPreferences.instance.getMerchantShorName() ?? 'Oxygen7';
    terminalID.value = SharedPrefManager.terminalID;
    userID.value =
        await SecureSharedPreferences.instance.getMerchantName() ?? 'Unknown';
    await initDonation();
  }

  void setListWalletTypeGw3(TerminalDetail terminalDetail) {
    // Demo build: every acquirer route is ignored and a single Ripple wallet
    // is exposed instead of the real payment methods.
    hasEnabledCardPayment.value = false;
    _setDemoWalletList();
  }

  /// Demo build: the app ships with one wallet - Ripple.
  void _setDemoWalletList() {
    final ripple = RoutePaymentModel(
      title: CommonConstants.paymentMethodRipple.tr,
      brand: ConstantsO7Lite.BRAND_RIPPLE,
      image: ImageConstant.imageRipple,
      acquireReport: ConstantsO7Lite.RIPPLE_HOST,
      acquirer: ConstantsO7Lite.RIPPLE_HOST,
      isActivated: true,
      currency: 'SGD',
      supportedCurrencies: const ['SGD'],
      acquirerVoid: ConstantsO7Lite.RIPPLE_TYPE,
      acquirerDigital: ConstantsO7Lite.RIPPLE_TYPE,
    );

    listWalletType
      ..clear()
      ..add(ripple);
    listWalletTypePayNow
      ..clear()
      ..add(ripple);
  }

  Future<void> getUserLimoApp() async {
    final futures = await Future.wait([
      Printer.isMobileUser(),
      SecureSharedPreferences.instance.getCarplaceNumber(),
      SecureSharedPreferences.instance.getServiceChargeRate(),
    ]);

    appController.isMobileUser.value = futures[0] as bool;
    getCarplaceNumber.value = (futures[1] as String?) ?? '';
    getServiceChargeRate.value = (futures[2] as int?) ?? 0;
  }

  Future<void> getDevice() async {
    if (Platform.isIOS) {
      deviceModel.value = 'IOS';
      return;
    }
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    LogUtils.debugLog('Running on ${androidInfo.device}');
    deviceModel.value = androidInfo.brand;
  }

  Future<void> getTerminalID() async {
    terminalID.value = SharedPrefManager.terminalID;

    if (StorageService.isGw3) {
      final terminalDetail =
          await SharedPrefManager.instance.getTerminalDetail();
      userID.value = terminalDetail?.merchant.name ?? 'Unknown';
    } else {
      userID.value =
          await SecureSharedPreferences.instance.getMerchantName() ?? 'Unknown';
    }
  }

  Future<void> setActivatedRoute(String routeListStr) async {
    isAlipayActivated = routeListStr.contains(ConstantsO7Lite.ALIPAY_HOST);
    isWechatPayActivated = routeListStr.contains(ConstantsO7Lite.WECHAT_HOST);
    isGrabPayActivated = routeListStr.contains(ConstantsO7Lite.GRABPAY_HOST) ||
        routeListStr.contains(ConstantsO7Lite.GRABPAY_V3_HOST);
    isNetspayActivated = routeListStr.contains(ConstantsO7Lite.NETSPAY_HOST);
    isAtomeActivated = routeListStr.contains(ConstantsO7Lite.ATOME_HOST);
    isPayNowActivated =
        routeListStr.contains(ConstantsO7Lite.PAYNOW_EMVQR_HOST) ||
            routeListStr.contains(ConstantsO7Lite.PAYNOW_SCB_HOST);
    isThaiQRActivated =
        routeListStr.contains(ConstantsO7Lite.KBANK_THAIQR_HOST);
    isDashActivated = routeListStr.contains(ConstantsO7Lite.DASH_HOST);
    isBootTouchNGoActivated =
        routeListStr.contains(ConstantsO7Lite.BOOST_TOUCHNGO_HOST);
    isTouchNGoActivated =
        routeListStr.contains(ConstantsO7Lite.TOUCH_N_GO_HOST);
    isShopeeActivated = routeListStr.contains(ConstantsO7Lite.SHOPPEE_HOST);
    isIouPayActivated = routeListStr.contains(ConstantsO7Lite.IOUPAY_HOST);

    stringRouteList = routeListStr;
    routeList = routeListStr
        .split(","); // Sample: SGD;wechatHost,SGD:alipayHost,SGD;grabpayHost
    mRouteList = {};
    for (String route in routeList) {
      List<String> routeInfo = route.split(";");
      if (routeInfo.length > 1) {
        String acquirer = routeInfo[1];
        mRouteList[acquirer] = routeInfo;
        if (acquirer == ConstantsO7Lite.FD_HOST ||
            acquirer == ConstantsO7Lite.FDINDIA_HOST ||
            acquirer == ConstantsO7Lite.MAYBACK_HOST ||
            acquirer == ConstantsO7Lite.MIGS_HOST ||
            acquirer == ConstantsO7Lite.SWIFTREM_HOST ||
            acquirer == ConstantsO7Lite.SWIFTREM_HOST ||
            acquirer == ConstantsO7Lite.AMEX_HOST ||
            acquirer == ConstantsO7Lite.DCI_HOST ||
            acquirer == ConstantsO7Lite.WORLDPAY_HOST ||
            acquirer == ConstantsO7Lite.UMOBILE_HOST ||
            acquirer == ConstantsO7Lite.TBANK_HOST ||
            acquirer == ConstantsO7Lite.EXIMBAY_HOST ||
            acquirer == ConstantsO7Lite.EROMNET_HOST ||
            acquirer == ConstantsO7Lite.ENETS_HOST ||
            acquirer == ConstantsO7Lite.ALETA_SECUREPAY_HOST ||
            await checkBrandList()) {
          isCreditCardActivated.value = true;
          mCreditCardHost += "$acquirer;";
        } else {
          isCreditCardActivated.value = false;
        }
      }
      mCreditCardCurrency = routeInfo[0];
    }
    setDataList();
  }

  void setDataList() {
    // Demo build: Ripple is the only payment method on offer.
    _setDemoWalletList();
    EasyLoading.dismiss();
  }

  Future<bool> checkBrandList() async {
    String? futureBrands =
        await SecureSharedPreferences.instance.getBrandList();
    List<String> brandList = futureBrands!.split(",");
    for (int i = 0; i < brandList.length; i++) {
      if (brandList[i] == ConstantsO7Lite.BRAND_VISA ||
          brandList[i] == ConstantsO7Lite.BRAND_JCB ||
          brandList[i] == ConstantsO7Lite.BRAND_MASTERCARD ||
          brandList[i] == ConstantsO7Lite.BRAND_DISCOVER ||
          brandList[i] == ConstantsO7Lite.BRAND_DINERS ||
          brandList[i] == ConstantsO7Lite.BRAND_AMEX ||
          brandList[i] == ConstantsO7Lite.BRAND_CUP) {
        return true;
      }
    }
    return false;
  }

  Future<void> initDonation() async {
    EasyLoading.show(status: CommonConstants.initializingStatus.tr);
    try {
      listWalletTypePayNow.clear();

      if (BaseAppO7Lite.getIsDonation) {
        if (BaseAppO7Lite.isDonationMode) {
          isDonationPressed.value = true;

          SecureSharedPreferences.instance.setRouteList(
              await SecureSharedPreferences.instance.getDonationRouteList());
          SecureSharedPreferences.instance.setBrandList(
              await SecureSharedPreferences.instance.getDonationBrandList());
        } else {
          isDonationPressed.value = false;
          SecureSharedPreferences.instance.setRouteList(
              await SecureSharedPreferences.instance.getRootRouteList());
          SecureSharedPreferences.instance.setBrandList(
              await SecureSharedPreferences.instance.getRootBrandList());
        }
        isDonationActive.value = true;
      } else {
        isDonationActive.value = false;
      }
      await _loadRouteData();
    } catch (e) {
      LogUtils.debugLog('initDonation error: $e');
    } finally {
      EasyLoading.dismiss();
    }
  }

  /// Load route data from secure storage and populate wallet lists
  Future<void> _loadRouteData() async {
    final routeListStr =
        await SecureSharedPreferences.instance.getRouteList() ?? '';
    await setActivatedRoute(routeListStr);
  }

  Future<void> donationAction() async {
    listWalletType.clear();
    EasyLoading.show(status: '${CommonConstants.loading.tr}...');

    try {
      if (BaseAppO7Lite.isDonationMode) {
        SharedPrefManager.setTerminalID =
            await SecureSharedPreferences.instance.getRootTerminalId() ?? '';
        // Add delay for UI feedback
        await Future.delayed(Duration(seconds: 1));
        await initDonation();
      } else {
        SharedPrefManager.setTerminalID =
            await SecureSharedPreferences.instance.getDonationTerminalId() ??
                '';
        await getDonationTerminalDetail();
      }

      BaseAppO7Lite.setDonationMode(!BaseAppO7Lite.isDonationMode);
    } finally {
      await EasyLoading.dismiss();
    }
  }

  Future<void> getDonationTerminalDetail() async {
    final result = await apiRepository.getDonationTerminalDetail(
      DonationTerminalDetailRequest(
        mcpTerminalId: SharedPrefManager.terminalID,
      ),
    );

    List<String> jsonRoute = result?.enabledRoutes ?? [];
    StringBuffer stringRoute = StringBuffer();

    for (var item in jsonRoute) {
      stringRoute.write('$item,');
    }

    SecureSharedPreferences.instance.setDonationRouteList(
        stringRoute.toString().substring(0, stringRoute.length - 1));

    List<String> jsonBrand = result?.enabledBrands ?? [];
    StringBuffer stringBrand = StringBuffer();

    for (var item in jsonBrand) {
      stringBrand.write('$item,');
    }

    SecureSharedPreferences.instance.setDonationBrandList(
        stringBrand.toString().substring(0, stringBrand.length - 1));

    await initDonation();
  }

  void resetState() => bottomNavIndex.value = 0;

  Future<bool> onWillPop(BuildContext context) async {
    if (isDonationPressed.value) {
      donationAction();
      return false; // Don't exit the app
    } else {
      // Show exit confirmation dialog instead of directly exiting
      return await _showExitConfirmationDialog(context);
    }
  }

  /// Show exit confirmation dialog to prevent accidental app exit
  Future<bool> _showExitConfirmationDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: appController.isDarkModeOn.value
                  ? ColorConstants.grey800
                  : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                CommonConstants.exitAppTitle.tr,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: appController.isDarkModeOn.value
                      ? Colors.white
                      : Color(0xFF382F41),
                ),
              ),
              content: Text(
                CommonConstants.exitAppMessage.tr,
                style: TextStyle(
                  fontFamily: 'Open Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: appController.isDarkModeOn.value
                      ? Colors.white.withOpacity(0.8)
                      : Color(0xFF6B7280),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    CommonConstants.cancel.tr,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: appController.isDarkModeOn.value
                          ? Colors.white.withOpacity(0.7)
                          : Color(0xFF6B7280),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                    SystemNavigator.pop(); // Exit the app
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF7E01D7),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    CommonConstants.exit.tr,
                    style: TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false; // Return false if dialog is dismissed without selection
  }

  Future<void> launchUrlOxpay(String url) async {
    final Uri urlSupport = Uri.parse(url);

    if (!await launchUrl(urlSupport)) {
      throw Exception('Could not launch $urlSupport');
    }
  }

  void setupTabs() async {
    tabController = TabController(length: 2, vsync: this);
    tabController.addListener(() {
      tabIndex = tabController.index;
    });
  }

  void changeTabIndex(int index) {
    tabIndex = index;
  }

  void setValueBottomIndex(int index) {
    // Add debounce to prevent rapid navigation clicks
    final now = DateTime.now();
    if (_lastNavigationTime != null &&
        now.difference(_lastNavigationTime!).inMilliseconds <
            _navigationDebounceMs) {
      return; // Ignore rapid clicks
    }

    _lastNavigationTime = now;
    bottomNavIndex.value = index;
  }

  void openLandiApp() async {
    // check is app installed
    var isAppInstalled = await LaunchApp.isAppInstalled(
      androidPackageName: 'com.mscardpayments.app',
    );

    if (isAppInstalled) {
      var openAppResult = await LaunchApp.openApp(
        androidPackageName: 'com.mscardpayments.app',
      );
      LogUtils.debugLog(
          'openAppResult => $openAppResult ${openAppResult.runtimeType}');
      return;
    }
    var openAppResult = await LaunchApp.openApp(
      androidPackageName: 'com.landiconnect.appstore',
    );
    LogUtils.debugLog(
        'openAppResult => $openAppResult ${openAppResult.runtimeType}');
  }

  Future<void> getVersionCode() async {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    versionCode.value = packageInfo.buildNumber;
    versionName.value = packageInfo.version;
  }

  @override
  void dispose() {
    _timeTimer.cancel();
    pageController.dispose();
    timer.cancel();
    super.dispose();
  }
}
