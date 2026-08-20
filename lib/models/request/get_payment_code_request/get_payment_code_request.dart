import 'package:json_annotation/json_annotation.dart';

part 'get_payment_code_request.g.dart';

@JsonSerializable()
class GetPaymentCodeRequest {
  GetPaymentCodeRequest({
    required this.currency,
    required this.description,
    required this.mcptid,
    required this.referenceNo,
    required this.remarks,
    required this.statusUrl,
    required this.returnUrl,
    required this.tokenize,
    required this.totalAmount,
    this.salesAmount,
    this.serviceAmount,
    this.serviceRate,
  });

  String? currency;
  String? description;
  String? mcptid;
  String? referenceNo;
  String? remarks;
  String? statusUrl;
  String? returnUrl;
  String? tokenize;
  String? totalAmount;
  String? salesAmount;
  String? serviceAmount;
  String? serviceRate;

  factory GetPaymentCodeRequest.fromJson(Map<String, dynamic> json) =>
      _$GetPaymentCodeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetPaymentCodeRequestToJson(this);
}
