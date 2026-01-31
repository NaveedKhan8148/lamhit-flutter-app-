import 'dart:developer';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/AppleAuthService.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/GoogleAuthService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/User%20Details%20Storage/UserDetailsStorageService.dart';
import 'package:lamhti_app/UI/Main%20Screens/MainNavigationBar.dart';
import 'package:lamhti_app/Utils/Toast.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  GoogleAuthService googleAuthService = GoogleAuthService();

  AppleAuthService appleAuthService = AppleAuthService();

  UserDetailsStorageService userDetailsStorageService =
      UserDetailsStorageService();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? Scaffold(body: Center(child: CircularProgressIndicator()))
        : Scaffold(
          body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,

              children: [
                Image(
                  image: AssetImage("assets/images/lamhti logo with text.png"),
                ),

                SizedBox(
                  height: 30.h,
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        "Capture, Upload, Earn.",
                        textStyle: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        duration: Duration(milliseconds: 2500),
                      ),

                      FadeAnimatedText(
                        "Explore breathtaking moments...",
                        textStyle: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        duration: Duration(milliseconds: 2500),
                      ),

                      FadeAnimatedText(
                        "A visual marketplace for creators.",
                        textStyle: TextStyle(
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[700],
                        ),
                        duration: Duration(milliseconds: 2500),
                      ),
                    ],
                    isRepeatingAnimation: true,
                    repeatForever: true,
                    // pause: Duration(milliseconds: 800),
                  ),
                ),

                SizedBox(height: 50.h),

                AnimatedTextKit(
                  animatedTexts: [
                    TyperAnimatedText(
                      'Sign In / Register',
                      textStyle: TextStyle(
                        fontSize: 24.0.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      speed: Duration(milliseconds: 100),
                    ),
                  ],
                  isRepeatingAnimation: false,
                  displayFullTextOnTap: true,
                  stopPauseOnTap: true,
                ),

                SizedBox(height: 20.h),

                (Platform.isIOS)
                    ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    )
                    : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.08,
                    ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        height: 2,
                        color: Colors.black,
                        indent: 20,
                        endIndent: 10,
                      ),
                    ),
                    Text(
                      "Lets get started",
                      style: TextStyle(color: Colors.black, fontSize: 16),
                    ),
                    Expanded(
                      child: Divider(
                        thickness: 1,
                        height: 2,
                        color: Colors.black,
                        indent: 10,
                        endIndent: 20,
                      ),
                    ),
                  ],
                ),

                (Platform.isIOS)
                    ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    )
                    : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.05,
                    ),

                ReuseableContinueButton(
                  buttonText: "Continue with Google",
                  imagePath: "assets/images/google.png",
                  onTap: () async {
                    setState(() {
                      isLoading = true;
                    });

                    try {
                      final user = await googleAuthService.signInWithGoogle();
                      log('-----------${user}');
                      if (user != null) {
                        await userDetailsStorageService.setupUserDetailsIfNeeded();

                        Toast.toastMessage(
                          "Signed In Successfully",
                          Colors.black,
                        );

                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MainNavigationBar(),
                          ),
                        );
                      } else {
                        debugPrint("Error Signing In");
                        // Toast.toastMessage("Error Signing In", Colors.red);
                      }
                    } catch (e) {
                      debugPrint(
                        "Something went wrong while signing in with Google: $e",
                      );
                      // Toast.toastMessage("Something went wrong: $e", Colors.red);
                    } finally {
                      setState(() {
                        isLoading = false;
                      });
                    }
                  },
                ),

                Visibility(
                  visible: Platform.isIOS,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(height: 10.h),

                      ReuseableContinueButton(
                        buttonText: "Continue with Apple",
                        imagePath: "assets/images/apple-logo-white.png",
                        onTap: () async {
                          setState(() {
                            isLoading = true;
                          });

                          try {
                            final user =
                                await appleAuthService.signInWithApple();

                            if (user != null) {
                              await userDetailsStorageService
                                  .setupUserDetailsIfNeeded();

                              Toast.toastMessage(
                                "Signed In Successfully",
                                Colors.black,
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MainNavigationBar(),
                                ),
                              );
                            } else {
                              Toast.toastMessage(
                                "Apple sign-in cancelled or failed.",
                                Colors.red,
                              );
                            }
                          } catch (e) {
                            debugPrint(
                              "Something went wrong while signing in with Apple: $e",
                            );
                            Toast.toastMessage(
                              "Something went wrong: $e",
                              Colors.red,
                            );
                          } finally {
                            setState(() {
                              isLoading = false;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).size.height * 0.02),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.all(12.0.w),
                    child: Text(
                      'By continuing, you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
  }
}

class ReuseableContinueButton extends StatelessWidget {
  String buttonText;
  String imagePath;
  GestureTapCallback onTap;

  ReuseableContinueButton({
    super.key,
    required this.buttonText,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,

      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.width * 0.2,

        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          color: Colors.black,
        ),

        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,

            children: [
              Image(image: AssetImage(imagePath), height: 32.h, width: 32.w),
              SizedBox(width: 20.w),
              Text(
                buttonText,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
