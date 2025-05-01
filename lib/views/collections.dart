import 'package:flutter/material.dart';
import 'detail.dart';
import '../utils/slideRoute.dart';

class ListPage extends StatefulWidget {
  const ListPage({super.key});

  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
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
      body: PageView.builder(
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
    );
  }
}
