import 'package:json_annotation/json_annotation.dart';

part 'donation_terminal_detail_request.g.dart';

@JsonSerializable()
class DonationTerminalDetailRequest {
  DonationTerminalDetailRequest({
    required this.mcpTerminalId,
  });

  String? mcpTerminalId;

  factory DonationTerminalDetailRequest.fromJson(Map<String, dynamic> json) =>
      _$DonationTerminalDetailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$DonationTerminalDetailRequestToJson(this);
}
