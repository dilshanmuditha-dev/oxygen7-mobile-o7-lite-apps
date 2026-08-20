// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';

class NormalButton extends StatelessWidget {
  const NormalButton({
    Key? key,
    this.title,
    required this.onPressed,
    required this.child,
    this.color,
    this.splashColors,
  }) : super(key: key);
  final String? title;
  final Function? onPressed;
  final Widget child;
  final Color? color;
  final Color? splashColors;
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      splashColor: splashColors,
      onTap: onPressed as void Function()?,
      child: child,
    );
  }
}
