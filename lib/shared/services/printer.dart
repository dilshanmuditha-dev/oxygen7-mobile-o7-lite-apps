// ignore_for_file: use_build_context_synchronously, unnecessary_import, depend_on_referenced_packages, unused_local_variable, empty_catches

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show compute;
import 'package:app/models/response/transaction_summary_AFG_response/transaction_summary_AFG_response.dart';
import 'package:app/shared/constants/constants_o7lite.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/services/castle_report_print_monitor.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:sunmi_printer_plus/column_maker.dart';
import 'package:sunmi_printer_plus/enums.dart';
import 'package:sunmi_printer_plus/sunmi_printer_plus.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

import '../utils/bytes_util.dart';
import '../utils/log_utils.dart';
import '../widgets/custom_dialog/custom_dialog.dart';

class Printer {
  /// Timeout for native MethodChannel print calls to prevent indefinite hangs.
  static const Duration _nativePrintTimeout = Duration(seconds: 30);

  Map<String, String> printerImages = {
    'DASH': 'assets/images/dash.jpg',
    'GRAB': 'assets/images/grabpay.png',
    'PAYNOW': 'assets/images/paynow - receipt.png',
    'WECHAT': 'assets/images/weChatPay.png'
  };

  Future<void> getBluetooth(Map snapshot) async {
    final myString =
        snapshot['terminal']['merchant']['business_entity']['address_1'];

    final regexp = RegExp(r'^(.*),\s+(Singapore\s+\d+)');

    final match = regexp.firstMatch(myString);

    final address = match?.group(1);
    final postalCode = match?.group(2);

    var dateTime = DateFormat("yyyy-MM-ddTHH:mm:ss")
        .parse(snapshot['transaction_datetime'], true);
    String dateLocal = dateTime.toLocal().toString();
    dateLocal = dateLocal.substring(0, dateLocal.length - 4);

    final bool? result = await SunmiPrinter.bindingPrinter();
    LogUtils.debugLog(result);
    SunmiPrinter.paperSize().then((int size) {
      LogUtils.debugLog(size);
    });

    SunmiPrinter.printerVersion().then((String version) {
      LogUtils.debugLog(version);
    });

    SunmiPrinter.serialNumber().then((String serial) {
      LogUtils.debugLog(serial);
    });
    final List<int> escPos = await getTicket(snapshot);
    await SunmiPrinter.initPrinter();
    await SunmiPrinter.startTransactionPrint(true);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    Uint8List byte1 = await _getImageFromAsset(
        ImageConstant.oxygen7IconTransparentBackground);
    await SunmiPrinter.printImage(byte1);
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.setFontSize(SunmiFontSize.XL);
    await SunmiPrinter.printText(snapshot['terminal']['merchant']['name']);
    await SunmiPrinter.resetFontSize();
    await SunmiPrinter.printText(address ?? "");
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    await SunmiPrinter.printText(postalCode ?? "");

    await SunmiPrinter.line();
    await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
    // Uint8List byte = await _getImageFromAsset(printerImages[
    //         snapshot['payment_brand']['name'].toString().toUpperCase()] ??
    //     '');
    Uint8List byte = await _getImageFromAsset(
      getPaymentPicture(
        snapshot['payment_brand']['name'].toString(),
      ),
    );
    await SunmiPrinter.printImage(byte);
    await SunmiPrinter.lineWrap(1);
    await SunmiPrinter.printRow(
      cols: [
        ColumnMaker(text: 'Receipt:', width: 8, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: snapshot['receipt_number'],
            width: 22,
            align: SunmiPrintAlign.RIGHT),
      ],
    );
    await SunmiPrinter.line();

    await SunmiPrinter.printRow(cols: [
      ColumnMaker(
          text: snapshot['transaction_type']['transaction_type'],
          width: 8,
          align: SunmiPrintAlign.LEFT),
      ColumnMaker(
          text: snapshot['transaction_state'] != null
              ? snapshot['transaction_state']['transaction_state']
              : '',
          width: 22,
          align: SunmiPrintAlign.RIGHT),
    ]);
    await SunmiPrinter.printRow(cols: [
      ColumnMaker(text: 'Date', width: 8, align: SunmiPrintAlign.LEFT),
      ColumnMaker(
          text: dateLocal.toString(), width: 22, align: SunmiPrintAlign.RIGHT),
    ]);
    if (double.parse(snapshot['fx_rate']) != 1) {
      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Base Amt', width: 8, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: snapshot['base_currency'] + ' ' + snapshot['base_amount'],
            width: 22,
            align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'FX rate', width: 8, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: snapshot['fx_rate'], width: 22, align: SunmiPrintAlign.RIGHT),
      ]);
      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Txn Amt', width: 8, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: snapshot['transaction_amount'] != null
                ? snapshot['transaction_currency'] +
                    ' ' +
                    snapshot['transaction_amount']
                : ' ',
            width: 22,
            align: SunmiPrintAlign.RIGHT),
      ]);
    } else {
      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Base Amt', width: 8, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: snapshot['base_currency'] + ' ' + snapshot['base_amount'],
            width: 22,
            align: SunmiPrintAlign.RIGHT),
      ]);
    }

    await SunmiPrinter.printRow(cols: [
      ColumnMaker(text: 'TID', width: 8, align: SunmiPrintAlign.LEFT),
      ColumnMaker(
          text: snapshot['terminal']['terminal_id'] ?? '',
          width: 22,
          align: SunmiPrintAlign.RIGHT),
    ]);

    await SunmiPrinter.printRawData(Uint8List.fromList(escPos));

    // await SunmiPrinter.printText(snapshot['host_transaction_id'] ?? '');

    await SunmiPrinter.printRow(cols: [
      // ColumnMaker(text: 'Txn Id', width: 8, align: SunmiPrintAlign.LEFT),
      ColumnMaker(
          text: snapshot['host_transaction_id'] ?? '',
          width: 30,
          align: SunmiPrintAlign.CENTER),
    ]);

    await SunmiPrinter.lineWrap(4);
    await SunmiPrinter.exitTransactionPrint(true);
  }

  Future<Uint8List> readFileBytes(String path) async {
    ByteData fileData = await rootBundle.load(path);
    Uint8List fileUnit8List = fileData.buffer
        .asUint8List(fileData.offsetInBytes, fileData.lengthInBytes);
    return fileUnit8List;
  }

  Future<Uint8List> _getImageFromAsset(String iconPath) async {
    return await readFileBytes(iconPath);
  }

  Future<List<int>> getTicket(Map snapshot) async {
    List<int> bytes = [];

    CapabilityProfile profile = await CapabilityProfile.load();
    final profiles = await CapabilityProfile.getAvailableProfiles();
    LogUtils.debugLog(profiles);
    final generator = Generator(PaperSize.mm58, profile);
    bytes += generator.setGlobalCodeTable('CP1252');

    bytes += generator.hr(ch: '=', linesAfter: 1);

    bytes += generator.qrcode(snapshot['receipt_number'], size: QRSize.Size8);

    // generator.feed(2);
    // bytes += generator.cut();

    return bytes;
  }

  static Future<void> print(
      BuildContext context, bool isMerchantCopy, GlobalKey key) async {
    EasyLoading.show(status: 'printerImagePrintingStarted'.tr);

    try {
      Uint8List imageData = await BytesUtil.capturePng(key);

      // Dynamically get printer paper width in dots
      int paperWidthDots = await _getSunmiPaperWidthDots();

      // Resize high-res capture to fit printer paper width
      Uint8List printData = await _resizeForPrinter(imageData, paperWidthDots);

      bool? isBluetoothConnected = await SunmiPrinter.bindingPrinter()
          .timeout(const Duration(seconds: 10), onTimeout: () => null);

      await SunmiPrinter.initPrinter();
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      if (isBluetoothConnected == null) {
        EasyLoading.dismiss();
        CustomDialog.showToast(
          'printerBluetoothConnectionNull'.tr,
        );
        return;
      }
      if (isBluetoothConnected) {
        await SunmiPrinter.startTransactionPrint(true);
        await SunmiPrinter.printImage(printData);
        await SunmiPrinter.lineWrap(5);
        await SunmiPrinter.exitTransactionPrint(true);
      }
      EasyLoading.dismiss();
    } catch (e) {
      EasyLoading.dismiss();
      LogUtils.debugLog('Printer.print error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'printerExceptionOccurred'.tr,
          ),
        ),
      );
    }
  }

  /// Get Sunmi printer paper width in dots based on paper size.
  /// paperSize() returns 0 = 80mm (576 dots), 1 = 58mm (384 dots).
  static Future<int> _getSunmiPaperWidthDots() async {
    try {
      int paperSize = await SunmiPrinter.paperSize();
      return paperSize == 0 ? 576 : 384;
    } catch (_) {
      return 384; // Default to 58mm
    }
  }

  /// Resize a high-res PNG image to fit the printer paper width
  /// while maintaining aspect ratio. Downscaling from a 3x capture
  /// produces sharper output than printing a low-res 1x capture.
  static Future<Uint8List> _resizeForPrinter(
      Uint8List imageData, int targetWidth) {
    return compute(
        _resizeForPrinterIsolate, _ResizeParams(imageData, targetWidth));
  }

  // By using sunmi printer plus (https://pub.dev/packages/sunmi_printer_plus)
  static Future<void> printReceiptDetail(
    BuildContext context,
    GlobalKey keyFullBitMap,
    GlobalKey keyLogoBitMap,
    String stringCompany,
    String address1,
    String address2,
    String address3,
    String address4,
    String txnState1,
    String txnState2,
    String txnTime,
    String txnDescription,
    String txnTotal,
    String terminalID,
    String txnID,
    GlobalKey keyBarcode,
  ) async {
    CustomDialog.showToast(
      'printerImagePrintingStarted'.tr,
    );

    try {
      bool? isBluetoothConnected = await SunmiPrinter.bindingPrinter();
      if (isBluetoothConnected == null) {
        CustomDialog.showToast(
          'printerBluetoothConnectionNull'.tr,
        );
        return;
      }

      Uint8List fullBitMap = await BytesUtil.capturePng(keyFullBitMap);
      Uint8List logoBitMap = await BytesUtil.capturePng(keyLogoBitMap);
      Uint8List bitmapBarCode = await BytesUtil.capturePng(keyBarcode);

      // Start printing data
      await SunmiPrinter.initPrinter();

      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printImage(logoBitMap);
      await SunmiPrinter.lineWrap(1);

      // print company name
      await SunmiPrinter.setFontSize(SunmiFontSize.XL);
      await SunmiPrinter.printText(stringCompany);
      await SunmiPrinter.resetFontSize();

      // print address
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.printText(address1 ?? '-');
      await SunmiPrinter.printText(address2 ?? '-');
      await SunmiPrinter.printText(address3 ?? '-');
      await SunmiPrinter.printText(address4 ?? '-');

      await SunmiPrinter.startTransactionPrint(true);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.line();

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Refund', width: 12, align: SunmiPrintAlign.LEFT),
        // ColumnMaker(text: '', width: 6, align: SunmiPrintAlign.CENTER),
        // ColumnMaker(text: '', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(text: 'Success', width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Time', width: 12, align: SunmiPrintAlign.LEFT),
        // ColumnMaker(text: '', width: 6, align: SunmiPrintAlign.CENTER),
        // ColumnMaker(text: '', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(text: txnTime, width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(
            text: 'Item description', width: 12, align: SunmiPrintAlign.LEFT),
        // ColumnMaker(text: '', width: 6, align: SunmiPrintAlign.CENTER),
        // ColumnMaker(text: '', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(
            text: txnDescription, width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      // this is sample code

      await SunmiPrinter.startTransactionPrint(true);
      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      // await SunmiPrinter.line();
      // await SunmiPrinter.printText('Payment receipt');
      // await SunmiPrinter.printText('Using the old way to bold!');
      // await SunmiPrinter.line();

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Name', width: 12, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: 'Qty', width: 6, align: SunmiPrintAlign.CENTER),
        ColumnMaker(text: 'UN', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(text: 'TOT', width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Fries', width: 12, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: '4x', width: 6, align: SunmiPrintAlign.CENTER),
        ColumnMaker(text: '3.00', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(text: '12.00', width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Strawberry', width: 12, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: '1x', width: 6, align: SunmiPrintAlign.CENTER),
        ColumnMaker(text: '24.44', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(text: '24.44', width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'Soda', width: 12, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: '1x', width: 6, align: SunmiPrintAlign.CENTER),
        ColumnMaker(text: '1.99', width: 6, align: SunmiPrintAlign.RIGHT),
        ColumnMaker(text: '1.99', width: 6, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.line();
      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: 'TOTAL', width: 25, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: '38.43', width: 5, align: SunmiPrintAlign.RIGHT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(
            text: 'ARABIC TEXT', width: 15, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: 'اسم المشترك', width: 15, align: SunmiPrintAlign.LEFT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(
            text: 'اسم المشترك', width: 15, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: 'اسم المشترك', width: 15, align: SunmiPrintAlign.LEFT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(
            text: 'RUSSIAN TEXT', width: 15, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: 'Санкт-Петербу́рг', width: 15, align: SunmiPrintAlign.LEFT),
      ]);
      await SunmiPrinter.printRow(cols: [
        ColumnMaker(
            text: 'Санкт-Петербу́рг', width: 15, align: SunmiPrintAlign.LEFT),
        ColumnMaker(
            text: 'Санкт-Петербу́рг', width: 15, align: SunmiPrintAlign.LEFT),
      ]);

      await SunmiPrinter.printRow(cols: [
        ColumnMaker(
            text: 'CHINESE TEXT', width: 15, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: '風俗通義', width: 15, align: SunmiPrintAlign.LEFT),
      ]);
      await SunmiPrinter.printRow(cols: [
        ColumnMaker(text: '風俗通義', width: 15, align: SunmiPrintAlign.LEFT),
        ColumnMaker(text: '風俗通義', width: 15, align: SunmiPrintAlign.LEFT),
      ]);

      await SunmiPrinter.setAlignment(SunmiPrintAlign.CENTER);
      await SunmiPrinter.line();
      await SunmiPrinter.bold();
      await SunmiPrinter.printText('printerTransactionQrcode'.tr);
      await SunmiPrinter.resetBold();
      await SunmiPrinter.printQRCode(
          'https://github.com/brasizza/sunmi_printer');
      await SunmiPrinter.lineWrap(2);
      await SunmiPrinter.exitTransactionPrint(true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('printerExceptionOccurred'.tr)),
      );
    }
  }

  static Future<void> printCastleReceipt(
    BuildContext context,
    GlobalKey keyFullBitMap,
    GlobalKey keyLogoBitMap,
    String stringCompany,
    String address1,
    String address2,
    String address3,
    String address4,
    String txnState1,
    String txnState2,
    String txnTime,
    String txnDescription,
    String txnTotal,
    String terminalID,
    String txnID,
    GlobalKey keyBarcode,
    String brandName,
  ) async {
    const channel = MethodChannel(AppChannel.CHANNEL_CASTLE);
    try {
      CustomDialog.showToast(
        'printerReceiptPrintingStarted'.tr,
      );

      LogUtils.debugLog("printCastleReceipt: Capturing bitmaps...");
      Uint8List fullBitMap = await BytesUtil.capturePng(keyFullBitMap);
      Uint8List logoBitMap = await BytesUtil.capturePng(keyLogoBitMap);
      Uint8List bitmapBarCode = await BytesUtil.capturePng(keyBarcode);

      LogUtils.debugLog(
          "printCastleReceipt: fullBitMap size: ${fullBitMap.length}");
      LogUtils.debugLog(
          "printCastleReceipt: logoBitMap size: ${logoBitMap.length}");
      LogUtils.debugLog(
          "printCastleReceipt: bitmapBarCode size: ${bitmapBarCode.length}");

      final Map<String, dynamic> arguments = {
        'fullBitMap': fullBitMap,
        'logoBitMap': logoBitMap,
        'stringCompany': stringCompany,
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'address4': address4,
        'txnState1': txnState1,
        'txnState2': txnState2,
        'txnTime': txnTime,
        'txnDescription': txnDescription,
        'txnTotal': txnTotal,
        'terminalID': terminalID,
        'txnID': txnID,
        'bitmapBarCode': bitmapBarCode,
        'brandName': brandName,
      };

      LogUtils.debugLog(
          "printCastleReceipt: Invoking method channel 'printCastleReceiptManual'...");
      CustomDialog.showToast('printerCallingNativePrint'.tr);

      final result = await channel
          .invokeMethod('printCastleReceiptManual', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () => 'TIMEOUT');

      LogUtils.debugLog("printCastleReceipt: Result = $result");
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      } else {
        CustomDialog.showToast(
            'printerPrintResult'.trParams({'result': '$result'}));
      }
    } catch (e, stackTrace) {
      LogUtils.debugLog("printCastleReceipt ERROR: $e");
      LogUtils.debugLog("printCastleReceipt STACK: $stackTrace");
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printANFUReceipt(
    BuildContext context,
    GlobalKey keyFullBitMap,
    GlobalKey keyLogoBitMap,
    String stringCompany,
    String address1,
    String address2,
    String address3,
    String address4,
    String txnState1,
    String txnState2,
    String txnTime,
    String txnDescription,
    String txnTotal,
    String terminalID,
    String txnID,
    GlobalKey keyBarcode,
    String brandName,
  ) async {
    const channel = MethodChannel(AppChannel.CHANNEL_ANFU);
    try {
      CustomDialog.showToast(
        'printerImagePrintingStarted'.tr,
      );
      Uint8List fullBitMap = await BytesUtil.capturePng(keyFullBitMap);
      Uint8List logoBitMap = await BytesUtil.capturePng(keyLogoBitMap);
      Uint8List bitmapBarCode = await BytesUtil.capturePng(keyBarcode);
      final Map<String, dynamic> arguments = {
        'fullBitMap': fullBitMap,
        'logoBitMap': logoBitMap,
        'stringCompany': stringCompany,
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'address4': address4,
        'txnState1': txnState1,
        'txnState2': txnState2,
        'txnTime': txnTime,
        'txnDescription': txnDescription,
        'txnTotal': txnTotal,
        'terminalID': terminalID,
        'txnID': txnID,
        'bitmapBarCode': bitmapBarCode,
        'brandName': brandName,
      };
      final String result = await channel
          .invokeMethod('printAnfuReceiptManual', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () => 'TIMEOUT');
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      }
    } catch (e) {
      LogUtils.debugLog('printANFUReceipt error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printWizarPosReceipt(
    BuildContext context,
    GlobalKey keyFullBitMap,
    GlobalKey keyLogoBitMap,
    String stringCompany,
    String address1,
    String address2,
    String address3,
    String address4,
    String txnState1,
    String txnState2,
    String txnTime,
    String txnDescription,
    String txnTotal,
    String terminalID,
    String txnID,
    GlobalKey keyBarcode,
    String brandName,
  ) async {
    const channel = MethodChannel(AppChannel.CHANNEL_WIZAR_POS);
    try {
      CustomDialog.showToast(
        'printerImagePrintingStarted'.tr,
      );
      Uint8List fullBitMap = await BytesUtil.capturePng(keyFullBitMap);
      Uint8List logoBitMap = await BytesUtil.capturePng(keyLogoBitMap);
      Uint8List bitmapBarCode = await BytesUtil.capturePng(keyBarcode);
      final Map<String, dynamic> arguments = {
        'fullBitMap': fullBitMap,
        'logoBitMap': logoBitMap,
        'stringCompany': stringCompany,
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'address4': address4,
        'txnState1': txnState1,
        'txnState2': txnState2,
        'txnTime': txnTime,
        'txnDescription': txnDescription,
        'txnTotal': txnTotal,
        'terminalID': terminalID,
        'txnID': txnID,
        'bitmapBarCode': bitmapBarCode,
        'brandName': brandName,
      };
      final String result = await channel
          .invokeMethod('printWizarPosReceiptManual', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () => 'TIMEOUT');
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      }
    } catch (e) {
      LogUtils.debugLog('printWizarPosReceipt error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printCoherentReceipt(
    BuildContext context,
    GlobalKey keyFullBitMap,
    GlobalKey keyLogoBitMap,
    String stringCompany,
    String address1,
    String address2,
    String address3,
    String address4,
    String txnState1,
    String txnState2,
    String txnTime,
    String txnDescription,
    String txnTotal,
    String terminalID,
    String txnID,
    GlobalKey keyBarcode,
    String brandName,
  ) async {
    const channel = MethodChannel(AppChannel.CHANNEL_COHERENT);
    try {
      CustomDialog.showToast(
        'printerImagePrintingStarted'.tr,
      );
      Uint8List fullBitMap = await BytesUtil.capturePng(keyFullBitMap);
      Uint8List logoBitMap = await BytesUtil.capturePng(keyLogoBitMap);
      Uint8List bitmapBarCode = await BytesUtil.capturePng(keyBarcode);
      final Map<String, dynamic> arguments = {
        'fullBitMap': fullBitMap,
        'logoBitMap': logoBitMap,
        'stringCompany': stringCompany,
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'address4': address4,
        'txnState1': txnState1,
        'txnState2': txnState2,
        'txnTime': txnTime,
        'txnDescription': txnDescription,
        'txnTotal': txnTotal,
        'terminalID': terminalID,
        'txnID': txnID,
        'bitmapBarCode': bitmapBarCode,
        'brandName': brandName,
      };
      final String result = await channel
          .invokeMethod('printCoherentReceiptManual', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () => 'TIMEOUT');
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      }
    } catch (e) {
      LogUtils.debugLog('printCoherentReceipt error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  /// Print a receipt on a Morefun POS device.
  ///
  /// Morefun's YSDK prints a single bitmap via `MultipleAppPrinter.printImage`,
  /// so we capture the already-designed Flutter print layout (correct payment
  /// logo, centered content, defined width) and send that bitmap. The native
  /// side scales it to the printer head width. This avoids re-rendering a native
  /// layout (which lost the logo and printed narrow/left-aligned).
  static Future<void> printMorefunReceipt(
    BuildContext context,
    GlobalKey receiptKey,
  ) async {
    const channel = MethodChannel(AppChannel.CHANNEL_MOREFUN);
    try {
      CustomDialog.showToast(
        'printerImagePrintingStarted'.tr,
      );
      Uint8List receiptBitmap = await BytesUtil.capturePng(receiptKey);
      final Map<String, dynamic> arguments = {
        'bitmap': receiptBitmap,
      };
      final result = await channel
          .invokeMethod('printMorefunReceiptManual', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () => 'TIMEOUT');
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      }
    } catch (e) {
      LogUtils.debugLog('printMorefunReceipt error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printLandiReceipt(
    BuildContext context,
    GlobalKey keyFullBitMap,
    GlobalKey keyLogoBitMap,
    String stringCompany,
    String address1,
    String address2,
    String address3,
    String address4,
    String txnState1,
    String txnState2,
    String txnTime,
    String txnDescription,
    String txnTotal,
    String terminalID,
    String txnID,
    GlobalKey keyBarcode,
    String brandName,
  ) async {
    const channel = MethodChannel(AppChannel.CHANNEL_LANDI);
    try {
      CustomDialog.showToast(
        'printerImagePrintingStarted'.tr,
      );
      Uint8List fullBitMap = await BytesUtil.capturePng(keyFullBitMap);
      Uint8List logoBitMap = await BytesUtil.capturePng(keyLogoBitMap);
      Uint8List bitmapBarCode = await BytesUtil.capturePng(keyBarcode);

      final Map<String, dynamic> arguments = {
        'fullBitMap': fullBitMap,
        'logoBitMap': logoBitMap,
        'stringCompany': stringCompany,
        'address1': address1,
        'address2': address2,
        'address3': address3,
        'address4': address4,
        'txnState1': txnState1,
        'txnState2': txnState2,
        'txnTime': txnTime,
        'txnDescription': txnDescription,
        'txnTotal': txnTotal,
        'terminalID': terminalID,
        'txnID': txnID,
        'bitmapBarCode': bitmapBarCode,
        'brandName': brandName,
      };
      final String result = await channel
          .invokeMethod('printLandiReceiptManual', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () => 'TIMEOUT');
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      }
    } catch (e) {
      LogUtils.debugLog('printLandiReceipt error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  // static Future<void> printCastle(BuildContext context, GlobalKey key) async {
  //   const channel = MethodChannel(AppChannel.CHANNEL_CASTLE);
  //   try {
  //     CustomDialog.showToast(
  //       "Image Printing Started",
  //     );
  //     Uint8List imageData = await BytesUtil.capturePng(key);
  //     double scaleWidth = 1.12;
  //     double scaleHeight = 1.22;
  //     Uint8List scaledImageData =
  //         scaleUpImage(imageData, scaleWidth, scaleHeight);
  //     final Map<String, dynamic> arguments = {
  //       'bitmap': scaledImageData,
  //     };
  //     await channel.invokeMethod('printCastle', arguments);
  //   } catch (e) {}
  // }

  static Future<void> printCastleSummaryReport(
      BuildContext context,
      String brand,
      String acquirer,
      String currency,
      String startDate,
      String endDate,
      String mcpTerminalId,
      String? signature,
      TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_CASTLE);
    final monitor = CastleReportPrintMonitor.instance;
    try {
      monitor.addStep('Flutter', 'Preparing Castle summary arguments');
      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      final Map<String, dynamic> arguments = buildCastleSummaryReportArguments(
        brand: brand,
        acquirer: acquirer,
        currency: currency,
        startDate: startDate,
        endDate: endDate,
        mcpTerminalId: mcpTerminalId,
        signature: signature,
        dataSource: dataSource,
      );

      monitor.addStep(
        'Flutter',
        'Invoking printCastleSummary via ${AppChannel.CHANNEL_CASTLE}',
      );
      final result = await channel
          .invokeMethod('printCastleSummary', arguments)
          .timeout(_nativePrintTimeout);
      monitor.addSuccess('Flutter', 'Native channel returned: $result');
    } catch (e) {
      LogUtils.debugLog('printCastleSummaryReport error: $e');
      monitor.addError('Flutter', 'Castle summary print error: $e');
      monitor.finish(success: false, message: 'Flutter/native channel failed');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Map<String, dynamic> buildCastleSummaryReportArguments({
    required String brand,
    required String acquirer,
    required String currency,
    required String startDate,
    required String endDate,
    required String mcpTerminalId,
    required String? signature,
    required TransactionSummaryAFGResponse? dataSource,
  }) {
    return {
      'brand': brand,
      'acquirer': acquirer, // acquirer is host
      'currency': currency,
      'startDate': startDate,
      'endDate': endDate,
      'mcpTerminalId': mcpTerminalId,
      'signature': signature,
      'summaryData': jsonEncode(dataSource?.toJson()),
    };
  }

  static Future<void> printAnfuSummaryReport(BuildContext context,
      String acquirer, TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_ANFU);
    try {
      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      var summaryData = jsonEncode(dataSource?.toJson());

      final Map<String, dynamic> arguments = {
        'acquirer': acquirer,
        'summaryData': summaryData,
      };

      await channel
          .invokeMethod('printAnfuSummary', arguments)
          .timeout(_nativePrintTimeout);
    } catch (e) {
      LogUtils.debugLog('printAnfuSummaryReport error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printSunmiSummaryReport(BuildContext context,
      String acquirer, TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_SUNMI);
    try {
      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      var summaryData = jsonEncode(dataSource?.toJson());

      final Map<String, dynamic> arguments = {
        'acquirer': acquirer,
        'summaryData': summaryData,
      };

      await channel
          .invokeMethod('printSunmiSummary', arguments)
          .timeout(_nativePrintTimeout);
    } catch (e) {
      LogUtils.debugLog('printSunmiSummaryReport error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printLandiSummaryReport(BuildContext context,
      String acquirer, TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_LANDI);
    try {
      LogUtils.debugLog('LANDI_SUMMARY: printLandiSummaryReport() called');
      LogUtils.debugLog(
          'LANDI_SUMMARY: acquirer=$acquirer, dataSource isNull=${dataSource == null}');

      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      var summaryData = jsonEncode(dataSource?.toJson());
      LogUtils.debugLog(
          'LANDI_SUMMARY: summaryData JSON length=${summaryData.length}');
      LogUtils.debugLog(
          'LANDI_SUMMARY: summaryData preview=${summaryData.length > 500 ? summaryData.substring(0, 500) : summaryData}');

      final Map<String, dynamic> arguments = {
        'acquirer': acquirer,
        'summaryData': summaryData,
      };

      LogUtils.debugLog(
          'LANDI_SUMMARY: Invoking method channel "printLandiSummary" on ${AppChannel.CHANNEL_LANDI}');

      final result = await channel
          .invokeMethod('printLandiSummary', arguments)
          .timeout(_nativePrintTimeout, onTimeout: () {
        LogUtils.debugLog(
            'LANDI_SUMMARY: Method channel TIMEOUT after ${_nativePrintTimeout.inSeconds}s');
        return 'TIMEOUT';
      });

      LogUtils.debugLog('LANDI_SUMMARY: Method channel result=$result');
      if (result == 'TIMEOUT') {
        CustomDialog.showToast('printerPrintTimeout'.tr);
      }
    } catch (e, stackTrace) {
      LogUtils.debugLog('LANDI_SUMMARY: ERROR in printLandiSummaryReport: $e');
      LogUtils.debugLog('LANDI_SUMMARY: STACK: $stackTrace');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printWizarPosSummaryReport(BuildContext context,
      String acquirer, TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_WIZAR_POS);
    try {
      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      var summaryData = jsonEncode(dataSource?.toJson());

      final Map<String, dynamic> arguments = {
        'acquirer': acquirer,
        'summaryData': summaryData,
      };

      await channel
          .invokeMethod('printWizarPosSummary', arguments)
          .timeout(_nativePrintTimeout);
    } catch (e) {
      LogUtils.debugLog('printWizarPosSummaryReport error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printCoherentSummaryReport(BuildContext context,
      String acquirer, TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_COHERENT);
    try {
      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      var summaryData = jsonEncode(dataSource?.toJson());

      final Map<String, dynamic> arguments = {
        'acquirer': acquirer,
        'summaryData': summaryData,
      };

      await channel
          .invokeMethod('printCoherentSummary', arguments)
          .timeout(_nativePrintTimeout);
    } catch (e) {
      LogUtils.debugLog('printCoherentSummaryReport error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<void> printMorefunSummaryReport(BuildContext context,
      String acquirer, TransactionSummaryAFGResponse? dataSource) async {
    const channel = MethodChannel(AppChannel.CHANNEL_MOREFUN);
    try {
      CustomDialog.showToast(
        'printerReportPrintingStarted'.tr,
      );

      var summaryData = jsonEncode(dataSource?.toJson());

      final Map<String, dynamic> arguments = {
        'acquirer': acquirer,
        'summaryData': summaryData,
      };

      await channel
          .invokeMethod('printMorefunSummary', arguments)
          .timeout(_nativePrintTimeout);
    } catch (e) {
      LogUtils.debugLog('printMorefunSummaryReport error: $e');
      CustomDialog.showToast('printerPrintError'.trParams({'error': '$e'}));
    }
  }

  static Future<bool> isCastleDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.brand.toLowerCase().contains('castles');
  }

  /// Returns true if running on a regular mobile device (not a POS terminal)
  /// Returns false if running on POS devices (Sunmi, Castle, Anfu, Landi, WizarPos, Coherent)
  static Future<bool> isMobileUser() async {
    bool isSunmi = await isSunmiDevice();
    bool isCastle = await isCastleDevice();
    bool isAnfu = await isAnfuDevice();
    bool isLandi = await isLandiDevice();
    bool isWizarPos = await isWizarPosDevice();
    bool isCoherent = await isCoherentDevice();
    bool isMorefun = await isMorefunDevice();

    if (!isSunmi &&
        !isCastle &&
        !isAnfu &&
        !isLandi &&
        !isWizarPos &&
        !isCoherent &&
        !isMorefun) {
      return true;
    }

    return false;
  }

  /// This function is using to check the connection with printer.
  static Future<bool?> isConnectedPrinter() async {
    bool isSunmi = await isSunmiDevice();
    bool isCastle = await isCastleDevice();
    bool isAnfu = await isAnfuDevice();
    bool isLandi = await isLandiDevice();
    bool isWizarPos = await isWizarPosDevice();
    bool isCoherent = await isCoherentDevice();
    bool isMorefun = await isMorefunDevice();

    if (isSunmi) {
      return await SunmiPrinter.bindingPrinter();
    }

    if (isCastle) {
      // todo - using method channel to check binding connection from castle SDK
      return false;
    }

    if (isAnfu) {
      // todo - using method channel to check binding connection from ANFU SDK
      return false;
    }

    if (isLandi) {
      return await _isLandiPrinterConnected();
    }

    if (isWizarPos) {
      // todo - using method channel to check binding connection from WizarPos SDK
      return false;
    }

    if (isCoherent) {
      return await _isCoherentPrinterConnected();
    }

    if (isMorefun) {
      return await _isMorefunPrinterConnected();
    }

    return false;
  }

  /// This function is using to check the connection with printer.
  static Future<bool?> isPrinter() async {
    bool isSunmi = await isSunmiDevice();
    bool isCastle = await isCastleDevice();
    bool isAnfu = await isAnfuDevice();
    bool isLandi = await isLandiDevice();
    bool isWizarPos = await isWizarPosDevice();
    bool isCoherent = await isCoherentDevice();
    bool isMorefun = await isMorefunDevice();

    if (isSunmi) {
      return await SunmiPrinter.bindingPrinter();
    }

    if (isCastle) {
      // todo - using method channel to check binding connection from castle SDK
      return false;
    }

    if (isAnfu) {
      // todo - using method channel to check binding connection from ANFU SDK
      return false;
    }

    if (isLandi) {
      return await _isLandiPrinterConnected();
    }

    if (isWizarPos) {
      // todo - using method channel to check binding connection from WizarPos SDK
      return false;
    }

    if (isCoherent) {
      return await _isCoherentPrinterConnected();
    }

    if (isMorefun) {
      return await _isMorefunPrinterConnected();
    }

    return false;
  }

  /// Check Coherent printer connection via method channel.
  /// Calls getPrinterState on the native side; state 0 = ready/connected.
  static Future<bool> _isCoherentPrinterConnected() async {
    const channel = MethodChannel(AppChannel.CHANNEL_COHERENT);
    try {
      final int state = await channel.invokeMethod('getPrinterState');
      return state == 0;
    } catch (e) {
      LogUtils.debugLog('Coherent printer state check failed: $e');
      return false;
    }
  }

  /// Check Landi printer connection via OmniDriver method channel.
  /// Calls getPrinterState on the native side; state 0 = ready/connected.
  static Future<bool> _isLandiPrinterConnected() async {
    const channel = MethodChannel(AppChannel.CHANNEL_LANDI);
    try {
      final int state = await channel
          .invokeMethod('getPrinterState')
          .timeout(const Duration(seconds: 5), onTimeout: () => -1);
      return state == 0;
    } catch (e) {
      LogUtils.debugLog('Landi printer state check failed: $e');
      return false;
    }
  }

  static Future<bool> isAnfuDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.brand.toLowerCase().contains('anfu');
  }

  static Future<bool> isSunmiDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.brand.toLowerCase().contains('sunmi');
  }

  static Future<bool> isLandiDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.brand.toLowerCase().contains('landi');
  }

  /**
   *  fun isWizarDevice(): Boolean {
        val deviceBrand = Build.BRAND
        return deviceBrand.contains("WIZARPOS", ignoreCase = true) ||
                deviceBrand.contains("WIZAR", ignoreCase = true) ||
                deviceBrand.contains("WIZAR POS", ignoreCase = true) ||
                deviceBrand.contains("SmartPOS", ignoreCase = true)
    }
   */

  static Future<bool> isWizarPosDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    // return androidInfo.brand.toLowerCase().contains('wizard') ||
    //     androidInfo.brand.toLowerCase().contains('wizar') ||
    //     androidInfo.brand.toLowerCase().contains('wizar pos') ||
    //     androidInfo.brand.toLowerCase().contains('smartpos');

    return androidInfo.model.toUpperCase().contains('WIZARPOS Q2');
  }

  static Future<bool> isCoherentDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.brand.toLowerCase().contains('coherent') ||
        androidInfo.brand.toLowerCase().contains('centerm') ||
        androidInfo.model.toLowerCase().contains('centerm');
  }

  static Future<bool> isMorefunDevice() async {
    if (Platform.isIOS) {
      return false;
    }

    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;

    return androidInfo.brand.toLowerCase().contains('morefun') ||
        androidInfo.manufacturer.toLowerCase().contains('morefun') ||
        androidInfo.model.toLowerCase().contains('morefun');
  }

  /// Check Morefun printer connection via YSDK method channel.
  /// Calls getPrinterState on the native side; state 0 (ServiceResult.Success)
  /// means the printer is ready/connected.
  static Future<bool> _isMorefunPrinterConnected() async {
    const channel = MethodChannel(AppChannel.CHANNEL_MOREFUN);
    try {
      final int state = await channel
          .invokeMethod('getPrinterState')
          .timeout(const Duration(seconds: 5), onTimeout: () => -1);
      return state == 0;
    } catch (e) {
      LogUtils.debugLog('Morefun printer state check failed: $e');
      return false;
    }
  }

  /// Print a self-test receipt on a Morefun device (used by the troubleshooting
  /// screen). The test bitmap is generated natively, so this has no dependency on
  /// any on-screen widget. Returns true if the print was dispatched successfully.
  static Future<bool> printMorefunTestReceipt() async {
    const channel = MethodChannel(AppChannel.CHANNEL_MOREFUN);
    try {
      final result = await channel
          .invokeMethod('printMorefunTest')
          .timeout(_nativePrintTimeout, onTimeout: () => false);
      return result == true;
    } catch (e) {
      LogUtils.debugLog('printMorefunTestReceipt error: $e');
      return false;
    }
  }

  static void showImageDialog(BuildContext context, Uint8List imageData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('printerImageDialogTitle'.tr),
          content: Image.memory(
            imageData,
            fit: BoxFit.cover,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('printerCloseBtn'.tr),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  static Uint8List scaleUpImage(
      Uint8List imageData, double scaleWidth, double scaleHeight) {
    img.Image? image = img.decodeImage(imageData);

    if (image == null) return imageData;

    int newWidth = (image.width * scaleWidth).toInt();
    int newHeight = (image.height * scaleHeight).toInt();

    img.Image resizedImage =
        img.copyResize(image, width: newWidth, height: newHeight);

    return Uint8List.fromList(img.encodePng(resizedImage));
  }

  static String getPaymentPicture(String name) {
    switch (name.toLowerCase()) {
      case "paynow":
        return "assets/images/paynow.png";
      case "grabpay":
        return "assets/images/grabpay_topup_on_grab_wallet-cb05df8413d1fff4b786f6cb2180534b.png";
      case "grab":
        return "assets/images/grabpay_topup_on_grab_wallet-cb05df8413d1fff4b786f6cb2180534b.png";
      case "duitnow":
        return "assets/images/duitnow-pic.png";
      case "duitnowqr":
        return "assets/images/duitnow-pic.png";
      case "thaiqr":
        return "assets/images/tlhaiQrPic.png";
      case "atome":
        return "assets/images/atomePic.png";
      case "dash":
        return "assets/images/singteldashPic.png";
      case "wechatpay":
        return "assets/images/wechatPic.png";
      case "alipay":
        return "assets/images/alipayPic.png";
      case "shopeepay":
        return "assets/images/shopeepayPic.png";

      default:
        return "assets/images/paynow.png";
    }
  }
}

/// Params for the isolate resize function.
class _ResizeParams {
  final Uint8List imageData;
  final int targetWidth;
  _ResizeParams(this.imageData, this.targetWidth);
}

/// Top-level function for compute() — runs in a separate isolate.
Uint8List _resizeForPrinterIsolate(_ResizeParams params) {
  img.Image? image = img.decodeImage(params.imageData);
  if (image == null) return params.imageData;

  if (image.width <= params.targetWidth) return params.imageData;

  final double ratio = params.targetWidth / image.width;
  final int targetHeight = (image.height * ratio).toInt();

  img.Image resized = img.copyResize(
    image,
    width: params.targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.average,
  );

  return Uint8List.fromList(img.encodePng(resized));
}
