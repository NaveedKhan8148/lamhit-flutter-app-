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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12.r),
        onTap: enabled ? onTap : null,
        child: Container(
          height: 50.h,
          width: MediaQuery.of(context).size.width * 0.9,
          decoration: BoxDecoration(
            color: enabled ? Colors.black : Colors.grey.shade500,
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 14.h),
          child: Center(
            child: Text(
              buttonText,
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
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
