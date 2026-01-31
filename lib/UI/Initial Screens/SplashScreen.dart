import 'package:flutter/material.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/LoginCheck.dart';
import 'package:lamhti_app/UI/Initial%20Screens/SignInScreen.dart';
import 'package:lamhti_app/UI/Main%20Screens/MainNavigationBar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  LoginCheck loginCheck = LoginCheck();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      navigateToNextScreen();
    });
  }

  void navigateToNextScreen() {
    final isLoggedIn = loginCheck.isLoggedIn();

    if (isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainNavigationBar()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SignInScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,

        children: [
          Image(image: AssetImage("assets/images/lamhti logo with text.png")),
        ],
      ),
    );
  }
}
