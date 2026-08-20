import 'package:json_annotation/json_annotation.dart';

part 'login_response_gw3.g.dart';

@JsonSerializable()
class LoginResponseGw3 {
  LoginResponseGw3({
    this.access_token,
    this.refresh_token,
  });

  String? access_token;
  String? refresh_token;

  factory LoginResponseGw3.fromJson(Map<String, dynamic> json) =>
      _$LoginResponseGw3FromJson(json);

  Map<String, dynamic> toJson() => _$LoginResponseGw3ToJson(this);
}
