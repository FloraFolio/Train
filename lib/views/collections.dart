import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
       appBar: AppBar(
        title: const Text('<Plant Name>'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
        centerTitle: true,
      ),

      body: Center(
        child: Text(
          'list',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
