import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart'; 

class DetailPage extends StatelessWidget {
  final String id;
  final Map<String, dynamic> plant = {
    'photoId': '12345',
    'speciesId': '1',
    'description': 'A plantaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.',
    'status': 'SUCCESS',
    'picture': 'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl.jpg',
    'metadata': {
      'location': {
        'latitude': 40.7128,
        'longitude': -74.0060,
      },
      'capturedAt': '2023-06-15T14:30:00Z',
      'tags': ['indoor', 'flowering'],
      'customAttributes': {},
    }
  };

  DetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    var capturedAt = DateTime.parse(plant['metadata']['capturedAt']);
    var formattedTime = DateFormat('HH:mm dd/MM/yyyy').format(capturedAt);
    var latitude = plant['metadata']['location']['latitude'].toStringAsFixed(2);
    var longitude = plant['metadata']['location']['longitude'].toStringAsFixed(2);

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light); // 设置状态栏字体颜色（亮色/白色）

    return Scaffold(
      body: Container(
        color: Colors.grey[900], 
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.network(
                  plant['picture'],
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
                            child: plant['status'] == 'SUCCESS'
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(
                                        'Captured at $formattedTime at ($latitude, $longitude)',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Species: get species by id ${plant['speciesId']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Description: ${plant['description']}',
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ],
                                  )
                                : Center(
                                    child: Text(
                                      '${plant['status']}',
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
