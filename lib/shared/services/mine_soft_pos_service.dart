import 'package:flutter/services.dart';
import 'package:get/get.dart';

/// MineSoft POS Service
/// Handles Flutter-to-Android communication for MineSec SoftPOS SDK integration
class MineSoftPOSService {
  static const MethodChannel _channel = MethodChannel('CHANNEL_MINESOFTPOS');

  static MineSoftPOSService? _instance;
  static MineSoftPOSService get instance =>
      _instance ??= MineSoftPOSService._();

  MineSoftPOSService._();

  bool _isInitialized = false;
  String? _currentProfileId;

  /// Initialize MineSec SDK with profile ID
  Future<MineSoftPOSResult<String>> initialize(String profileId) async {
    try {
      final result = await _channel.invokeMethod('initialize', {
        'profileId': profileId,
      });

      if (result['success'] == true) {
        _isInitialized = true;
        _currentProfileId = profileId;
        return MineSoftPOSResult.success(result['message']);
      } else {
        return MineSoftPOSResult.error(
            result['error'] ?? 'Initialization failed');
      }
    } on PlatformException catch (e) {
      return MineSoftPOSResult.error('Platform error: ${e.message}');
    } catch (e) {
      return MineSoftPOSResult.error('Unexpected error: $e');
    }
  }

  /// Process card payment using MineSec SDK
  Future<MineSoftPOSResult<CardPaymentResult>> processCardPayment({
    required double amount,
    required String currency,
    String? description,
  }) async {
    try {
      final result = await _channel.invokeMethod('processCardPayment', {
        'amount': amount,
        'currency': currency,
        'description': description,
      });

      if (result['success'] == true) {
        final paymentResult = CardPaymentResult(
          success: true,
          transactionId: result['transactionId'],
          amount: result['amount'],
          currency: result['currency'],
          cardType: result['cardType'],
          maskedCardNumber: result['maskedCardNumber'],
          authCode: result['authCode'],
          referenceNumber: result['referenceNumber'],
        );
        return MineSoftPOSResult.success(paymentResult);
      } else {
        final paymentResult = CardPaymentResult(
          success: false,
          errorMessage: result['error'],
        );
        return MineSoftPOSResult.success(paymentResult);
      }
    } on PlatformException catch (e) {
      return MineSoftPOSResult.error('Platform error: ${e.message}');
    } catch (e) {
      return MineSoftPOSResult.error('Unexpected error: $e');
    }
  }

  /// Check if MineSec SDK is ready
  Future<MineSoftPOSResult<bool>> isReady() async {
    try {
      final result = await _channel.invokeMethod('isReady');
      return MineSoftPOSResult.success(result['ready'] ?? false);
    } on PlatformException catch (e) {
      return MineSoftPOSResult.error('Platform error: ${e.message}');
    } catch (e) {
      return MineSoftPOSResult.error('Unexpected error: $e');
    }
  }

  /// Get current initialization status
  bool get isInitialized => _isInitialized;

  /// Get current profile ID
  String? get currentProfileId => _currentProfileId;
}

/// Result wrapper for MineSoftPOS operations
class MineSoftPOSResult<T> {
  final bool success;
  final T? data;
  final String? error;

  MineSoftPOSResult._({
    required this.success,
    this.data,
    this.error,
  });

  factory MineSoftPOSResult.success(T data) {
    return MineSoftPOSResult._(
      success: true,
      data: data,
    );
  }

  factory MineSoftPOSResult.error(String error) {
    return MineSoftPOSResult._(
      success: false,
      error: error,
    );
  }

  /// Execute different actions based on result
  void fold({
    required Function(T data) onSuccess,
    required Function(String error) onError,
  }) {
    if (success && data != null) {
      onSuccess(data!);
    } else {
      onError(error ?? 'Unknown error');
    }
  }
}

/// Card payment result data model
class CardPaymentResult {
  final bool success;
  final String? transactionId;
  final double? amount;
  final String? currency;
  final String? cardType;
  final String? maskedCardNumber;
  final String? authCode;
  final String? referenceNumber;
  final String? errorMessage;
  final String? errorCode;

  CardPaymentResult({
    required this.success,
    this.transactionId,
    this.amount,
    this.currency,
    this.cardType,
    this.maskedCardNumber,
    this.authCode,
    this.referenceNumber,
    this.errorMessage,
    this.errorCode,
  });

  @override
  String toString() {
    return 'CardPaymentResult(success: $success, transactionId: $transactionId, amount: $amount, currency: $currency, cardType: $cardType, maskedCardNumber: $maskedCardNumber, authCode: $authCode, referenceNumber: $referenceNumber, errorMessage: $errorMessage, errorCode: $errorCode)';
  }
}
