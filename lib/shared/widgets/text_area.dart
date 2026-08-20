// ignore_for_file: library_private_types_in_public_api, must_be_immutable, overridden_fields

import 'package:app/modules/main/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../app_controller.dart';
import '../constants/colors.dart';
import '../constants/common.dart';
import '../utils/responsive_util.dart';
import 'custom_text_style.dart';

class TextArea extends StatefulWidget {
  @override
  _BodyState createState() => _BodyState();

  final TextEditingController textEditingController;
  final IconData? suffixIcon;
  final Color? borderColor;
  final double? borderRadius;
  final int? maxLength;
  final bool digitsOnly;
  final String? errorText;
  @override
  Key? key;

  TextArea({
    Key? key,
    this.digitsOnly = false,
    required this.textEditingController,
    this.suffixIcon,
    required this.borderColor,
    this.borderRadius,
    this.errorText,
    this.maxLength,
  }) : super(key: key);
}

class _BodyState extends State<TextArea> {
  var reasonErrorVisibility = false;
  Color? borderColor;
  AppController appController = Get.find();
  HomeController homeController = Get.find();
  @override
  void initState() {
    borderColor = widget.borderColor;
    widget.textEditingController.text = homeController.getCarplaceNumber.value;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: ResponsiveUtil().getSize(120),
          decoration: BoxDecoration(
            color: appController.isDarkModeOn.value
                ? ColorConstants.grey800!
                : ColorConstants.white,
            border: Border.all(
              color: appController.isDarkModeOn.value
                  ? ColorConstants.white
                  : Colors.grey.withOpacity(0.4),
              width: .6,
            ),
            borderRadius: BorderRadius.circular(
              8,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 8.0, right: 8.0),
                  child: TextFormField(
                    style: TextStyle(
                      fontSize: ResponsiveUtil().getFontSize(
                        16,
                      ),
                      color: appController.isDarkModeOn.value
                          ? ColorConstants.white
                          : ColorConstants.black,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: CommonConstants.itemDescription.tr,
                      hintStyle: CustomTextStyles.labelGray600Size16Fw400,
                    ),
                    keyboardType: widget.digitsOnly
                        ? TextInputType.number
                        : TextInputType.multiline,
                    textInputAction: TextInputAction.done,
                    minLines: 2,
                    maxLines: 5,
                    controller: widget.textEditingController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (value) {
                      setState(() {});
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return widget.errorText;
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: ResponsiveUtil().getSize(8)),
        Align(
          alignment: Alignment.topRight,
          child: Text(
            '${widget.textEditingController.text.length}/${widget.maxLength}',
            style: CustomTextStyles.labelBlack500Size12Fw400,
          ),
        ),
      ],
    );
  }
}
