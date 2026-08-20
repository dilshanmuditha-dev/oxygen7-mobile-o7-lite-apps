import 'package:json_annotation/json_annotation.dart';
import 'address_model.dart';

part 'merchant_model.g.dart';

@JsonSerializable()
class MerchantModel {
  MerchantModel({
    this.address,
    this.id,
    this.shortName,
  });

  AddressModel? address;
  int? id;
  String? shortName;

  factory MerchantModel.fromJson(Map<String, dynamic> json) =>
      _$MerchantModelFromJson(json);

  Map<String, dynamic> toJson() => _$MerchantModelToJson(this);
}
