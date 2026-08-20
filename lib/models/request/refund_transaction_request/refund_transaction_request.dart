import 'package:json_annotation/json_annotation.dart';

part 'refund_transaction_request.g.dart';

@JsonSerializable()
class RefundTransactionRequest {
  RefundTransactionRequest({
    required this.currency,
    required this.eType,
    required this.tradeNo,
    required this.totalAmount,
  });

  String? currency;
  String? eType;
  String? tradeNo;
  String? totalAmount;

  factory RefundTransactionRequest.fromJson(Map<String, dynamic> json) =>
      _$RefundTransactionRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefundTransactionRequestToJson(this);
}
