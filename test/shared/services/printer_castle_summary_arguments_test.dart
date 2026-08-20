import 'dart:convert';

import 'package:app/models/response/transaction_summary_AFG_response/transaction_summary_AFG_response.dart';
import 'package:app/models/response/transaction_summary_list_response/transaction_summary_list_response.dart';
import 'package:app/shared/services/printer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Castle summary arguments include direct summaryData JSON', () {
    final summary = TransactionSummaryAFGResponse(
      totalCount: 1,
      totalPayAmount: 100,
      totalPayCount: 1,
      totalVoidAmount: 0,
      totalVoidCount: 0,
      totalRefundAmount: 0,
      totalRefundCount: 0,
      transactionList: [
        TransactionSummaryListResponse(
          type: 'SALE',
          responseCode: '00',
          currency: 'SGD',
          brandName: 'Visa',
          gatewayResponseDate: '2026-06-26T10:00:00',
          mcpTerminalId: '12345678',
          totalAmount: 100,
        ),
      ],
    );

    final arguments = Printer.buildCastleSummaryReportArguments(
      brand: 'Visa Daily Summary',
      acquirer: 'gw3Host',
      currency: 'SGD',
      startDate: '20260626000000',
      endDate: '20260626235959',
      mcpTerminalId: '12345678',
      signature: 'signature',
      dataSource: summary,
    );

    expect(arguments['brand'], 'Visa Daily Summary');
    expect(arguments['acquirer'], 'gw3Host');
    expect(arguments['summaryData'], isA<String>());

    final decoded = jsonDecode(arguments['summaryData'] as String);
    expect(decoded['totalCount'], 1);
    expect(decoded['transactionList'], isA<List<dynamic>>());
    expect(decoded['transactionList'][0]['type'], 'SALE');
  });
}
