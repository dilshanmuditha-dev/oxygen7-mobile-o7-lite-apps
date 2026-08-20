import 'package:app/shared/shared.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shimmer/shimmer.dart';
import '../utils/responsive_util.dart';
import '../../app_controller.dart';

class ShimmerLoading extends StatelessWidget {
  final AppController appController = Get.find();

  ShimmerLoading({Key? key}) : super(key: key);

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
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                SizedBox(height: 24),
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 20,
                  crossAxisSpacing: 20,
                  childAspectRatio: 1.2,
                  children: List.generate(
                    4,
                    (index) => Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: ResponsiveUtil().getSize(78),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                SizedBox(width: 24),
                Expanded(
                  child: Container(
                    height: ResponsiveUtil().getSize(78),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30),
          // Padding(
          //   padding: EdgeInsets.symmetric(horizontal: 24),
          //   child: Row(
          //     children: [
          //       Expanded(
          //         child: Container(
          //           height: ResponsiveUtil().getSize(78),
          //           decoration: BoxDecoration(
          //             color: Colors.white,
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //         ),
          //       ),
          //       SizedBox(width: 24),
          //       Expanded(
          //         child: Container(
          //           height: ResponsiveUtil().getSize(78),
          //           decoration: BoxDecoration(
          //             color: Colors.white,
          //             borderRadius: BorderRadius.circular(8),
          //           ),
          //         ),
          //       ),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }
}
