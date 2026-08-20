import 'package:json_annotation/json_annotation.dart';

part 'credit_card_void_request.g.dart';

@JsonSerializable()
class CreditCardVoidRequest {
  CreditCardVoidRequest({
    required this.originalId,
    required this.currency,
    required this.totalAmount,
  });

  String? originalId;
  String? currency;
  String? totalAmount;

  factory CreditCardVoidRequest.fromJson(Map<String, dynamic> json) =>
      _$CreditCardVoidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$CreditCardVoidRequestToJson(this);
}
