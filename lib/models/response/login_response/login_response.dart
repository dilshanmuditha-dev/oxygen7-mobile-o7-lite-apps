import 'package:app/models/response/login_response/user_login_model/terminal_address_model.dart';
import 'package:app/models/response/login_response/user_login_model/triple_a_module_data_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'user_login_model/merchant_model.dart';
import 'user_login_model/wallet_types_model.dart';

part 'login_response.g.dart';

@JsonSerializable()
class LoginResponse {
  LoginResponse({
    this.brands,
    this.currencyList,
    this.donationMcptid,
    this.enabledBrands,
    this.enabledRoutes,
    this.isDonation,
    this.mcpTerminalId,
    this.merchant,
    this.modules,
    this.routeList,
    this.signKey,
    this.terminal,
    this.tripleAModuleData,
    this.walletTypes,
  });

  List<String>? brands;
  List<String>? currencyList;
  String? donationMcptid;
  List<String>? enabledBrands;
  List<String>? enabledRoutes;
  bool? isDonation;
  String? mcpTerminalId;
  MerchantModel? merchant;
  List<String>? modules;
  List<String>? routeList;
  String? signKey;
  TerminalAddressModel? terminal;
  TripleAModuleDataModel? tripleAModuleData;
  WalletTypeModel? walletTypes;

  factory LoginResponse.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseFromJson(json['data']);

  Map<String, dynamic> toJson() => _$LoginResponseToJson(this);
}
