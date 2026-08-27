// TerminalSettings Constants
// ignore_for_file: constant_identifier_names

import 'common.dart';

class ConstantsO7Lite {
  // Font text type
  static const String ARIAL_TYPE = "Arial";

  // Request Header Key
  static const String APP_TYPE = "appType";
  static const String APP_NAME = "appName";
  static const String TERMINAL_APP_VERSION = "appVersion";
  static const String PROTOCOL_VERSION = "protocolVersion";
  static const String MCP_TERMINAL_ID = "mcpTerminalId";
  static const String MERCHANT = "merchant";
  static const String ID = "id";
  static const String MCP_MERCHANT_OID = "mcpMerchantOId";
  static const String DONATION_TERMINAL_ID = "donationMcptid";
  static const String VERSION = "version";
  static const String SIGN_KEY = "signKey";
  static const String SIGNATURE = "signature";

  // Request response Key
  static const String BRAND_NAME = "brandName";
  static const String TYPE = "type";
  static const String GATEWAY_RESPONSE_DATE = "gatewayResponseDate";
  static const String CURRENCY = "currency";
  static const String LAST_UPDATE_DATE = "lastUpdateDate";
  static const String TEXT = "text";
  static const String TRANSACTION_LIST = "transactionList";
  static const String TOTAL_AMOUNT = "totalAmount";
  static const String TOTAL_PAY_AMOUNT = "totalPayAmount";
  static const String TOTAL_VOID_COUNT = "totalVoidCount";
  static const String TOTAL_VOID_AMOUNT = "totalVoidAmount";
  static const String TOTAL_PAY_COUNT = "totalPayCount";

  // payment Host
  static const String WECHAT_HOST = "wechatHost";
  static const String ALIPAY_HOST = "alipayHost";
  static const String AMEX_HOST = "amexHost";
  static const String DCI_HOST = "dciHost";
  static const String WORLDPAY_HOST = "worldpayHost";
  static const String GRABPAY_HOST = "grabpayHost";
  static const String NETSPAY_HOST = "netspayHost";
  static const String FDINDIA_HOST = "fdIndiaHost";
  static const String MIGS_HOST = "migsHost";
  static const String MAYBACK_HOST = "infinitiumHost";
  static const String FD_HOST = "fdHost";
  static const String ATOME_HOST = "atomeHost";
  static const String PAYNOW_SCB_HOST = "scbHost";
  static const String PAYNOW_EMVQR_HOST = "emvqrHost";
  static const String KBANK_THAIQR_HOST = "kbankThaiqrHost";
  static const String TBANK_HOST = "tbankHost";
  static const String PAYTABS_HOST = "paytabsHost";
  static const String SWIFTREM_HOST = "swiftremHost";
  static const String UMOBILE_HOST = "umobileHost";
  static const String EXIMBAY_HOST = "eximbayHost";
  static const String EROMNET_HOST = "eromnetHost";
  static const String ENETS_HOST = "enetsHost";
  static const String ALETA_SECUREPAY_HOST = "aletaSecurePayHost";
  static const String CREDIT_CARD_HOST = "creditCard";
  static const String DASH_HOST = "dashHost";
  static const String BOOST_TOUCHNGO_HOST = "revPayHost";
  static const String TOUCH_N_GO_HOST = "gw3v2Host";
  static const String SHOPPEE_HOST = "shopeePayHost";
  static const String GRABPAY_V3_HOST = "gw3Host";
  static const String UNIQGIFT_HOST = "uniqgiftHost";
  static const String IOUPAY_HOST = "ioupayHost";
  static const String ALETAQRC_HOST = "aletaQrcHost";
  static const String FAKE_GIFT_HOST = "fakeGiftHost";
  static const String RIPPLE_HOST = "rippleHost";
  // Demo build: placeholder destination and transaction prefix used until the
  // real Ripple acquirer configuration is available. Transactions created this
  // way exist only on the device.
  static const String RIPPLE_DEMO_ADDRESS =
      "rN7n7otQDd6FczFgLdSqtcsAUxDkw6fzRH";
  static const String RIPPLE_DEMO_TXN_PREFIX = "RPL";

