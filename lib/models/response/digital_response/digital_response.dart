import 'package:json_annotation/json_annotation.dart';

part 'digital_response.g.dart';

@JsonSerializable()
class DigitalResponse {
  DigitalResponse({
    this.transactionType,
    this.walletPaymentType,
    this.totalAmount,
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
  int? walletType;
  String? amountInCNY;
  String? currencySettled;
  String? currency;
  String? amountSettled;
  String? merchantOrderNo;
  String? transactionState;
  String? transactionId;

  factory DigitalResponse.fromJson(Map<String, dynamic> json) =>
      _$DigitalResponseFromJson(json['data']);

  Map<String, dynamic> toJson() => _$DigitalResponseToJson(this);
}
