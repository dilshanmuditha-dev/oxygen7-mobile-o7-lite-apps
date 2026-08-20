// ignore_for_file: use_build_context_synchronously, unnecessary_null_comparison

import 'package:app/app_controller.dart';
import 'package:app/api/api_repository.dart';
import 'package:app/models/request/get_transacion_summary_AFG_request/get_transacion_summary_AFG_request.dart';
import 'package:app/models/response/report_model/report_model.dart';
import 'package:app/models/response/transaction_summary_AFG_response/transaction_summary_AFG_response.dart';
import 'package:app/models/response/transaction_summary_list_response/transaction_summary_list_response.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:app/shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import 'package:app/shared/services/bluetooth_printer/models.dart';
import 'package:app/shared/services/bluetooth_printer/print_job_manager.dart';
import 'package:app/shared/services/castle_report_print_monitor.dart';
import 'package:app/shared/services/printer.dart';
import 'package:app/shared/shared.dart';
import 'package:app/shared/utils/log_utils.dart';
import 'package:app/routes/routes.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:app/shared/widgets/castle_report_print_monitor_dialog.dart';
import 'package:app/shared/widgets/custom_dialog/custom_dialog.dart';
import 'package:app/shared/widgets/custom_text_style.dart';
import 'package:app/shared/widgets/string_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/widgets/dialog_common.dart';

class ReportController extends GetxController {
  final ApiRepository apiRepository;
  ReportController({required this.apiRepository});

  final ScrollController scrollController = ScrollController();
  GlobalKey cardKey = GlobalKey();

  Rx<DateTime> selectedFromDate = Rx<DateTime>(DateTime.now());
  late DateTime mCurrentDate;

  String mDateFrom = '';
  String mDateTo = '';
  String oldestDate = '';
  RxString getTerminalID = ''.obs;
  String mCurrency = '';
  String mAcquirer = '';
  String acquirer = '';

  RxInt positionHost = 0.obs;
  RxString transactionAmount = "0".obs;
  RxString transactionCount = "0".obs;
  RxString transactionVoidAmount = "0".obs;
  RxString transactionVoidCount = "0".obs;

  final ReportModel reportModel = Get.arguments;

  RxBool isDisableBack = false.obs;

  Rx<TransactionSummaryAFGResponse?> listData =
      Rx<TransactionSummaryAFGResponse?>(null);

  List<TransactionSummaryListResponse> transactionList = [];
  RxList<String> mCreditCardHost = <String>[].obs;
  final List<String> allowedHosts = [
    ConstantsO7Lite.FD_HOST,
    ConstantsO7Lite.FDINDIA_HOST,
    ConstantsO7Lite.MIGS_HOST,
    ConstantsO7Lite.TBANK_HOST,
    ConstantsO7Lite.MAYBACK_HOST,
    ConstantsO7Lite.PAYTABS_HOST,
    ConstantsO7Lite.AMEX_HOST,
    ConstantsO7Lite.DCI_HOST,
    ConstantsO7Lite.SWIFTREM_HOST
  ];

  var convertStartDate = '';
  var convertEndDate = '';
  var signature = '';

