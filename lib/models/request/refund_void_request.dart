import 'package:app/models/request/amount.dart';
import 'package:json_annotation/json_annotation.dart';

part 'refund_void_request.g.dart';

@JsonSerializable()
class RefundVoidRequest {
  @JsonKey(name: 'merchant_id')
  final String merchantId;

  @JsonKey(name: 'terminal_id')
  final String terminalId;

  @JsonKey(name: 'merchant_reference_id')
  final String merchantReferenceId;

  @JsonKey(name: 'oxpay_original_txn_id')
  final String oxpayOriginalTxnId;

  @JsonKey(name: 'notification_url')
  final String? notificationUrl;

  @JsonKey(name: 'amount')
  final Amount amount;

  RefundVoidRequest({
    required this.merchantId,
    required this.terminalId,
    required this.merchantReferenceId,
    required this.oxpayOriginalTxnId,
    this.notificationUrl,
    required this.amount,
  });

  factory RefundVoidRequest.fromJson(Map<String, dynamic> json) =>
      _$RefundVoidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefundVoidRequestToJson(this);
}
