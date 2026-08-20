import 'package:json_annotation/json_annotation.dart';

part 'credit_card_purchase.g.dart';

@JsonSerializable()
class CreditCardPurchaseRequest {
  CreditCardPurchaseRequest({
    required this.currency,
    required this.pan,
    required this.cardExpiryDate,
    required this.cardHolderName,
    required this.cvv,
    required this.description,
    required this.totalAmount,
    required this.referenceNo,
    this.salesAmount,
    this.serviceAmount,
    this.serviceRate,
  });

  String? currency;
  String? salesAmount;
  String? serviceAmount;
  String? serviceRate;
  String? pan;
  String? cardExpiryDate;
  String? cardHolderName;
  String? cvv;
  String? description;
  String? totalAmount;
  String? referenceNo;

  factory CreditCardPurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$CreditCardPurchaseRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreditCardPurchaseRequestToJson(this);
}
