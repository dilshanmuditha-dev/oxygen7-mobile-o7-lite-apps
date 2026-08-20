import 'package:json_annotation/json_annotation.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentResponse {
  @JsonKey(name: 'oxpay_txn_id', fromJson: _oxpayTxnIdFromJson)
  final String oxpayTxnId;

  static String _oxpayTxnIdFromJson(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  @JsonKey(name: 'host_txn_id')
  final String? hostTxnId;

  @JsonKey(name: 'payment_brand')
  final String paymentBrand;

  @JsonKey(name: 'qr_string', defaultValue: '')
  final String qrString;

  @JsonKey(name: 'transaction_amount')
  final int transactionAmount;

  @JsonKey(name: 'transaction_currency')
  final String transactionCurrency;

  @JsonKey(name: 'payment_expiry_time', fromJson: _paymentExpiryTimeFromJson)
  final String? paymentExpiryTime;

  static String? _paymentExpiryTimeFromJson(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  @JsonKey(name: 'merchant_reference_id', defaultValue: '')
  final String merchantReferenceId;

  @JsonKey(name: 'status')
  final String? status;

  @JsonKey(name: 'status_desc')
  final String? statusDesc;

  PaymentResponse({
    required this.oxpayTxnId,
    this.hostTxnId,
    required this.paymentBrand,
    required this.qrString,
    required this.transactionAmount,
    required this.transactionCurrency,
    this.paymentExpiryTime,
    required this.merchantReferenceId,
    this.status,
    this.statusDesc,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);
}
