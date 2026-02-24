import 'package:Satsails/models/auth_model.dart';
import 'package:Satsails/notifications/firebase.dart';
import 'package:Satsails/models/user_model.dart';
import 'package:Satsails/providers/address_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

const FlutterSecureStorage _storage = FlutterSecureStorage();

final initializeUserProvider = FutureProvider<User>((ref) async {
  debugPrint('SATSAILS_DEBUG: initializeUserProvider RUNNING');
  final box = await Hive.openBox('user');
  final paymentId = box.get('paymentId', defaultValue: '');
  final affiliateCode = box.get('affiliateCode', defaultValue: '');
  final hasUploadedAffiliateCode = box.get('hasUploadedAffiliateCode', defaultValue: false);
  final jwt = await _storage.read(key: 'backendJwt') ?? '';
  final recoveryCode = await _storage.read(key: 'recoveryCode') ?? '';
  final hasUploadedLiquidAddress = box.get('hasUploadedLiquidAddress', defaultValue: false);
  debugPrint('SATSAILS_DEBUG: initializeUserProvider paymentId=$paymentId, jwt=${jwt.isNotEmpty ? jwt.substring(0, 10) : "empty"}');

  return User(
    recoveryCode: recoveryCode,
    paymentId: paymentId,
    affiliateCode: affiliateCode,
    hasUploadedAffiliateCode: hasUploadedAffiliateCode ?? false,
    hasUploadedLiquidAddress: hasUploadedLiquidAddress ?? false,
    jwt: jwt,
  );
});

final userProvider = StateNotifierProvider<UserModel, User>((ref) {
  final initialUser = ref.watch(initializeUserProvider);

  return UserModel(initialUser.when(
    data: (user) => user,
    loading: () => User(
      affiliateCode: '',
      recoveryCode: '',
      paymentId: '',
      jwt: '',
      hasUploadedLiquidAddress: false,
      hasUploadedAffiliateCode: false,
    ),
    error: (Object error, StackTrace stackTrace) {
      throw error;
    },
  ));
});

final addAffiliateCodeProvider = FutureProvider.autoDispose.family<void, String>((ref, affiliateCode) async {
  final auth = ref.read(userProvider).jwt;
  final result = await UserService.addAffiliateCode(affiliateCode, auth);

  if (result.isSuccess && result.data == true) {
    ref.read(userProvider.notifier).setAffiliateCode(affiliateCode);
    ref.read(userProvider.notifier).setHasUploadedAffiliateCode(true);
  } else {
    ref.read(userProvider.notifier).setAffiliateCode('');
    throw result.error!;
  }
});

final fetchBackendChallangeProvider = FutureProvider.autoDispose<String>((ref) async {
  final result = await BackendAuth.fetchChallenge();
  if (result.isSuccess && result.data != null) {
    return result.data!;
  } else {
    throw result.error!;
  }
});

final createUserProvider = FutureProvider<void>((ref) async {
  debugPrint('SATSAILS_DEBUG: createUserProvider START');
  final existingJwt = await _storage.read(key: 'backendJwt') ?? '';
  final challenge = await ref.read(fetchBackendChallangeProvider.future);
  final signedChallenge = await BackendAuth.signChallengeWithPrivateKey(challenge);
  final result = await UserService.createUserRequest(challenge, signedChallenge!, existingJwt: existingJwt);
  debugPrint('SATSAILS_DEBUG: createUserRequest done, isSuccess=${result.isSuccess}, hasData=${result.data != null}');

  if (result.isSuccess && result.data != null) {
    final user = result.data!;
    debugPrint('SATSAILS_DEBUG: parsed user paymentId=${user.paymentId}');

    // Save to Hive/SecureStorage FIRST, before touching userProvider
    final box = await Hive.openBox('user');
    await box.put('paymentId', user.paymentId);
    await box.put('affiliateCode', user.affiliateCode ?? '');
    await _storage.write(key: 'backendJwt', value: user.jwt);
    debugPrint('SATSAILS_DEBUG: persisted to Hive/SecureStorage');

    // Read affiliate code from link before invalidating
    final affiliateCodeFromLink = ref.read(userProvider).affiliateCode ?? '';

    // Now rebuild userProvider from the persisted data
    ref.invalidate(initializeUserProvider);
    // Wait for it to complete so userProvider picks up the new state
    await ref.read(initializeUserProvider.future);
    debugPrint('SATSAILS_DEBUG: userProvider rebuilt, paymentId=${ref.read(userProvider).paymentId}');

    await FirebaseService.storeTokenOnbackend();
    if (affiliateCodeFromLink.isNotEmpty) {
      await ref.read(addAffiliateCodeProvider(affiliateCodeFromLink).future);
    }
    debugPrint('SATSAILS_DEBUG: createUserProvider COMPLETE');
  } else {
    debugPrint('SATSAILS_DEBUG: createUserProvider FAILED: ${result.error}');
    throw result.error!;
  }
});

final depositInitializerProvider = FutureProvider.autoDispose<void>((ref) async {
  final user = ref.read(userProvider);

  if ((user.affiliateCode?.isNotEmpty ?? false) &&
      !(user.hasUploadedAffiliateCode ?? false)) {
    await ref.read(addAffiliateCodeProvider(user.affiliateCode!).future);
  }
});

final getUserEulenFeeAmount = FutureProvider.autoDispose<double>((ref) async {
  final auth = ref.read(userProvider).jwt;
  final result = await UserService.eulenFeeAmount(auth);
  if (result.isSuccess && result.data != null) {
    return result.data!;
  } else {
    throw result.error!;
  }
});

final getUserNoxFeeAmount = FutureProvider.autoDispose<double>((ref) async {
  final auth = ref.read(userProvider).jwt;
  final result = await UserService.noxFeeAmount(auth);
  if (result.isSuccess && result.data != null) {
    return result.data!;
  } else {
    throw result.error!;
  }
});
