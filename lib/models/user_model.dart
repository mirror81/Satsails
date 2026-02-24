import 'dart:convert';
import 'package:Satsails/handlers/response_handlers.dart';
import 'package:Satsails/helpers/http_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();

class UserModel extends StateNotifier<User> {
  UserModel(super.state);
  Future<void> setPaymentId(String paymentCode) async {
    final box = await Hive.openBox('user');
    await box.put('paymentId', paymentCode);
    state = state.copyWith(paymentId: paymentCode);
  }

  Future<void> setAffiliateCode(String affiliateCode) async {
    final box = await Hive.openBox('user');
    await box.put('affiliateCode', affiliateCode);
    state = state.copyWith(affiliateCode: affiliateCode);
  }

  Future<void> setJwt(String jwt) async {
    await _storage.write(key: 'backendJwt', value: jwt);
    state = state.copyWith(jwt: jwt);
  }

  // legacy we can delete by the end of 2025
  Future<void> setRecoveryCode(String recoveryCode) async {
    await _storage.write(key: 'recoveryCode', value: recoveryCode);
    state = state.copyWith(recoveryCode: recoveryCode);
  }

  Future<void> setHasUploadedAffiliateCode(bool hasUploadedAffiliateCode) async {
    final box = await Hive.openBox('user');
    await box.put('hasUploadedAffiliateCode', hasUploadedAffiliateCode);
    state = state.copyWith(hasUploadedAffiliateCode: hasUploadedAffiliateCode);
  }

  Future<void> setHasUploadedLiquidAddress(bool hasUploadedLiquidAddress) async {
    final box = await Hive.openBox('user');
    await box.put('hasUploadedLiquidAddress', hasUploadedLiquidAddress);
    state = state.copyWith(hasUploadedLiquidAddress: hasUploadedLiquidAddress);
  }
}

class User {
  final String? recoveryCode;
  final String paymentId;
  final String? affiliateCode;
  final bool? hasUploadedAffiliateCode;
  final bool? hasUploadedLiquidAddress;
  final String jwt;

  User({
    this.recoveryCode,
    required this.paymentId,
    required this.affiliateCode,
    this.hasUploadedAffiliateCode,
    this.hasUploadedLiquidAddress,
    required this.jwt,
  });

  User copyWith({
    String? recoveryCode,
    String? paymentId,
    String? affiliateCode,
    bool? hasUploadedAffiliateCode,
    bool? hasUploadedLiquidAddress,
    String? jwt,
  }) {
    return User(
      recoveryCode: recoveryCode ?? this.recoveryCode,
      paymentId: paymentId ?? this.paymentId,
      affiliateCode: affiliateCode ?? this.affiliateCode,
      hasUploadedAffiliateCode: hasUploadedAffiliateCode ?? this.hasUploadedAffiliateCode,
      hasUploadedLiquidAddress: hasUploadedLiquidAddress ?? this.hasUploadedLiquidAddress,
      jwt: jwt ?? this.jwt,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      paymentId: json['user']['payment_id'],
      affiliateCode: json['inserted_affiliate']['code'] ?? '',
      jwt: json['token'],
    );
  }
}

class UserService {
  /// Create a new user.
  static Future<Result<User>> createUserRequest(String challenge, String signature, {String? existingJwt}) async {
    try {
      final headers = await HttpHelper.headers();
      if (existingJwt != null && existingJwt.isNotEmpty) {
        headers['Authorization'] = existingJwt;
      }
      final deviceId = await HttpHelper.deviceId;
      final appVersion = await HttpHelper.appVersion;

      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND']!}/users'),
        body: jsonEncode({
          'user': {
            'challenge': challenge,
            'signature': signature,
            if (deviceId != null) 'device_id': deviceId,
            if (appVersion != null) 'app_version': appVersion,
          }
        }),
        headers: headers,
      );

      if (response.statusCode == 201) {
        return Result(data: User.fromJson(jsonDecode(response.body)));
      } else {
        return Result(error: 'Failed to create user: ${response.body}');
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please try again later');
    }
  }

  /// Migrate to JWT (authenticate and receive a JWT token).
  static Future<Result<String>> migrateToJWT(String auth, String challenge, String signature) async {
    try {
      final headers = await HttpHelper.headers();
      headers['Authorization'] = auth;

      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND']!}/users/migrate'),
        body: jsonEncode({
          'user': {
            'challenge': challenge,
            'signature': signature,
          }
        }),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Result(data: jsonDecode(response.body)['token']);
      } else {
        return Result(error: 'Failed to migrate user: ${response.body}');
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please try again later');
    }
  }

  /// Add an affiliate code to the user.
  static Future<Result<bool>> addAffiliateCode(String affiliateCode, String auth) async {
    try {
      final headers = await HttpHelper.authHeaders(auth);

      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND']!}/users/add_affiliate'),
        body: jsonEncode({
          'user': {
            'affiliate_code': affiliateCode,
          }
        }),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Result(data: true);
      } else {
        String errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to add affiliate code';
        return Result(error: errorMsg);
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please try again later');
    }
  }

  static Future<Result<double>> eulenFeeAmount(String auth) async {
    try {
      final headers = await HttpHelper.authHeaders(auth);

      final response = await http.get(
        Uri.parse('${dotenv.env['BACKEND']!}/users/eulen_fee_amount'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return  Result(data: jsonDecode(response.body)['fee']);
      } else {
        String errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to add affiliate code';
        return Result(error: errorMsg);
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please try again later');
    }
  }

  static Future<Result<bool>> setCustomerType(String auth, String customerType, {Map<String, String>? merchantDetails}) async {
    try {
      final headers = await HttpHelper.authHeaders(auth);

      final body = <String, dynamic>{
        'customer_type': customerType,
      };
      if (merchantDetails != null) {
        body['merchant_details'] = merchantDetails;
      }

      final response = await http.post(
        Uri.parse('${dotenv.env['BACKEND']!}/users/set_customer_type'),
        body: jsonEncode(body),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Result(data: true);
      } else {
        String errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to set customer type';
        return Result(error: errorMsg);
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please try again later');
    }
  }

  static Future<Result<double>> noxFeeAmount(String auth) async {
    try {
      final headers = await HttpHelper.authHeaders(auth);

      final response = await http.get(
        Uri.parse('${dotenv.env['BACKEND']!}/users/nox_fee_amount'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return Result(data: jsonDecode(response.body)['fee']);
      } else {
        String errorMsg = jsonDecode(response.body)['error'] ?? 'Failed to get NOX fee';
        return Result(error: errorMsg);
      }
    } catch (e) {
      return Result(error: 'An error has occurred. Please try again later');
    }
  }
}