  // Payment Type
  static const String ALIPAY_TYPE = "77772";
  static const String WECHAT_TYPE = "77771";
  static const String GRABPAY_TYPE = "77773";
  static const String NETSPAY_TYPE = "77774";
  static const String ATOME_TYPE = "77778";
  static const String PAYNOW_TYPE = "77780";
  static const String THAIQR_TYPE = "77777";
  static const String CARD_TYPE = "00000";
  static const String DASH_TYPE = "77779";
  static const String BOOST_TYPE = "77782";
  static const String TOUCHNGO_TYPE =
      "77799"; // Ray Kim confirmed 14PM 06/08/24 old: "77783"
  static const String QUICKPASS_TYPE = "77776";
  static const String SHOPEE_TYPE = "77787";
  static const String IOUPAY_TYPE = "77789";
  static const String GRABPAY_V3_TYPE = "77791";
  static const String RIPPLE_TYPE = "77799";
  static const String UNIQGIFT_TYPE = "77775";
  static const String BLUE_PAYMENT_TYPE = "BLUE_PAYMENT_TYPE";

  // Receipt Info Brand Image
  static const String BRAND_ALETA_CUP = "Internet Banking";
  static const String BRAND_ALIPAY = "alipayHost";
  static const String BRAND_ALIPAY_NEW = "Alipay";
  static const String BRAND_AMEX = "American Express";
  static const String BRAND_ATOME = "Atome";
  static const String BRAND_CUP = "China UnionPay";
  static const String BRAND_DASH = "Dash";
  static const String BRAND_DINERS = "Diners";
  static const String BRAND_DISCOVER = "Discover";
  static const String BRAND_ENETS = "eNETs";
  static const String BRAND_GRABPAY = "GrabPay";
  static const String BRAND_GRABPAY2 = "Grabpay";
  static const String BRAND_MASTERCARD = "MasterCard";
  static const String BRAND_PAYNOW = "SCB_PayNow";
  static const String BRAND_PAYNOW2 = "OCBC_PayNow";
  static const String BRAND_QUICKPASS = "Quickpass";
  static const String BRAND_RIPPLE = "Ripple";
  static const String BRAND_RUPAY = "RuPay";
  static const String BRAND_THAIQR = "ThaiQR";
  static const String BRAND_VISA = "Visa";
  static const String BRAND_UNIQGIFT = "UniqGift";
  static const String BRAND_WECHAT = "wechatHost";
  static const String BRAND_WECHAT_NEW = "WeChat Pay";
  static const String BRAND_TNG = "TouchNGo";
  static const String BRAND_BOOST = "Boost";
  static const String BRAND_SHOPEE = "ShopeePay";
  static const String BRAND_JCB = "JCB";
  static const String BRAND_IOUPAY = "IOUpay";
  static const String BRAND_GRABPAY3 = "GrabpayV3";
  static const String BLUE_REWARD = "BlueReward";
  static const String BRAND_TOUCH_N_GO_DUITNOW_QR = "Touch 'n Go DuitNowQR";
  static const String BRAND_UPI = 'UPI';

  //RouteList Changes Starts
  static const String ROUTE_LIST = "enabledRoutes";
  static const String BRAND_LIST = "enabledBrands";
  static const String LOGIN_TYPE = "isDonation";

  //WeChat Payment - QueryOrder API Parameter O7Lite
  static const String OFFICIAL_ACCOUNT_APP_ID = "appid";
  static const String VENDOR_ID = "vendorId";
  static const String RANDOM_STRING = "nonce_str";
  static const String RESULT_CODE = "resultCode";
  static const String ERROR_CODE = "errorCode";
  static const String ERROR_CODE_DESCRIPTION = "errorCodeDescription";
  static const String WECHAT_RETURN_STATUSCODE = "return_code";
  static const String STATUS_SUCCESS = "SUCCESS";
  static const String TRANSACTION_STATUS = "transactionStatus";
  static const String TRANSACTION_STATE = "transactionState";
  static const String BIDPRICE = "bidPrice";

  // daily summary disable credit card host
  static const String TRIPLEA_HOST = "tripleAHost";
  static const String ALETA_QRC_HOST = "aletaQrcHost";

