import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:app/shared/utils/log_utils.dart';

String? encryptionHmacSHA512(String encryptString, String key) {
  try {
    final bytesKey = utf8.encode(key);
    final mac = Hmac(sha512, bytesKey);
    final macData = mac.convert(utf8.encode(encryptString));
    return bytesToHex(macData.bytes.toList());
  } catch (e) {
    LogUtils.debugLog(e);
  }
  return null;
}

String bytesToHex(List<int> bytes) {
  return bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
}
