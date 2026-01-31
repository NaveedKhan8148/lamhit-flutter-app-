import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageDeleteService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageFetchService.dart';
import 'package:lamhti_app/Utils/Toast.dart';
import 'package:shimmer/shimmer.dart';

import '../Home Section Screens/DetailedImageDiisplayScreen.dart';

class Myuploadsscreen extends StatefulWidget {
  const Myuploadsscreen({super.key});

  @override
  State<Myuploadsscreen> createState() => _MyuploadsscreenState();
}

class _MyuploadsscreenState extends State<Myuploadsscreen> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  ImageFetchService imageFetchService = ImageFetchService();

  ImageDeleteService imageDeleteService = ImageDeleteService();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("My Uploads"),
        automaticallyImplyLeading: true,
      ),
      body: FutureBuilder(
        future: imageFetchService.getUserAvaiableUplaods(uid),
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
                "No images available. Try uploading one.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final uploads = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            itemCount: uploads.length,
            itemBuilder: (context, index) {
              final imageData = uploads[index];

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => DetailedImageDisplayScreen(
                            imageSize: imageData['imageSize'],
                            location: imageData['location'],
                            ownerId: imageData["userId"],
                            ownerEmail: imageData['email'],
                            imageUrl: imageData["imageUrl"],
                            imageTitle: imageData["title"],
                            imageDescription: imageData["description"],
                            imagePrice: 2.0,
                            isOwner: true,
                          ),
                    ),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.black),
                    onPressed: () async {
                      final confirm = await showDialog(
                        context: context,
                        builder:
                            (context) => AlertDialog(
                              title: const Text('Delete Image'),
                              content: const Text(
                                'Are you sure you want to delete this image?',
                              ),
                              actions: [
                                TextButton(
                                  child: const Text('Cancel'),
                                  onPressed:
                                      () => Navigator.pop(context, false),
                                ),
                                TextButton(
                                  child: const Text('Delete'),
                                  onPressed: () => Navigator.pop(context, true),
                                ),
                              ],
                            ),
                      );

                      if (confirm) {
                        try {
                          await imageDeleteService.deleteUploadedImage(
                            imageData["imageUrl"],
                            imageData.id,
                          );

                          // Force rebuild to reflect deletion
                          setState(() {});

                          Toast.toastMessage(
                            'Image deleted successfully',
                            Colors.black,
                          );
                        } catch (e) {
                          Toast.toastMessage(
                            'Error deleting image: $e',
                            Colors.red,
                          );
                        }
                      }
                    },
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
