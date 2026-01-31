
import 'package:firebase_auth/firebase_auth.dart';

class LoginCheck{


  bool isLoggedIn() {

    User? user = FirebaseAuth.instance.currentUser;

    if(user != null){
      return true;
    } else{
      return false;
    }
  }

}