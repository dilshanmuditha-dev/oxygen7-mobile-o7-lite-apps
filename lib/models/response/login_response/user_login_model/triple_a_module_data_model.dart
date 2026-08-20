import 'package:json_annotation/json_annotation.dart';

import 'crypto_currency_api_key_model.dart';

part 'triple_a_module_data_model.g.dart';

@JsonSerializable()
class TripleAModuleDataModel {
  TripleAModuleDataModel({
    this.cryptoCurrencyApiKeyModel,
  });

  List<CryptoCurrencyApiKeyModel>? cryptoCurrencyApiKeyModel;

  factory TripleAModuleDataModel.fromJson(Map<String, dynamic> json) =>
      _$TripleAModuleDataModelFromJson(json);

  Map<String, dynamic> toJson() => _$TripleAModuleDataModelToJson(this);
}
