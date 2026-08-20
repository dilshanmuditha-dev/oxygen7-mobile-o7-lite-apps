import 'package:app/models/response/login_response/user_login_model/address_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'terminal_address_model.g.dart';

@JsonSerializable()
class TerminalAddressModel {
  TerminalAddressModel({
    this.addressModel,
  });

  AddressModel? addressModel;

  factory TerminalAddressModel.fromJson(Map<String, dynamic> json) =>
      _$TerminalAddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$TerminalAddressModelToJson(this);
}
