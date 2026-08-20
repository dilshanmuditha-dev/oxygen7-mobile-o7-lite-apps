// Test Result Card Widget - Displays individual test results with recommendations
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:app/app_controller.dart';
import 'package:app/shared/constants/colors.dart';
import '../services/diagnostics/models/diagnostic_models.dart';

class TestResultCard extends StatelessWidget {
  final String testName;
  final bool passed;
  final String? errorMessage;
  final List<String> recommendations;
  final Duration? duration;

  const TestResultCard({
    Key? key,
    required this.testName,
    required this.passed,
    this.errorMessage,
    this.recommendations = const [],
    this.duration,
  }) : super(key: key);

  factory TestResultCard.fromTestResult(TestResult result) {
    return TestResultCard(
      testName: result.testName,
      passed: result.passed,
      errorMessage: result.errorMessage,
      recommendations: result.recommendations,
      duration: result.duration,
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppController appController = Get.find();
    final isDark = appController.isDarkModeOn.value;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? ColorConstants.grey800?.withOpacity(0.5) ?? Colors.grey[800]
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: passed
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFF75145).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: passed ? const Color(0xFF10B981) : const Color(0xFFF75145),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              passed ? Icons.check : Icons.close,
              color: Colors.white,
              size: 18,
            ),
          ),
          title: Text(
            testName,
            style: TextStyle(
              fontFamily: 'Open Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF382F41),
            ),
          ),
          subtitle: duration != null
              ? Text(
                  '${duration!.inMilliseconds}ms',
                  style: TextStyle(
                    fontFamily: 'Open Sans',
                    fontSize: 12,
                    color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
                  ),
                )
              : null,
          trailing: Icon(
            Icons.expand_more,
            color: isDark ? Colors.white60 : const Color(0xFF9CA3AF),
          ),
          children: [
            if (!passed && errorMessage != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: Color(0xFFDC2626),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(
                          fontFamily: 'Open Sans',
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.blue.withOpacity(0.1)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'diagnosticRecommendations'.tr,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark ? Colors.blue[200] : const Color(0xFF1D4ED8),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ...recommendations.map((rec) => Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontFamily: 'Open Sans',
                                  fontSize: 12,
                                  color: isDark
                                      ? Colors.blue[200]
                                      : const Color(0xFF3B82F6),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  rec,
                                  style: TextStyle(
                                    fontFamily: 'Open Sans',
                                    fontSize: 12,
                                    color: isDark
                                        ? Colors.blue[200]
                                        : const Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
            if (passed && recommendations.isEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 16,
                      color: Color(0xFF059669),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'diagnosticTestPassed'.tr,
                      style: TextStyle(
                        fontFamily: 'Open Sans',
                        fontSize: 12,
                        color: Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
