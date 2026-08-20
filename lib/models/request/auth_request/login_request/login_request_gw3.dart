import 'package:json_annotation/json_annotation.dart';

part 'login_request_gw3.g.dart';

@JsonSerializable()
class LoginRequestGw3 {
  LoginRequestGw3({
    required this.operatorName,
    required this.operatorPassword,
  });

  String operatorName;
  String operatorPassword;

  factory LoginRequestGw3.fromJson(Map<String, dynamic> json) =>
      _$LoginRequestGw3FromJson(json);

  Map<String, dynamic> toJson() => _$LoginRequestGw3ToJson(this);
}
