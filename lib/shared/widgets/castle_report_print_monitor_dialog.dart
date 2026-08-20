import 'package:app/shared/services/castle_report_print_monitor.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class CastleReportPrintMonitorDialog extends StatefulWidget {
  const CastleReportPrintMonitorDialog({Key? key}) : super(key: key);

  @override
  State<CastleReportPrintMonitorDialog> createState() =>
      _CastleReportPrintMonitorDialogState();
}

class _CastleReportPrintMonitorDialogState
    extends State<CastleReportPrintMonitorDialog> {
  final CastleReportPrintMonitor monitor = CastleReportPrintMonitor.instance;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF3C3C3C)),
          ),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: Obx(() {
                  _scrollToBottom();
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: monitor.entries.length,
                    itemBuilder: (context, index) {
                      return _buildEntry(monitor.entries[index]);
                    },
                  );
                }),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          _trafficLight(const Color(0xFFFF5F56)),
          const SizedBox(width: 8),
          _trafficLight(const Color(0xFFFFBD2E)),
          const SizedBox(width: 8),
          _trafficLight(const Color(0xFF27C93F)),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              'Castle report print monitor',
              style: TextStyle(
                color: Color(0xFFE5E5E5),
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Obx(
            () => monitor.isRunning.value
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFF27C93F)),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF3C3C3C))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(
              () => Text(
                monitor.isRunning.value ? 'Running...' : 'Finished',
                style: const TextStyle(
                  color: Color(0xFF9D9D9D),
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: Get.back,
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(CastleReportPrintMonitorEntry entry) {
    final color = _entryColor(entry.level);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '${_time(entry.timestamp)} ',
              style: const TextStyle(color: Color(0xFF6B7280)),
            ),
            TextSpan(
              text: '[${entry.stage}] ',
              style: const TextStyle(
                color: Color(0xFF9D9D9D),
                fontWeight: FontWeight.w600,
              ),
            ),
            TextSpan(
              text: '${_prefix(entry.level)}${entry.message}',
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trafficLight(Color color) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Color _entryColor(CastleReportPrintMonitorLevel level) {
    switch (level) {
      case CastleReportPrintMonitorLevel.success:
        return const Color(0xFF27C93F);
      case CastleReportPrintMonitorLevel.warning:
        return const Color(0xFFFFBD2E);
      case CastleReportPrintMonitorLevel.error:
        return const Color(0xFFFF5F56);
      case CastleReportPrintMonitorLevel.info:
        return const Color(0xFFE5E5E5);
    }
  }

  String _prefix(CastleReportPrintMonitorLevel level) {
    switch (level) {
      case CastleReportPrintMonitorLevel.success:
        return 'OK ';
      case CastleReportPrintMonitorLevel.warning:
        return 'WARN ';
      case CastleReportPrintMonitorLevel.error:
        return 'ERR ';
      case CastleReportPrintMonitorLevel.info:
        return '';
    }
  }

  String _time(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.hour)}:${twoDigits(value.minute)}:'
        '${twoDigits(value.second)}';
  }
}
