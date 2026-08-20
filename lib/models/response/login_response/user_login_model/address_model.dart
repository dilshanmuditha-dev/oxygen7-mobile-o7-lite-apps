import 'package:json_annotation/json_annotation.dart';

part 'address_model.g.dart';

@JsonSerializable()
class AddressModel {
  AddressModel({
    this.city,
    this.country,
    this.countryCode,
    this.countryCodeAlpha,
    this.line1,
    this.line2,
    this.line3,
    this.postalCode,
    this.regionCode,
    this.line4,
    this.line5,
  });

  String? city;
  String? country;
  String? countryCode;
  String? countryCodeAlpha;
  String? line1;
  String? line2;
  String? line3;
  String? line4;
  String? line5;
  String? postalCode;
  String? regionCode;

  factory AddressModel.fromJson(Map<String, dynamic> json) =>
      _$AddressModelFromJson(json);

  Map<String, dynamic> toJson() => _$AddressModelToJson(this);
}
