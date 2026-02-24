import 'package:Satsails/models/user_model.dart';
import 'package:Satsails/providers/user_provider.dart';
import 'package:Satsails/screens/shared/message_display.dart';
import 'package:Satsails/translations/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class CustomerTypeSelection extends ConsumerStatefulWidget {
  const CustomerTypeSelection({super.key});

  @override
  _CustomerTypeSelectionState createState() => _CustomerTypeSelectionState();
}

class _CustomerTypeSelectionState extends ConsumerState<CustomerTypeSelection> {
  bool _isLoading = false;

  Future<void> _selectIndividual() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      final result = await UserService.setCustomerType(user.jwt, 'individual');

      if (!mounted) return;

      if (result.data != null) {
        context.go('/affiliate');
      } else {
        showMessageSnackBar(
          message: result.error ?? 'An error occurred'.i18n,
          error: true,
          context: context,
        );
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        showMessageSnackBar(
          message: 'An error occurred'.i18n,
          error: true,
          context: context,
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 60.h),
                    Text(
                      'Choose Account Type'.i18n,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      'How will you use Satsails?'.i18n,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16.sp,
                      ),
                    ),
                    SizedBox(height: 48.h),
                    _buildOptionCard(
                      icon: Icons.person_outline,
                      title: 'Individual'.i18n,
                      subtitle: 'Individual account, deposits must come from a single CPF'.i18n,
                      color: const Color(0xFFF7931A),
                      onTap: _selectIndividual,
                    ),
                    SizedBox(height: 20.h),
                    _buildOptionCard(
                      icon: Icons.store_outlined,
                      title: 'Merchant'.i18n,
                      subtitle: 'Merchant account, deposits can come from different CPFs or CNPJs. If there is a Pix chargeback your account will be blocked'.i18n,
                      color: Colors.green,
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.push('/merchant_form');
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 32.sp),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white30, size: 24.sp),
          ],
        ),
      ),
    );
  }
}
