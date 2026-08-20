import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app_controller.dart';
import '../../../shared/services/bluetooth_printer/bluetooth_printer_service.dart';
import '../../../shared/services/bluetooth_printer/models.dart';
import '../../../shared/utils/log_utils.dart';
import '../../../shared/widgets/custom_dialog/custom_dialog.dart';

/// Controller for the Bluetooth printer selection screen.
///
/// Manages UI state for scanning, connecting, and disconnecting
/// Bluetooth thermal printers. Delegates all Bluetooth operations
/// to [BluetoothPrinterService.instance].
class BluetoothPrinterController extends GetxController {
  final BluetoothPrinterService _service = BluetoothPrinterService.instance;
  final AppController appController = Get.find<AppController>();

  /// List of printers discovered during the current scan.
  final RxList<ScanResult> discoveredPrinters = <ScanResult>[].obs;

  /// Whether a Bluetooth scan is currently in progress.
  final RxBool isScanning = false.obs;

  /// Current connection status of the Bluetooth printer.
  final Rx<BluetoothPrinterStatus> printerStatus =
      BluetoothPrinterStatus.disconnected.obs;

  /// Saved paired printer info loaded from secure storage.
  final Rx<PairedPrinterInfo?> savedPrinter = Rx<PairedPrinterInfo?>(null);

  StreamSubscription<List<ScanResult>>? _scanSubscription;
  Worker? _statusWorker;

  @override
  void onInit() {
    super.onInit();
    _bindStatusStream();
    _loadSavedPrinter();
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    _statusWorker?.dispose();
    super.onClose();
  }

  /// Bind to the service's reactive status so the UI stays in sync.
  void _bindStatusStream() {
    _statusWorker = ever(_service.status, (BluetoothPrinterStatus status) {
      printerStatus.value = status;
    });
    // Sync initial value.
    printerStatus.value = _service.status.value;
  }