  @override
  void onInit() async {
    super.onInit();
    initDateTime();
    activatedHosts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EasyLoading.show(
        status: '${CommonConstants.loading.tr}...',
      );
      processSearch();
    });
  }

  Future<void> onRefresh() async {
    processSearch();
  }

  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedFromDate.value,
      firstDate: DateTime(2010),
      lastDate: DateTime(2050),
    );
    if (picked != null) {
      selectedFromDate.value = picked;
      positionHost.value = 0;
      processSearch();
    }
  }

  void processSearch() async {
    isDisableBack.value = true;

    if (!isDateValid(Get.context!)) {
      isDisableBack.value = false;
      return;
    }

    signature = await SecureSharedPreferences.instance.signature() ?? '';
    getTerminalID.value = SharedPrefManager.terminalID;

    convertStartDate =
        StringUtils.convertToGW2StartDate(selectedFromDate.value);
    convertEndDate = StringUtils.convertToGW2EndDate(selectedFromDate.value);

    EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );
    if (StringUtils.equalsIgnoreCase(
        mAcquirer, ConstantsO7Lite.CREDIT_CARD_HOST)) {
      final listDataDailySummary = await apiRepository.getTransacionSummaryAFG(
        GetTransacionSummaryAFGRequest(
          acquirer: mAcquirer,
          currency: mCurrency,
          startDate: convertStartDate,
          endDate: convertEndDate,
          isShowError: false,
        ),
      );
      if (listDataDailySummary != null) {
        listData.value = listDataDailySummary;
        // update data
        if (listData.value?.totalPayAmount != null) {
          transactionAmount.value = (int.parse(transactionAmount.value) +
                  listData.value!.totalPayAmount!)
              .toString();
        }
        if (listData.value?.transactionList != null) {
          // transactionList = listData['transactionList'];
          transactionList.addAll(listData.value!.transactionList!);
        }
        if (listData.value?.totalVoidCount != null) {
          transactionVoidCount.value = (int.parse(transactionVoidCount.value) +
                  listData.value!.totalVoidCount!)
              .toString();
        }
        if (listData.value?.totalVoidAmount != null) {
          transactionVoidAmount.value =
              (int.parse(transactionVoidAmount.value) +
                      listData.value!.totalVoidAmount!)
                  .toString();
        }
        if (listData.value?.totalPayCount != null) {
          transactionCount.value = (int.parse(transactionCount.value) +
                  listData.value!.totalPayCount!)
              .toString();
        }
      } else if (positionHost < mCreditCardHost.length - 1) {
        positionHost++;
        processSearch();
      } else {
        if (transactionList.isEmpty) {
          Get.dialog(
            CustomAlertDialog(
              title: CommonConstants.noTransactionFound.tr,
              onPressed: () {
                Get.back();
              },
            ),
          );
        }
        isDisableBack.value = false;
      }
    } else {
      TransactionSummaryAFGResponse? listDataDailySummary;
      if (StorageService.isGw3) {
        var startDate =
            StringUtils.convertToGW3StartDate(selectedFromDate.value);
        var endDate = StringUtils.convertToGW3EndDate(selectedFromDate.value);
        LogUtils.debugLog('startDate: $startDate');
        LogUtils.debugLog('endDate: $endDate');
        listDataDailySummary = await apiRepository.getTxnSummaryReportGw3(
          mAcquirer,
          mCurrency,
          startDate,
          endDate,
        );
      } else {
        listDataDailySummary = await apiRepository.getTransacionSummaryAFG(
          GetTransacionSummaryAFGRequest(
            acquirer: mAcquirer,
            currency: mCurrency,
            startDate: convertStartDate,
            endDate: convertEndDate,
            isShowError: true,
          ),
        );
      }
      LogUtils.debugLog('listDataDailySummary: $listDataDailySummary');
      if (listDataDailySummary != null) {
        listData.value = listDataDailySummary;
        setDataAfterCallApiSuccess();
      } else {
        isDisableBack.value = false;
        listData.value = null;
        return;
      }
    }
  }

  void setDataAfterCallApiSuccess() {
    if (listData.value?.totalPayAmount != null) {
      transactionAmount.value = listData.value!.totalPayAmount.toString();
    }
    if (listData.value?.transactionList != null) {
      transactionList = listData.value!.transactionList!;
    }
    if (listData.value?.totalVoidCount != null) {
      transactionVoidCount.value = listData.value!.totalVoidCount.toString();
    }
    if (listData.value?.totalVoidAmount != null) {
      transactionVoidAmount.value = listData.value!.totalVoidAmount.toString();
    }

    // if gw3, set totalRefundCount and totalRefundAmount
    if (StorageService.isGw3) {
      if (listData.value?.totalRefundCount != null) {
        transactionVoidCount.value =
            listData.value!.totalRefundCount.toString();
      }
      if (listData.value?.totalRefundAmount != null) {
        transactionVoidAmount.value =
            listData.value!.totalRefundAmount.toString();
      }
    }

    if (listData.value?.totalPayCount != null) {
      transactionCount.value = listData.value!.totalPayCount.toString();
    }

    isDisableBack.value = false;
  }

  void initDateTime() {
    mCurrentDate = DateTime.now();
    selectedFromDate.value =
        DateTime(mCurrentDate.year, mCurrentDate.month, mCurrentDate.day);
  }

  void activatedHosts() {
    mAcquirer = reportModel.acquirer ?? CommonConstants.textEmpty;
    mCurrency = reportModel.currency ?? CommonConstants.textEmpty;

    if (reportModel.creditCardActivated?.isNotEmpty == true &&
        reportModel.creditCardActivated != null) {
      List<String> activatedHosts = reportModel.creditCardActivated!.split(";");
      mCreditCardHost.value =
          activatedHosts.where((host) => allowedHosts.contains(host)).toList();
    }
  }

  void onPrintClicked(BuildContext context) async {
    LogUtils.debugLog('LANDI_SUMMARY: onPrintClicked() called');

    if (listData.value == null ||
        listData.value?.transactionList == null ||
        listData.value?.transactionList!.isEmpty == true) {
      LogUtils.debugLog('LANDI_SUMMARY: No transaction data, showing dialog');
      CustomDialog.showMaterial(
        context,
        CommonConstants.noTransactionFound.tr,
        btnText: CommonConstants.ok.tr,
      );
      return;
    }

    LogUtils.debugLog(
        'LANDI_SUMMARY: listData is valid, txnCount=${listData.value?.transactionList?.length}');

    // Use cached device detection from AppController for better performance
    final AppController appController = Get.find<AppController>();

    LogUtils.debugLog(
        'LANDI_SUMMARY: isMobileUser=${appController.isMobileUser.value}, '
        'isCastle=${appController.isCastleDevice.value}, '
        'isAnfu=${appController.isAnfuDevice.value}, '
        'isLandi=${appController.isLandiDevice.value}, '
        'isWizarPos=${appController.isWizarPosDevice.value}, '
        'isCoherent=${appController.isCoherentDevice.value}, '
        'isMorefun=${appController.isMorefunDevice.value}');

    // Mobile user: route to Bluetooth printer instead of POS printer (Requirement 5.1, 6.1)
    if (appController.isMobileUser.value) {
      final btService = BluetoothPrinterService.instance;

      if (btService.status.value != BluetoothPrinterStatus.connected) {
        LogUtils.debugLog(
          'ReportController: No Bluetooth printer connected, prompting user',
        );
        CustomDialog.showToast('btPrinterNotConnected'.tr);
        Get.toNamed(Routes.BLUETOOTH_PRINTER);
        return;
      }

      await PrintJobManager.printSummaryReport(
        context: context,
        acquirer: acquirer,
        dataSource: listData.value,
      );
      return;
    }

    final isCoherentDevice = appController.isCoherentDevice.value;
    final isCastleDevice = appController.isCastleDevice.value;
    final isLandiDevice = appController.isLandiDevice.value;
    final isWizarPosDevice = appController.isWizarPosDevice.value;
    final isAnfuDevice = appController.isAnfuDevice.value;
    final isMorefunDevice = appController.isMorefunDevice.value;

    // COHERENT DEVICE
    if (isCoherentDevice) {
      Printer.printCoherentSummaryReport(context, acquirer, listData.value);
      return;
    }

    // MOREFUN DEVICE
    if (isMorefunDevice) {
      Printer.printMorefunSummaryReport(context, acquirer, listData.value);
      return;
    }

    if (isCastleDevice) {
      final monitor = CastleReportPrintMonitor.instance;
      if (monitor.isEnabled) {
        monitor.startAttempt('Castle summary report print requested');
        monitor.addStep('Flutter', 'Report data validated');
        monitor.addStep('Flutter', 'Opening temporary monitor popup');
        Get.dialog(
          const CastleReportPrintMonitorDialog(),
          barrierDismissible: true,
        );
      }

      // acquirer is brand
      // mAcquirer is host
      monitor.addStep(
        'Flutter',
        'Calling Castle native print: brand=$acquirer, host=$mAcquirer',
      );
      await Printer.printCastleSummaryReport(
          context,
          acquirer,
          mAcquirer,
          mCurrency,
          convertStartDate,
          convertEndDate,
          getTerminalID.value,
          signature,
          listData.value);
    } else if (isAnfuDevice) {
      Printer.printAnfuSummaryReport(context, acquirer, listData.value);
    } else if (isLandiDevice) {
      LogUtils.debugLog(
          'LANDI_SUMMARY: Landi device detected, calling Printer.printLandiSummaryReport()');
      LogUtils.debugLog(
          'LANDI_SUMMARY: acquirer=$acquirer, dataSource isNull=${listData.value == null}');
      Printer.printLandiSummaryReport(context, acquirer, listData.value);
    } else if (isWizarPosDevice) {
      Printer.printWizarPosSummaryReport(context, acquirer, listData.value);
    } else {
      // sunmi device
      // if Android 11, use  Printer.print(context, true, cardKey); instead of Printer.printSunmiSummaryReport(context, acquirer, listData.value);
      // DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
      // final androidInfo = await deviceInfoPlugin.androidInfo;
      // final sdkInt = androidInfo.version.sdkInt;
      // if (Platform.isAndroid && sdkInt >= 30) {
      //   Printer.print(context, true, cardKey);
      //   return;
      // }

      Printer.printSunmiSummaryReport(context, acquirer, listData.value);
    }
  }

  void clearData() {
    transactionAmount.value = "0";
    transactionCount.value = "0";
    transactionVoidAmount.value = "0";
    transactionVoidCount.value = "0";
    transactionList.clear();
  }

  Widget setTextDailySummaryTitle() {
    var isBoost = reportModel.isBoost;

    if (StorageService.isGw3) {
      acquirer = "${reportModel.brand} ${CommonConstants.dailySummary.tr}";
      return Text(
        acquirer,
        style: CustomTextStyles.labelBlack500Size24Fw600,
      );
    }

    switch (mAcquirer) {
      case ConstantsO7Lite.ALIPAY_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectAlipay} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.WECHAT_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectWechat} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.GRABPAY_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectGrabpay} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.NETSPAY_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectNetspay} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.ATOME_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectAtome} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.KBANK_THAIQR_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectThaiqr} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.PAYNOW_SCB_HOST:
      case ConstantsO7Lite.PAYNOW_EMVQR_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectPaynow} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.CREDIT_CARD_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectCard} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.DASH_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectDash} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.BOOST_TOUCHNGO_HOST:
        if (isBoost != null) {
          acquirer =
              "${CommonConstants.labelDailySummarySelectBoost} ${CommonConstants.dailySummary.tr}";
        } else {
          acquirer =
              "${CommonConstants.labelDailySummarySelectTouchngo} ${CommonConstants.dailySummary.tr}";
        }
        break;
      case ConstantsO7Lite.SHOPPEE_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectShopee} ${CommonConstants.dailySummary.tr}";
        break;
      case ConstantsO7Lite.IOUPAY_HOST:
        acquirer =
            "${CommonConstants.labelDailySummarySelectIoupay} ${CommonConstants.dailySummary.tr}";
        break;
      default:
        acquirer = CommonConstants.dailySummary.tr;
        break;
    }

    return Text(
      acquirer,
      style: CustomTextStyles.labelBlack500Size24Fw600,
    );
  }

  Widget setImageBrand({required String brandName}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.asset(
        getBrandImage(brandName),
        height: ResponsiveUtil().getSize(60),
        width: ResponsiveUtil().getSize(60),
        fit: BoxFit.cover,
      ),
    );
  }

  Widget setTextTransactionItemType({required String inputTransactionType}) {
    var transactionType = CommonConstants.textEmpty;

    switch (inputTransactionType) {
      case TransactionTypeAFG.PREAUTH:
      case TransactionTypeAFG.SALES:
      case TransactionTypeAFG.SALE:
      case TransactionTypeAFG.QUICK_PAY:
      case TransactionTypeAFG.UNIFIED_ORDER:
      case TransactionTypeAFG.SUBMIT_QUICK_PAY:
        transactionType = CommonConstants.sale.tr;

        break;
      case TransactionTypeAFG.VOID:
      case TransactionTypeAFG.REVERSE:
      case TransactionTypeAFG.EWALLET_VOID:
        transactionType = CommonConstants.voided.tr;
        break;
      case TransactionTypeAFG.REFUND:
        transactionType = CommonConstants.refund.tr;
        break;
      default:
        break;
    }
    return Text(
      transactionType,
      style: CustomTextStyles.labelBlack500Size16Fw500,
    );
  }

  Widget setTextTransactionItemTime({required String? inputTransactionTime}) {
    var transactiontime = CommonConstants.textEmpty;

    if (StorageService.isGw3) {
      // format this fulltime 2025-05-06T06:56:20+00:00 to 2025-05-06 06:56:20
      DateTime dateTime = DateTime.parse(inputTransactionTime ?? '');
      transactiontime = StringUtils.convert2LocalTimeString(dateTime);
    } else {
      transactiontime =
          StringUtils.dateToStringGiftReportAFG(inputTransactionTime ?? '');
    }

    return Text(
      transactiontime,
      maxLines: 1,
      style: CustomTextStyles.labelGray500Size12Fw400,
    );
  }

  Widget setTextTransactionItemAmount({
    required String inputTransactionType,
    required String inputTransactionAmount,
    required String inputTransactionCurrency,
  }) {
    var transactionItemAmount = CommonConstants.textEmpty;
    TextStyle colorTransactionAmount = CustomTextStyles.labelRed300Size14Fw600;

    switch (inputTransactionType) {
      case TransactionTypeAFG.PREAUTH:
      case TransactionTypeAFG.SALES:
      case TransactionTypeAFG.SALE:
      case TransactionTypeAFG.QUICK_PAY:
      case TransactionTypeAFG.UNIFIED_ORDER:
      case TransactionTypeAFG.SUBMIT_QUICK_PAY:
        transactionItemAmount =
            '$inputTransactionCurrency ${StringUtils.formatAmount(double.parse(
                  StringUtils.toDollars(
                    inputTransactionAmount,
                  ),
                ), "#,##0.00")}';
        colorTransactionAmount = CustomTextStyles.labelGreen400Size14Fw400;

        break;
      case TransactionTypeAFG.VOID:
      case TransactionTypeAFG.REVERSE:
      case TransactionTypeAFG.EWALLET_VOID:
        transactionItemAmount =
            '$inputTransactionCurrency -${StringUtils.formatAmount(double.parse(
                  StringUtils.toDollars(
                    inputTransactionAmount,
                  ),
                ), "#,##0.00")}';
        colorTransactionAmount = CustomTextStyles.labelRed300Size16Fw600;
        break;
      case TransactionTypeAFG.REFUND:
        transactionItemAmount =
            '$inputTransactionCurrency -${StringUtils.formatAmount(double.parse(
                  StringUtils.toDollars(
                    inputTransactionAmount,
                  ),
                ), "#,##0.00")}';
        colorTransactionAmount = CustomTextStyles.labelRed300Size16Fw600;
        break;
      default:
        break;
    }

    return Text(
      transactionItemAmount,
      style: colorTransactionAmount,
    );
  }

  bool isDateValid(BuildContext context) {
    mDateFrom = StringUtils.dateToString(selectedFromDate.value);
    mDateFrom = mDateFrom.replaceAll(".", "");
    String tmpDate1 = mDateFrom.substring(4) +
        mDateFrom.substring(2, 4) +
        mDateFrom.substring(0, 2);

    mCurrentDate = DateTime.now().add(Duration(days: 6));
    mCurrentDate =
        DateTime(mCurrentDate.year, mCurrentDate.month - 3, mCurrentDate.day);

    int iYear3 = mCurrentDate.year;
    int iMonth3 = mCurrentDate.month; // + 1
    int iDay3 = mCurrentDate.day;
    oldestDate = iYear3.toString() +
        (iMonth3 > 9 ? iMonth3.toString() : "0$iMonth3") +
        (iDay3 > 9 ? iDay3.toString() : "0$iDay3");

    if (oldestDate.compareTo(tmpDate1) > 0) {
      CustomDialog.showMaterial(
        context,
        "${CommonConstants.dateEarlierThan.tr} [${oldestDate.substring(6, 8)}.${oldestDate.substring(4, 6)}.${oldestDate.substring(0, 4)}] ${CommonConstants.cannotData.tr}",
        btnText: CommonConstants.dataOutRange.tr,
      );
      return false;
    }
    mDateTo = mDateFrom;
    return true;
  }
}
