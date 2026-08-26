import '../../models/route_payment_model.dart';
import '../constants/constants_o7lite.dart';
import 'package:app/shared/constants/image_constant.dart';
import 'package:app/shared/utils/responsive_util.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

import '../widgets/custom_text_style.dart';

export 'focus.dart';
export 'regex.dart';

/// Maps OxPay transaction state strings to their corresponding integer codes
/// Based on GW2 to GW3 transaction state mapping
int mapTransactionState(String state) {
  switch (state.toLowerCase()) {
    case 'requested':
      return int.parse(TransactionState.STATE_REQUESTED);
    case 'success':
    case 'approved':
      return int.parse(TransactionState.STATE_SUCCESS);
    case 'authorized':
      return int.parse(TransactionState.STATE_AUTHORIZED);
    case 'voided':
      return int.parse(TransactionState.STATE_VOIDED);
    case 'rejected':
    case 'denied':
      return int.parse(TransactionState.STATE_DENIED);
    case 'capture_submitted':
      return int.parse(TransactionState.STATE_SETTLEMENT_SUBMITTED);
    case 'captured':
    case 'settled':
      return int.parse(TransactionState.STATE_SETTLED);
    case 'capture_rejected':
      return int.parse(TransactionState.STATE_SETTLEMENT_REJECTED);
    case 'refunded':
      return int.parse(TransactionState.STATE_REFUNDED);
    case 'order_closed':
      return int.parse(TransactionState.STATE_ORDER_CLOSED);
    case 'pending':
    case 'user_paying':
      return int.parse(TransactionState.STATE_USER_PAYING);
    default:
      return int.parse(
          TransactionState.STATE_REQUESTED); // Default to REQUESTED state
  }
}

/// Maps OxPay transaction type strings to their corresponding integer codes
int mapTransactionType(String type) {
  switch (type.toLowerCase()) {
    case 'preauth':
    case 'authorization':
      return int.parse(TransactionType.PREAUTH); // 100
    case 'sale':
    case 'sales':
      return int.parse(TransactionType.SALES); // 200
    case 'refund':
      return int.parse(TransactionType.REFUND); // 400
    case 'void':
      return int.parse(TransactionType.VOID); // 300
    case 'reverse':
    case 'authorization_reversal':
      return int.parse(TransactionType.REVERSE); // 100400
    case 'quick_pay':
    case 'submit_quick_pay':
      return int.parse(TransactionType.QUICK_PAY); // 71001
    case 'unified_order':
      return int.parse(TransactionType.UNIFIED_ORDER); // 72001
    case 'ewallet_void':
      return int.parse(TransactionType.EWALLET_VOID); // 81002
    default:
      return int.parse(TransactionType.SALES); // Default to SALES (200)
  }
}

/// Brand keyword patterns for fuzzy matching
/// Each entry contains keywords that identify a brand, ordered by specificity (most specific first)
final List<_BrandPattern> _brandPatterns = [
  // Demo build: Ripple is the only wallet the app offers.
  _BrandPattern(
    keywords: ['ripple', 'xrp'],
    getImage: (_) => ImageConstant.imageRipple,
  ),
  // ---- Malaysia (MY) specific brand variants ----
  // These must be checked BEFORE the generic patterns below because they
  // share the same prefixes (grab, shopback, tng) and would otherwise be
  // matched by the more generic entries first.
  _BrandPattern(
    keywords: ['grabpaymy'],
    getImage: (_) => ImageConstant.imageGrabPayMY,
  ),
  _BrandPattern(
    keywords: ['shopeemy'],
    getImage: (_) => ImageConstant.imageShopeeMY,
  ),
  _BrandPattern(
    keywords: ['shopbackmy'],
    getImage: (_) => ImageConstant.iconShopback,
  ),
  _BrandPattern(
    keywords: ['tngdduitnowqr'],
    getImage: (_) => ImageConstant.imageTouchNGoDuitnow,
  ),
  // Touch 'n Go - check before generic patterns
  _BrandPattern(
    keywords: ['touchngo', 'touch_n_go', 'tng', 'touchandgo'],
    getImage: (_) => ImageConstant.iconTouchNGoEWallet,
  ),
  // Alipay
  _BrandPattern(
    keywords: ['alipay', 'ali_pay'],
    getImage: (_) => ImageConstant.imageAlipay,
  ),
  // WeChat
  _BrandPattern(
    keywords: ['wechat', 'we_chat', 'weixin'],
    getImage: (_) => ImageConstant.imageWechatPay,
  ),
  // GrabPay - location dependent
  _BrandPattern(
    keywords: ['grab', 'grabpay'],
    getImage: (isSGP) =>
        isSGP ? ImageConstant.imageGrabPay : ImageConstant.imageGrabPayMY,
    // isSGP ? ImageConstant.imageGrabPay : ImageConstant.imageGrabPayMY,
  ),
  // Card brands - check specific ones first
  _BrandPattern(
    keywords: ['mastercard', 'master_card', 'master'],
    getImage: (_) => ImageConstant.iconMasterCardTxn,
  ),
  _BrandPattern(
    keywords: ['visa'],
    getImage: (_) => ImageConstant.iconVisaTxn,
  ),
  _BrandPattern(
    keywords: ['amex', 'american_express', 'americanexpress'],
    getImage: (_) => ImageConstant.iconAmexTxn,
  ),
  _BrandPattern(
    keywords: ['diners', 'diner'],
    getImage: (_) => ImageConstant.iconDinersTxn,
  ),
  _BrandPattern(
    keywords: ['discover'],
    getImage: (_) => ImageConstant.iconDiscoverTxn,
  ),
  _BrandPattern(
    keywords: ['rupay', 'ru_pay'],
    getImage: (_) => ImageConstant.iconDiscoverTxn,
  ),
  // E-wallets and QR payments
  _BrandPattern(
    keywords: ['atome'],
    getImage: (_) => ImageConstant.imageAtome,
  ),
  _BrandPattern(
    keywords: ['thaiqr', 'thai_qr', 'promptpay'],
    getImage: (_) => ImageConstant.imageThaiQR,
  ),
  _BrandPattern(
    keywords: ['paynow', 'pay_now'],
    getImage: (_) => ImageConstant.imagePaynow,
  ),
  _BrandPattern(
    keywords: ['quickpass', 'quick_pass', 'unionpay', 'cup'],
    getImage: (_) => ImageConstant.iconCupTxn,
  ),
  _BrandPattern(
    keywords: ['enets', 'e_nets'],
    getImage: (_) => ImageConstant.iconMCPTxn,
  ),
  _BrandPattern(
    keywords: ['dash', 'singtel'],
    getImage: (_) => ImageConstant.imageSingleDash,
  ),
  _BrandPattern(
    keywords: ['boost'],
    getImage: (_) => ImageConstant.imageBoost,
  ),
  _BrandPattern(
    keywords: ['shopee', 'shopeepay'],
    getImage: (_) => ImageConstant.imageShopeePay,
  ),
  _BrandPattern(
    keywords: ['ioupay', 'iou_pay', 'iou'],
    getImage: (_) => ImageConstant.imageIOUPay,
  ),
  _BrandPattern(
    keywords: ['shopback', 'shop_back'],
    getImage: (_) => ImageConstant.iconShopbackWhiteBg,
  ),
  _BrandPattern(
    keywords: ['upi'],
    getImage: (_) => ImageConstant.iconUPI2,
  ),
  // DuitNow - check after TNG since TNG DuitNow should match TNG first
  _BrandPattern(
    keywords: ['duitnow', 'duit_now'],
    getImage: (_) => ImageConstant.imageTouchNGoDuitnow,
  ),
];

