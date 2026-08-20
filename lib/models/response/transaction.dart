import 'package:json_annotation/json_annotation.dart';

part 'transaction.g.dart';

/// GW3 Transaction data model
@JsonSerializable()
class Transaction {
  @JsonKey(name: 'oxpay_txn_id')
  final String? oxpayTxnId;

  @JsonKey(name: 'merchant_reference_id')
  final String? merchantReferenceId;

  @JsonKey(name: 'host_txn_id')
  final String? hostTxnId;

  @JsonKey(name: 'transaction_state')
  final String? transactionState;

  @JsonKey(name: 'transaction_type')
  final String? transactionType;

  @JsonKey(name: 'transaction_datetime')
  final String? transactionDatetime;

  @JsonKey(name: 'payment_brand')
  final String? paymentBrand;

  @JsonKey(name: 'transaction_amount')
  final int? transactionAmount;

  @JsonKey(name: 'transaction_currency')
  final String? transactionCurrency;

  @JsonKey(name: 'is_allow_void')
  final bool? isAllowVoid;

  @JsonKey(name: 'is_allow_refund')
  final bool? isAllowRefund;

  @JsonKey(name: 'description')
  final String? description;

  Transaction({
    required this.oxpayTxnId,
    this.merchantReferenceId,
    this.hostTxnId,
    this.transactionState,
    this.transactionType,
    this.transactionDatetime,
    this.paymentBrand,
    this.transactionAmount,
    this.transactionCurrency,
    this.isAllowVoid,
    this.isAllowRefund,
    this.description,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}
