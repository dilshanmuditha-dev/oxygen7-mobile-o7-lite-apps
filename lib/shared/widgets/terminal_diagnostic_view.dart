import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/shared/services/diagnostics/models/diagnostic_models.dart';

/// Terminal-style diagnostic view that displays test results like a CLI
class TerminalDiagnosticView extends StatefulWidget {
  final List<TerminalLine> lines;
  final bool isRunning;
  final String? currentCommand;
  final ScrollController? scrollController;

  const TerminalDiagnosticView({
    Key? key,
    required this.lines,
    this.isRunning = false,
    this.currentCommand,
    this.scrollController,
  }) : super(key: key);

  @override
  State<TerminalDiagnosticView> createState() => _TerminalDiagnosticViewState();
}

class _TerminalDiagnosticViewState extends State<TerminalDiagnosticView>
    with SingleTickerProviderStateMixin {
  late AnimationController _cursorController;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _cursorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    _cursorController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  void didUpdateWidget(TerminalDiagnosticView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Auto-scroll to bottom when new lines are added
    if (widget.lines.length > oldWidget.lines.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF3C3C3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Terminal header
          _buildTerminalHeader(),
          // Terminal content
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...widget.lines.map((line) => _buildTerminalLine(line)),
                  if (widget.isRunning && widget.currentCommand != null)
                    _buildCurrentCommand(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF2D2D2D),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(8),
          topRight: Radius.circular(8),
        ),
      ),
      child: Row(
        children: [
          // Traffic light buttons
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5F56),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFFFFBD2E),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF27C93F),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'diagnosticTerminalTitle'.tr,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Color(0xFF9D9D9D),
            ),
          ),
          const Spacer(),
          if (widget.isRunning)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF27C93F)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTerminalLine(TerminalLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (line.showPrompt) ...[
            const Text(
              '\$ ',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: Color(0xFF27C93F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
                ),
                children: _buildTextSpans(line),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<TextSpan> _buildTextSpans(TerminalLine line) {
    final spans = <TextSpan>[];

    switch (line.type) {
      case TerminalLineType.command:
        spans.add(TextSpan(
          text: line.text,
          style: const TextStyle(color: Color(0xFFE5E5E5)),
        ));
        break;

      case TerminalLineType.info:
        spans.add(TextSpan(
          text: line.text,
          style: const TextStyle(color: Color(0xFF9D9D9D)),
        ));
        break;

      case TerminalLineType.success:
        spans.add(const TextSpan(
          text: '✓ ',
          style: TextStyle(color: Color(0xFF27C93F)),
        ));
        spans.add(TextSpan(
          text: line.text,
          style: const TextStyle(color: Color(0xFF27C93F)),
        ));
        break;

      case TerminalLineType.error:
        spans.add(const TextSpan(
          text: '✗ ',
          style: TextStyle(color: Color(0xFFFF5F56)),
        ));
        spans.add(TextSpan(
          text: line.text,
          style: const TextStyle(color: Color(0xFFFF5F56)),
        ));
        break;

      case TerminalLineType.warning:
        spans.add(const TextSpan(
          text: '⚠ ',
          style: TextStyle(color: Color(0xFFFFBD2E)),
        ));
        spans.add(TextSpan(
          text: line.text,
          style: const TextStyle(color: Color(0xFFFFBD2E)),
        ));
        break;

      case TerminalLineType.progress:
        spans.add(TextSpan(
          text: '  ${line.text}',
          style: const TextStyle(color: Color(0xFF6A9FB5)),
        ));
        break;

      case TerminalLineType.result:
        spans.add(TextSpan(
          text: '  → ${line.text}',
          style: const TextStyle(color: Color(0xFFB294BB)),
        ));
        break;

      case TerminalLineType.header:
        spans.add(TextSpan(
          text: '\n═══ ${line.text} ═══\n',
          style: const TextStyle(
            color: Color(0xFF7E01D7),
            fontWeight: FontWeight.bold,
          ),
        ));
        break;

      case TerminalLineType.divider:
        spans.add(const TextSpan(
          text: '────────────────────────────────',
          style: TextStyle(color: Color(0xFF4A4A4A)),
        ));
        break;
    }

    return spans;
  }

  Widget _buildCurrentCommand() {
    return Row(
      children: [
        const Text(
          '\$ ',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFF27C93F),
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          widget.currentCommand!,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            color: Color(0xFFE5E5E5),
          ),
        ),
        AnimatedBuilder(
          animation: _cursorController,
          builder: (context, child) {
            return Opacity(
              opacity: _cursorController.value,
              child: const Text(
                '█',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 13,
                  color: Color(0xFFE5E5E5),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Represents a single line in the terminal output
class TerminalLine {
  final String text;
  final TerminalLineType type;
  final bool showPrompt;
  final DateTime timestamp;

  TerminalLine({
    required this.text,
    this.type = TerminalLineType.info,
    this.showPrompt = false,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  /// Create a command line (with $ prompt)
  factory TerminalLine.command(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.command,
        showPrompt: true,
      );

  /// Create an info line
  factory TerminalLine.info(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.info,
      );

  /// Create a success line
  factory TerminalLine.success(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.success,
      );

  /// Create an error line
  factory TerminalLine.error(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.error,
      );

  /// Create a warning line
  factory TerminalLine.warning(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.warning,
      );

  /// Create a progress line
  factory TerminalLine.progress(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.progress,
      );

  /// Create a result line
  factory TerminalLine.result(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.result,
      );

  /// Create a header line
  factory TerminalLine.header(String text) => TerminalLine(
        text: text,
        type: TerminalLineType.header,
      );

  /// Create a divider line
  factory TerminalLine.divider() => TerminalLine(
        text: '',
        type: TerminalLineType.divider,
      );

  /// Create from TestResult
  factory TerminalLine.fromTestResult(TestResult result) {
    if (result.passed) {
      return TerminalLine.success(
        '${result.testName}: PASSED (${result.duration.inMilliseconds}ms)',
      );
    } else {
      return TerminalLine.error(
        '${result.testName}: FAILED - ${result.errorMessage ?? "Unknown error"}',
      );
    }
  }
}

/// Types of terminal lines
enum TerminalLineType {
  command,
  info,
  success,
  error,
  warning,
  progress,
  result,
  header,
  divider,
}