/// Helper class for brand pattern matching
class _BrandPattern {
  final List<String> keywords;
  final String Function(bool isSGPLocation) getImage;

  const _BrandPattern({required this.keywords, required this.getImage});

  /// Check if the brand name contains any of the keywords
  bool matches(String normalizedBrand) {
    for (final keyword in keywords) {
      if (normalizedBrand.contains(keyword)) {
        return true;
      }
    }
    return false;
  }
}

/// Normalizes brand name for matching by removing special characters and converting to lowercase
String _normalizeBrandName(String brandName) {
  return brandName
      .toLowerCase()
      .replaceAll(RegExp(r'[-_\s]+'), '') // Remove dashes, underscores, spaces
      .replaceAll(RegExp(r'[^a-z0-9]'), ''); // Keep only alphanumeric
}

/// Returns the appropriate brand image asset path based on the brand name
/// Uses fuzzy matching with keyword patterns to handle variations in brand names
String getBrandImage(String brandName, {bool isSGPLocation = true}) {
  if (brandName.isEmpty) {
    return ImageConstant.oxygen7IconTransparentBackground;
  }

  final normalizedBrand = _normalizeBrandName(brandName);

  // Try fuzzy matching with keyword patterns
  for (final pattern in _brandPatterns) {
    if (pattern.matches(normalizedBrand)) {
      return pattern.getImage(isSGPLocation);
    }
  }

  // Fallback to default icon
  return ImageConstant.oxygen7IconTransparentBackground;
}

/// Returns a widget displaying the brand image
Widget getBrandImageWidget(String brandName,
    {double? height, bool isSGPLocation = true}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.asset(
      getBrandImage(brandName, isSGPLocation: isSGPLocation),
      height: ResponsiveUtil().getSize(height ?? 100),
      fit: BoxFit.cover,
    ),
  );
}

Widget getBrandImageWidgetV2(RoutePaymentModel routePaymentModel,
    {double? height, bool isSGPLocation = true}) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: routePaymentModel.acquirer?.toLowerCase() == 'grabpay-online'
        ? Stack(
            children: [
              Image.asset(
                ImageConstant.imageGrabPay,
                height: ResponsiveUtil().getSize(height ?? 100),
                fit: BoxFit.cover,
              ),
              Positioned(
                top: 5,
                right: -25,
                child: Transform.rotate(
                  angle: 0.785398, // 45 degrees in radians
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Online',
                      style: CustomTextStyles.titleSmallGreen.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Image.asset(
            resolveImageFromModel(routePaymentModel,
                isSGPLocation: isSGPLocation),
            height: ResponsiveUtil().getSize(height ?? 100),
            fit: BoxFit.contain,
          ),
  );
}

/// Resolves the brand image by checking acquirer (host) first for
/// region-specific variants, then falling back to generic brand matching.
String resolveImageFromModel(RoutePaymentModel model,
    {bool isSGPLocation = true}) {
  final acquirer =
      model.acquirer?.toLowerCase() ?? model.acquireReport.toLowerCase() ?? '';

  // Acquirer-specific overrides (host string carries region info)
  if (acquirer == 'grabpay-my') {
    return ImageConstant.imageGrabPayMY;
  }
  if (acquirer == 'shopeepay-my') {
    return ImageConstant.imageShopeeMY;
  }
  if (acquirer == 'shopback-my') {
    return ImageConstant.iconShopback;
  }
  if (acquirer == 'tngdduitnowqr' ||
      acquirer.contains('tngd') && acquirer.contains('duitnow')) {
    return ImageConstant.imageTouchNGoDuitnow;
  }

  // Fallback to brand-based matching
  return getBrandImage(model.brand ?? '', isSGPLocation: isSGPLocation);
}
