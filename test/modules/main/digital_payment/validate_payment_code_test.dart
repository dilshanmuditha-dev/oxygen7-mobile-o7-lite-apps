// ignore_for_file: avoid_print

/// Unit tests for `DigitalPaymentController.validatePaymentCode`.
///
/// **Validates: Requirements 3.3, 3.4**
///
/// Feature: 29-digital-payment-scan-to-charge
///
/// These tests exercise the REAL `DigitalPaymentController.validatePaymentCode`
/// method (not a mirror). `DigitalPaymentController` is awkward to construct in
/// isolation because its field initializers read `Get.arguments`
/// (`routePaymentModel`) and resolve `Get.find<HomeController>()` /
/// `Get.find<AppController>()`. We satisfy those by:
///   - enabling `Get.testMode`,
///   - registering lifecycle-neutralized fakes for `ApiProvider`,
///     `AppController`, and `HomeController` (onInit overridden so no platform
///     channels / SSL / package-info work runs), and
///   - injecting a `RoutePaymentModel` via `Get.routing.args` (which backs
///     `Get.arguments`).
///
/// Note on localization: no translations are loaded here, so GetX `.tr`
/// resolves an unknown key to the key string itself. Therefore an invalid
/// payment code returns the literal `'msgInvalidPaymentCode'` (non-null),
/// while a valid code returns `null`.

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'package:app/api/api_provider.dart';
import 'package:app/api/api_repository.dart';
import 'package:app/app_controller.dart';
import 'package:app/models/route_payment_model.dart';
import 'package:app/modules/main/digital_payment/digital_payment_controller.dart';
import 'package:app/modules/main/home_controller.dart';
import 'package:app/shared/utils/app_flavor_helper.dart';

/// ApiProvider fake whose lifecycle does no platform work.
/// The real `onInit` fetches `PackageInfo` and installs SSL/interceptors, which
/// is irrelevant here and unavailable in a plain unit-test binding.
class _TestApiProvider extends ApiProvider {
  _TestApiProvider() : super(AppFlavor.development);

  @override
  void onInit() {}
}

/// AppController fake whose lifecycle does no heavy init.
class _TestAppController extends AppController {
  _TestAppController() : super(AppFlavor.development);

  @override
  void onInit() {}
}

/// HomeController fake whose lifecycle does no heavy init. Its super field
/// initializers still resolve `Get.find<ApiProvider>()` and
/// `Get.find<AppController>()`, so those must be registered first.
class _TestHomeController extends HomeController {
  _TestHomeController(ApiRepository repository)
      : super(apiRepository: repository);

  @override
  Future<void> onInit() async {}
}

/// Builds the real DigitalPaymentController with all GetX dependencies wired.
DigitalPaymentController _buildRealController() {
  // Register dependencies in dependency order (ApiProvider first, since
  // ApiRepository + HomeController read it during field initialization).
  Get.put<ApiProvider>(_TestApiProvider());
  final repository = ApiRepository();
  Get.put<ApiRepository>(repository);
  Get.put<AppController>(_TestAppController());
  Get.put<HomeController>(_TestHomeController(repository));

  // `Get.arguments` is backed by `Get.routing.args`; the controller reads it
  // as its `routePaymentModel` during field initialization.
  Get.routing.args = RoutePaymentModel(
    image: '',
    acquireReport: '',
    isActivated: true,
    currency: 'SGD',
    brand: 'Alipay',
  );

  return DigitalPaymentController(apiRepository: repository);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DigitalPaymentController controller;

  setUpAll(() {
    Get.testMode = true;
    controller = _buildRealController();
  });

  tearDownAll(() {
    Get.reset();
  });

  group('validatePaymentCode', () {
    // -----------------------------------------------------------------------
    // Design-specified cases (Testing Strategy)
    // -----------------------------------------------------------------------
    test('16-digit numeric code is valid (returns null)', () {
      expect(controller.validatePaymentCode('1234567890123456'), isNull);
    });

    test('15-digit code is invalid (below minimum length)', () {
      expect(controller.validatePaymentCode('123456789012345'), isNotNull);
    });

    test('25-digit code is invalid (above maximum length)', () {
      expect(
        controller.validatePaymentCode('1234567890123456789012345'),
        isNotNull,
      );
    });

    test('URL / non-digit content is invalid', () {
      expect(
        controller.validatePaymentCode('https://pay.example/abc'),
        isNotNull,
      );
    });

    test('leading/trailing spaces around a valid code are trimmed -> valid',
        () {
      expect(controller.validatePaymentCode('  1234567890123456  '), isNull);
    });

    // -----------------------------------------------------------------------
    // Boundary cases around the [16, 24] length window
    // -----------------------------------------------------------------------
    test('exactly 16 digits (lower bound) is valid', () {
      expect(controller.validatePaymentCode('1234567890123456'), isNull);
    });

    test('exactly 17 digits (just inside lower bound) is valid', () {
      expect(controller.validatePaymentCode('12345678901234567'), isNull);
    });

    test('exactly 23 digits (just inside upper bound) is valid', () {
      expect(
        controller.validatePaymentCode('12345678901234567890123'),
        isNull,
      );
    });

    test('exactly 24 digits (upper bound) is valid', () {
      expect(
        controller.validatePaymentCode('123456789012345678901234'),
        isNull,
      );
    });

    // -----------------------------------------------------------------------
    // Additional invalid / whitespace edge cases
    // -----------------------------------------------------------------------
    test('empty string is invalid', () {
      expect(controller.validatePaymentCode(''), isNotNull);
    });

    test('whitespace-only string is invalid (trims to empty)', () {
      expect(controller.validatePaymentCode('      '), isNotNull);
    });

    test('code with an internal space is invalid', () {
      expect(
        controller.validatePaymentCode('1234 5678 9012 3456'),
        isNotNull,
      );
    });

    test('16-char code containing letters is invalid', () {
      expect(controller.validatePaymentCode('ABCD567890123456'), isNotNull);
    });

    test('whitespace-padded 20-digit code is valid after trimming', () {
      expect(
        controller.validatePaymentCode('  12345678901234567890  '),
        isNull,
      );
    });

    test('newline/tab padded 18-digit code is valid after trimming', () {
      expect(
          controller.validatePaymentCode('\t\n123456789012345678\n'), isNull);
    });

    // -----------------------------------------------------------------------
    // Localized message contract: invalid input resolves the localization key
    // (which equals the key string when no translations are loaded).
    // -----------------------------------------------------------------------
    test('invalid code returns the localized invalid-payment-code message', () {
      final result = controller.validatePaymentCode('nope');
      expect(result, isNotNull);
      expect(result, equals('msgInvalidPaymentCode'));
    });
  });
}
