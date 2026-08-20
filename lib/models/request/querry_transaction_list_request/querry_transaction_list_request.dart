import 'package:json_annotation/json_annotation.dart';

part 'querry_transaction_list_request.g.dart';

@JsonSerializable()
class QuerryTransactionListRequest {
  QuerryTransactionListRequest({
    this.startDate,
    this.endDate,
    this.page,
    this.pageSize,
    this.transactionId,
    this.brands,
    this.states,
  });

  String? startDate;
  String? endDate;
  String? page;
  int? pageSize;
  String? transactionId;
  List<String>? brands;
  List<String>? states;

  factory QuerryTransactionListRequest.fromJson(Map<String, dynamic> json) =>
      _$QuerryTransactionListRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QuerryTransactionListRequestToJson(this);
}
