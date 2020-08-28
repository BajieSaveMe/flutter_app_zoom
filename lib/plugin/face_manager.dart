import 'package:flutter/services.dart';

class FaceManager {
  static const MethodChannel _channel = const MethodChannel('facetec_plugin');

  ///活体检测
  static Future<String> livenessCheck({Map params}) async {
    return await _channel.invokeMethod('livenessCheck', params ?? {});
  }

  ///注册用户
  static Future<String> enrollUser() async {
    return await _channel.invokeMethod('enrollUser');
  }

  ///验证用户
  static Future<String> authenticateUser() async {
    return await _channel.invokeMethod('authenticateUser');
  }

  ///卡片检测
  static Future<String> photoIDMatch() async {
    return await _channel.invokeMethod('photoIDMatch');
  }
}
