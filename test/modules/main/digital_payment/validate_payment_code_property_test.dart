// ignore_for_file: avoid_print

/// Property-based tests for `DigitalPaymentController.validatePaymentCode`.
///
/// **Validates: Requirements 3.3, 3.4**
///
/// Feature: 29-digital-payment-scan-to-charge, Property 1: payment code
/// validation threshold.
///
/// Design — Correctness Property 1:
///   For any string, `validatePaymentCode` returns null (valid) if and only if,
///   after trimming, the string consists solely of digits with length in
///   [16, 24]. Any other input returns a non-null error message.
///
/// Approach: this is a custom (dependency-free) property-based test. We drive a
/// seeded `Random(29)` generator across several input buckets (>= 100 cases
/// total, in fact 100 per bucket) and compare the REAL controller method to an
/// INDEPENDENT oracle computed inline (trim, then check digits-only + length in
/// [16, 24] using raw code-unit inspection — deliberately NOT the method's own
/// regex, to avoid a tautological check). The property asserted for every input
/// is: `(validatePaymentCode(input) == null) == oracleValid(input)`.
///
/// Harness note: `DigitalPaymentController` is awkward to construct in isolation
/// because its field initializers read `Get.arguments` (`routePaymentModel`) and
/// resolve `Get.find<HomeController>()` / `Get.find<AppController>()`. We reuse
/// the exact harness that already works in task 8.1's
/// `validate_payment_code_test.dart`: enable `Get.testMode`, register
/// lifecycle-neutralized fakes for `ApiProvider` / `AppController` /
/// `HomeController`, an `ApiRepository`, and inject a `RoutePaymentModel` via
/// `Get.routing.args`. With no translations loaded, GetX `.tr` resolves an
/// unknown key to the key string, so an invalid code returns the literal
/// `'msgInvalidPaymentCode'` (non-null) and a valid code returns `null`.

import 'dart:convert';
import 'dart:math';

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

/// HomeController fake whose lifecycle does no heavy init.
class _TestHomeController extends HomeController {
  _TestHomeController(ApiRepository repository)
      : super(apiRepository: repository);

  @override
  Future<void> onInit() async {}
}

/// Builds the real DigitalPaymentController with all GetX dependencies wired.
DigitalPaymentController _buildRealController() {
  Get.put<ApiProvider>(_TestApiProvider());
  final repository = ApiRepository();
  Get.put<ApiRepository>(repository);
  Get.put<AppController>(_TestAppController());
  Get.put<HomeController>(_TestHomeController(repository));

  Get.routing.args = RoutePaymentModel(
    image: '',
    acquireReport: '',
    isActivated: true,
    currency: 'SGD',
    brand: 'Alipay',
  );

  return DigitalPaymentController(apiRepository: repository);
}

