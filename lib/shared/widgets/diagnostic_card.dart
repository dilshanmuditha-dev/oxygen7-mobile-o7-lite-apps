// Diagnostic Card Widget - Reusable card for displaying diagnostic information
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/app_controller.dart';
import 'package:app/shared/constants/colors.dart';
import '../services/diagnostics/models/diagnostic_models.dart';

class DiagnosticCard extends StatelessWidget {
  final String title;
  final Widget content;
  final DiagnosticStatus status;
  final VoidCallback? onTest;
  final String? testButtonText;
  final bool showStatusIndicator;

  const DiagnosticCard({
    Key? key,
    required this.title,
    required this.content,
    this.status = DiagnosticStatus.unknown,
    this.onTest,
    this.testButtonText,
    this.showStatusIndicator = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    final isDark = appController.isDarkModeOn.value;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? ColorConstants.grey800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF4A5568) : const Color(0xFFCFD3D0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF382F41),
                  ),
                ),
                if (showStatusIndicator) _buildStatusIndicator(isDark),
              ],
            ),
            const SizedBox(height: 12),
            content,
            if (onTest != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: onTest,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7E01D7),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text(
                    testButtonText ?? 'diagnosticTestBtn'.tr,
                    style: const TextStyle(
                      fontFamily: 'Open Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(bool isDark) {
    Color color;
    IconData icon;

    switch (status) {
      case DiagnosticStatus.good:
        color = const Color(0xFF10B981);
        icon = Icons.check_circle;
        break;
      case DiagnosticStatus.warning:
        color = const Color(0xFFF59E0B);
        icon = Icons.warning;
        break;
      case DiagnosticStatus.critical:
        color = const Color(0xFFF75145);
        icon = Icons.error;
        break;
      case DiagnosticStatus.error:
        color = const Color(0xFFF75145);
        icon = Icons.cancel;
        break;
      case DiagnosticStatus.unknown:
        color = isDark ? Colors.grey : const Color(0xFF9CA3AF);
        icon = Icons.help_outline;
        break;
    }

    return Icon(icon, color: color, size: 24);
  }
}
