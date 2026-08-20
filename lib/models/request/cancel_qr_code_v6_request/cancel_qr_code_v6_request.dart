import 'package:json_annotation/json_annotation.dart';

part 'cancel_qr_code_v6_request.g.dart';

@JsonSerializable()
class CancelQrCodeV6Request {
  CancelQrCodeV6Request({
    required this.mcptid,
    required this.currency,
    required this.eType,
    required this.transactionId,
  });

  String? mcptid;
  String? currency;
  String? eType;
  String? transactionId;

  factory CancelQrCodeV6Request.fromJson(Map<String, dynamic> json) =>
      _$CancelQrCodeV6RequestFromJson(json);

  Map<String, dynamic> toJson() => _$CancelQrCodeV6RequestToJson(this);
}
