// ignore_for_file: file_names
import 'package:json_annotation/json_annotation.dart';

part 'USDT_model.g.dart';

@JsonSerializable()
class USDTModel {
  USDTModel({
    this.eType,
    this.alias,
    this.timeout,
  });
  String? eType;
  String? alias;
  String? timeout;

  factory USDTModel.fromJson(Map<String, dynamic> json) =>
      _$USDTModelFromJson(json);

  Map<String, dynamic> toJson() => _$USDTModelToJson(this);
}
