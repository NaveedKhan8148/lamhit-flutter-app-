import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageFetchService.dart';
import 'package:lamhti_app/Services/ImageDownloadService/ImageDownlaodService.dart';
import 'package:shimmer/shimmer.dart';

import '../Home Section Screens/DetailedImageDiisplayScreen.dart';

class MyPurchasesScreen extends StatefulWidget {
  const MyPurchasesScreen({super.key});

  @override
  State<MyPurchasesScreen> createState() => _MyPurchasesScreenState();
}

class _MyPurchasesScreenState extends State<MyPurchasesScreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  ImageFetchService imageFetchService = ImageFetchService();
  ImageDownloadService imageDownloadService = ImageDownloadService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Purchases"),
        automaticallyImplyLeading: true,
      ),

      body: FutureBuilder(
        future: imageFetchService.getUserPurchases(uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No images available. Try purchasing one.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final purchases = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            itemCount: purchases.length,
            itemBuilder: (context, index) {
              final imageData = purchases[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DetailedImageDisplayScreen(
                            imageSize: imageData['imageSize'],
                            location: imageData['location'],
                            ownerEmail: imageData['email'],
                            ownerId: imageData["userId"],

                            imageUrl: imageData["imageUrl"],
                            imageTitle: imageData["title"],
                            imageDescription: imageData["description"],
                            imagePrice: 0,
                            isOwner:
                                true, //just so that buy now button remains hidden
                          ),
                    ),
                  );
                },

                child: InkWell(
                  onTap: () {
                    imageDownloadService.downloadImageToPhone(
                      imageData["imageUrl"],
                      imageData["title"] + ".jpeg",
                      context,
                    );
                  },
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 22.r,
                      child: ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: imageData["imageUrl"],
                          width: 50.w,
                          height: 50.h,
                          placeholder:
                              (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(
                                  color: Colors.white,
                                  height: 50.h,
                                  width: 50.h,
                                ),
                              ),
                          errorWidget:
                              (context, url, error) =>
                                  const Icon(Icons.error, color: Colors.red),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    title: Text(
                      imageData["title"],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      imageData["description"],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Icon(Icons.download),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
