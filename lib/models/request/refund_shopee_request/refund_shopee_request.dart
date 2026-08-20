import 'package:json_annotation/json_annotation.dart';

part 'refund_shopee_request.g.dart';

@JsonSerializable()
class RefundShopeeRequest {
  RefundShopeeRequest({
    required this.originalTransactionId,
    required this.currency,
    required this.totalAmount,
  });

  String? currency;
  String? originalTransactionId;
  String? totalAmount;

  factory RefundShopeeRequest.fromJson(Map<String, dynamic> json) =>
      _$RefundShopeeRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RefundShopeeRequestToJson(this);
}
