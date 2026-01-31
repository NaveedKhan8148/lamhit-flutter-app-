import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageFetchService.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageUploadService.dart';
import 'package:lamhti_app/UI/Main%20Screens/Upload%20Section%20Screens/ImageUploadScreen.dart';
import 'package:lamhti_app/Utils/ReuseableBottomButton.dart';
import 'package:shimmer/shimmer.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'DetailedImageDiisplayScreen.dart';
import 'HomeScreen.dart';

class FeaturedImagesScreen extends StatefulWidget {
  const FeaturedImagesScreen({super.key});

  @override
  State<FeaturedImagesScreen> createState() => _FeaturedImagesScreenState();
}

class _FeaturedImagesScreenState extends State<FeaturedImagesScreen> {
  final userid = FirebaseAuth.instance.currentUser!.uid;
  final ImageFetchService imageFetchService = ImageFetchService();
  Future? featuredImages;

  @override
  void initState() {
    super.initState();
    _initializeData();
    featuredImages = imageFetchService.getFeaturedImages();
  }

  Future<void> _initializeData() async {
    await imageFetchService.deleteUnsoldUploads();

    // once cleanup done, fetch fresh featured images
    final fetched = imageFetchService.getFeaturedImages();

    // ensure the widget is still mounted before updating state
    if (mounted) {
      setState(() {
        featuredImages = fetched;
      });
    }
  }

  Future<void> _refreshImages() async {
    await imageFetchService.deleteUnsoldUploads();

    setState(() {
      featuredImages = imageFetchService.getFeaturedImages();
    });
  }

  @override
  String? selectedCategory;

  final List<String> categories = [
    'All',

    'Art',

    'Tech',
    'Food',

    'Travel',
    'Nature',

    'Fashion',
    'Other',
  ];
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          selectedCategory == null || selectedCategory == 'All'
              ? "Latest Uploads"
              : "Latest ${selectedCategory!} Uploads",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
        actions: [
          PopupMenuButton<String>(
            color: Colors.white,
            elevation: 4,
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                selectedCategory = value;
              });
            },
            itemBuilder: (context) {
              return categories.map((String category) {
                return PopupMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList();
            },
          ),
        ],
      ),
      body: FutureBuilder(
        future: featuredImages,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            log('error ${snapshot.error}');
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
            return Center(
              child: Text(
                "No images available. Try uploading one.",
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final images = snapshot.data.docs;
          final filteredImages =
              (selectedCategory == null || selectedCategory == 'All')
                  ? images
                  : images.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final cat =
                        (data['category'] ?? 'Other').toString().toLowerCase();
                    return cat == selectedCategory!.toLowerCase();
                  }).toList();
          return Padding(
            padding: EdgeInsets.all(12.w),
            child: Column(
              children: [
                Expanded(
                  child:
                      filteredImages.isEmpty
                          ? Center(child: Text('No Category found'))
                          : RefreshIndicator(
                            onRefresh: _refreshImages,
                            child: GridView.builder(
                              itemCount: filteredImages.length,
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 16.h,
                                    crossAxisSpacing: 12.w,
                                    childAspectRatio: 0.7,
                                  ),
                              itemBuilder: (context, index) {
                                final image = filteredImages[index];
                                final imageId = image.id;

                                return InkWell(
                                  borderRadius: BorderRadius.circular(16.r),
                                  onTap: () {
                                    log(
                                      '------print the image id is ---------${imageId}',
                                    );
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) =>
                                                DetailedImageDisplayScreen(
                                                  imageSize: image['imageSize'],
                                                  location: image['location'],
                                                  ownerId: image["userId"],
                                                  ownerEmail: image['email'],
                                                  imageUrl: image["imageUrl"],
                                                  imageTitle: image["title"],
                                                  imageDescription:
                                                      image["description"],

                                                  imagePrice: image["price"],
                                                  imageId: imageId,
                                                  isOwner:
                                                      image["userId"] == userid,
                                                ),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    elevation: 4,
                                    color: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16.r),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.vertical(
                                              top: Radius.circular(16.r),
                                            ),
                                            child: CachedNetworkImage(
                                              imageUrl: image["imageUrl"],
                                              placeholder:
                                                  (context, url) =>
                                                      Shimmer.fromColors(
                                                        baseColor:
                                                            Colors.grey[300]!,
                                                        highlightColor:
                                                            Colors.grey[100]!,
                                                        child: Container(
                                                          color: Colors.white,
                                                        ),
                                                      ),
                                              errorWidget:
                                                  (context, url, error) =>
                                                      const Icon(
                                                        Icons.error,
                                                        color: Colors.red,
                                                      ),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 10.w,
                                            vertical: 8.h,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                image["title"],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                              ),
                                              SizedBox(height: 4.h),

                                              Text(
                                                'Price :\$' +
                                                    image["price"].toString(),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme
                                                    .textTheme
                                                    .titleSmall
                                                    ?.copyWith(
                                                      fontWeight:
                                                          FontWeight.w500,
                                                    ),
                                              ),
                                              SizedBox(height: 4.h),
                                              Text(
                                                image["description"],
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                ),

                // View All Button
                SizedBox(height: 10.h),
                SizedBox(
                  width: double.infinity,
                  child: ReuseableBottomButton(
                    buttonText: "View All Images",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
