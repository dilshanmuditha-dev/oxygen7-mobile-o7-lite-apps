import 'package:json_annotation/json_annotation.dart';

part 'crypto_currency_api_key_model.g.dart';

@JsonSerializable()
class CryptoCurrencyApiKeyModel {
  CryptoCurrencyApiKeyModel({
    this.name,
    this.currency,
    this.enabled,
  });

  String? name;
  String? currency;
  bool? enabled;
  factory CryptoCurrencyApiKeyModel.fromJson(Map<String, dynamic> json) =>
      _$CryptoCurrencyApiKeyModelFromJson(json);

  Map<String, dynamic> toJson() => _$CryptoCurrencyApiKeyModelToJson(this);
}
