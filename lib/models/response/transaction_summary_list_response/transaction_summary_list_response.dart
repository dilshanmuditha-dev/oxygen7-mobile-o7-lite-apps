import 'package:json_annotation/json_annotation.dart';

part 'transaction_summary_list_response.g.dart';

@JsonSerializable()
class TransactionSummaryListResponse {
  TransactionSummaryListResponse({
    this.country,
    this.acceptorTerminalId,
    this.moduleName,
    this.acceptorId,
    this.type,
    this.merchantName,
    this.responseCode,
    this.routeId,
    this.serviceAmount,
    this.merchantId,
    this.currency,
    this.id,
    this.state,
    this.refundAmount,
    this.saleAmount,
    this.brandName,
    this.authCode,
    this.gatewayRequestDate,
    this.hostResponseCode,
    this.cardHolderName,
    this.hostResponseDate,
    this.clientRequestDate,
    this.gatewayResponseDate,
    this.mcpTerminalId,
    this.totalAmount,
    this.lastUpdatedDate,
    this.remarks,
  });
  String? country;
  String? acceptorTerminalId;
  String? moduleName;
  String? acceptorId;
  String? type;
  String? merchantName;
  String? responseCode;
  dynamic routeId;
  dynamic serviceAmount;
  dynamic merchantId;
  String? currency;
  dynamic id;
  String? state;
  dynamic refundAmount;
  dynamic saleAmount;
  String? brandName;
  String? authCode;
  dynamic gatewayRequestDate;
  String? hostResponseCode;
  String? cardHolderName;
  dynamic hostResponseDate;
  dynamic clientRequestDate;
  dynamic gatewayResponseDate;
  String? mcpTerminalId;
  dynamic totalAmount;
  dynamic lastUpdatedDate;
  String? remarks;

  factory TransactionSummaryListResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionSummaryListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionSummaryListResponseToJson(this);
}
