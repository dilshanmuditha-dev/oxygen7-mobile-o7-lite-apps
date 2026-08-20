import 'package:json_annotation/json_annotation.dart';

part 'ewallet_void_response.g.dart';

@JsonSerializable()
class EwalletVoidResponse {
  EwalletVoidResponse({
    this.transactionType,
    this.walletPaymentType,
    this.walletType,
    this.currency,
    this.transactionState,
  });
  int? transactionType;
  int? walletPaymentType;
  int? walletType;
  String? currency;
  String? transactionState;

  factory EwalletVoidResponse.fromJson(Map<String, dynamic> json) =>
      _$EwalletVoidResponseFromJson(json);

  Map<String, dynamic> toJson() => _$EwalletVoidResponseToJson(this);
}
