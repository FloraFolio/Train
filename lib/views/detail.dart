import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:flora_folio/data/models/plant_photo.dart';
import 'package:flora_folio/data/models/photo_status.dart';

class DetailPage extends StatelessWidget {
  final String id;
  late final PlantPhoto plantPhoto;

  DetailPage({super.key, required this.id}) {
    plantPhoto = PlantPhoto(
      photoId: id,
      speciesId: '1',
      description: 'A plant...aaaaaaaaaaaaaaaaaaaaaa',
      introduction: '1',
      photoPath: 'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
      status: PhotoStatusExtension.fromString('SUCCESS'),
      metadata: {
      'location': {
      'latitude': 40.7128,
      'longitude': -74.0060,
      }},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    var capturedAt = plantPhoto.createdAt;
    var formattedTime = DateFormat('HH:mm dd/MM/yyyy').format(capturedAt);
    var latitude = plantPhoto.metadata['location']['latitude'].toStringAsFixed(2);
    var longitude = plantPhoto.metadata['location']['longitude'].toStringAsFixed(2);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Container(
        color: Colors.grey[900],
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  plantPhoto.photoPath,
                  fit: BoxFit.cover,
                  height: 400,
                ),
              ),
              Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        height: 400,
                      ),
                      Positioned(
                        top: 0,
                        left: 10,
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                      Positioned(
                        top: 8,
                        left: 60,
                        child: Text(
                          'Plant Detail ($id)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: DraggableScrollableSheet(
                      initialChildSize: 0.6,
                      minChildSize: 0.5,
                      maxChildSize: 1,
                      builder: (context, scrollController) {
                        return SingleChildScrollView(
                          controller: scrollController,
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromRGBO(0, 0, 0, 0.2),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(24.0),
                            child: plantPhoto.status == PhotoStatus.SUCCESS
                                ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Captured at $formattedTime at ($latitude, $longitude)',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Species: get species by id ${plantPhoto.speciesId}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'Description: ${plantPhoto.description}',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            )
                                : Center(
                              child: Text(
                                '${plantPhoto.status}',
                                style: const TextStyle(fontSize: 24, color: Colors.red),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
