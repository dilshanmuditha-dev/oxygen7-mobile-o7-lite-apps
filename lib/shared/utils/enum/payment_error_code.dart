import 'package:get/get.dart';

import '../../constants/common.dart';

/// Known payment gateway (GW3) rejection error codes returned by the sale /
/// payment endpoints, mapped to user-friendly, localized messages.
///
/// GW3 rejections may not populate `error_message` and instead expose the
/// reason only through the `error_description` field (a machine-readable code
/// such as `SOUNDWAVE_PARSER_FAIL`). Those codes are not suitable to show to a
/// cashier, so each known code is mapped to a friendly localization key.
///
/// To support a new gateway error code, add a new enum value with its raw
/// [code] and a localized [messageKey] (defined in `CommonConstants` and the
/// locale files).
enum PaymentErrorCode {
  /// The scanned barcode/QR code could not be parsed by the gateway, usually
  /// caused by an invalid code or the same code being scanned repeatedly.
  soundwaveParserFail(
    'SOUNDWAVE_PARSER_FAIL',
    CommonConstants.paymentErrorSoundwaveParserFail,
  );

  const PaymentErrorCode(this.code, this.messageKey);

  /// The raw error code exactly as returned by the payment gateway.
  final String code;

  /// The localization key resolving to the friendly, user-facing message.
  final String messageKey;

  /// Returns the [PaymentErrorCode] matching [rawCode] (case-insensitive), or
  /// `null` when the code is empty or not mapped.
  static PaymentErrorCode? fromCode(String? rawCode) {
    final normalized = rawCode?.trim().toUpperCase();
    if (normalized == null || normalized.isEmpty) return null;
    for (final value in PaymentErrorCode.values) {
      if (value.code == normalized) return value;
    }
    return null;
  }

  /// Resolves the friendly, localized message for [rawCode], or `null` when the
  /// code is unknown/unmapped (so callers can fall back to a generic message).
  static String? messageForCode(String? rawCode) =>
      fromCode(rawCode)?.messageKey.tr;
}
