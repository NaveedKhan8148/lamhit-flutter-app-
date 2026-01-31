import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamhti_app/Services/Firebase%20Storage/ImageFetchService.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

import 'DetailedImageDiisplayScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final userid = FirebaseAuth.instance.currentUser!.uid;
  final ImageFetchService imageFetchService = ImageFetchService();
  static const int _pageSize = 10;
  bool _isInitialLoading = false;

  List<DocumentSnapshot> _images = [];
  List<DocumentSnapshot> _filteredImages = [];

  bool _isLoadingMore = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDoc;

  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchInitialImages();
    scrollController.addListener(_scrollListener);
    searchController.addListener(_filterImages);
  }

  void _scrollListener() {
    if (scrollController.position.pixels >=
        scrollController.position.maxScrollExtent - 300) {
      if (!_isLoadingMore && _hasMore) {
        _fetchMoreImages();
      }
    }
  }

  void _filterImages() {
    final query = searchController.text.toLowerCase();

    setState(() {
      _filteredImages =
          _images.where((img) {
            final title = img["title"].toString().toLowerCase();
            final desc = img["description"].toString().toLowerCase();
            return title.contains(query) || desc.contains(query);
          }).toList();
    });
  }

  Future<void> _fetchInitialImages() async {
    setState(() {
      _isInitialLoading = true;
    });

    final snapshot =
        await imageFetchService.getAllAvailableImagesWithPagination();

    if (!mounted) return;
    setState(() {
      _images = snapshot.docs;
      _filteredImages = snapshot.docs;
      _lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;
      _hasMore = snapshot.docs.length == _pageSize;
      _isInitialLoading = false;
    });
  }

  Future<void> _fetchMoreImages() async {
    if (_lastDoc == null || !mounted) return;

    setState(() {
      _isLoadingMore = true;
    });

    final snapshot = await imageFetchService
        .getAllAvailableImagesWithPagination(lastDoc: _lastDoc);
    if (!mounted) return;

    final newDocs = snapshot.docs;
    final newDocIds = newDocs.map((doc) => doc.id).toSet();
    _images.removeWhere((doc) => newDocIds.contains(doc.id));

    setState(() {
      _images.addAll(newDocs);
      _lastDoc = newDocs.isNotEmpty ? newDocs.last : _lastDoc;
      _hasMore = newDocs.length == _pageSize;
      _isLoadingMore = false;
    });

    _filterImages();
  }

  @override
  void dispose() {
    scrollController.removeListener(_scrollListener);
    scrollController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Marketplace",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          children: [
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: "Search images...",
                suffixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(80.r),
                  borderSide: BorderSide(color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 12.h),
            Expanded(
              child:
                  _isInitialLoading
                      ? Center(child: CircularProgressIndicator())
                      : (_filteredImages.isEmpty && !_isLoadingMore)
                      ? Center(child: Text("No images found."))
                      : GridView.builder(
                        controller: scrollController,
                        itemCount:
                            _filteredImages.length + (_isLoadingMore ? 1 : 0),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16.h,
                          crossAxisSpacing: 12.w,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (context, index) {
                          if (index < _filteredImages.length) {
                            final image = _filteredImages[index];
                            final imageId = image.id;

                            return InkWell(
                              borderRadius: BorderRadius.circular(16.r),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => DetailedImageDisplayScreen(
                                          ownerId: image["userId"],
                                          imageSize: image['imageSize'],
                                          location: image['location'],
                                          ownerEmail: image['email'],
                                          imageUrl: image["imageUrl"],
                                          imageTitle: image["title"],
                                          imageDescription:
                                              image["description"],
                                          imagePrice: image["price"],
                                          imageId: imageId,
                                          isOwner: image["userId"] == userid,
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
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                          SizedBox(height: 5.h),
                                          Text(
                                            'Price : \$' +
                                                image["price"].toString(),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w600,
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
                                          SizedBox(height: 6.h),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
