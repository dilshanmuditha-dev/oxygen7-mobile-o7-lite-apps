import 'package:json_annotation/json_annotation.dart';

part 'digital_payment_request.g.dart';

@JsonSerializable()
class DigitalPaymentRequest {
  DigitalPaymentRequest({
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.authCode,
    required this.eType,
    required this.ipAddress,
    this.salesAmount,
    this.serviceAmount,
    this.serviceRate,
  });

  String? description;
  String? totalAmount;
  String? currency;
  String? authCode;
  String? eType;
  String? ipAddress;
  String? salesAmount;
  String? serviceAmount;
  String? serviceRate;

  factory DigitalPaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$DigitalPaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DigitalPaymentRequestToJson(this);
}
