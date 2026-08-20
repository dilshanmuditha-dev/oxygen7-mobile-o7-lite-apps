class ReportModel {
  String? acquirer;
  String? currency;
  String? creditCardActivated;
  bool? isBoost;
  String? brand;

  ReportModel({
    required this.acquirer,
    required this.currency,
    required this.creditCardActivated,
    required this.isBoost,
    this.brand,
  });
}
