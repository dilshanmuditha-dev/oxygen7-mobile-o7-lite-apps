// ignore_for_file: deprecated_member_use, must_be_immutable

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/colors.dart';
import '../utils/responsive_util.dart';
import '../widgets/normal_button.dart';

class BottomBarItem {
  BottomBarItem({this.iconData, this.text, this.isDarkMode});
  String? iconData;
  String? text;
  bool? isDarkMode = false;
}

class CustomBottomNavigationBar extends StatefulWidget {
  CustomBottomNavigationBar({
    Key? key,
    required this.items,
    this.centerItemText,
    this.iconSize = 24.0,
    this.backgroundColor,
    this.color,
    this.selectedColor,
    this.notchedShape,
    required this.onTabSelected,
    required this.selectedIndex,
  }) : super(key: key) {
    assert(items.length == 2 || items.length == 3);
  }

  final List<BottomBarItem> items;
  final String? centerItemText;
  final double? iconSize;
  final Color? backgroundColor;
  final Color? color;
  final Color? selectedColor;
  final NotchedShape? notchedShape;
  final Function onTabSelected;
  int selectedIndex;

  @override
  State<StatefulWidget> createState() => CustomBottomNavigationBarState();
}

class CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  Widget _buildTabItem({
    BottomBarItem? item,
    int? index,
    required ValueChanged<int?> onPressed,
  }) {
    Color? color = widget.selectedIndex == index
        ? widget.selectedColor
        : item?.isDarkMode == true
            ? ColorConstants.white
            : ColorConstants.greyColor;

    return Expanded(
      child: NormalButton(
        color: Colors.transparent,
        splashColors:
            ColorConstants.backgroundColorButtonPrint.withOpacity(.26),
        onPressed: () {
          widget.selectedIndex = index!;
          widget.onTabSelected(index);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: ResponsiveUtil().getPadding(bottom: 5),
              child: SvgPicture.asset(
                item?.iconData ?? '',
                color: color,
                height: ResponsiveUtil().getSize(28),
              ),
            ),
            Text(
              item?.text ?? '',
              style: TextStyle(
                color: color,
                fontSize: ResponsiveUtil().getSize(12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> items = List.generate(widget.items.length, (int index) {
      return _buildTabItem(
        item: widget.items[index],
        index: index,
        onPressed: (int? index) {
          widget.selectedIndex = index!;
          widget.onTabSelected(index);
        },
      );
    });
    // items.insert(items.length >> 1, _buildMiddleTabItem());

    return BottomAppBar(
      shape: widget.notchedShape,
      color: widget.backgroundColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: items,
      ),
    );
  }
}
