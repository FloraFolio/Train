import 'package:flutter/material.dart';
import 'detail.dart';
import 'dart:io';
import '../utils/slideRoute.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository_impl.dart';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flora_folio/data/models/plant_photo.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final PlantPhotoRepositoryImpl _photoRepository = PlantPhotoRepositoryImpl();
  final PageController _pageController = PageController();
  Future<List<PlantPhoto>> _photosFuture = Future.value([]);

  int currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _photosFuture = _photoRepository.getPhotosByStatus(PhotoStatus.SUCCESS);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlantPhoto>>(
      future: _photosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Error'),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            body: Center(
              child: Text('Error loading photos'),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Please take a photo'),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            body: Center(
              child: const Text('No SUCCESS photos yet'),
            ),
          );
        } else {
          final photos = snapshot.data!;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                photos[currentIndex].metadata['species'] is Map &&
                    photos[currentIndex].metadata['species']?['species'] is Map &&
                    photos[currentIndex].metadata['species']?['species']?['english'] is String
                    ? photos[currentIndex].metadata['species']['species']['english'] ?? 'Unknown'
                    : 'Unknown',
              ),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              centerTitle: true,
            ),
            body: PageView.builder(
              controller: _pageController,
              scrollDirection: Axis.vertical,
              itemCount: photos.length,
              onPageChanged: (index) {
                setState(() {
                  currentIndex = index;
                });
              },
              itemBuilder: (context, index) {
                final plant = photos[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      SlidePageRoute(page: DetailPage(id: plant.photoId)),
                    );
                  },
                  child: Image.file(
                    File(plant.photoPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(Icons.broken_image, size: 64, color: Colors.white70)),
                  ),
                );
              },
            ),
          );
        }
      },
    );
  }
}
