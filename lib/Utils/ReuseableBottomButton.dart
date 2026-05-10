import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class ReuseableBottomButton extends StatelessWidget {
  final String buttonText;
  final GestureTapCallback onTap;
  final bool enabled;

  const ReuseableBottomButton({
    super.key,
    required this.buttonText,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isIPad = screenWidth >= 600;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 50.h, // Minimum 44pt for touch - using 50 for comfort
          width: double.infinity,
          constraints: BoxConstraints(
            minHeight: 44.h,
            maxWidth: isIPad ? 500 : double.infinity,
          ),
          decoration: BoxDecoration(
            color: enabled ? Colors.black : Colors.grey.shade500,
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          child: Center(
            child: Text(
              buttonText,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: GoogleFonts.poppins(
                fontSize: isLandscape ? 13.sp : (isIPad ? 14.sp : 16.sp),
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
