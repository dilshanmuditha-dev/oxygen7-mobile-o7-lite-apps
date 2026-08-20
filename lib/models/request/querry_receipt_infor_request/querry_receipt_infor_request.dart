import 'package:json_annotation/json_annotation.dart';

part 'querry_receipt_infor_request.g.dart';

@JsonSerializable()
class QuerryReceiptInforRequest {
  QuerryReceiptInforRequest({required this.transactionId});

  String? transactionId;

  factory QuerryReceiptInforRequest.fromJson(Map<String, dynamic> json) =>
      _$QuerryReceiptInforRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QuerryReceiptInforRequestToJson(this);
}
