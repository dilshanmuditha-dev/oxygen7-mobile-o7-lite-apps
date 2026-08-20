import 'package:json_annotation/json_annotation.dart';

part 'ewallet_void_request.g.dart';

@JsonSerializable()
class EwalletVoidRequest {
  EwalletVoidRequest({
    required this.tradeNo,
    required this.eType,
    required this.currencySelected,
  });

  String? tradeNo;
  String? eType;
  String? currencySelected;

  factory EwalletVoidRequest.fromJson(Map<String, dynamic> json) =>
      _$EwalletVoidRequestFromJson(json);

  Map<String, dynamic> toJson() => _$EwalletVoidRequestToJson(this);
}
