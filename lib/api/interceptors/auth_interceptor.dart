import 'dart:async';
import 'package:get/get_connect/http/src/request/request.dart';
import '../../shared/secure_shared_preferences/secure_shared_preferences.dart';

FutureOr<Request> authInterceptor(request) async {
  final accessToken = await SecureSharedPreferences.instance.getAccessToken();

  request.headers['X-Requested-With'] = 'XMLHttpRequest';
  request.headers['Authorization'] = 'Bearer $accessToken';

  return request;
}
