// ignore_for_file: avoid_print

/// Property-based tests for `PaymentSource.toJson`.
///
/// **Validates: Requirements 5.3, 5.5**
///
/// Feature: 29-digital-payment-scan-to-charge, Property 2: consumer_identifier
/// omission.
///
/// Design — Correctness Property 2:
///   For any `PaymentSource` where `consumerIdentifier` is null, the serialized
///   JSON SHALL NOT contain the `consumer_identifier` key. When non-null, the
///   key SHALL be present with the exact value.
///
/// Approach: this is a custom (dependency-free) property-based test. A seeded
/// `Random(29)` generator independently decides, for each of the four optional
/// fields (`name`, `email`, `phone`, `consumerIdentifier`), whether it is null
/// or a random non-null string. Non-null strings are drawn from a varied
/// alphabet (digits, letters, symbols) and, occasionally, the EMPTY string ''.
/// The empty string is important: `@JsonKey(includeIfNull: false)` omits only
/// NULL values, so a non-null '' MUST still be serialized (present with value
/// '').
///
/// For every generated `PaymentSource`, the full contract is asserted:
///   1. Each field's JSON key is present iff the field is non-null, and when
///      present carries the exact value passed (empty string included).
///   2. The serialized map contains NO unexpected keys: its key set equals
///      exactly the set of JSON names of the non-null fields.
///
/// Points 1 & 2 together strengthen Requirement 5.5 (null fields omitted ->
/// MPQR byte-compatibility) and Requirement 5.3 (consumer_identifier carries
/// the scanned Payment_Code verbatim when set).

import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/request/payment_source.dart';

void main() {
  // Seeded for reproducibility across runs.
  final rng = Random(29);

  const digits = '0123456789';
  const letters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ';
  const symbols = '/:.?=&#@-_%+ ';
  const alphabet = digits + letters + symbols;

  /// Generates a random string of length [len] from the mixed [alphabet].
  String randomString(int len) =>
      List.generate(len, (_) => alphabet[rng.nextInt(alphabet.length)]).join();

  /// Independently decides a field value: ~1/4 chance null, otherwise a random
  /// non-null string. Among the non-null cases, ~1/6 are the empty string ''.
  String? randomFieldValue() {
    if (rng.nextInt(4) == 0) return null; // null bucket
    if (rng.nextInt(6) == 0) return ''; // non-null empty string bucket
    return randomString(1 + rng.nextInt(20)); // 1..20 chars
  }

  /// Maps a Dart field name to its serialized JSON key.
  const jsonKeyOf = <String, String>{
    'name': 'name',
    'email': 'email',
    'phone': 'phone',
    'consumerIdentifier': 'consumer_identifier',
  };

  /// Asserts the full omit-iff-null + exact-value + no-extra-keys contract for
  /// the given field combination.
  void assertProperty({
    required String? name,
    required String? email,
    required String? phone,
    required String? consumerIdentifier,
  }) {
    final fields = <String, String?>{
      'name': name,
      'email': email,
      'phone': phone,
      'consumerIdentifier': consumerIdentifier,
    };

    final source = PaymentSource(
      name: name,
      email: email,
      phone: phone,
      consumerIdentifier: consumerIdentifier,
    );
    final json = source.toJson();

    final combo = jsonEncode(fields);

    // (1) Per-field: present iff non-null, exact value when present.
    fields.forEach((field, value) {
      final key = jsonKeyOf[field]!;
      final shouldBePresent = value != null;
      expect(
        json.containsKey(key),
        equals(shouldBePresent),
        reason: 'Key "$key" presence should be $shouldBePresent for combo '
            '$combo',
      );
      if (shouldBePresent) {
        expect(
          json[key],
          equals(value),
          reason: 'Key "$key" should carry exact value ${jsonEncode(value)} '
              'for combo $combo',
        );
      }
    });

    // (2) No unexpected keys: key set == JSON names of the non-null fields.
    final expectedKeys = <String>{
      for (final entry in fields.entries)
        if (entry.value != null) jsonKeyOf[entry.key]!,
    };
    expect(
      json.keys.toSet(),
      equals(expectedKeys),
      reason: 'Serialized key set must equal exactly the non-null fields for '
          'combo $combo (got ${jsonEncode(json.keys.toList())})',
    );
  }

  group(
      'Feature: 29-digital-payment-scan-to-charge, '
      'Property 2: consumer_identifier omission', () {
    test(
        'presence iff non-null with exact values across randomized field '
        'combinations (>=100 iterations)', () {
      const iterations = 500; // >> 100
      var executed = 0;

      for (var i = 0; i < iterations; i++) {
        assertProperty(
          name: randomFieldValue(),
          email: randomFieldValue(),
          phone: randomFieldValue(),
          consumerIdentifier: randomFieldValue(),
        );
        executed++;
      }

      expect(executed, greaterThanOrEqualTo(100));
      print('Property 2 iterations executed: $executed');
    });

    // Explicit corner cases alongside the randomized loop.
    test('all-null source serializes to an empty map', () {
      expect(PaymentSource().toJson(), isEmpty);
    });

    test('only consumerIdentifier non-null -> exactly one key', () {
      const code = '1234567890123456';
      final json = PaymentSource(consumerIdentifier: code).toJson();
      expect(json, equals({'consumer_identifier': code}));
    });

    test('consumerIdentifier = "" (empty non-null) is present with value ""',
        () {
      final json = PaymentSource(consumerIdentifier: '').toJson();
      expect(json.containsKey('consumer_identifier'), isTrue);
      expect(json['consumer_identifier'], equals(''));
      expect(json, equals({'consumer_identifier': ''}));
    });
  });
}
