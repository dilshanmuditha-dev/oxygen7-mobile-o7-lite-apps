import 'package:app/models/response/login_response/user_login_model/USDT_model.dart';
import 'package:app/models/response/login_response/user_login_model/thai_QR_model.dart';
import 'package:json_annotation/json_annotation.dart';

part 'wallet_types_model.g.dart';

@JsonSerializable()
class WalletTypeModel {
  WalletTypeModel({
    this.thaiQR,
    this.wechatHost,
    this.grabpayV3,
    this.uSDT,
    this.shopeePay,
    this.iOUpay,
    this.alipayHost,
    this.bTC,
    this.dash,
    this.sCBPayNow,
    this.boost,
    this.touchNGo,
    this.eTH,
    this.oCBCPayNow,
    this.grabPay,
    this.atome,
  });

  ThaiQRModel? thaiQR;
  ThaiQRModel? wechatHost;
  ThaiQRModel? grabpayV3;
  USDTModel? uSDT;
  ThaiQRModel? shopeePay;
  ThaiQRModel? iOUpay;
  ThaiQRModel? alipayHost;
  USDTModel? bTC;
  ThaiQRModel? dash;
  ThaiQRModel? sCBPayNow;
  ThaiQRModel? boost;
  ThaiQRModel? touchNGo;
  USDTModel? eTH;
  ThaiQRModel? oCBCPayNow;
  ThaiQRModel? grabPay;
  ThaiQRModel? atome;

  factory WalletTypeModel.fromJson(Map<String, dynamic> json) =>
      _$WalletTypeModelFromJson(json);

  Map<String, dynamic> toJson() => _$WalletTypeModelToJson(this);
}
