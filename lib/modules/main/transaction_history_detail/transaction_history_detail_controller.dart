// ignore_for_file: use_build_context_synchronously, avoid_print

import 'dart:io';
import 'dart:typed_data';

import 'package:app/app_controller.dart';
import 'package:app/models/request/send_email_request/send_email_request.dart';
import 'package:app/modules/auth/auth.dart';
import 'package:app/routes/routes.dart';
import 'package:app/shared/mixins/auto_polling_mixin.dart';
import 'package:app/shared/services/storage_service.dart';
import 'package:app/shared/utils/bytes_util.dart';
import 'package:app/shared/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../../api/api_repository.dart';
import '../../../models/request/amount.dart';
import '../../../models/request/credit_card_void_request/credit_card_void_request.dart';
import '../../../models/request/querry_receipt_infor_request/querry_receipt_infor_request.dart';
import '../../../models/request/refund_shopee_request/refund_shopee_request.dart';
import '../../../models/request/refund_transaction_request/refund_transaction_request.dart';
import '../../../models/response/querry_receipt_infor_response/querry_receipt_infor_response.dart';
import '../../../shared/constants/common.dart';
import '../../../shared/constants/constants_o7lite.dart';
import '../../../shared/constants/image_constant.dart';
import '../../../shared/secure_shared_preferences/secure_shared_preferences.dart';
import '../../../shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import '../../../shared/services/bluetooth_printer/models.dart';
import '../../../shared/services/bluetooth_printer/print_job_manager.dart';
import '../../../shared/services/printer.dart';
import '../../../shared/utils/log_utils.dart';
import '../../../shared/utils/enum/app_dialog_type.dart';
import '../../../shared/utils/responsive_util.dart';
import '../../../shared/secure_shared_preferences/sharepreference.dart';
import '../../../shared/widgets/custom_dialog/custom_dialog.dart';
import '../../../shared/widgets/string_utils.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/widgets.dart' as pw;

