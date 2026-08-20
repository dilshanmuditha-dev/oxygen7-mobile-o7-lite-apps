import 'package:app/models/response/transaction_list_response/transaction_list_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'querry_transaction_list_response.g.dart';

@JsonSerializable()
class QuerryTransactionListResponse {
  QuerryTransactionListResponse({
    this.endDate,
    this.totalPage,
    this.clientIP,
    this.transactionList,
    this.gatewayResponseCode,
    this.queryFilter,
    this.currentPage,
    this.totalCount,
    this.type,
    this.startDate,
    this.queryType,
  });
  String? endDate;
  int? totalPage;
  String? clientIP;
  List<TransactionListResponse>? transactionList;
  String? gatewayResponseCode;
  String? queryFilter;
  int? currentPage;
  int? totalCount;
  String? type;
  String? startDate;
  String? queryType;

  factory QuerryTransactionListResponse.fromJson(Map<String, dynamic> json) =>
      _$QuerryTransactionListResponseFromJson(json['data']);

  Map<String, dynamic> toJson() => _$QuerryTransactionListResponseToJson(this);
}
