import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/email_service.dart';
import 'package:lamhti_app/Services/Payment%20Service/PlatformPaymentService.dart';
import 'package:lamhti_app/Theme/AppTheme.dart';
import 'package:lamhti_app/UI/Initial%20Screens/SplashScreen.dart';
import 'package:screen_protector/screen_protector.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await SmtpConfig.setup(
    gmailAddress: 'Lamhti.firebase@gmail.com', //'khawajasaim23@gmail.com',

    appPassword:
        "llxs umel hesg wdjg", //'xdai fxyk dxht fwuj', // Gmail App Password
  );
  // TODO: Screenshot prevention disabled temporarily for debugging
  // Uncomment the lines below to re-enable screenshot protection
  await ScreenProtector.preventScreenshotOn();
  await ScreenProtector.protectDataLeakageOn();

  // Initialize platform payment service (IAP for all platforms)
  final platformPaymentService = PlatformPaymentService();
  await platformPaymentService.initialize();

  runApp(
    ScreenUtilInit(
      designSize: Size(375, 812), // iPhone X standard
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) => const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lamhti',
      theme: AppTheme.lightTheme,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }

  //
  //
}