class TransactionHistoryDetailController extends GetxController
    with AutoPollingMixin {
  final ApiRepository apiRepository;
  TransactionHistoryDetailController({required this.apiRepository});

  final AppController appController = Get.find<AppController>();
  final AuthController authController = Get.find<AuthController>();

  // Make transaction ID reactive so it can be updated after refund
  late final RxString mTransactionId;

  QuerryReceiptInforResponse? resultReceiptInfoArgument =
      Get.arguments['resultReceiptInfo'] ?? null;
  final bool isDonation = Get.arguments['isDonation'] ?? false;
  bool isDisableSound = Get.arguments['isDisableSound'] ?? false;

  // This variable is using to check the navigator from Void or transaction list screen.
  // This is a cheat to help reload local data for refund transactino
  final int comeFromScreen =
      Get.arguments['comeFromScreen'] ?? TransactionState.COMEFROMLIST;
  RxString transactionState = ''.obs;
  var countCheckTransactionTime = 0;
  RxString messageTransactionState = ''.obs;
  RxString textTransactionType = ''.obs;
  RxString mCurrency = ''.obs;
  RxString textTransactionAmount = ''.obs;
  RxString textBtn = CommonConstants.refunded.tr.obs;
  RxString mQrUrl = ''.obs;

  RxBool isVoidable = false.obs;
  RxBool isBtnReceiptRefundEnable = false.obs;
  RxBool isActiveBtn = false.obs;
  RxBool isPasswordVisible = true.obs;
  RxBool isMobileUser = false.obs;
  RxBool isEnableEmailReceipt = false.obs;

  late AudioPlayer player = AudioPlayer();

  Color colorTextTransactionAmount = Colors.black;

  Rx<QuerryReceiptInforResponse?> resultReceiptInfoData =
      Rx<QuerryReceiptInforResponse>(QuerryReceiptInforResponse());

  final ScrollController scrollController = ScrollController();

  GlobalKey cardKey = GlobalKey();
  GlobalKey printCardKey = GlobalKey();
  GlobalKey logoKey = GlobalKey();
  GlobalKey barCodeKey = GlobalKey();
  final GlobalKey<FormState> currentPasswordFormKey = GlobalKey<FormState>();
  TextEditingController currentPasswordController = TextEditingController();

  final GlobalKey<FormState> receiptEmailFormKey = GlobalKey<FormState>();

  bool refreshInterval = false;
  RxString getServiceChargeRate = ''.obs;
  RxString getSaleAmount = ''.obs;

  bool isRequiredPassword = true;

  @override
  void onInit() async {
    // Initialize reactive transaction ID from arguments
    mTransactionId = RxString(Get.arguments['mTransactionId'] ?? '');

    refreshInterval = await SharedPrefManager.instance.getRefreshInterval();

    isRequiredPassword =
        await SharedPrefManager.instance.getBool('isEnableRefundPassword') ??
            false;

    isEnableEmailReceipt.value =
        await SharedPrefManager.instance.getBool('isEnableEmailReceipt') ??
            false;

    isMobileUser.value = appController.isMobileUser.value;

    super.onInit();
  }

  @override
  void onReady() {
    player = AudioPlayer();
    super.onReady();

    // op1
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   EasyLoading.show(
    //     status: '${CommonConstants.loading.tr}...',
    //   );
    //   Future.delayed(Duration(seconds: 2)).then((_) => fetchReceiptInfo(true));
    // });

    EasyLoading.show(
      status: '${CommonConstants.loading.tr}...',
    );
    // op2
    Future.delayed(Duration(seconds: 2)).then((_) => {fetchReceiptInfo(true)});

    // op3
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    //   EasyLoading.show(
    //     status: '${CommonConstants.loading.tr}...',
    //   );
    //   Future.delayed(Duration(seconds: 2)).then((_) => fetchReceiptInfo(true));
    // });
  }

  @override
  void onClose() {
    LogUtils.debugLog(
        '[TransactionHistoryDetailController] onClose: cleaning up');
    // Release the native audio player. GetX only calls onClose() (never
    // dispose()), so without this the ExoPlayer leaks on every screen visit
    // and exhausts the limited audio resources on POS devices, causing an ANR
    // or crash on the next player.setAsset() call.
    try {
      player.dispose();
    } catch (e) {
      LogUtils.debugLog('onClose: player dispose error: $e');
    }
    scrollController.dispose();
    resetPolling();
    super.onClose();
  }

  Future<void> onRefresh() async {
    isDisableSound = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      EasyLoading.show(
        status: '${CommonConstants.loading.tr}...',
      );
      Future.delayed(Duration(seconds: 2)).then((_) => fetchReceiptInfo(true));
    });
  }

  Future<bool> fetchReceiptInfo(bool isCheckUserPaying) async {
    var resultStatus = false;
    if (isCheckUserPaying) {
      stopPolling();
    }

    final resultReceiptInfo = resultReceiptInfoArgument ??
        await apiRepository.querryReceiptInfor(
          QuerryReceiptInforRequest(
            transactionId: mTransactionId.value,
          ),
          StorageService.isGw3,
        );
    EasyLoading.dismiss();
    if (resultReceiptInfo != null) {
      resultReceiptInfoArgument = null;
      // if navigate from Void screen will self-update transaction state,
      // because sometime is slowly load data and keep old status
      if (comeFromScreen == TransactionState.COMEFROMVOID &&
          resultReceiptInfo.transactionState ==
              TransactionState.STATE_SUCCESS) {
        // 2 is success, but we will update to 11 (refunded)
        if (!isDisableSound &&
            comeFromScreen == TransactionState.COMEFROMVOID) {
          await playSound();
        }
        resultReceiptInfo.transactionState = TransactionState.STATE_REFUNDED;
      }

      transactionState.value = resultReceiptInfo.transactionState ?? '';
      resultReceiptInfoData.value = resultReceiptInfo;
      isActiveBtn.value = true;
    }

    // GW3 uses string states — handle separately
    if (StorageService.isGw3) {
      resultStatus = _handleGw3TransactionState(isCheckUserPaying);
    } else {
      switch (transactionState.value) {
        case TransactionState.STATE_USER_PAYING:
          showUserPaying(Get.context!, isCheckUserPaying);
          await checkUserPaid(isCheckUserPaying);
          break;
        case TransactionState.STATE_VOIDED:
        case TransactionState.STATE_REVERSED:
          messageTransactionState.value = CommonConstants.voided.tr;
          isVoidable.value = false;
          isBtnReceiptRefundEnable.value = false;
          resultStatus = true;
          break;
        case TransactionState.STATE_REFUNDED:
          messageTransactionState.value = CommonConstants.refunded.tr;
          isVoidable.value = false;
          isBtnReceiptRefundEnable.value = false;
          resultStatus = true;
          break;
        case TransactionState.STATE_DENIED:
        case TransactionState.STATE_ORDER_CLOSED:
          CustomDialog.showMaterial(
              Get.context, CommonConstants.transactionFailed.tr,
              textTitle: Text(CommonConstants.dialogPaymentStatusTitle.tr),
              btnText: CommonConstants.ok.tr, onPressed: () {
            Get.back();
          });
          resultStatus = true;
          break;
        case TransactionState.STATE_SUCCESS:
          isVoidable.value = true;
          resultStatus = true;
          break;
      }
    }

    return resultStatus;
  }

  /// Handles GW3 string-based transaction states in fetchReceiptInfo
  bool _handleGw3TransactionState(bool isCheckUserPaying) {
    switch (transactionState.value) {
      case GW3TransactionState.PENDING:
      case GW3TransactionState.REQUESTED:
        showUserPaying(Get.context!, isCheckUserPaying);
        checkUserPaid(isCheckUserPaying);
        return false;
      case GW3TransactionState.VOIDED:
        messageTransactionState.value = CommonConstants.voided.tr;
        isVoidable.value = false;
        isBtnReceiptRefundEnable.value = false;
        return true;
      case GW3TransactionState.REFUNDED:
        messageTransactionState.value = CommonConstants.refunded.tr;
        isVoidable.value = false;
        isBtnReceiptRefundEnable.value = false;
        return true;
      case GW3TransactionState.EXPIRED:
        messageTransactionState.value = CommonConstants.statusExpired.tr;
        isVoidable.value = false;
        isBtnReceiptRefundEnable.value = false;
        return true;
      case GW3TransactionState.REJECTED:
      case GW3TransactionState.ERROR:
        CustomDialog.showMaterial(
            Get.context, CommonConstants.transactionFailed.tr,
            textTitle: Text(CommonConstants.dialogPaymentStatusTitle.tr),
            btnText: CommonConstants.ok.tr, onPressed: () {
          Get.back();
        });
        return true;
      case GW3TransactionState.CANCELLED:
        messageTransactionState.value = CommonConstants.statusCancelled.tr;
        isVoidable.value = false;
        isBtnReceiptRefundEnable.value = false;
        return true;
      case GW3TransactionState.APPROVED:
      case GW3TransactionState.CAPTURED:
      case GW3TransactionState.AUTHORIZED:
        isVoidable.value = resultReceiptInfoData.value?.isAllowRefund ?? false;
        return true;
      default:
        return true;
    }
  }

  void onPrintClicked(BuildContext context) async {
    // Mobile user: route to Bluetooth printer instead of POS printer (Requirement 6.1)
    if (appController.isMobileUser.value) {
      final btService = BluetoothPrinterService.instance;

      if (btService.status.value != BluetoothPrinterStatus.connected) {
        LogUtils.debugLog(
          'TransactionHistoryDetailController: No Bluetooth printer connected, prompting user',
        );
        CustomDialog.showToast('btPrinterNotConnected'.tr);
        Get.toNamed(Routes.BLUETOOTH_PRINTER);
        return;
      }

      await PrintJobManager.printReceipt(
        context: context,
        receiptKey: cardKey,
      );
      return;
    }

    // Use cached device detection from AppController for better performance
    final isCoherentDevice = appController.isCoherentDevice.value;
    final isCastleDevice = appController.isCastleDevice.value;
    final isLandiDevice = appController.isLandiDevice.value;
    final isWizarPosDevice = appController.isWizarPosDevice.value;
    final isANFUDevice = appController.isAnfuDevice.value;
    final isMorefunDevice = appController.isMorefunDevice.value;

    final merchantInfo = resultReceiptInfoData.value?.merchant;
    final address = merchantInfo?.address;
    final postalCode = address?.postalCode;
    final location = address?.country ?? address?.city;
    final merchantAddress4 = postalCode != null
        ? (location != null ? "$location, $postalCode" : postalCode)
        : (location ?? '');

    final brandName = resultReceiptInfoData.value?.brandName ?? '';

    // Safely scroll to top before capturing — guard against detached controller
    try {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          0,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
        // Wait for scroll animation to complete before capturing
        await Future.delayed(const Duration(milliseconds: 350));
      }
    } catch (e) {
      LogUtils.debugLog('onPrintClicked: scrollController error: $e');
    }

    // COHERENT DEVICE
    if (isCoherentDevice) {
      Printer.printCoherentReceipt(
          context,
          cardKey,
          logoKey,
          merchantInfo?.shortName ?? '',
          merchantInfo?.address?.line1 ?? '',
          merchantInfo?.address?.line2 ?? '',
          merchantInfo?.address?.line3 ?? '',
          merchantAddress4,
          textTransactionType.value,
          messageTransactionState.value,
          StringUtils.formatResponeDateTimeToString(
              setTextTransactionTime(), StringUtils.dateFormatddMMyyyyHHMMss),
          resultReceiptInfoData.value?.remarks ?? '',
          textTransactionAmount.value,
          SharedPrefManager.terminalID,
          mTransactionId.value,
          barCodeKey,
          brandName);

      return;
    }

    // MOREFUN DEVICE
    // Morefun prints a single bitmap via the YSDK, so send the already-designed
    // Flutter print layout (correct logo, centered, full width) instead of
    // re-rendering a native layout.
    if (isMorefunDevice) {
      final GlobalKey receiptKey =
          StorageService.isGw3 ? printCardKey : cardKey;
      Printer.printMorefunReceipt(context, receiptKey);
      return;
    }

    // CASTLE DEVICE
    if (isCastleDevice) {
      Printer.printCastleReceipt(
          context,
          cardKey,
          logoKey,
          merchantInfo?.shortName ?? '',
          merchantInfo?.address?.line1 ?? '',
          merchantInfo?.address?.line2 ?? '',
          merchantInfo?.address?.line3 ?? '',
          merchantAddress4,
          textTransactionType.value,
          messageTransactionState.value,
          StringUtils.formatResponeDateTimeToString(
              setTextTransactionTime(), StringUtils.dateFormatddMMyyyyHHMMss),
          resultReceiptInfoData.value?.remarks ?? '',
          textTransactionAmount.value,
          SharedPrefManager.terminalID,
          mTransactionId.value,
          barCodeKey,
          brandName);

      return;
    }

    // ANFU DEVICE
    if (isANFUDevice) {
      Printer.printANFUReceipt(
          context,
          cardKey,
          logoKey,
          merchantInfo?.shortName ?? '',
          merchantInfo?.address?.line1 ?? '',
          merchantInfo?.address?.line2 ?? '',
          merchantInfo?.address?.line3 ?? '',
          merchantAddress4,
          textTransactionType.value,
          messageTransactionState.value,
          StringUtils.formatResponeDateTimeToString(
              setTextTransactionTime(), StringUtils.dateFormatddMMyyyyHHMMss),
          resultReceiptInfoData.value?.remarks ?? '',
          textTransactionAmount.value,
          SharedPrefManager.terminalID,
          mTransactionId.value,
          barCodeKey,
          brandName);

      return;
    }

    if (isLandiDevice) {
      Printer.printLandiReceipt(
          context,
          cardKey,
          logoKey,
          merchantInfo?.shortName ?? '',
          merchantInfo?.address?.line1 ?? '',
          merchantInfo?.address?.line2 ?? '',
          merchantInfo?.address?.line3 ?? '',
          merchantAddress4,
          textTransactionType.value,
          messageTransactionState.value,
          StringUtils.formatResponeDateTimeToString(
              setTextTransactionTime(), StringUtils.dateFormatddMMyyyyHHMMss),
          resultReceiptInfoData.value?.remarks ?? '',
          textTransactionAmount.value,
          SharedPrefManager.terminalID,
          mTransactionId.value,
          barCodeKey,
          brandName);

      return;
    }

    if (isWizarPosDevice) {
      Printer.printWizarPosReceipt(
          context,
          cardKey,
          logoKey,
          merchantInfo?.shortName ?? '',
          merchantInfo?.address?.line1 ?? '',
          merchantInfo?.address?.line2 ?? '',
          merchantInfo?.address?.line3 ?? '',
          merchantAddress4,
          textTransactionType.value,
          messageTransactionState.value,
          StringUtils.formatResponeDateTimeToString(
              setTextTransactionTime(), StringUtils.dateFormatddMMyyyyHHMMss),
          resultReceiptInfoData.value?.remarks ?? '',
          textTransactionAmount.value,
          SharedPrefManager.terminalID,
          mTransactionId.value,
          barCodeKey,
          brandName);

      return;
    }

    // SUNMI DEVICE
    final GlobalKey receiptKey = StorageService.isGw3 ? printCardKey : cardKey;
    Printer.print(context, true, receiptKey);
  }

  void onSendEmailReceiptClicked(BuildContext context) {
    CustomDialog.showSendReceiptEmailDialogV2(
        context: context,
        formKey: receiptEmailFormKey,
        onCancelClicked: () {
          Get.back();
        },
        onSubmitClicked: (List<String> emails) {
          // Handle the list of emails here
          LogUtils.debugLog(emails);
          _generatePdf(context, cardKey, emails);
          // Get.back();
        });
  }

  void togglePasswordVisibility(RxBool isVisible) =>
      isVisible.value = !isVisible.value;

  void onRefundClicked(BuildContext context) async {
    LogUtils.debugLog(
        'REFUND::: Step 1 - Refund button clicked, verifying authorization...');
    await EasyLoading.show(
      status: CommonConstants.verifyingAuthorization.tr,
    );
    final hasAuthorized = await authController.reLogin();

    EasyLoading.dismiss();
    LogUtils.debugLog(
        'REFUND::: Step 2 - Authorization result: hasAuthorized=$hasAuthorized');

    if (!hasAuthorized) {
      LogUtils.debugLog(
          'REFUND::: Step 2a - Authorization FAILED, clearing credentials and redirecting to login');
      CustomDialog.showToast(CommonConstants.authorizationFailed.tr);
      await SecureSharedPreferences.instance.clearSecureSharedPef();
      Get.offAllNamed(
        Routes.LOG_IN,
        parameters: {"needToResetCredential": "true"},
      );
      return;
    }

    LogUtils.debugLog(
        'REFUND::: Step 3 - Authorization passed, showing confirmation dialog');
    String mess;
    if (checkIsCreditCard()) {
      mess = CommonConstants.doYouWantVoidTransaction.tr;
    } else {
      mess = CommonConstants.doYouWantRefundTransaction.tr;
    }
    LogUtils.debugLog(
        'REFUND::: Step 3a - isCreditCard=${checkIsCreditCard()}, isGw3=${StorageService.isGw3}, isRequiredPassword=$isRequiredPassword');

    isRequiredPassword
        ? CustomDialog.showCustomDialogConfirmPassword(
            isPasswordVisible: isPasswordVisible,
            onPressPassword: () => togglePasswordVisibility(isPasswordVisible),
            formKey: currentPasswordFormKey,
            currentPasswordController: currentPasswordController,
            titleButton: CommonConstants.ok.tr,
            content: mess,
            context: Get.context!,
            onpressCancel: () {
              LogUtils.debugLog(
                  'REFUND::: Step 4 - User cancelled refund (password dialog)');
              Get.back();
              currentPasswordController.clear();
            },
            onPressedCheck: () {
              if (currentPasswordFormKey.currentState!.validate()) {
                Get.back();
                currentPasswordController.clear();
                if (StorageService.isGw3) {
                  LogUtils.debugLog(
                      'REFUND::: Step 4 - User confirmed, calling processRefund() (GW3)');
                  processRefund();
                } else {
                  LogUtils.debugLog(
                      'REFUND::: Step 4 - User confirmed, calling processVoid() (GW2)');
                  processVoid();
                }
              }
            },
            dialogType: AppDialogType.confirm,
          )
        : CustomDialog.showCustomDialog(
            titleButton: CommonConstants.ok.tr,
            content: mess,
            context: Get.context!,
            onpressCancel: () {
              LogUtils.debugLog('REFUND::: Step 4 - User cancelled refund');
              Get.back();
            },
            onPressedCheck: () {
              Get.back();
              if (StorageService.isGw3) {
                LogUtils.debugLog(
                    'REFUND::: Step 4 - User confirmed, calling processRefund() (GW3)');
                processRefund();
              } else {
                LogUtils.debugLog(
                    'REFUND::: Step 4 - User confirmed, calling processVoid() (GW2)');
                processVoid();
              }
            },
            dialogType: AppDialogType.confirm,
          );
  }

  var isShowingCheckUserPayingDialog = false;
  void showUserPaying(BuildContext context, bool isCheckUserPayding) {
    if (!isCheckUserPayding) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isShowingCheckUserPayingDialog) return;

      CustomDialog.showCustomDialog(
        isBarrierDismissible: true,
        isShowLoading: false,
        titleButton: CommonConstants.check.tr,
        content: CommonConstants.msgWaitingPaymentStatus.trParams(
            {'brandName': resultReceiptInfoData.value?.brandName ?? ''}),
        context: Get.context!,
        isCheckEnableCloseIcon: true,
        onpressCancel: () {
          if (comeFromScreen == TransactionState.COMEFROMLIST) {
            Get.offNamedUntil(Routes.TRANSACTION_HISTORY, (route) => false);
          } else {
            Get.offAllNamed(Routes.HOME);
          }

          isShowingCheckUserPayingDialog = false;
        },
        onPressedCheck: () async {
          isShowingCheckUserPayingDialog = true;
          transactionState.value = '';
          countCheckTransactionTime++;
          // Change from 3 to 10 times to press check button
          if (countCheckTransactionTime == 10) {
            CustomDialog.showMaterial(
              context,
              CommonConstants.checkTransactionStatus.tr,
              btnText: CommonConstants.ok.tr.toUpperCase(),
              onPressed: () {
                Get.offNamedUntil(Routes.TRANSACTION_HISTORY, (route) => false);
              },
            );
          } else {
            await EasyLoading.show(
              status: '${CommonConstants.loading.tr}...',
            );
            Future.delayed(Duration(seconds: 5)).then(
              (_) async {
                bool hasPaid = await fetchReceiptInfo(true);
                if (hasPaid) {
                  Get.back();
                }
              },
            );
          }
        },
        dialogType: AppDialogType.waiting_payment,
        isCheckDisplayTitle: true,
      );
    });
  }

  Future<void> checkUserPaid(bool isCheckUserPaying) async {
    if (!refreshInterval) {
      LogUtils.debugLog(
          '[TransactionHistoryDetailController] checkUserPaid: refreshInterval disabled, skipping');
      return;
    }
    LogUtils.debugLog(
        '[TransactionHistoryDetailController] checkUserPaid: starting auto-poll (isCheckUserPaying=$isCheckUserPaying)');
    startPolling(() => _pollReceiptStatus());
  }

  /// Polling callback for auto-refresh. Returns true to stop polling
  /// when the transaction is no longer in STATE_USER_PAYING.
  Future<bool> _pollReceiptStatus() async {
    LogUtils.debugLog(
        '[TransactionHistoryDetailController] _pollReceiptStatus: current state=${transactionState.value}');
    if (transactionState.value != TransactionState.STATE_USER_PAYING) {
      LogUtils.debugLog(
          '[TransactionHistoryDetailController] _pollReceiptStatus: state changed, stopping poll');
      Get.back();
      return true; // stop polling
    }
    await fetchReceiptInfo(false);
    return false; // keep polling
  }

  // Refund transaction for GW3
  void processRefund() async {
    LogUtils.debugLog('REFUND::: Step 5 - processRefund() started');
    await EasyLoading.show(
      status: CommonConstants.processingStatus.tr,
    );

    bool isAllowRefund = resultReceiptInfoData.value?.isAllowRefund ?? false;
    LogUtils.debugLog(
        'REFUND::: Step 5a - isAllowRefund=$isAllowRefund, transactionId=$mTransactionId');

    if (!isAllowRefund) {
      EasyLoading.dismiss();
      LogUtils.debugLog(
          'REFUND::: Step 5b - Refund NOT allowed, showing error dialog');
      CustomDialog.showMaterial(
        Get.context,
        CommonConstants.msgTransactionNotRefundable.tr,
      );
      return;
    }

    LogUtils.debugLog(
        'REFUND::: Step 6 - Calling apiRepository.refundTxn() with transactionId=$mTransactionId.value, amount=${resultReceiptInfoData.value?.totalAmount}, currency=${mCurrency.value}');

    final refundResponse = await apiRepository.refundTxn(
      mTransactionId.value,
      Amount(
        value: int.parse(resultReceiptInfoData.value?.totalAmount ?? '0'),
        currency: mCurrency.value,
      ),
    );

    LogUtils.debugLog(
        'REFUND::: Step 6a - refundTxn result: refundResponse=$refundResponse');

    EasyLoading.dismiss();

    if (refundResponse != null) {
      final newTxnId = refundResponse.oxpayTxnId;
      LogUtils.debugLog(
          'REFUND::: Step 7 - Refund completed successfully, new txnId=$newTxnId, showing success dialog');

      CustomDialog.showCustomDialog(
        titleButton: CommonConstants.btnViewReceipt.tr,
        content: CommonConstants.msgRefundCompleted.tr,
        context: Get.context!,
        onPressedCheck: () async {
          Get.back();
          LogUtils.debugLog(
              'REFUND::: Step 8 - User clicked View Receipt, updating to new txnId and refreshing receipt info');

          await EasyLoading.show(
            status: '${CommonConstants.loading.tr}...',
          );

          // Small delay to allow dialog to dismiss before fetching
          await Future.delayed(Duration(milliseconds: 300));

          // Fetch the new refund transaction using the new txnId
          final newReceiptInfo = await apiRepository.querryReceiptInfor(
            QuerryReceiptInforRequest(
              transactionId: newTxnId,
            ),
            StorageService.isGw3,
          );

          EasyLoading.dismiss();

          if (newReceiptInfo != null) {
            LogUtils.debugLog(
                'REFUND::: Step 9 - Successfully fetched new receipt info, updating current screen');

            // Update the transaction ID to the new refund transaction ID
            mTransactionId.value = newTxnId;

            // Update the current controller with new transaction data
            resultReceiptInfoArgument = newReceiptInfo;
            transactionState.value = newReceiptInfo.transactionState ?? '';
            resultReceiptInfoData.value = newReceiptInfo;
            isActiveBtn.value = true;

            // Process the new transaction state to update UI elements
            if (StorageService.isGw3) {
              _handleGw3TransactionState(true);
            }

            // Trigger UI update by calling setTextTransactionType which updates all display values
            setTextTransactionType();
            setTextTransactionState();

            LogUtils.debugLog(
                'REFUND::: Step 9a - Controller updated successfully, txnId=${mTransactionId.value}, state=${transactionState.value}, type=${textTransactionType.value}');
          } else {
            LogUtils.debugLog(
                'REFUND::: Step 9 - Failed to fetch new receipt info');
            CustomDialog.showToast(CommonConstants.pleaseTryAgain.tr);
          }
        },
        dialogType: AppDialogType.success,
        isCheckIconPng: true,
      );
    } else {
      LogUtils.debugLog(
          'REFUND::: Step 7 - Refund FAILED (refundResponse=null)');
    }
  }

  /// Refund transaction
  void processVoid() async {
    await EasyLoading.show(
      status: CommonConstants.processingStatus.tr,
    );
    var tempType = "";
    switch (resultReceiptInfoData.value?.brandName) {
      case ConstantsO7Lite.BRAND_ALIPAY:
      case ConstantsO7Lite.BRAND_ALIPAY_NEW:
        tempType = ConstantsO7Lite.ALIPAY_TYPE;
        break;
      case ConstantsO7Lite.BRAND_WECHAT:
      case ConstantsO7Lite.BRAND_WECHAT_NEW:
        tempType = ConstantsO7Lite.WECHAT_TYPE;
        break;
      case ConstantsO7Lite.BRAND_QUICKPASS:
        tempType = ConstantsO7Lite.QUICKPASS_TYPE;
        break;
      case ConstantsO7Lite.BRAND_GRABPAY:
      case ConstantsO7Lite.BRAND_GRABPAY2:
        tempType = ConstantsO7Lite.GRABPAY_TYPE;
        break;
      case ConstantsO7Lite.BRAND_GRABPAY3:
        tempType = ConstantsO7Lite.GRABPAY_V3_TYPE;
        break;
      case ConstantsO7Lite.BRAND_ATOME:
        tempType = ConstantsO7Lite.ATOME_TYPE;
        break;
      case ConstantsO7Lite.BRAND_BOOST:
        tempType = ConstantsO7Lite.BOOST_TYPE;
        break;
      case ConstantsO7Lite.BRAND_TNG:
        tempType = ConstantsO7Lite.TOUCHNGO_TYPE;
        break;
      case ConstantsO7Lite.BRAND_SHOPEE:
        tempType = ConstantsO7Lite.SHOPEE_TYPE;
        break;
      case ConstantsO7Lite.BRAND_TOUCH_N_GO_DUITNOW_QR:
        tempType = ConstantsO7Lite.TOUCHNGO_TYPE;
        break;
      case ConstantsO7Lite.BRAND_DASH:
      case ConstantsO7Lite.BRAND_AMEX:
      case ConstantsO7Lite.BRAND_VISA:
      case ConstantsO7Lite.BRAND_MASTERCARD:
      case ConstantsO7Lite.BRAND_DINERS:
      case ConstantsO7Lite.BRAND_DISCOVER:
        await apiRepository.creditCardVoid(
          CreditCardVoidRequest(
            originalId: mTransactionId.value,
            currency: mCurrency.value,
            totalAmount: resultReceiptInfoData.value?.totalAmount,
          ),
        );

        WidgetsBinding.instance.addPostFrameCallback((_) {
          Future.delayed(Duration(seconds: 1))
              .then((_) => fetchReceiptInfo(true));
        });
        return;
      case ConstantsO7Lite.BRAND_PAYNOW:
        tempType = ConstantsO7Lite.PAYNOW_TYPE;
        break;
      case ConstantsO7Lite.BRAND_PAYNOW2:
      default:
        CustomDialog.showToast(
          CommonConstants.refundFailed.tr,
        );
        break;
    }

    if (tempType == ConstantsO7Lite.SHOPEE_TYPE) {
      await apiRepository.refundShopee(
        RefundShopeeRequest(
          originalTransactionId: mTransactionId.value,
          currency: mCurrency.value,
          totalAmount: resultReceiptInfoData.value?.totalAmount,
        ),
      );
    } else {
      final res = await apiRepository.refundTransaction(
        RefundTransactionRequest(
          tradeNo: mTransactionId.value,
          currency: mCurrency.value,
          totalAmount: resultReceiptInfoData.value?.totalAmount,
          eType: tempType,
        ),
      );
      if (res?.data != null) {
        CustomDialog.showCustomDialog(
          titleButton: CommonConstants.btnViewReceipt.tr,
          content: CommonConstants.msgRefundCompleted.tr,
          context: Get.context!,
          onPressedCheck: () {
            Get.back();
          },
          dialogType: AppDialogType.success,
          isCheckIconPng: true,
        );
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(Duration(seconds: 1)).then((_) => fetchReceiptInfo(true));
    });
    return;
  }

  playSound() async {
    final isEnableSound =
        await SharedPrefManager.instance.getBool('isEnableSound') ?? false;

    if (!isEnableSound) return;

    final sound = await SharedPrefManager.instance.getCashierSound();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await player.setAsset('assets/' + sound);
        await player.play();
      } catch (e) {
        LogUtils.debugLog('playSound: failed to play "$sound": $e');
      }
    });
  }

  Widget setImageBrand() {
    if (resultReceiptInfoData.value == null) {
      return Container(
        height: 100,
      );
    }

    var brandName = resultReceiptInfoData.value?.brandName ?? '';
    var imageBrand = ImageConstant.iconOxayWallet;

    switch (brandName) {
      case ConstantsO7Lite.BRAND_ALIPAY:
      case ConstantsO7Lite.BRAND_ALIPAY_NEW:
        imageBrand = ImageConstant.iconAlipayWallet;
        break;
      case ConstantsO7Lite.BRAND_WECHAT:
      case ConstantsO7Lite.BRAND_WECHAT_NEW:
        imageBrand = ImageConstant.iconWeChatpayWallet;
        break;
      case ConstantsO7Lite.BRAND_GRABPAY:
      case ConstantsO7Lite.BRAND_GRABPAY2:
      case ConstantsO7Lite.BRAND_GRABPAY3:
        imageBrand = ImageConstant.iconGrabpayWallet;
        if (!appController.isSGPLocation()) {
          imageBrand = ImageConstant.imageGrabDuitnow;
        }
        break;
      case ConstantsO7Lite.BRAND_DASH:
        imageBrand = ImageConstant.iconDashWallet;
        break;
      case ConstantsO7Lite.BRAND_ATOME:
        imageBrand = ImageConstant.iconAtomeWallet;
        break;
      case ConstantsO7Lite.BRAND_PAYNOW:
      case ConstantsO7Lite.BRAND_PAYNOW2:
        imageBrand = ImageConstant.iconPaynowWallet;
        break;
      case ConstantsO7Lite.BRAND_THAIQR:
        imageBrand = ImageConstant.iconThaiQRWallet;
        break;
      case ConstantsO7Lite.BRAND_AMEX:
        imageBrand = ImageConstant.iconAmexWallet;
        break;
      case ConstantsO7Lite.BRAND_VISA:
        imageBrand = ImageConstant.iconVisaWallet;
        break;
      case ConstantsO7Lite.BRAND_MASTERCARD:
        imageBrand = ImageConstant.iconMasterCardWallet;
        break;
      case ConstantsO7Lite.BRAND_DINERS:
        imageBrand = ImageConstant.iconDinersWallet;
        break;
      case ConstantsO7Lite.BRAND_DISCOVER:
      case ConstantsO7Lite.BRAND_RUPAY:
        imageBrand = ImageConstant.iconDiscoverWallet;
        break;
      case ConstantsO7Lite.BRAND_CUP:
      case ConstantsO7Lite.BRAND_QUICKPASS:
        imageBrand = ImageConstant.iconCupWallet;
        break;
      case ConstantsO7Lite.BRAND_ENETS:
        imageBrand = ImageConstant.iconNetsPayWallet;
        isVoidable.value = false;
        break;
      case ConstantsO7Lite.BRAND_BOOST:
        imageBrand = ImageConstant.iconBoostWallet;
        break;
      case ConstantsO7Lite.BRAND_TNG:
        imageBrand = ImageConstant.iconTouchNGoEWallet;
        break;
      case ConstantsO7Lite.BRAND_SHOPEE:
        imageBrand = ImageConstant.iconShopeeWallet;
        break;
      case ConstantsO7Lite.BRAND_IOUPAY:
        imageBrand = ImageConstant.iconIOUpayWallet;
        break;
      case ConstantsO7Lite.BRAND_TOUCH_N_GO_DUITNOW_QR:
        imageBrand = ImageConstant.iconTouchNGoxDuitNow;
        break;
      default:
        imageBrand = ImageConstant.iconOxayWallet;
        break;
    }

    return RepaintBoundary(
      key: logoKey,
      child: getLogoWidget(brandName, imageBrand),
    );
    //   child: StorageService.isGw3
    //       ? getBrandImageWidget(brandName, height: 160)
    //       : Image.asset(
    //           imageBrand,
    //           width: ResponsiveUtil().getSize(240),
    //         ),
    // );
  }

  /// Returns the brand logo widget without GlobalKey wrapping.
  /// Used by the offscreen print layout to avoid duplicate GlobalKey errors.
  Widget setImageBrandForPrint() {
    if (resultReceiptInfoData.value == null) {
      return Container(height: 100);
    }
    final brandName = resultReceiptInfoData.value?.brandName ?? '';
    return getLogoWidget(brandName, _getBrandImage(brandName));
  }

  String _getBrandImage(String brandName) {
    switch (brandName) {
      case ConstantsO7Lite.BRAND_ALIPAY:
      case ConstantsO7Lite.BRAND_ALIPAY_NEW:
        return ImageConstant.iconAlipayWallet;
      case ConstantsO7Lite.BRAND_WECHAT:
      case ConstantsO7Lite.BRAND_WECHAT_NEW:
        return ImageConstant.iconWeChatpayWallet;
      case ConstantsO7Lite.BRAND_GRABPAY:
      case ConstantsO7Lite.BRAND_GRABPAY2:
      case ConstantsO7Lite.BRAND_GRABPAY3:
        return !appController.isSGPLocation()
            ? ImageConstant.imageGrabDuitnow
            : ImageConstant.iconGrabpayWallet;
      case ConstantsO7Lite.BRAND_DASH:
        return ImageConstant.iconDashWallet;
      case ConstantsO7Lite.BRAND_ATOME:
        return ImageConstant.iconAtomeWallet;
      case ConstantsO7Lite.BRAND_PAYNOW:
      case ConstantsO7Lite.BRAND_PAYNOW2:
        return ImageConstant.iconPaynowWallet;
      case ConstantsO7Lite.BRAND_THAIQR:
        return ImageConstant.iconThaiQRWallet;
      case ConstantsO7Lite.BRAND_AMEX:
        return ImageConstant.iconAmexWallet;
      case ConstantsO7Lite.BRAND_VISA:
        return ImageConstant.iconVisaWallet;
      case ConstantsO7Lite.BRAND_MASTERCARD:
        return ImageConstant.iconMasterCardWallet;
      case ConstantsO7Lite.BRAND_DINERS:
        return ImageConstant.iconDinersWallet;
      case ConstantsO7Lite.BRAND_DISCOVER:
      case ConstantsO7Lite.BRAND_RUPAY:
        return ImageConstant.iconDiscoverWallet;
      case ConstantsO7Lite.BRAND_CUP:
      case ConstantsO7Lite.BRAND_QUICKPASS:
        return ImageConstant.iconCupWallet;
      case ConstantsO7Lite.BRAND_ENETS:
        return ImageConstant.iconNetsPayWallet;
      case ConstantsO7Lite.BRAND_BOOST:
        return ImageConstant.iconBoostWallet;
      case ConstantsO7Lite.BRAND_TNG:
      case ConstantsO7Lite.BRAND_TOUCH_N_GO_DUITNOW_QR:
        return ImageConstant.iconTouchNGoxDuitNow;
      case ConstantsO7Lite.BRAND_SHOPEE:
        return ImageConstant.iconShopeeWallet;
      case ConstantsO7Lite.BRAND_IOUPAY:
        return ImageConstant.iconIOUpayWallet;
      default:
        return ImageConstant.iconOxayWallet;
    }
  }

  Widget getLogoWidget(String brandName, String imageBrand) {
    if (!StorageService.isGw3) {
      return Image.asset(
        imageBrand,
        width: ResponsiveUtil().getSize(240),
      );
    }

    if (brandName.toLowerCase().contains("wechat")) {
      // Use wallet icon for WeChat (wechat.png has rendering issues on print)
      // Must use BoxFit.contain so the image scales within the parent SizedBox(height: 90)
      // instead of overflowing and getting clipped
      return Image.asset(
        ImageConstant.iconWeChatpayWallet,
        height: 90,
        fit: BoxFit.contain,
      );
    }

    return getBrandImageWidget(brandName, height: 160);
  }

  Widget setMerchantName() {
    return Text(
      resultReceiptInfoData.value?.merchant?.shortName ?? '',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w500,
        fontFamily: ConstantsO7Lite.ARIAL_TYPE,
        color: Colors.black,
      ),
    );
  }

  Widget setTextAddress() {
    return Text(
      resultReceiptInfoData.value?.merchant?.address?.line1 ?? '',
      style: TextStyle(
        fontSize: ResponsiveUtil().getFontSize(20),
        fontWeight: FontWeight.w400,
        fontFamily: ConstantsO7Lite.ARIAL_TYPE,
        color: Colors.black,
      ),
    );
  }

  Widget setTextCompanyAddress() {
    return Text(
      resultReceiptInfoData.value?.merchant?.address?.line2 ?? '',
      style: TextStyle(
        fontSize: ResponsiveUtil().getFontSize(20),
        fontWeight: FontWeight.w400,
        fontFamily: ConstantsO7Lite.ARIAL_TYPE,
        color: Colors.black,
      ),
    );
  }

  Widget setTextTime() {
    return Text(
      resultReceiptInfoData.value?.merchant?.address?.line3 ?? '',
      style: TextStyle(
        fontSize: ResponsiveUtil().getFontSize(20),
        fontWeight: FontWeight.w400,
        fontFamily: ConstantsO7Lite.ARIAL_TYPE,
        color: Colors.black,
      ),
    );
  }

  Widget setTextBizRegNo() {
    return Text(
      resultReceiptInfoData.value?.merchant?.address?.country != null &&
              resultReceiptInfoData.value?.merchant?.address?.postalCode != null
          ? '${resultReceiptInfoData.value?.merchant?.address?.country ?? ''}, ${resultReceiptInfoData.value?.merchant?.address?.postalCode ?? ''}'
          : '',
      style: TextStyle(
        fontSize: ResponsiveUtil().getFontSize(20),
        fontWeight: FontWeight.w400,
        fontFamily: ConstantsO7Lite.ARIAL_TYPE,
        color: Colors.black,
      ),
    );
  }

  String setTextTransactionType() {
    if (isUserPayingOrNotPaid()) return '';

    mCurrency.value = resultReceiptInfoData.value?.currency ?? '';
    var mTotalAmount = resultReceiptInfoData.value?.totalAmount ?? '';
    var serviceChargeRate = resultReceiptInfoData.value?.serviceAmount ?? '';
    var salesAmount = resultReceiptInfoData.value?.salesAmount ?? '';

    // GW3 returns string transaction types (e.g. "SALE", "REFUND", "VOID")
    if (StorageService.isGw3) {
      return _setTextTransactionTypeGw3(
          mTotalAmount, serviceChargeRate, salesAmount);
    }

    switch (resultReceiptInfoData.value?.transactionType.toString()) {
      case TransactionType.EWALLET_VOID:
      case TransactionType.REFUND:
      case TransactionType.VOID:
      case TransactionType.REVERSE:
        if (checkIsCreditCard()) {
          textTransactionType.value = CommonConstants.voidText.tr;
        } else {
          textTransactionType.value = CommonConstants.refund.tr;
        }
        colorTextTransactionAmount = Colors.red;
        isBtnReceiptRefundEnable.value = false;
        textTransactionAmount.value =
            '${mCurrency.value} -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(mTotalAmount)), "#,##0.00")}';
        getServiceChargeRate.value =
            '${mCurrency.value} -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(serviceChargeRate)), "#,##0.00")}';
        getSaleAmount.value =
            '${mCurrency.value} -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(salesAmount)), "#,##0.00")}';
        return textTransactionType.value;

      // return '$mCurrency -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(mTotalAmount)), "#,##0.00")}';
      case TransactionType.SALES:
      case TransactionType.PREAUTH:
      case TransactionType.QUICK_PAY:
      case TransactionType.UNIFIED_ORDER:
        textTransactionType.value = CommonConstants.sale.tr;
        if (isVoidable.value) {
          isBtnReceiptRefundEnable.value = true;
        } else {
          isBtnReceiptRefundEnable.value = false;
        }
        if (checkIsCreditCard()) {
          textBtn.value = CommonConstants.voided.tr;
        } else {
          textBtn.value = CommonConstants.refund.tr;
        }
        if (isDonation) {
          isBtnReceiptRefundEnable.value = false;
        }
        textTransactionAmount.value =
            '${mCurrency.value} ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(mTotalAmount)), "#,##0.00")}';
        getServiceChargeRate.value =
            '${mCurrency.value} ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(serviceChargeRate)), "#,##0.00")}';
        getSaleAmount.value =
            '${mCurrency.value} ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(salesAmount)), "#,##0.00")}';
        return textTransactionType.value;
      // return '$mCurrency ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(mTotalAmount)), "#,##0.00")}';

      default:
        break;
    }

    return CommonConstants.textEmpty;
  }

  /// Handles GW3 string-based transaction types (SALE, REFUND, VOID, etc.)
  String _setTextTransactionTypeGw3(
      String mTotalAmount, String serviceChargeRate, String salesAmount) {
    final txnType =
        resultReceiptInfoData.value?.transactionType?.toString() ?? '';

    switch (txnType) {
      case GW3TransactionType.REFUND:
      case GW3TransactionType.VOID:
        textTransactionType.value = txnType == GW3TransactionType.VOID
            ? CommonConstants.voidText.tr
            : CommonConstants.refund.tr;
        colorTextTransactionAmount = Colors.red;
        isBtnReceiptRefundEnable.value = false;
        textTransactionAmount.value =
            '${mCurrency.value} -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(mTotalAmount)), "#,##0.00")}';
        getServiceChargeRate.value =
            '${mCurrency.value} -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(serviceChargeRate)), "#,##0.00")}';
        getSaleAmount.value =
            '${mCurrency.value} -${StringUtils.formatAmount(double.parse(StringUtils.toDollars(salesAmount)), "#,##0.00")}';
        return textTransactionType.value;

      case GW3TransactionType.SALE:
      case GW3TransactionType.AUTHORIZATION:
      case GW3TransactionType.CAPTURE:
      case GW3TransactionType.QUERY:
        textTransactionType.value = CommonConstants.sale.tr;
        textBtn.value = CommonConstants.refund.tr;
        isBtnReceiptRefundEnable.value = isVoidable.value && !isDonation;
        textTransactionAmount.value =
            '${mCurrency.value} ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(mTotalAmount)), "#,##0.00")}';
        getServiceChargeRate.value =
            '${mCurrency.value} ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(serviceChargeRate)), "#,##0.00")}';
        getSaleAmount.value =
            '${mCurrency.value} ${StringUtils.formatAmount(double.parse(StringUtils.toDollars(salesAmount)), "#,##0.00")}';
        return textTransactionType.value;

      default:
        break;
    }

    return CommonConstants.textEmpty;
  }

  bool isUserPayingOrNotPaid() {
    // GW3 uses string states — PENDING is the equivalent of "user paying"
    if (StorageService.isGw3) {
      return transactionState.value == GW3TransactionState.PENDING ||
          transactionState.value == '';
    }

    bool isUserPayingOrNotPaidYet =
        transactionState.value == TransactionState.STATE_USER_PAYING ||
            transactionState.value == TransactionState.STATE_DENIED ||
            transactionState.value == TransactionState.STATE_ORDER_CLOSED ||
            transactionState.value == '';

    return isUserPayingOrNotPaidYet;
  }

  String setTextTransactionState() {
    if (isUserPayingOrNotPaid()) return '';

    // GW3 uses string states (e.g. "SUCCESS", "CAPTURED", "CANCELLED")
    if (StorageService.isGw3) {
      return _setTextTransactionStateGw3();
    }

    var transactionState = resultReceiptInfoData.value?.transactionState;
    switch (transactionState) {
      case TransactionState.STATE_USER_PAYING:
        // showUserPaying(context);
        break;
      case TransactionState.STATE_VOIDED:
      case TransactionState.STATE_REVERSED:
        // to do : set flag for total amount
        // tvTotalAmount.setPaintFlags(
        // tvTotalAmount.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
        messageTransactionState.value = CommonConstants.voided.tr;
        // to do check is Voidable
        // isVoidable = false;
        break;
      case TransactionState.STATE_REFUNDED:
        // to do : set flag for total amount
        // tvTotalAmount.setPaintFlags(
        // tvTotalAmount.getPaintFlags() | Paint.STRIKE_THRU_TEXT_FLAG);
        messageTransactionState.value = CommonConstants.refunded.tr;
        // isVoidable = false;
        break;
      case TransactionState.STATE_DENIED:
      case TransactionState.STATE_ORDER_CLOSED:
        break;
      case TransactionState.STATE_SUCCESS:
      case TransactionState.STATE_AUTHORIZED:
        messageTransactionState.value = CommonConstants.success.tr;
        if (!isDisableSound &&
            comeFromScreen == TransactionState.COMEFROMDIGITALPAYMENT) {
          playSound();
        }
        break;
      default:
        // todo : show failed transaction
        // showQuitAlertDialog(R.string.dialog_title_payment_status,
        //     R.string.dialog_message_transaction_failed);
        break;
    }

    return messageTransactionState.value;
  }

  /// Handles GW3 string-based transaction states for display text
  String _setTextTransactionStateGw3() {
    final state =
        resultReceiptInfoData.value?.transactionState?.toString() ?? '';

    switch (state) {
      case GW3TransactionState.APPROVED:
        messageTransactionState.value = CommonConstants.success.tr;
        if (!isDisableSound &&
            comeFromScreen == TransactionState.COMEFROMDIGITALPAYMENT) {
          playSound();
        }
        break;
      case GW3TransactionState.CAPTURED:
        messageTransactionState.value = CommonConstants.success.tr;
        if (!isDisableSound &&
            comeFromScreen == TransactionState.COMEFROMDIGITALPAYMENT) {
          playSound();
        }
        break;
      case GW3TransactionState.VOIDED:
        messageTransactionState.value = CommonConstants.voided.tr;
        break;
      case GW3TransactionState.REFUNDED:
        messageTransactionState.value = CommonConstants.refunded.tr;
        break;
      case GW3TransactionState.CANCELLED:
        messageTransactionState.value = CommonConstants.statusCancelled.tr;
        break;
      case GW3TransactionState.EXPIRED:
        messageTransactionState.value = CommonConstants.statusExpired.tr;
        break;
      case GW3TransactionState.REJECTED:
      case GW3TransactionState.ERROR:
        messageTransactionState.value = CommonConstants.transactionFailed.tr;
        break;
      case GW3TransactionState.AUTHORIZED:
        messageTransactionState.value = CommonConstants.success.tr;
        break;
      case GW3TransactionState.REQUESTED:
        messageTransactionState.value = CommonConstants.statusPending.tr;
        break;
      default:
        break;
    }

    return messageTransactionState.value;
  }

  String setTextTransactionTime() {
    if (isUserPayingOrNotPaid()) return '';

    if (resultReceiptInfoData.value?.gatewayResponseDate != null &&
        resultReceiptInfoData.value?.gatewayResponseDate.toString() != "") {
      return resultReceiptInfoData.value?.gatewayResponseDate ?? '';
    }

    if (resultReceiptInfoData.value?.gatewayRequestDate != null &&
        resultReceiptInfoData.value?.gatewayRequestDate.toString() != "") {
      return resultReceiptInfoData.value?.gatewayRequestDate ?? '';
    }

    if (resultReceiptInfoData.value?.clientRequestDate != null &&
        resultReceiptInfoData.value?.clientRequestDate.toString() != "") {
      return resultReceiptInfoData.value?.clientRequestDate ?? '';
    }

    return CommonConstants.textEmpty;
  }

  String setQrUrl() {
    if (isUserPayingOrNotPaid()) return '';

    if (resultReceiptInfoData.value != null) {
      mQrUrl.value = resultReceiptInfoData.value?.commChestQrUrl ?? '';
    }

    return mQrUrl.value;
  }

  bool checkIsCreditCard() {
    switch (resultReceiptInfoData.value?.brandName) {
      case ConstantsO7Lite.BRAND_VISA:
      case ConstantsO7Lite.BRAND_MASTERCARD:
      case ConstantsO7Lite.BRAND_AMEX:
      case ConstantsO7Lite.BRAND_DINERS:
      case ConstantsO7Lite.BRAND_DISCOVER:
      case ConstantsO7Lite.BRAND_JCB:
      case ConstantsO7Lite.BRAND_CUP:
      case ConstantsO7Lite.BRAND_ENETS:
        return true;
      default:
        return false;
    }
  }

  BarcodeType convertToBarcodeType(int format) {
    switch (format) {
      case 8:
        return BarcodeType.Codabar;
      case 1:
        return BarcodeType.Code128;
      case 2:
        return BarcodeType.Code39;
      case 4:
        return BarcodeType.Code93;
      case 32:
        return BarcodeType.CodeEAN13;
      case 64:
        return BarcodeType.CodeEAN8;
      case 128:
        return BarcodeType.CodeITF14;
      case 512:
        return BarcodeType.CodeUPCA;
      case 1024:
        return BarcodeType.CodeUPCE;
      default:
        return BarcodeType.Code128;
    }
  }

  String saleAmount() {
    if (isUserPayingOrNotPaid()) return '';
    return getSaleAmount.value;
  }

  String serviceCharge() {
    if (isUserPayingOrNotPaid()) return '';
    return getServiceChargeRate.value;
  }

  String getTermialID() {
    if (isUserPayingOrNotPaid()) return '';
    return SharedPrefManager.terminalID;
  }

  String getTxnAmount() {
    if (isUserPayingOrNotPaid()) return '';
    return textTransactionAmount.value;
  }

  String getItemDescription() {
    if (isUserPayingOrNotPaid()) return '';
    return resultReceiptInfoData.value?.remarks ?? '';
  }

  String getTransactionID() {
    if (isUserPayingOrNotPaid()) return '';
    return mTransactionId.value;
  }

  String getPaymentType() {
    if (StorageService.isGw3) {
      return resultReceiptInfoData.value?.brandName ?? '';
    }

    switch (resultReceiptInfoData.value?.brandName) {
      case ConstantsO7Lite.BRAND_ALIPAY:
      case ConstantsO7Lite.BRAND_ALIPAY_NEW:
        return "Alipay";
      case ConstantsO7Lite.BRAND_WECHAT:
      case ConstantsO7Lite.BRAND_WECHAT_NEW:
        return "WeChatPay";

      case ConstantsO7Lite.BRAND_QUICKPASS:
        return "Alternative Payment Method";

      case ConstantsO7Lite.BRAND_GRABPAY:
      case ConstantsO7Lite.BRAND_GRABPAY2:
      case ConstantsO7Lite.BRAND_GRABPAY3:
        return "GrabPay";

      case ConstantsO7Lite.BRAND_ATOME:
        return "Atome";

      case ConstantsO7Lite.BRAND_BOOST:
        return "Boost";

      case ConstantsO7Lite.BRAND_TNG:
        return "TouchNGo";

      case ConstantsO7Lite.BRAND_SHOPEE:
        return "Shopee";

      case ConstantsO7Lite.BRAND_TOUCH_N_GO_DUITNOW_QR:
        return "TouchNGo";

      case ConstantsO7Lite.BRAND_DASH:
        return "Singtel Dash";
      case ConstantsO7Lite.BRAND_AMEX:
        return "Amex";
      case ConstantsO7Lite.BRAND_DINERS:
        return "Diners";
      case ConstantsO7Lite.BRAND_DISCOVER:
        return "Discover";

      case ConstantsO7Lite.BRAND_VISA:
        return "Visa";
      case ConstantsO7Lite.BRAND_MASTERCARD:
        return "Mastercard";

      case ConstantsO7Lite.BRAND_PAYNOW2:
      case ConstantsO7Lite.BRAND_PAYNOW:
        return "PayNow";

      default:
        return "Unknown";
    }
  }

  Future<pw.Document> _generatePdf(
      BuildContext context, GlobalKey key, List<String> emails) async {
    EasyLoading.show(
      status: CommonConstants.processingStatus.tr,
    );

    Uint8List imageData = await BytesUtil.capturePng(key);
    pw.Image receiptImage = pw.Image(pw.MemoryImage(imageData));

    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Center(
            child: pw.Container(
              alignment: pw.Alignment.center,
              child: receiptImage,
            ),
          );
        },
      ),
    );

    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/receipt_detail.pdf');
    await file.writeAsBytes(await pdf.save());

    // check if the file is created or not and open it in the pdf viewer if it is created
    if (await file.exists()) {
      // Open the PDF document in mobile
      LogUtils.debugLog('File is created ${file.path}');
      // CustomDialog.showToast(
      //   'File is created ${file.path}',
      // );

      var emailTo = emails.join(',');

      var isEnableCCEmail =
          await SharedPrefManager.instance.getBool('isEnableEmailCC') ?? false;
      var emailCC = null;
      if (isEnableCCEmail) {
        emailCC = await SecureSharedPreferences.instance.getEmailCC() ?? null;
      }

      var hasSuccess = transactionState.value == TransactionState.STATE_SUCCESS;

      var transactionType = textTransactionType.value;
      if (messageTransactionState.value == CommonConstants.voided.tr) {
        transactionType = CommonConstants.voidText.tr;
      }

      var paymentDate = StringUtils.formatResponeDateTimeToString(
          setTextTransactionTime(), StringUtils.dateFormatddMMyyyyHHMMss);
      var amount = StringUtils.formatAmount(
          double.parse(StringUtils.toDollars(
              resultReceiptInfoData.value?.totalAmount ?? '')),
          "#,##0.00");
      var currency = mCurrency.value;
      var paymentMethod = getPaymentType();
      var merchantName =
          await SecureSharedPreferences.instance.getMerchantShorName() ??
              'Oxygen7';

      var sendEmailRequest = SendEmailRequest(
        invoiceFilePath: file.path,
        emailTo: emailTo,
        emailCc: emailCC,
        mcpTerminalId: SharedPrefManager.terminalID,
        merchantName: merchantName,
        transactionId: getTransactionID(),
        paymentStatus: hasSuccess ? 'Success' : 'Success',
        transactionType: transactionType,
        paymentDate: paymentDate,
        paymentMethod: paymentMethod,
        paymentAmount: amount,
        paymentCurrency: currency,
      );

      onSendPDF2Email(sendEmailRequest);
    } else {
      EasyLoading.dismiss();
    }
    return pdf;
  }

  Future<void> onSendPDF2Email(
    SendEmailRequest sendEmailRequest,
  ) async {
    var result = await apiRepository.sendEmailReceipt(
      sendEmailRequest,
    );

    EasyLoading.dismiss();
    if (result) {
      CustomDialog.showCustomDialog(
        titleButton: CommonConstants.ok.tr,
        content: CommonConstants.msgEmailReceiptSent.tr,
        context: Get.context!,
        onPressedCheck: () {
          Get.back();
        },
        dialogType: AppDialogType.success,
        isCheckIconPng: true,
      );
    }
  }
}
