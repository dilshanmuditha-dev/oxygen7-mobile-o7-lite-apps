import 'package:app/shared/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/responsive_util.dart';
import '../../app_controller.dart';

class TransactionDetailShimmer extends StatelessWidget {
  final AppController appController = Get.find();

  TransactionDetailShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: appController.isDarkModeOn.value
          ? Colors.grey[800]!
          : ColorConstants.backgroundColorButtonPrint.withAlpha(30),
      highlightColor: appController.isDarkModeOn.value
          ? Colors.grey[500]!
          : ColorConstants.backgroundColorButtonPrint.withAlpha(10),
      child: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Padding(
            padding: ResponsiveUtil().getPadding(all: 12),
            child: Column(
              children: [
                // Brand logo placeholder
                Container(
                  width: ResponsiveUtil().getSize(100),
                  height: ResponsiveUtil().getSize(100),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(10)),
                // Merchant name placeholder
                Container(
                  width: ResponsiveUtil().getSize(200),
                  height: ResponsiveUtil().getSize(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(10)),
                // Address placeholder
                Container(
                  width: ResponsiveUtil().getSize(250),
                  height: ResponsiveUtil().getSize(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                SizedBox(height: ResponsiveUtil().getSize(10)),
                Divider(color: Colors.white),
                // Transaction type and state
                _buildRow(
                  height: ResponsiveUtil().getSize(30),
                  leftWidth: ResponsiveUtil().getSize(150),
                  rightWidth: ResponsiveUtil().getSize(100),
                ),
                Divider(color: Colors.white),
                // Time
                _buildRow(
                  height: ResponsiveUtil().getSize(21),
                  leftWidth: ResponsiveUtil().getSize(80),
                  rightWidth: ResponsiveUtil().getSize(180),
                ),
                Divider(color: Colors.white),
                // Item description
                _buildRow(
                  height: ResponsiveUtil().getSize(21),
                  leftWidth: ResponsiveUtil().getSize(120),
                  rightWidth: ResponsiveUtil().getSize(150),
                ),
                Divider(color: Colors.white),
                // Total amount
                _buildRow(
                  height: ResponsiveUtil().getSize(32),
                  leftWidth: ResponsiveUtil().getSize(80),
                  rightWidth: ResponsiveUtil().getSize(120),
                ),
                Divider(color: Colors.white),
                // Terminal ID
                _buildRow(
                  height: ResponsiveUtil().getSize(28),
                  leftWidth: ResponsiveUtil().getSize(100),
                  rightWidth: ResponsiveUtil().getSize(150),
                ),
                Divider(color: Colors.white),
                // Transaction ID
                _buildRow(
                  height: ResponsiveUtil().getSize(23),
                  leftWidth: ResponsiveUtil().getSize(120),
                  rightWidth: ResponsiveUtil().getSize(180),
                ),
                SizedBox(height: ResponsiveUtil().getSize(20)),
                // Barcode placeholder
                Container(
                  width: ResponsiveUtil().getSize(200),
                  height: ResponsiveUtil().getSize(80),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required double height,
    required double leftWidth,
    required double rightWidth,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: leftWidth,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          Container(
            width: rightWidth,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
