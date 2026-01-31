import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/AppleAuthService.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/GoogleAuthService.dart';
import 'package:lamhti_app/UI/Initial%20Screens/SignInScreen.dart';

import 'AboutUsScreen.dart';
import 'MyPurchasesScreen.dart';
import 'MyUploadsScreen.dart';


class ProfileScreen extends StatelessWidget {

  String? userName = FirebaseAuth.instance.currentUser!.displayName;

  GoogleAuthService googleAuthService = GoogleAuthService();

  AppleAuthService appleAuthService = AppleAuthService();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text("Profile",
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),

      ),
      body: Padding(
        padding:  EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Welcome, $userName!",
              maxLines: 1,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 30.h),
            ListTile(
              leading: Icon(Icons.upload_file),
              title: Text("My Uploads"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => Myuploadsscreen())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.shopping_bag),
              title: Text("My Purchases"),
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MyPurchasesScreen())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.edit),
              title: Text("About Us"),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => AboutUsScreen())
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red,),
              title: Text("Logout", style: TextStyle(color: Colors.red),),
              onTap: () async{
                final shouldLogout = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text("Confirm Logout"),
                      content: const Text("Are you sure you want to logout?"),
                      actions: [
                        TextButton(onPressed: (){
                          Navigator.pop(context, false);
                        },
                            child: const Text("Cancel")
                        ),
                        TextButton(onPressed: (){
                          Navigator.pop(context,true);
                        },
                            child: const Text("Yes")
                        )
                      ],
                    )
                );

                if(shouldLogout == true){

                  final authenticationProviderId = FirebaseAuth.instance.currentUser!.providerData.first.providerId;

                  if(authenticationProviderId == "google.com"){
                    await googleAuthService.signOut();
                  } else if(authenticationProviderId == "apple.com"){
                    await appleAuthService.signOut();
                  } else{
                    //in case new sign in features such as email apssword  added
                    await FirebaseAuth.instance.signOut();
                  }

                  Navigator.pushAndRemoveUntil(context,
                      MaterialPageRoute(builder: (context) => SignInScreen()),
                      (route) => false);
                }

              },
            ),
          ],
        ),
      ),
    );
  }
}
