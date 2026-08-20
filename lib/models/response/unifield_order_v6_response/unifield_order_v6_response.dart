import 'package:json_annotation/json_annotation.dart';

part 'unifield_order_v6_response.g.dart';

@JsonSerializable()
class UnifiedOrderV6Response {
  UnifiedOrderV6Response({
    this.mcptid,
    this.qrUrl,
    this.walletType,
    this.currency,
    this.transactionId,
  });
  String? qrUrl;
  String? walletType;
  String? currency;
  String? mcptid;
  String? transactionId;

  factory UnifiedOrderV6Response.fromJson(Map<String, dynamic> json) =>
      _$UnifiedOrderV6ResponseFromJson(json);

  Map<String, dynamic> toJson() => _$UnifiedOrderV6ResponseToJson(this);
}
