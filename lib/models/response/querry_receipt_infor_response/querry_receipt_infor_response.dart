import 'package:json_annotation/json_annotation.dart';
import 'merchant_response/merchant_response.dart';
import 'terminal_response/terminal_response.dart';

part 'querry_receipt_infor_response.g.dart';

@JsonSerializable()
class QuerryReceiptInforResponse {
  QuerryReceiptInforResponse({
    this.totalCount,
    this.type,
    this.serviceAmount,
    this.salesAmount,
    this.clientIP,
    this.currency,
    this.receiptNumber,
    this.brandName,
    this.gatewayRequestDate,
    this.hostResponseCode,
    this.hostResponseDate,
    this.clientRequestDate,
    this.totalPage,
    this.gatewayResponseDate,
    this.gatewayResponseCode,
    this.queryFilter,
    this.merchant,
    this.terminal,
    this.transactionId,
    this.queryType,
    this.transactionType,
    this.totalAmount,
    this.serviceRate,
    this.currentPage,
    this.transactionState,
    this.remarks,
    this.callbackType,
    this.isAllowRefund,
    this.isAllowVoid,
  });
  int? totalCount;
  String? type;
  String? serviceAmount;
  String? salesAmount;
  String? clientIP;
  String? currency;
  String? receiptNumber;
  String? brandName;
  String? gatewayRequestDate;
  String? hostResponseCode;
  String? hostResponseDate;
  String? clientRequestDate;
  int? totalPage;
  String? gatewayResponseDate;
  String? gatewayResponseCode;
  String? queryFilter;
  MerchantResponse? merchant;
  TerminalResponse? terminal;
  String? transactionId;
  String? queryType;
  dynamic transactionType;
  String? totalAmount;
  String? serviceRate;
  int? currentPage;
  String? transactionState;
  String? remarks;
  String? commChestQrUrl;
  int? callbackType;
  bool? isAllowRefund;
  bool? isAllowVoid;

  factory QuerryReceiptInforResponse.fromJson(Map<String, dynamic> json) =>
      _$QuerryReceiptInforResponseFromJson(json['data']);

  Map<String, dynamic> toJson() => _$QuerryReceiptInforResponseToJson(this);
}
