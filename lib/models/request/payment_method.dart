import 'package:json_annotation/json_annotation.dart';
import 'payment_source.dart';

part 'payment_method.g.dart';

@JsonSerializable()
class PaymentMethod {
  final String brand;

  @JsonKey(name: 'payment_channel')
  final String paymentChannel;

  @JsonKey(
      includeIfNull:
          true) // grabpay v3 is getting source data and values can be null, so we change from false to true
  final PaymentSource? source;

  PaymentMethod({
    required this.brand,
    required this.paymentChannel,
    this.source,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) =>
      _$PaymentMethodFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentMethodToJson(this);
}
