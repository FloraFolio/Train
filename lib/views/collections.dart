import 'package:flutter/material.dart';
import 'detail.dart';
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

  Future<List<PlantPhoto>> _fetchSuccessPhotos() {
    return _photoRepository.getPhotosByStatus(PhotoStatus.SUCCESS);
  }

  int currentIndex = 0;

  final List<Map<String, String>> listPlants = [
    {
      'photoId': '12345',
      'picture': 'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
    },
    {
      'photoId': '67890',
      'picture': 'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Photo ID: ${listPlants[currentIndex]['photoId']}'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          PageView.builder(
            scrollDirection: Axis.vertical,
            itemCount: listPlants.length,
            onPageChanged: (index) {
              setState(() {
                currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final plant = listPlants[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    SlidePageRoute(page: DetailPage(id: plant['photoId']!)),
                  );
                },
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      plant['picture'] ?? '',
                      fit: BoxFit.cover,
                    ),
                  ],
                ),
              );
            },
          ),
          Positioned(
            top: 16,
            left: 16,
            child: FutureBuilder<List<PlantPhoto>>(
              future: _fetchSuccessPhotos(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error loading photos',
                      style: TextStyle(color: Colors.white));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Text('No SUCCESS photos yet',
                      style: TextStyle(color: Colors.white));
                } else {
                  final photos = snapshot.data!;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color.fromRGBO(0, 0, 0, 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'SUCCESS Photos: ${photos.length}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