  // afg Gift card field
  static const String ACCOUNT_VALID_STATUS = "validStatus";
  static const String TRANSACTION_ID = "transactionId";
  static const String TRANSACTION_TYPE = "transactionType";
  static const String GATEWAY_RESPONSE_TIMESTAMP = "gatewayResponseDate";
  static const String GATEWAY_REQUEST_TIMESTAMP = "gatewayRequestDate";
  static const String GATEWAY_RESPONSE_CODE = "gatewayResponseCode";
  static const String EXPIRY_DATE = "ExpiryDate";
  static const String EXPIRY_DATE2 = "expiryDate";
  static const String ORIGINAL_ID = "originalTxnId";
  static const String GIFTCARD_NUMBER = "cardNo";
  static const String GIFTCARD_RECEIPT = "receiptNo";
  static const String OUTLET_CODE = "outletCode";
  static const String POS_ID = "posID";
  static const String CASHIER_ID = "cashierID";
  static const String GIFTCARD_AMOUNT = "amount";
  static const String GIFTCARD_EMAIL = "email";
  static const String GIFTCARD_TXN_DATETIME = "txnDateTime";
  static const String GIFTCARD_PRINTED_NAME = "printedName";
  static const String STORED_VALUE_BAL = "storedValueBalance";
  static const String GIFTCARD_STORED_VALUE_BALANCE = "cardStoredValueBalance";
  static const String TRACE_ID = "traceID";
  static const String ISSUE_DATE = "IssueDate";
  static const String GIFTCARD_EFFECTIVE_DATE = "EffectiveDate";
  static const String GIFTCARD_MEMBERSHIP_STATUS = "MembershipStatusCode";
}

class TransactionType {
  static const String PREAUTH = "100";
  static const String SALES = "200";
  static const String REFUND = "400";
  static const String VOID = "300";
  static const String REVERSE = "100400";
  static const String QUICK_PAY = "71001";
  static const String UNIFIED_ORDER = "72001";
  static const String EWALLET_VOID = "81002";
}

class TransactionState {
  // Transaction List Item State
  static const String STATE_REQUESTED = "1";
  static const String STATE_SUCCESS = "2";
  static const String STATE_AUTHORIZED = "3";
  static const String STATE_REVERSED = "4";
  static const String STATE_DENIED = "5";
  static const String STATE_REFUNDED = "11";
  static const String STATE_SETTLEMENT_SUBMITTED = "6";
  static const String STATE_SETTLED = "7";
  static const String STATE_SETTLEMENT_REJECTED = "8";
  static const String STATE_VOIDED = "12";
  static const String STATE_ORDER_CLOSED = "78";
  static const String STATE_USER_PAYING = "71";
  static const int COMEFROMLIST = 1;
  static const int COMEFROMDIGITALPAYMENT = 0;
  static const int COMEFROMVOID = 2;
}

class EWallet {
  static const String Alipay = "Alipay";
  static const String WeChat = "WeChat";
  static const String Uniqgift = "Uniqgift";
  static const String BluePayment = "Blue Payment";
  static const String Atome = "Atome";
  static const String GrabPay = "GrabPay";
  static const String QuickPass = "QuickPass";
  static const String PayNow = "PayNow";
  static const String Dash = "Dash";
  static const String SingtelDash = "Dash";
  static const String Shopee = "Shopee";
  static const String ShopeePay = "Shopee Pay";
  static const String GiftCard = "Gift Card";
}

class TransactionTypeAFG {
  static const String PREAUTH = "PREAUTH";
  static const String SALE = "SALE";
  static const String SALES = "SALES";
  static const String REFUND = "REFUND";
  static const String VOID = "VOID";
  static const String REVERSE = "REVERSE";
  static const String QUICK_PAY = "QUICK_PAY";
  static const String UNIFIED_ORDER = "UNIFIED_ORDER";
  static const String EWALLET_VOID = "EWALLET_VOID";
  static const String SUBMIT_QUICK_PAY = "SUBMIT_QUICK_PAY";
}

class GiftCardState {
  // Transaction List Item State
  static const String TYPE_GIFT_REDEEM_VALUE = "220";
  static const String TYPE_GIFT_PURCHASE_VALUE = "202";
  static const String TYPE_GIFT_VOID_PURCHASE_VALUE = "202300";
  static const String TYPE_GIFT_VOID_REDEEM_VALUE = "220300";
}

class ResponseType {
  // Transaction List Item State
  static const String STATE_SUCCESS = "0000";
  static const String STATE_SUCCESS_00 = "00";
}

class ResponseMessage {
  static const String INVALID_SIGNATURE = "Invalid Signature";
  static const String SIGNATURE_NOT_FOUND = "Signature not found";
}

class ShowDialogWalletType {
  static const REPORT_PAGE = 0;
  static const DIGITAL_PAYMENT_PAGE = 1;
  static const VOID_PAGE = 2;
}

