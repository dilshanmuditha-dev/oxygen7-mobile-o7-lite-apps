import 'package:json_annotation/json_annotation.dart';

part 'refund_txn_response.g.dart';

@JsonSerializable()
class RefundTxnResponse {
  @JsonKey(name: 'oxpay_txn_id')
  final String oxpayTxnId;

  @JsonKey(name: 'merchant_reference_id')
  final String? merchantReferenceId;

  @JsonKey(name: 'oxpay_original_txn_id')
  final String? oxpayOriginalTxnId;

  @JsonKey(name: 'payment_brand')
  final String? paymentBrand;

  @JsonKey(name: 'transaction_currency')
  final String? transactionCurrency;

  @JsonKey(name: 'refund_amount')
  final int? refundAmount;

  @JsonKey(name: 'host_txn_id')
  final String? hostTxnId;

  @JsonKey(name: 'gateway_response_datetime')
  final String? gatewayResponseDatetime;

  RefundTxnResponse({
    required this.oxpayTxnId,
    this.merchantReferenceId,
    this.oxpayOriginalTxnId,
    this.paymentBrand,
    this.transactionCurrency,
    this.refundAmount,
    this.hostTxnId,
    this.gatewayResponseDatetime,
  });

  factory RefundTxnResponse.fromJson(Map<String, dynamic> json) =>
      _$RefundTxnResponseFromJson(json);

  Map<String, dynamic> toJson() => _$RefundTxnResponseToJson(this);
}
