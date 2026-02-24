import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

class HttpHelper {
  static String? _deviceId;
  static String? _appVersion;
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
    } catch (_) {
      _appVersion = 'unknown';
    }

    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isIOS) {
        final ios = await deviceInfo.iosInfo;
        _deviceId = ios.identifierForVendor;
      } else if (Platform.isAndroid) {
        // Settings.Secure.ANDROID_ID — unique per device+app signing key
        const channel = MethodChannel('com.satsails.Satsails/device');
        try {
          _deviceId = await channel.invokeMethod('getAndroidId');
        } catch (_) {
          final android = await deviceInfo.androidInfo;
          _deviceId = android.fingerprint;
        }
      }
    } catch (_) {
      _deviceId = null;
    }

    _initialized = true;
  }

  static Future<String?> get deviceId async {
    await _init();
    return _deviceId;
  }

  static Future<String?> get appVersion async {
    await _init();
    return _appVersion;
  }

  static Future<Map<String, String>> headers() async {
    await _init();
    final h = <String, String>{
      'Content-Type': 'application/json',
    };
    if (_appVersion != null) h['X-App-Version'] = _appVersion!;
    if (_deviceId != null) h['X-Device-Id'] = _deviceId!;
    return h;
  }

  static Future<Map<String, String>> authHeaders(String auth) async {
    final h = await headers();
    h['Authorization'] = auth;
    return h;
  }
}
