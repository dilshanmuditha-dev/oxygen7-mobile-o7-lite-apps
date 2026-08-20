// ignore_for_file: file_names
import 'package:json_annotation/json_annotation.dart';

part 'get_transacion_summary_AFG_request.g.dart';

@JsonSerializable()
class GetTransacionSummaryAFGRequest {
  GetTransacionSummaryAFGRequest({
    required this.acquirer,
    required this.currency,
    required this.endDate,
    required this.startDate,
    required this.isShowError,
  });

  String? acquirer;
  String? currency;
  String? endDate;
  String? startDate;
  bool? isShowError;

  factory GetTransacionSummaryAFGRequest.fromJson(Map<String, dynamic> json) =>
      _$GetTransacionSummaryAFGRequestFromJson(json);

  Map<String, dynamic> toJson() => _$GetTransacionSummaryAFGRequestToJson(this);
}
