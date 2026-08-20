import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';

/// A widget that intercepts back button presses while EasyLoading is shown
class LoadingNavigationHandler extends StatelessWidget {
  final Widget child;

  const LoadingNavigationHandler({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If loading is shown, dismiss it and prevent navigation
        if (EasyLoading.isShow) {
          EasyLoadingExtension.dismissWithNavHandling();
          return false; // Prevent navigation
        }
        return true; // Allow navigation
      },
      child: child,
    );
  }
}

/// Extension methods for EasyLoading to handle navigation
extension EasyLoadingExtension on EasyLoading {
  /// Shows EasyLoading with safe navigation handling
  /// This automatically prevents dismiss on tap and handles back button events
  static Future<void> showWithNavHandling({
    String? status,
    Widget? indicator,
    EasyLoadingMaskType? maskType,
    bool? dismissOnTap,
  }) async {
    await EasyLoadingExtension.showWithNavHandling(
      status: status,
      indicator: indicator,
      maskType: maskType,
      dismissOnTap:
          false, // Always prevent dismiss on tap to handle it ourselves
    );
  }

  /// Safely dismisses EasyLoading and handles any pending navigation
  static void dismissWithNavHandling() {
    if (EasyLoading.isShow) {
      EasyLoadingExtension.dismissWithNavHandling();
    }
  }
}
