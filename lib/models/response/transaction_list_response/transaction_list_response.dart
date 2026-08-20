import 'package:json_annotation/json_annotation.dart';

part 'transaction_list_response.g.dart';

@JsonSerializable()
class TransactionListResponse {
  TransactionListResponse({
    this.saleAmount,
    this.gstRate,
    this.gstAmount,
    this.brandName,
    this.gatewayRequestDate,
    this.hostResponseDate,
    this.clientRequestDate,
    this.gatewayResponseDate,
    this.transactionId,
    this.transactionType,
    this.totalAmount,
    this.serviceAmount,
    this.currency,
    this.serviceRate,
    this.transactionState,
    this.hostTxnId,
  });
  String? saleAmount;
  String? gstRate;
  String? gstAmount;
  String? brandName;
  String? gatewayRequestDate;
  String? hostResponseDate;
  String? clientRequestDate;
  String? gatewayResponseDate;
  String? transactionId;
  dynamic transactionType;
  dynamic transactionState;
  String? totalAmount;
  String? serviceAmount;
  String? currency;
  String? serviceRate;
  String? hostTxnId;

  factory TransactionListResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionListResponseToJson(this);
}
