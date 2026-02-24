import 'package:Satsails/providers/user_provider.dart';
import 'package:Satsails/translations/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateBenefits extends ConsumerWidget {
  const AffiliateBenefits({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final affiliateCode = user.affiliateCode ?? '';
    final eulenFee = ref.watch(getUserEulenFeeAmount);
    final noxFee = ref.watch(getUserNoxFeeAmount);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Affiliate Program'.i18n,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20.sp,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildAffiliateCodeCard(affiliateCode),
              SizedBox(height: 24.h),
              _buildFeesCard(eulenFee, noxFee),
              const Spacer(),
              _buildBecomeAffiliateCard(context),
              SizedBox(height: 16.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAffiliateCodeCard(String code) {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.group_add_outlined,
            color: Colors.orange,
            size: 40.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'Your Affiliate Code'.i18n,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            code,
            style: TextStyle(
              color: Colors.orange,
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeesCard(AsyncValue<double> eulenFee, AsyncValue<double> noxFee) {
    return Container(
      padding: EdgeInsets.all(20.sp),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Fees'.i18n,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16.h),
          _buildFeeRow(
            'Depix Purchase Fee'.i18n,
            eulenFee,
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 24.h),
          _buildFeeRow(
            'BTC Purchase Fee'.i18n,
            noxFee,
          ),
          Divider(color: Colors.white.withOpacity(0.1), height: 24.h),
          _buildStaticRow(
            'Your Discount'.i18n,
            '0.20%',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFeeRow(String label, AsyncValue<double> feeAsync) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15.sp,
          ),
        ),
        feeAsync.when(
          data: (fee) => Text(
            '${(fee * 100).toStringAsFixed(2)}%',
            style: TextStyle(
              color: Colors.orange,
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          loading: () => SizedBox(
            width: 16.sp,
            height: 16.sp,
            child: const CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.orange,
            ),
          ),
          error: (_, __) => Text(
            '--',
            style: TextStyle(
              color: Colors.red,
              fontSize: 16.sp,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 15.sp,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildBecomeAffiliateCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Want to earn commissions by referring new users?'.i18n,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12.h),
          GestureDetector(
            onTap: () => _openAffiliateRegistration(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                'Become an Affiliate'.i18n,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAffiliateRegistration(BuildContext context) async {
    final uri = Uri.parse('https://affiliates.satsails.com/register');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
