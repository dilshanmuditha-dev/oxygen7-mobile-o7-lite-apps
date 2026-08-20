import 'package:json_annotation/json_annotation.dart';

part 'donation_terminal_detail_response.g.dart';

@JsonSerializable()
class DionationTerminalDetailResponse {
  DionationTerminalDetailResponse({
    this.enabledBrands,
    this.enabledRoutes,
  });
  List<String>? enabledBrands;
  List<String>? enabledRoutes;

  factory DionationTerminalDetailResponse.fromJson(Map<String, dynamic> json) =>
      _$DionationTerminalDetailResponseFromJson(json['data']);

  Map<String, dynamic> toJson() =>
      _$DionationTerminalDetailResponseToJson(this);
}
