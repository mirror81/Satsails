import 'package:Satsails/providers/bitcoin_config_provider.dart';
import 'package:Satsails/screens/shared/message_display.dart';
import 'package:Satsails/translations/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

class ExportXpub extends ConsumerStatefulWidget {
  const ExportXpub({super.key});

  @override
  _ExportXpubState createState() => _ExportXpubState();
}

class _ExportXpubState extends ConsumerState<ExportXpub> {
  String _selectedNetwork = 'bitcoin';
  bool _isLoading = true;
  String? _bitcoinXpub;
  String? _liquidXpub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchXpubs();
    });
  }

  Future<void> _fetchXpubs() async {
    try {
      // Fetch Bitcoin xpub
      final btcXpub = await ref.read(bitcoinXpubProvider.future);
      setState(() {
        _bitcoinXpub = btcXpub;
        _isLoading = false;
      });

      // Optionally fetch Liquid if wallet exists
      try {
        final liqXpub = await ref.read(liquidXpubProvider.future);
        setState(() => _liquidXpub = liqXpub);
      } catch (e) {
        // Liquid wallet may not exist, ignore error
      }
    } catch (e) {
      if (mounted) {
        showMessageSnackBar(
          context: context,
          message: 'Failed to load xpub: $e'.i18n,
          error: true,
        );
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Export Xpub'.i18n,
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
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: Colors.white, size: 22.sp),
            onPressed: _shareXpub,
          ),
          IconButton(
            icon: Icon(Icons.copy, color: Colors.white, size: 22.sp),
            onPressed: _copyXpub,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                children: [
                  SizedBox(height: 16.h),
                  _buildWarningBox(),
                  SizedBox(height: 24.h),
                  if (_liquidXpub != null) _buildNetworkSelector(),
                  if (_liquidXpub != null) SizedBox(height: 24.h),
                  _buildQrCode(),
                  SizedBox(height: 16.h),
                  _buildXpubDisplay(),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
      ),
    );
  }

  Widget _buildWarningBox() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 16.sp),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.orange, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacy Warning'.i18n,
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6.h),
                Text(
                  'Anyone with your xpub can view all addresses, balances, and transaction history. Only share for watch-only wallet setup.'.i18n,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildNetworkTab('bitcoin', 'Bitcoin'),
        SizedBox(width: 16.w),
        _buildNetworkTab('liquid', 'Liquid'),
      ],
    );
  }

  Widget _buildNetworkTab(String network, String label) {
    final isSelected = _selectedNetwork == network;
    return GestureDetector(
      onTap: () => setState(() => _selectedNetwork = network),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(24.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildQrCode() {
    final xpub = _selectedNetwork == 'bitcoin' ? _bitcoinXpub : _liquidXpub;
    if (xpub == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
      ),
      padding: EdgeInsets.all(16.w),
      child: QrImageView(
        data: xpub,
        version: QrVersions.auto,
        size: 280.w,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildXpubDisplay() {
    final xpub = _selectedNetwork == 'bitcoin' ? _bitcoinXpub : _liquidXpub;
    if (xpub == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extended Public Key'.i18n,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            xpub,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontFamily: 'monospace',
              height: 1.6,
            ),
            softWrap: true,
          ),
        ],
      ),
    );
  }

  void _copyXpub() {
    final xpub = _selectedNetwork == 'bitcoin' ? _bitcoinXpub : _liquidXpub;
    if (xpub == null) return;

    Clipboard.setData(ClipboardData(text: xpub));
    showMessageSnackBar(
      context: context,
      message: 'Xpub copied to clipboard'.i18n,
      error: false,
    );
  }

  void _shareXpub() {
    final xpub = _selectedNetwork == 'bitcoin' ? _bitcoinXpub : _liquidXpub;
    if (xpub == null) return;

    Share.share(xpub);
  }
}
