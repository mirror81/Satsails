import 'package:Satsails/helpers/http_helper.dart';
import 'package:Satsails/providers/user_provider.dart';
import 'package:dot_navigation_bar/dot_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomBottomNavigationBar extends ConsumerStatefulWidget {
  final int currentIndex;
  final void Function(int) onTap;

  const CustomBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  _CustomBottomNavigationBarState createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends ConsumerState<CustomBottomNavigationBar> {
  int _homeTapCount = 0;
  DateTime _lastHomeTap = DateTime.now();

  void _handleTap(int index) {
    if (index == 0 && widget.currentIndex == 0) {
      final now = DateTime.now();
      if (now.difference(_lastHomeTap).inSeconds > 2) {
        _homeTapCount = 0;
      }
      _homeTapCount++;
      _lastHomeTap = now;

      if (_homeTapCount >= 5) {
        _homeTapCount = 0;
        _showDebugInfo();
      }
    } else {
      _homeTapCount = 0;
    }
    widget.onTap(index);
  }

  Future<void> _showDebugInfo() async {
    final paymentId = ref.read(userProvider).paymentId;
    final appVersion = await HttpHelper.appVersion ?? 'unknown';
    final deviceId = await HttpHelper.deviceId ?? 'unknown';

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF212121),
        title: Text('Debug Info', style: TextStyle(color: Colors.white, fontSize: 18.sp)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('App Version', appVersion),
            SizedBox(height: 8.h),
            _infoRow('Payment ID', paymentId.isEmpty ? 'N/A' : paymentId),
            SizedBox(height: 8.h),
            _infoRow('Device ID', deviceId),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(
                text: 'Version: $appVersion\nPayment ID: $paymentId\nDevice ID: $deviceId',
              ));
              Navigator.pop(ctx);
            },
            child: const Text('Copy', style: TextStyle(color: Colors.orangeAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
        SizedBox(height: 2.h),
        Text(value, style: TextStyle(color: Colors.white, fontSize: 14.sp, fontFamily: 'monospace')),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = 25.0.sp;

    final List<DotNavigationBarItem> bottomBarItems = [
      DotNavigationBarItem(
        icon: Icon(Icons.home, size: iconSize),
        selectedColor: Colors.orangeAccent,
        unselectedColor: Colors.white,
      ),
      DotNavigationBarItem(
        icon: Icon(Icons.bar_chart, size: iconSize),
        selectedColor: Colors.orangeAccent,
        unselectedColor: Colors.white,
      ),
      DotNavigationBarItem(
        icon: Icon(Icons.swap_horiz, size: iconSize),
        selectedColor: Colors.orangeAccent,
        unselectedColor: Colors.white,
      ),
      DotNavigationBarItem(
        icon: Icon(Icons.add_shopping_cart_outlined, size: iconSize),
        selectedColor: Colors.orangeAccent,
        unselectedColor: Colors.white,
      ),
    ];

    return DotNavigationBar(
      items: bottomBarItems,
      enablePaddingAnimation: false,
      currentIndex: widget.currentIndex,
      onTap: _handleTap,
      backgroundColor: const Color(0xFF212121),
      dotIndicatorColor: Colors.transparent,
      unselectedItemColor: Colors.grey[300],
      splashColor: Colors.transparent,
      marginR: EdgeInsets.zero,
      itemPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
    );
  }
}
