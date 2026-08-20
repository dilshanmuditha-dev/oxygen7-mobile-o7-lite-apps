import 'package:json_annotation/json_annotation.dart';

part 'unifield_order_response.g.dart';

@JsonSerializable()
class UnifiedOrderResponse {
  UnifiedOrderResponse({
    this.transactionType,
    this.walletPaymentType,
    this.totalAmount,
    this.qrUrl,
    this.walletType,
    this.amountInCNY,
    this.currencySettled,
    this.currency,
    this.amountSettled,
    this.merchantOrderNo,
    this.transactionState,
    this.transactionId,
  });
  int? transactionType;
  int? walletPaymentType;
  String? totalAmount;
  String? qrUrl;
  int? walletType;
  String? amountInCNY;
  String? currencySettled;
  String? currency;
  String? amountSettled;
  String? merchantOrderNo;
  String? transactionState;
  String? transactionId;

  factory UnifiedOrderResponse.fromJson(Map<String, dynamic> json) =>
      _$UnifiedOrderResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedOrderResponseToJson(this);
}
