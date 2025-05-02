import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _showDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final listItems = [
      {'icon': Icons.person, 'title': 'Account'},
      {'icon': Icons.info, 'title': 'About'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[

            ElevatedButton(
              onPressed: () => _showDialog(context, 'Import App Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(24.0),
                elevation: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Icon(Icons.download, size: 40, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Import App Data',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Export Button
            ElevatedButton(
              onPressed: () => _showDialog(context, 'Export App Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                padding: const EdgeInsets.all(24.0),
                elevation: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const <Widget>[
                  Icon(Icons.upload, size: 40, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Export App Data',
                      style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Use Expanded so the ListView fits in remaining space
            Expanded(
              child: ListView.builder(
                itemCount: listItems.length,
                itemBuilder: (context, index) {
                  final item = listItems[index];
                  return ListTile(
                    leading: Icon(item['icon'] as IconData),
                    title: Text(item['title'] as String),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
