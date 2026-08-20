// ignore_for_file: file_names

import 'package:app/models/response/transaction_summary_list_response/transaction_summary_list_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'transaction_summary_AFG_response.g.dart';

@JsonSerializable()
class TransactionSummaryAFGResponse {
  TransactionSummaryAFGResponse({
    this.totalCount,
    this.totalPayAmount,
    this.totalPayCount,
    this.totalVoidAmount,
    this.totalVoidCount,
    this.transactionList,
    this.totalRefundAmount,
    this.totalRefundCount,
  });
  int? totalCount = 0;
  double? totalPayAmount = 0;
  int? totalPayCount = 0;
  double? totalVoidAmount = 0;
  int? totalVoidCount = 0;
  int? totalRefundAmount = 0;
  int? totalRefundCount = 0;
  List<TransactionSummaryListResponse>? transactionList;

  factory TransactionSummaryAFGResponse.fromJson(Map<String, dynamic> json) =>
      _$TransactionSummaryAFGResponseFromJson(json['data']);

  /// Custom toJson that replaces null values with defaults to prevent
  /// null pointer exceptions in native code
  Map<String, dynamic> toJson() {
    final json = _$TransactionSummaryAFGResponseToJson(this);
    // Replace null values with defaults
    json['totalCount'] = json['totalCount'] ?? 0;
    json['totalPayAmount'] = json['totalPayAmount'] ?? 0.0;
    json['totalPayCount'] = json['totalPayCount'] ?? 0;
    json['totalVoidAmount'] = json['totalVoidAmount'] ?? 0.0;
    json['totalVoidCount'] = json['totalVoidCount'] ?? 0;
    json['totalRefundAmount'] = json['totalRefundAmount'] ?? 0;
    json['totalRefundCount'] = json['totalRefundCount'] ?? 0;
    json['transactionList'] = json['transactionList'] ?? [];
    return json;
  }
}