  /// Load saved paired printer info from secure storage.
  Future<void> _loadSavedPrinter() async {
    try {
      savedPrinter.value = await _service.getSavedPrinter();
      LogUtils.debugLog(
        'BluetoothPrinterController: Loaded saved printer - ${savedPrinter.value}',
      );
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterController: Error loading saved printer - $e',
      );
    }
  }

  /// Check and request Bluetooth and location permissions.
  ///
  /// On Android, requests [Permission.bluetooth], [Permission.bluetoothScan],
  /// [Permission.bluetoothConnect], and [Permission.location].
  /// On iOS, only Bluetooth permission is needed (handled by the OS dialog).
  ///
  /// Returns `true` if all required permissions are granted.
  Future<bool> ensurePermissions() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetooth,
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.location,
        ].request();

        final allGranted = statuses.values.every(
          (status) => status.isGranted,
        );

        if (!allGranted) {
          LogUtils.debugLog(
            'BluetoothPrinterController: Some permissions denied - $statuses',
          );
          CustomDialog.showToast('bluetoothPermissionRequired'.tr);
          return false;
        }
      } else if (Platform.isIOS) {
        final status = await Permission.bluetooth.request();
        if (!status.isGranted) {
          LogUtils.debugLog(
            'BluetoothPrinterController: Bluetooth permission denied on iOS',
          );
          CustomDialog.showToast('bluetoothPermissionRequired'.tr);
          return false;
        }
      }

      LogUtils.debugLog(
        'BluetoothPrinterController: All permissions granted',
      );
      return true;
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterController: Error requesting permissions - $e',
      );
      return false;
    }
  }

  /// Check if the Bluetooth adapter is enabled.
  ///
  /// Reads the current adapter state from [FlutterBluePlus.adapterState].
  /// If Bluetooth is off, prompts the user to enable it (Android only via
  /// [FlutterBluePlus.turnOn]). On iOS, shows a toast directing the user
  /// to system settings.
  ///
  /// Returns `true` if Bluetooth is on.
  Future<bool> ensureBluetoothEnabled() async {
    try {
      final adapterState = await FlutterBluePlus.adapterState.first;

      if (adapterState == BluetoothAdapterState.on) {
        return true;
      }

      LogUtils.debugLog(
        'BluetoothPrinterController: Bluetooth is off, prompting user',
      );

      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
        // Re-check after the system dialog.
        final newState = await FlutterBluePlus.adapterState
            .firstWhere((s) => s != BluetoothAdapterState.turningOn)
            .timeout(const Duration(seconds: 10),
                onTimeout: () => BluetoothAdapterState.off);
        if (newState == BluetoothAdapterState.on) {
          return true;
        }
      }

      CustomDialog.showToast('bluetoothEnableRequired'.tr);
      return false;
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterController: Error checking Bluetooth state - $e',
      );
      CustomDialog.showToast('bluetoothEnableRequired'.tr);
      return false;
    }
  }

  /// Start scanning for nearby Bluetooth printers.
  ///
  /// Checks permissions and Bluetooth state first. Clears previous results,
  /// sets [isScanning] to `true`, and subscribes to the service's scan stream.
  /// Discovered printers are added to [discoveredPrinters] incrementally.
  Future<void> scanForPrinters() async {
    if (isScanning.value) return;

    final hasPermissions = await ensurePermissions();
    if (!hasPermissions) return;

    final bluetoothOn = await ensureBluetoothEnabled();
    if (!bluetoothOn) return;

    discoveredPrinters.clear();
    isScanning.value = true;

    try {
      LogUtils.debugLog('BluetoothPrinterController: Starting scan...');

      final scanStream = _service.startScan();
      _scanSubscription?.cancel();
      _scanSubscription = scanStream.listen(
        (results) {
          discoveredPrinters.value = results;
        },
        onDone: () {
          isScanning.value = false;
          LogUtils.debugLog(
            'BluetoothPrinterController: Scan complete - '
            '${discoveredPrinters.length} printer(s) found',
          );
        },
        onError: (dynamic error) {
          isScanning.value = false;
          LogUtils.debugLog(
            'BluetoothPrinterController: Scan error - $error',
          );
          CustomDialog.showToast('bluetoothScanFailed'.tr);
        },
      );
    } catch (e) {
      isScanning.value = false;
      LogUtils.debugLog(
        'BluetoothPrinterController: Error starting scan - $e',
      );
      CustomDialog.showToast('bluetoothScanFailed'.tr);
    }
  }

  /// Connect to a selected Bluetooth printer.
  ///
  /// Updates [printerStatus] to [BluetoothPrinterStatus.connecting] via the
  /// service's status stream. On success, reloads [savedPrinter]. On failure,
  /// shows an error toast.
  Future<void> connectToPrinter(BluetoothDevice device) async {
    try {
      LogUtils.debugLog(
        'BluetoothPrinterController: Connecting to ${device.platformName}...',
      );

      final success = await _service.connect(device);

      if (success) {
        await _loadSavedPrinter();
        CustomDialog.showToast('bluetoothConnected'.tr);
      } else {
        CustomDialog.showToast('bluetoothConnectionFailed'.tr);
      }
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterController: Connection error - $e',
      );
      CustomDialog.showToast('bluetoothConnectionFailed'.tr);
    }
  }

  /// Disconnect from the currently connected printer.
  ///
  /// Delegates to the service and clears [savedPrinter].
  Future<void> disconnectPrinter() async {
    try {
      LogUtils.debugLog('BluetoothPrinterController: Disconnecting...');
      await _service.disconnect();
      savedPrinter.value = null;
      CustomDialog.showToast('bluetoothDisconnected'.tr);
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterController: Disconnect error - $e',
      );
    }
  }

  /// Forget the saved paired printer without disconnecting first.
  ///
  /// Clears the persisted printer data and resets [savedPrinter].
  Future<void> forgetSavedPrinter() async {
    try {
      LogUtils.debugLog(
        'BluetoothPrinterController: Forgetting saved printer...',
      );
      await _service.disconnect();
      savedPrinter.value = null;
      CustomDialog.showToast('bluetoothPrinterForgotten'.tr);
    } catch (e) {
      LogUtils.debugLog(
        'BluetoothPrinterController: Error forgetting printer - $e',
      );
    }
  }
}
