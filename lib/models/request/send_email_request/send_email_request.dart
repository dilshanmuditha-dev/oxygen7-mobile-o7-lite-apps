import 'package:json_annotation/json_annotation.dart';

part 'send_email_request.g.dart';

@JsonSerializable()
class SendEmailRequest {
  SendEmailRequest({
    required this.invoiceFilePath,
    required this.emailTo,
    this.emailCc,
    required this.mcpTerminalId,
    required this.merchantName,
    required this.transactionId,
    required this.paymentStatus,
    required this.paymentDate,
    required this.transactionType,
    required this.paymentMethod,
    required this.paymentAmount,
    required this.paymentCurrency,
  });

  String invoiceFilePath;
  String emailTo;
  String? emailCc;
  String mcpTerminalId;
  String merchantName;
  String transactionId;
  String transactionType;
  String paymentStatus;
  String paymentDate;
  String paymentMethod;
  String paymentAmount;
  String paymentCurrency;

  factory SendEmailRequest.fromJson(Map<String, dynamic> json) =>
      _$SendEmailRequestFromJson(json);

  Map<String, dynamic> toJson() => _$SendEmailRequestToJson(this);
}
