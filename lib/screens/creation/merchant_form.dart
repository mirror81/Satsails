import 'package:Satsails/models/user_model.dart';
import 'package:Satsails/providers/user_provider.dart';
import 'package:Satsails/screens/shared/custom_button.dart';
import 'package:Satsails/screens/shared/message_display.dart';
import 'package:Satsails/translations/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

class MerchantForm extends ConsumerStatefulWidget {
  const MerchantForm({super.key});

  @override
  _MerchantFormState createState() => _MerchantFormState();
}

class _MerchantFormState extends ConsumerState<MerchantForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _whatsappController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final user = ref.read(userProvider);
      final result = await UserService.setCustomerType(
        user.jwt,
        'merchant',
        merchantDetails: {
          'name': _nameController.text.trim(),
          'whatsapp': _whatsappController.text.trim(),
          'email': _emailController.text.trim(),
        },
      );

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
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 20.h),
                  Center(
                    child: Text(
                      'Merchant Registration'.i18n,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: 40.h),
                  _buildTextField(
                    controller: _nameController,
                    label: 'Name'.i18n,
                    icon: Icons.person_outline,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please fill all fields'.i18n;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _whatsappController,
                    label: 'WhatsApp'.i18n,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please fill all fields'.i18n;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 20.h),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email'.i18n,
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please fill all fields'.i18n;
                      }
                      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value.trim())) {
                        return 'Invalid email'.i18n;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 40.h),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Colors.white))
                      : CustomButton(
                          text: 'Continue'.i18n,
                          onPressed: _submit,
                          primaryColor: Colors.green.withOpacity(0.8),
                          secondaryColor: Colors.green.withOpacity(0.6),
                          textColor: Colors.black,
                        ),
                  SizedBox(height: 40.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: Colors.white, fontSize: 16.sp),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white60, fontSize: 14.sp),
        prefixIcon: Icon(icon, color: Colors.white60),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.green),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
    );
  }
}