class GW3TransactionState {
  static const String APPROVED = 'SUCCESS';
  static const String REQUESTED = 'REQUESTED';
  static const String AUTHORIZED = 'AUTHORIZED';
  static const String PENDING = 'PENDING';
  static const String REJECTED = 'REJECTED';
  static const String ERROR = 'ERROR';
  static const String EXPIRED = 'EXPIRED';
  static const String VOIDED = 'VOIDED';
  static const String REFUNDED = 'REFUNDED';
  static const String CAPTURED = 'CAPTURED';
  static const String CANCELLED = 'CANCELLED';
  // static const String CAPTURE_SUBMITTED = 'capture_submitted';
  // static const String CAPTURE_REJECTED = 'capture_rejected';
}

class GW3TransactionType {
  static const String SALE = 'SALE';
  static const String AUTHORIZATION = 'AUTHORIZATION';
  static const String REFUND = 'REFUND';
  static const String QUERY = 'QUERY';
  static const String VOID = 'VOID';
  static const String CAPTURE = 'CAPTURE';
}

class ScanQRVoidType {
  // Transaction List Item State
  static const String STATE_FAIL = "-1";
}

class TerminalSettings {
  static const mcpTerminalId = CommonConstants.textEmpty;
}

class AppLogin {
  // Transaction List Item State
  static const String AFG_APP = "AFG";
  static const String GMG_APP = "GMG";
  static String? cashierID = CommonConstants.textEmpty;
  static bool isO7LiteLogin = true;
}

class AppChannel {
  static const String CHANNEL_CASTLE = "CHANNEL_CASTLE";
  static const String CHANNEL_ANFU = "CHANNEL_ANFU";
  static const String CHANNEL_SUNMI = "CHANNEL_SUNMI";
  static const String CHANNEL_LANDI = "CHANNEL_LANDI";
  static const String CHANNEL_WIZAR_POS = "CHANNEL_WIZAR_POS";
  static const String CHANNEL_COHERENT = "CHANNEL_COHERENT";
  static const String CHANNEL_MOREFUN = "CHANNEL_MOREFUN";
}

class BaseAppO7Lite {
  static bool isDonation = false;
  static bool donationMode = false;
  static bool isLoginPayment = false;
  static bool isLoginCharity = false;

  static String _donationUser = '';
  static String _donationPassword = '';
  static String _paymentUser = '';
  static String _paymentPassword = '';

  static String _encryptKey = 'HmacSHA512';

  /// Centralized HMAC key accessor using build-time `--dart-define`.
  /// Build with: `flutter build apk --dart-define=HMAC_KEY=<secret>`
  static String get hmacKey {
    const key = String.fromEnvironment('HMAC_KEY');
    if (key.isEmpty) throw StateError('HMAC_KEY not configured');
    return key;
  }

  static bool get isDonationMode {
    return donationMode;
  }

  static void setDonationMode(bool donationMode) {
    BaseAppO7Lite.donationMode = donationMode;
  }

  static bool get getIsLoginPayment {
    return isLoginPayment;
  }

  static void setLoginPayment(bool loginPayment) {
    isLoginPayment = loginPayment;
  }

  static bool get isLoginDonation {
    return isLoginCharity;
  }

  static void setLoginDonation(bool loginCharity) {
    isLoginCharity = loginCharity;
  }

  static bool get getIsDonation {
    return isDonation;
  }

  static void setDonation(bool isDonation) {
    BaseAppO7Lite.isDonation = isDonation;
  }

  static String get getDonationUser {
    return _donationUser;
  }

  static void setDonationUser(String donationUser) {
    _donationUser = donationUser;
  }

  static String get getDonationPassword {
    return _donationPassword;
  }

  static void setDonationPassword(String donationPassword) {
    _donationPassword = donationPassword;
  }

  static String get getPaymentUser {
    return _paymentUser;
  }

  static void setPaymentUser(String paymentUser) {
    _paymentUser = paymentUser;
  }

  static String get getPaymentPassword {
    return _paymentPassword;
  }

  static void setPaymentPassword(String paymentPassword) {
    _paymentPassword = paymentPassword;
  }

  static String get getEncryptKey {
    return _encryptKey;
  }

  static void setEncryptKey(String encryptKey) {
    _encryptKey = encryptKey;
  }
}
