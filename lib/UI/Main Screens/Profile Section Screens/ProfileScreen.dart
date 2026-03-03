import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/AccountDeletionService.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/AppleAuthService.dart';
import 'package:lamhti_app/Services/Firebase%20Auth/GoogleAuthService.dart';
import 'package:lamhti_app/UI/Initial%20Screens/SignInScreen.dart';

import 'AboutUsScreen.dart';
import 'MyPurchasesScreen.dart';
import 'MyUploadsScreen.dart';


class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userName = FirebaseAuth.instance.currentUser!.displayName;

  GoogleAuthService googleAuthService = GoogleAuthService();

  AppleAuthService appleAuthService = AppleAuthService();

  AccountDeletionService accountDeletionService = AccountDeletionService();

  bool isDeleting = false;

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
            
            // Delete Account Option
            ListTile(
              leading: Icon(Icons.delete_forever, color: Colors.red),
              title: Text("Delete Account", style: TextStyle(color: Colors.red)),
              onTap: isDeleting ? null : () async {
                // Show confirmation dialog
                final shouldDelete = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Delete Account?"),
                      ],
                    ),
                    content: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "This action is permanent and cannot be undone.",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          SizedBox(height: 15),
                          Text("The following data will be permanently deleted:"),
                          SizedBox(height: 10),
                          _buildDeleteItem("• Your account and profile"),
                          _buildDeleteItem("• All uploaded images"),
                          _buildDeleteItem("• Purchase history"),
                          _buildDeleteItem("• All associated data"),
                          SizedBox(height: 15),
                          Text(
                            "Are you absolutely sure you want to delete your account?",
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context, false);
                        },
                        child: Text("Cancel"),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: Text("DELETE"),
                      ),
                    ],
                  ),
                );

                if (shouldDelete == true) {
                  // Show final confirmation
                  final finalConfirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text("Final Confirmation"),
                      content: Text(
                        "This is your last chance to cancel. Once deleted, your account cannot be recovered.\n\nDelete account permanently?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context, false);
                          },
                          child: Text("Cancel"),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, true);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: Text("YES, DELETE"),
                        ),
                      ],
                    ),
                  );

                  if (finalConfirm == true) {
                    setState(() {
                      isDeleting = true;
                    });

                    // Perform account deletion
                    final success = await accountDeletionService.deleteUserAccount();

                    if (success) {
                      // Navigate to sign-in screen
                      if (mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => SignInScreen()),
                          (route) => false,
                        );
                      }
                    } else {
                      setState(() {
                        isDeleting = false;
                      });
                    }
                  }
                }
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

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Text(
        text,
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }
}
