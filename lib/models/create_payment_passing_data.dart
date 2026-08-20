class CreatePaymentPassingData {
  final String? qrURL;
  final String? amount;
  final String? currency;
  final String? description;
  final String? serviceChargeAmount;
  final List<String>? supportedCurrencies;

  CreatePaymentPassingData({
    required this.qrURL,
    required this.amount,
    required this.currency,
    required this.description,
    required this.serviceChargeAmount,
    this.supportedCurrencies,
  });
}
