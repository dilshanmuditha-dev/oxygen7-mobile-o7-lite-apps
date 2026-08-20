import 'package:json_annotation/json_annotation.dart';

part 'address_response.g.dart';

@JsonSerializable()
class AddressResponse {
  AddressResponse({
    this.country,
    this.regionCode,
    this.city,
    this.countryCode,
    this.countryCodeAlpha,
    this.postalCode,
    this.line3,
    this.line2,
    this.line1,
  });
  String? country;
  String? regionCode;
  String? city;
  String? countryCode;
  String? countryCodeAlpha;
  String? postalCode;
  String? line3;
  String? line2;
  String? line1;

  factory AddressResponse.fromJson(Map<String, dynamic> json) =>
      _$AddressResponseFromJson(json);

  Map<String, dynamic> toJson() => _$AddressResponseToJson(this);
}
