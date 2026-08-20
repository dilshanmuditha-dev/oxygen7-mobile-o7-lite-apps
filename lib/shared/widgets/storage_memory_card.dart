// Storage/Memory Card Widget - Displays storage or memory info with progress bar
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/app_controller.dart';
import 'package:app/shared/constants/colors.dart';
import '../services/diagnostics/models/diagnostic_models.dart';
import '../services/diagnostics/utils/formatters.dart';

class StorageMemoryCard extends StatelessWidget {
  final String title;
  final int totalBytes;
  final int usedBytes;
  final int freeBytes;
  final double usagePercentage;
  final DiagnosticStatus status;
  final VoidCallback? onRefresh;

  const StorageMemoryCard({
    Key? key,
    required this.title,
    required this.totalBytes,
    required this.usedBytes,
    required this.freeBytes,
    required this.usagePercentage,
    required this.status,
    this.onRefresh,
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
                if (onRefresh != null)
                  IconButton(
                    icon: Icon(
                      Icons.refresh,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                      size: 20,
                    ),
                    onPressed: onRefresh,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: usagePercentage / 100,
                backgroundColor:
                    isDark ? Colors.grey[700] : const Color(0xFFE5E7EB),
                valueColor: AlwaysStoppedAnimation<Color>(_getProgressColor()),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            // Usage info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInfoItem(
                  'storageUsed'.tr,
                  formatBytes(usedBytes),
                  isDark,
                ),
                _buildInfoItem(
                  'storageFree'.tr,
                  formatBytes(freeBytes),
                  isDark,
                ),
                _buildInfoItem(
                  'total'.tr,
                  formatBytes(totalBytes),
                  isDark,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Status message
            if (status == DiagnosticStatus.warning ||
                status == DiagnosticStatus.critical)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: status == DiagnosticStatus.critical
                      ? const Color(0xFFFEE2E2)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      status == DiagnosticStatus.critical
                          ? Icons.error_outline
                          : Icons.warning_amber_outlined,
                      size: 16,
                      color: status == DiagnosticStatus.critical
                          ? const Color(0xFFDC2626)
                          : const Color(0xFFD97706),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      status == DiagnosticStatus.critical
                          ? 'storageCriticallyLowSpace'.tr
                          : 'storageLowSpaceWarning'.tr,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: status == DiagnosticStatus.critical
                            ? const Color(0xFFDC2626)
                            : const Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Open Sans',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF382F41),
          ),
        ),
      ],
    );
  }

  Color _getProgressColor() {
    switch (status) {
      case DiagnosticStatus.good:
        return const Color(0xFF10B981);
      case DiagnosticStatus.warning:
        return const Color(0xFFF59E0B);
      case DiagnosticStatus.critical:
      case DiagnosticStatus.error:
        return const Color(0xFFF75145);
      default:
        return const Color(0xFF7E01D7);
    }
  }
}