/// Independent oracle for the property under test.
///
/// Deliberately implemented WITHOUT the method's own `RegExp(r'^\d{16,24}$')`:
/// we trim, then check the length window and that every remaining character is
/// an ASCII digit by inspecting raw UTF-16 code units ('0' = 48 .. '9' = 57).
/// This makes the property a genuine cross-check rather than a tautology.
bool oracleValid(String input) {
  final trimmed = input.trim();
  if (trimmed.length < 16 || trimmed.length > 24) return false;
  for (final unit in trimmed.codeUnits) {
    if (unit < 0x30 || unit > 0x39) return false; // not '0'..'9'
  }
  return true;
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

  // Seeded for reproducibility across runs.
  final rng = Random(29);

  const digits = '0123456789';
  const whitespace = ' \t\n\r';
  const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const symbols = '/:.?=&#@-_%+';

  String randomDigits(int len) =>
      List.generate(len, (_) => digits[rng.nextInt(digits.length)]).join();

  String randomWhitespace(int len) => List.generate(
        len,
        (_) => whitespace[rng.nextInt(whitespace.length)],
      ).join();

  /// The single property, asserted for every generated [input].
  void assertProperty(String input) {
    final result = controller.validatePaymentCode(input);
    final actualValid = result == null;
    final expectedValid = oracleValid(input);
    expect(
      actualValid,
      equals(expectedValid),
      reason: 'Property violated for input=${jsonEncode(input)} '
          '(len=${input.length}, trimmedLen=${input.trim().length}); '
          'expectedValid=$expectedValid, method result=${jsonEncode(result)}',
    );
    // Contract on the error message: invalid inputs resolve the localization
    // key (which equals the key string when no translations are loaded).
    if (!expectedValid) {
      expect(result, equals('msgInvalidPaymentCode'),
          reason: 'invalid input must return the localized key: '
              '${jsonEncode(input)}');
    }
  }

  group(
      'Feature: 29-digital-payment-scan-to-charge, '
      'Property 1: payment code validation threshold', () {
    const perBucket = 100; // >= 100 per bucket => >> 100 iterations overall.
    var totalIterations = 0;

    test('property holds across randomized input buckets (>=100 iterations)',
        () {
      // Bucket A: pure-digit strings, length 0..40. Exercises the threshold on
      // BOTH sides (below 16, inside 16..24, above 24).
      for (var i = 0; i < perBucket; i++) {
        final len = rng.nextInt(41); // 0..40
        assertProperty(randomDigits(len));
        totalIterations++;
      }

      // Bucket B: valid-length digit core (16..24) padded with random leading
      // and trailing ASCII whitespace. Must remain VALID after trimming.
      for (var i = 0; i < perBucket; i++) {
        final coreLen = 16 + rng.nextInt(9); // 16..24
        final lead = randomWhitespace(rng.nextInt(5)); // 0..4
        final trail = randomWhitespace(rng.nextInt(5)); // 0..4
        final input = '$lead${randomDigits(coreLen)}$trail';
        // Sanity: this bucket is designed to be valid.
        expect(oracleValid(input), isTrue,
            reason: 'bucket B should be valid: ${jsonEncode(input)}');
        assertProperty(input);
        totalIterations++;
      }

      // Bucket C: in-range length (16..24) alphanumeric/mixed strings with at
      // least one NON-digit (letters/symbols). No surrounding whitespace, so
      // the trimmed length stays in range but content is not digits-only ->
      // must be INVALID.
      for (var i = 0; i < perBucket; i++) {
        final len = 16 + rng.nextInt(9); // 16..24
        final chars = List<String>.generate(len, (_) {
          final pool = rng.nextInt(3);
          if (pool == 0) return digits[rng.nextInt(digits.length)];
          if (pool == 1) return letters[rng.nextInt(letters.length)];
          return symbols[rng.nextInt(symbols.length)];
        });
        // Force at least one non-digit so the string is guaranteed invalid.
        final pos = rng.nextInt(len);
        chars[pos] = rng.nextBool()
            ? letters[rng.nextInt(letters.length)]
            : symbols[rng.nextInt(symbols.length)];
        final input = chars.join();
        expect(oracleValid(input), isFalse,
            reason: 'bucket C should be invalid: ${jsonEncode(input)}');
        assertProperty(input);
        totalIterations++;
      }

      // Bucket D: digits with INTERNAL whitespace. After trimming, an internal
      // space remains among the digits -> not digits-only -> must be INVALID.
      for (var i = 0; i < perBucket; i++) {
        final leftLen = 1 + rng.nextInt(12); // 1..12
        final rightLen = 1 + rng.nextInt(12); // 1..12
        final gap = randomWhitespace(1 + rng.nextInt(3)); // 1..3 ws chars
        final input = '${randomDigits(leftLen)}$gap${randomDigits(rightLen)}';
        expect(oracleValid(input), isFalse,
            reason: 'bucket D should be invalid: ${jsonEncode(input)}');
        assertProperty(input);
        totalIterations++;
      }

      // Bucket E: empty and whitespace-only strings -> must be INVALID.
      assertProperty('');
      totalIterations++;
      for (var i = 0; i < perBucket - 1; i++) {
        final input = randomWhitespace(rng.nextInt(10)); // 0..9 ws chars
        expect(oracleValid(input), isFalse,
            reason: 'bucket E should be invalid: ${jsonEncode(input)}');
        assertProperty(input);
        totalIterations++;
      }

      expect(totalIterations, greaterThanOrEqualTo(100));
      print('Property 1 iterations executed: $totalIterations');
    });

    // Explicit boundary assertions around the [16, 24] length window.
    test('boundary lengths 15/16/17/23/24/25 (pure digits)', () {
      expect(controller.validatePaymentCode(randomDigits(15)), isNotNull);
      expect(controller.validatePaymentCode(randomDigits(16)), isNull);
      expect(controller.validatePaymentCode(randomDigits(17)), isNull);
      expect(controller.validatePaymentCode(randomDigits(23)), isNull);
      expect(controller.validatePaymentCode(randomDigits(24)), isNull);
      expect(controller.validatePaymentCode(randomDigits(25)), isNotNull);
    });
  });
}
