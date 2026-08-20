import 'package:json_annotation/json_annotation.dart';
import '../address_response/address_response.dart';

part 'terminal_response.g.dart';

@JsonSerializable()
class TerminalResponse {
  TerminalResponse({
    this.address,
  });
  AddressResponse? address;

  factory TerminalResponse.fromJson(Map<String, dynamic> json) =>
      _$TerminalResponseFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalResponseToJson(this);
}
