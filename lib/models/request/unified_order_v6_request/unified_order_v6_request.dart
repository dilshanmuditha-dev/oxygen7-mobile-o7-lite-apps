import 'package:json_annotation/json_annotation.dart';

part 'unified_order_v6_request.g.dart';

@JsonSerializable()
class UnifiedOrderV6Request {
  UnifiedOrderV6Request({
    required this.description,
    required this.totalAmount,
    required this.currency,
    required this.eType,
    required this.referenceNo,
    required this.reqKey,
    required this.mcptid,
    this.salesAmount,
    this.serviceAmount,
    this.serviceRate,
    this.statusUrl,
  });

  String? description;
  String? totalAmount;
  String? currency;
  String? eType;
  String? referenceNo;
  String? reqKey;
  String? mcptid;
  String? salesAmount;
  String? serviceAmount;
  String? serviceRate;
  String? statusUrl;
  factory UnifiedOrderV6Request.fromJson(Map<String, dynamic> json) =>
      _$UnifiedOrderV6RequestFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedOrderV6RequestToJson(this);
}
