import 'package:json_annotation/json_annotation.dart';

part 'unified_order_request.g.dart';

@JsonSerializable()
class UnifiedOrderRequest {
  UnifiedOrderRequest({
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.eType,
    this.salesAmount,
    this.serviceAmount,
    this.serviceRate,
    this.referenceNo,
    this.statusUrl,
  });

  String? description;
  String? totalAmount;
  String? currency;
  String? eType;
  String? salesAmount;
  String? serviceAmount;
  String? serviceRate;
  String? referenceNo;
  String? statusUrl;

  factory UnifiedOrderRequest.fromJson(Map<String, dynamic> json) =>
      _$UnifiedOrderRequestFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedOrderRequestToJson(this);
}
