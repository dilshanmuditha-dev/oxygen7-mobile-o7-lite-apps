import 'dart:io';
import 'package:app/shared/widgets/dialog_common.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkUtils {
  /// Check if internet connection is available
  static Future<bool> checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  /// Shows an error dialog when there is no internet connection
  static void showNoInternetDialog(BuildContext? context) {
    if (context != null) {
      Get.dialog(
        CustomAlertDialog(
          title:
              'No internet connection. Please check your network settings and try again.',
          onPressed: () {
            Get.back();
          },
        ),
      );
    }
  }

  /// Helper method that combines checking connection and showing dialog if needed
  /// Returns true if connected, false otherwise
  static Future<bool> hasConnection(BuildContext? context) async {
    bool isConnected = await checkInternetConnection();
    if (!isConnected && context != null) {
      showNoInternetDialog(context);
    }
    return isConnected;
  }
}
