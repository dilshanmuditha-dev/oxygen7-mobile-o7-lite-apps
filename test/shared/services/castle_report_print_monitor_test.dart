import 'package:app/shared/services/castle_report_print_monitor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CastleReportPrintMonitor monitor;

  setUp(() {
    monitor = CastleReportPrintMonitor();
    monitor.isEnabled = true;
  });

  test('tracks Castle report print attempt lifecycle', () {
    monitor.startAttempt('Castle report print');
    monitor.addStep('Flutter', 'Print button tapped');
    monitor.addError('Native', 'HTTP 500');
    monitor.finish(success: false, message: 'Stopped after API response');

    expect(monitor.isRunning.value, isFalse);
    expect(monitor.entries.length, 4);
    expect(monitor.entries[0].level, CastleReportPrintMonitorLevel.info);
    expect(monitor.entries[0].message, 'Castle report print');
    expect(monitor.entries[1].stage, 'Flutter');
    expect(monitor.entries[1].message, 'Print button tapped');
    expect(monitor.entries[2].level, CastleReportPrintMonitorLevel.error);
    expect(monitor.entries[2].message, 'HTTP 500');
    expect(monitor.entries[3].level, CastleReportPrintMonitorLevel.error);
    expect(monitor.entries[3].message, 'Stopped after API response');

    monitor.clear();

    expect(monitor.entries, isEmpty);
    expect(monitor.isRunning.value, isFalse);
  });
}
