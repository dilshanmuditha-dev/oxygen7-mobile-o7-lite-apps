import 'package:json_annotation/json_annotation.dart';

part 'payment_source.g.dart';

@JsonSerializable()
class PaymentSource {
  @JsonKey(includeIfNull: false)
  final String? name;

  @JsonKey(includeIfNull: false)
  final String? email;

  @JsonKey(includeIfNull: false)
  final String? phone;

  @JsonKey(name: 'consumer_identifier', includeIfNull: false)
  final String? consumerIdentifier;

  PaymentSource({
    this.name,
    this.email,
    this.phone,
    this.consumerIdentifier,
  });

  factory PaymentSource.fromJson(Map<String, dynamic> json) =>
      _$PaymentSourceFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentSourceToJson(this);
}
