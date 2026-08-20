import 'package:app/shared/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/responsive_util.dart';
import '../../app_controller.dart';

class TransactionHistoryShimmer extends StatelessWidget {
  final AppController appController = Get.find();

  TransactionHistoryShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: appController.isDarkModeOn.value
          ? Colors.grey[800]!
          : ColorConstants.backgroundColorButtonPrint.withAlpha(30),
      highlightColor: appController.isDarkModeOn.value
          ? Colors.grey[500]!
          : ColorConstants.backgroundColorButtonPrint.withAlpha(10),
      child: Column(
        children: [
          // Date selection row
          Row(
            children: [
              Expanded(
                child: Container(
                  height: ResponsiveUtil().getSize(45),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              SizedBox(width: ResponsiveUtil().getSize(20)),
              Expanded(
                child: Container(
                  height: ResponsiveUtil().getSize(45),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtil().getSize(26)),
          // Transaction list items
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 6, // Show 6 shimmer items
            itemBuilder: (context, index) {
              return Padding(
                padding: ResponsiveUtil().getPadding(bottom: 10),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      width: .6,
                      color: Colors.white,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Brand logo placeholder
                      Container(
                        width: ResponsiveUtil().getSize(50),
                        height: ResponsiveUtil().getSize(50),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Transaction ID placeholder
                            Container(
                              width: double.infinity,
                              height: ResponsiveUtil().getSize(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Status placeholder
                            Container(
                              width: ResponsiveUtil().getSize(80),
                              height: ResponsiveUtil().getSize(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            SizedBox(height: 8),
                            // Time placeholder
                            Container(
                              width: ResponsiveUtil().getSize(120),
                              height: ResponsiveUtil().getSize(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 16),
                      // Amount placeholder
                      Container(
                        width: ResponsiveUtil().getSize(80),
                        height: ResponsiveUtil().getSize(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
