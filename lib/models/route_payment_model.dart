class RoutePaymentModel {
  final String image;
  final String? imageOnTap;
  final String acquireReport;
  final bool isActivated;
  final String? currency;
  final List<String>? supportedCurrencies;
  final String? acquirer;
  final String? creditCardActivated;
  final bool? isBoost;
  final String? acquirerVoid;
  final String? acquirerDigital;
  final String? title;
  final String? brand;

  RoutePaymentModel({
    required this.image,
    required this.acquireReport,
    required this.isActivated,
    this.currency,
    this.supportedCurrencies,
    this.imageOnTap,
    this.isBoost,
    this.creditCardActivated,
    this.acquirer,
    this.acquirerDigital,
    this.acquirerVoid,
    this.title,
    this.brand,
  });
}
