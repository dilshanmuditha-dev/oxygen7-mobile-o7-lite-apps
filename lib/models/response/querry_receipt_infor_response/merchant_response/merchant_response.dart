import 'package:app/models/response/querry_receipt_infor_response/address_response/address_response.dart';
import 'package:json_annotation/json_annotation.dart';

part 'merchant_response.g.dart';

@JsonSerializable()
class MerchantResponse {
  MerchantResponse({
    this.address,
    this.shortName,
  });
  AddressResponse? address;
  String? shortName;

  factory MerchantResponse.fromJson(Map<String, dynamic> json) =>
      _$MerchantResponseFromJson(json);

  Map<String, dynamic> toJson() => _$MerchantResponseToJson(this);
}
