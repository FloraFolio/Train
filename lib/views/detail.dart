import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flora_folio/data/models/plant_photo.dart';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository_impl.dart';

class DetailPage extends StatefulWidget {
  final String id;

  const DetailPage({Key? key, required this.id}) : super(key: key);

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  final PlantPhotoRepositoryImpl _photoRepository = PlantPhotoRepositoryImpl();
  late Future<PlantPhoto?> _futurePhoto;

  @override
  void initState() {
    super.initState();
    _futurePhoto = _photoRepository.getPhotoById(widget.id);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  }

  String getFullChineseClassification(dynamic metadata) {
    try {
      final species = metadata['species'];
      if (species is! Map) return 'Unknown';

      final levels = [
        'kingdom',
        'phylum',
        'class',
        'order',
        'family',
        'genus',
        'species'
      ];
      final result = <String>[];

      for (var level in levels) {
        final node = species[level];
        if (node is Map && node['chinese'] is String) {
          result.add(node['chinese']);
        } else if (node is List && node.isNotEmpty && node[0] is Map &&
            node[0]['chinese'] is String) {
          result.add(node[0]['chinese']);
        } else {
          result.add('unknown');
        }
      }

      return result.join(' ');
    } catch (e) {
      return 'Unknown';
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<PlantPhoto?>(
        future: _futurePhoto,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Photo not found", style: TextStyle(color: Colors.white)));
          }

          final plantPhoto = snapshot.data!;
          final capturedAt = plantPhoto.createdAt;
          final formattedTime = DateFormat('HH:mm dd/MM/yyyy').format(capturedAt);
          final metadata = plantPhoto.metadata;

          return Container(
            color: Colors.grey[900],
            child: SafeArea(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.file(
                      File(plantPhoto.photoPath),
                      fit: BoxFit.cover,
                      height: 400,
                    ),
                  ),
                  Column(
                    children: [
                      Stack(
                        children: [
                          Container(height: 400),
                          Positioned(
                            top: 0,
                            left: 10,
                            child: IconButton(
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                          Positioned(
                            top: 8,
                            left: 60,
                            child: Text(
                              plantPhoto.metadata['species'] is Map &&
                              plantPhoto.metadata['species']?['species'] is Map &&
                              plantPhoto.metadata['species']?['species']?['english'] is String
                              ? plantPhoto.metadata['species']['species']['english'] ?? 'Unknown'
                                  : 'Unknown',
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
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color.fromRGBO(0, 0, 0, 0.2),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(24.0),
                                child: plantPhoto.status == PhotoStatus.SUCCESS
                                    ? Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      'Captured at $formattedTime',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Species: ${getFullChineseClassification(plantPhoto.metadata)}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Introduction: ${plantPhoto.introduction ?? "No introduction"}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Description: ${plantPhoto.description ?? "No description"}',
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ],
                                )
                                    : Center(
                                  child: Text(
                                    'Status: ${plantPhoto.status.value}',
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
          );
        },
      ),
    );
  }
}
