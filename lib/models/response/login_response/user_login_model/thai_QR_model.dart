// ignore_for_file: file_names
import 'package:json_annotation/json_annotation.dart';

part 'thai_QR_model.g.dart';

@JsonSerializable()
class ThaiQRModel {
  ThaiQRModel({
    this.icon,
    this.eType,
    this.alias,
    this.timeout,
  });
  String? icon;
  String? eType;
  String? alias;
  String? timeout;

  factory ThaiQRModel.fromJson(Map<String, dynamic> json) =>
      _$ThaiQRModelFromJson(json);

  Map<String, dynamic> toJson() => _$ThaiQRModelToJson(this);
}
