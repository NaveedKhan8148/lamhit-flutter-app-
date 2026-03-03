import 'dart:developer';
import 'dart:io';

import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/AppleAuthService.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/EmailAuthService.dart';
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

  EmailAuthService emailAuthService = EmailAuthService();

  UserDetailsStorageService userDetailsStorageService =
      UserDetailsStorageService();

  bool isLoading = false;

  // Email authentication controllers
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUpMode = false; // Toggle between sign-in and sign-up
  bool _obscurePassword = true; // Toggle password visibility

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

                SizedBox(height: 15.h),

                // Email Login Form
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 30.w),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email TextField
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: TextStyle(fontSize: 14.sp),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined, size: 20.sp),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 12.h),

                        // Password TextField
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: TextStyle(fontSize: 14.sp),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock_outline, size: 20.sp),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 20.sp,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                            isDense: true,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (_isSignUpMode && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),

                        SizedBox(height: 5.h),

                        // Forgot Password Link
                        if (!_isSignUpMode)
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () async {
                                if (_emailController.text.trim().isEmpty) {
                                  Toast.toastMessage(
                                    "Please enter your email first",
                                    Colors.orange,
                                  );
                                  return;
                                }
                                await emailAuthService.sendPasswordResetEmail(
                                  _emailController.text.trim(),
                                );
                              },
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 14.sp,
                                ),
                              ),
                            ),
                          ),

                        SizedBox(height: 5.h),

                        // Sign In / Sign Up Button
                        InkWell(
                          onTap: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() {
                                isLoading = true;
                              });

                              try {
                                final user = _isSignUpMode
                                    ? await emailAuthService.signUpWithEmail(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      )
                                    : await emailAuthService.signInWithEmail(
                                        _emailController.text.trim(),
                                        _passwordController.text,
                                      );

                                if (user != null) {
                                  await userDetailsStorageService
                                      .setupUserDetailsIfNeeded();

                                  Toast.toastMessage(
                                    _isSignUpMode
                                        ? "Account Created Successfully"
                                        : "Signed In Successfully",
                                    Colors.black,
                                  );

                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => MainNavigationBar(),
                                    ),
                                  );
                                }
                              } catch (e) {
                                debugPrint("Email auth error: $e");
                              } finally {
                                setState(() {
                                  isLoading = false;
                                });
                              }
                            }
                          },
                          child: Container(
                            width: double.infinity,
                            height: 45.h,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12.r),
                              color: Colors.black,
                            ),
                            child: Center(
                              child: Text(
                                _isSignUpMode ? 'Sign Up' : 'Sign In',
                                style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 10.h),

                        // Toggle between Sign In and Sign Up
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isSignUpMode
                                  ? 'Already have an account?'
                                  : "Don't have an account?",
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _isSignUpMode = !_isSignUpMode;
                                });
                              },
                              child: Text(
                                _isSignUpMode ? 'Sign In' : 'Sign Up',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 12.h),

                (Platform.isIOS)
                    ? SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
                    )
                    : SizedBox(
                      height: MediaQuery.of(context).size.height * 0.02,
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
                      "OR",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
