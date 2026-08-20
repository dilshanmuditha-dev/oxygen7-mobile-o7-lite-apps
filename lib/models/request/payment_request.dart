import 'package:json_annotation/json_annotation.dart';
import 'payment_method.dart';
import 'amount.dart';

part 'payment_request.g.dart';

@JsonSerializable()
class PaymentRequest {
  @JsonKey(name: 'merchant_id')
  final String merchantId;

  @JsonKey(name: 'terminal_id')
  final String terminalId;

  @JsonKey(name: 'merchant_reference_id')
  final String merchantReferenceId;

  @JsonKey(name: 'success_url')
  final String? successUrl;

  @JsonKey(name: 'failure_url')
  final String? failureUrl;

  @JsonKey(name: 'notification_url')
  final String? notificationUrl;

  @JsonKey(name: 'payment_method', includeIfNull: false)
  final PaymentMethod? paymentMethod;

  final Amount amount;

  @JsonKey(includeIfNull: false)
  final bool? capture;

  final String? description;

  PaymentRequest({
    required this.merchantId,
    required this.terminalId,
    required this.merchantReferenceId,
    this.successUrl,
    this.failureUrl,
    this.notificationUrl,
    this.paymentMethod,
    required this.amount,
    this.capture,
    this.description,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) =>
      _$PaymentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);
}
