// ignore_for_file: empty_catches

import 'package:app/shared/secure_shared_preferences/secure_shared_preferences.dart';
import 'package:intl/intl.dart';

class StringUtils {
  // Date time Format
  static const dateFormatddMMyyyyDot = 'dd.MM.yyyy';
  static const dateFormatddMMyyyy = 'ddMMyyyy';
  static const dateFormatyyyyMMddHHmmss = 'yyyyMMddHHmmss';
  static const dateFormatddMMyyyyHHMMss = "dd.MM.yyyy HH:mm:ss";
  static const dateFormatddMMyyyyHHMM = "dd.MM.yyyy HH:mm";
  static const hourFormatHHMM = "HH:mm";
  static const dateFormatyyyyMMdd = 'yyyy-MM-dd';

  static String convert2LocalTimeString(DateTime dateTime,
      {String? strFormat}) {
    // the input date is in Singapore time (UTC+8)
    // final singaporeOffset = Duration(hours: 8);

    // Convert the dateTime to the device's local time zone
    // final deviceTimeZone = DateTime.now().timeZoneOffset;
    // final timeZoneDifference = singaporeOffset - deviceTimeZone;
    // dateTime = dateTime.subtract(timeZoneDifference);

    // convert dateTime to local time
    dateTime = dateTime.toLocal();

    if (strFormat == null) {
      return DateFormat(hourFormatHHMM).format(dateTime);
    } else {
      return DateFormat(strFormat).format(dateTime);
    }
  }

  static String dateToString(DateTime dateTime) {
    return DateFormat(dateFormatddMMyyyyDot).format(dateTime);
  }

  static String dateToStringWithFormat(DateTime dateTime, String format) {
    return DateFormat(format).format(dateTime);
  }

  static String getTimeStampGW2() {
    var date = DateTime.now();
    var formatter = DateFormat(dateFormatyyyyMMddHHmmss);
    return formatter.format(date);
  }

  static String convertToGW2StartDate(DateTime dateTime) {
    final DateFormat yyyyMMddHHmmss = DateFormat(dateFormatyyyyMMddHHmmss);
    return yyyyMMddHHmmss.format(dateTime);
  }

  static String convertToGW2EndDate(DateTime dateTime) {
    final DateFormat yyyyMMddHHmmss = DateFormat(dateFormatyyyyMMddHHmmss);
    dateTime = dateTime.add(Duration(days: 1));
    return yyyyMMddHHmmss.format(dateTime);
  }

  static String convertToGW3StartDate(DateTime dateTime) {
    final DateFormat yyyyMMdd = DateFormat(dateFormatyyyyMMdd);
    return yyyyMMdd.format(dateTime);
  }

  static String convertToGW3EndDate(DateTime dateTime) {
    final DateFormat yyyyMMdd = DateFormat(dateFormatyyyyMMdd);
    dateTime = dateTime.add(Duration(days: 1));
    return yyyyMMdd.format(dateTime);
  }

  static String convertToGW2SameDate(DateTime dateTime) {
    final DateFormat yyyyMMddHHmmss = DateFormat(dateFormatyyyyMMddHHmmss);
    dateTime =
        DateTime(dateTime.year, dateTime.month, dateTime.day, 23, 59, 59, 999);
    return yyyyMMddHHmmss.format(dateTime);
  }

  static String formatResponeDateTimeToString(
      String inputDate, String strFormat) {
    try {
      if (strFormat.trim().isEmpty) {
        strFormat = "dd/MM/yyyy HH:mm:ss";
      }

      if (inputDate.isNotEmpty) {
        String dateWithT =
            '${inputDate.substring(0, 8)}T${inputDate.substring(8)}';
        DateTime dateTime = DateTime.parse(dateWithT);

        // the input date is in Singapore time (UTC+8)
        final singaporeOffset = Duration(hours: 8);

        // Convert the dateTime to the device's local time zone
        final deviceTimeZone = DateTime.now().timeZoneOffset;
        final timeZoneDifference = singaporeOffset - deviceTimeZone;
        dateTime = dateTime.subtract(timeZoneDifference);

        return DateFormat(strFormat).format(dateTime);
      } else {
        return "";
      }
    } catch (e) {
      DateTime dateTime = DateTime.parse(inputDate);
      // Convert UTC time to local time
      final localDateTime = dateTime.toLocal();

      return DateFormat(strFormat).format(localDateTime);
    }
  }

  static String dateToStringGiftReportAFG(String date) {
    try {
      int dateTime = int.tryParse(date) ?? 0;
      if (dateTime < 20100000000000) {
        return DateFormat('HH:mm')
            .format(DateTime.fromMillisecondsSinceEpoch(dateTime));
      }
    } catch (e) {}
    return DateFormat('HH:mm').format(DateTime.parse(date));
  }

  static String formatAmount(double num, String pattern) {
    final formatter = NumberFormat(pattern);
    return formatter.format(num);
  }

  static String toCents(String amount) {
    String s = (double.parse(amount) * 100).toStringAsFixed(0);
    return s;
  }

  static Future<String> setServiceChargeAmout(String amount) async {
    if (amount.isEmpty) {
      return "0";
    }
    final getServiceChargeRate =
        await SecureSharedPreferences.instance.getServiceChargeRate() ?? 0;

    String s =
        (double.parse(amount) * getServiceChargeRate / 100).toStringAsFixed(2);
    return s;
  }

  static Future<String> setServiceChangePayment(String amount) async {
    final getServiceChargeRate =
        await SecureSharedPreferences.instance.getServiceChargeRate() ?? 0;
    if (amount.isEmpty) {
      return "0";
    }
    double serviceCharge = getServiceChargeRate / 100;
    String serviceChargeAmount =
        (double.parse(amount) * serviceCharge).toStringAsFixed(2);

    return serviceChargeAmount;
  }

  static String toDollars(String amount) {
    if (amount.isEmpty) {
      return "0.00";
    }
    double amt = double.parse(amount);
    String result = (amt / 100).toStringAsFixed(2);
    return result;
  }

  static bool equalsIgnoreCase(String a, String b) {
    return a.toLowerCase() == b.toLowerCase();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
