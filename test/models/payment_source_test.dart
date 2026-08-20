import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/request/payment_source.dart';

/// **Feature: 29-digital-payment-scan-to-charge, Property 2: consumer_identifier omission**
/// **Validates: Requirements 5.3, 5.5**
///
/// Requirement 5.3 = `source.consumer_identifier` carries the scanned Payment_Code.
/// Requirement 5.5 = the field is omitted from the request body when not set, so the
/// Merchant-Presented (MPQR) Generate QR flow stays byte-compatible with current behavior.
void main() {
  group('PaymentSource.toJson', () {
    test(
        'CPQR case: only consumer_identifier is serialized with its exact value',
        () {
      // Arrange
      const code = '1234567890123456';

      // Act
      final json = PaymentSource(consumerIdentifier: code).toJson();

      // Assert - contains the key with the exact value and nothing else
      expect(json, containsPair('consumer_identifier', code));
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('phone'), isFalse);
      expect(json.length, equals(1));
    });

    test('all-null case (MPQR-style empty source) serializes to an empty map',
        () {
      // Act
      final json = PaymentSource().toJson();

      // Assert - no consumer_identifier key, no other keys
      expect(json.isEmpty, isTrue);
      expect(json.containsKey('consumer_identifier'), isFalse);
    });

    test('mixed case: set fields present, null fields omitted', () {
      // Act
      final json =
          PaymentSource(name: 'Acme', consumerIdentifier: 'X').toJson();

      // Assert
      expect(json, containsPair('name', 'Acme'));
      expect(json, containsPair('consumer_identifier', 'X'));
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('phone'), isFalse);
      expect(json.length, equals(2));
    });

    test(
        'name/email/phone set with null consumerIdentifier omits consumer_identifier',
        () {
      // Act
      final json = PaymentSource(
        name: 'Acme',
        email: 'acme@example.com',
        phone: '99998888',
      ).toJson();

      // Assert - the set fields are present, consumer_identifier is absent
      expect(json, containsPair('name', 'Acme'));
      expect(json, containsPair('email', 'acme@example.com'));
      expect(json, containsPair('phone', '99998888'));
      expect(json.containsKey('consumer_identifier'), isFalse);
    });

    test('consumer_identifier is present iff consumerIdentifier is non-null',
        () {
      // Non-null -> key present with exact value
      final withCode =
          PaymentSource(consumerIdentifier: 'abc123def456ghi7').toJson();
      expect(withCode.containsKey('consumer_identifier'), isTrue);
      expect(withCode['consumer_identifier'], equals('abc123def456ghi7'));

      // Null -> key absent
      final withoutCode = PaymentSource(consumerIdentifier: null).toJson();
      expect(withoutCode.containsKey('consumer_identifier'), isFalse);
    });

    test(
        'round-trips through fromJson/toJson for a consumer_identifier-only map',
        () {
      // Arrange
      final source = PaymentSource.fromJson({'consumer_identifier': 'abc'});

      // Assert - only consumerIdentifier is populated
      expect(source.consumerIdentifier, equals('abc'));
      expect(source.name, isNull);
      expect(source.email, isNull);
      expect(source.phone, isNull);

      // Act + Assert - toJson round-trips back to the same single-key map
      expect(source.toJson(), equals({'consumer_identifier': 'abc'}));
    });
  });
}
