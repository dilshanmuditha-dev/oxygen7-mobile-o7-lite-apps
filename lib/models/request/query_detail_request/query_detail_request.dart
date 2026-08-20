import 'package:json_annotation/json_annotation.dart';

part 'query_detail_request.g.dart';

@JsonSerializable()
class QueryDetailRequest {
  QueryDetailRequest({
    required this.transactionId,
  });

  String? transactionId;

  factory QueryDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$QueryDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$QueryDetailRequestToJson(this);
}
