import 'dart:io';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository_impl.dart';

class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  _HomePageContentState createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  File? _image;
  final PlantPhotoRepositoryImpl _photoRepository = PlantPhotoRepositoryImpl();

  // 打开相机拍照
  Future<void> _getImageFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });

      // Saving the photo to local and post it to gemini
      try {
        // 使用repository添加照片
        final photoId = await _photoRepository.addPlantPhoto(photoFile: _image!);
        print('Photo added successfully with ID: $photoId');
        
        // 这里可以添加其他逻辑（比如导航到结果页面）
      } catch (e) {
        print('Error adding plant photo: $e');
        // 可以添加错误处理比如显示SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // 显示最近一次的捕获内容
  Future<Widget> _getLastImage() async{
    final lastImages = await _photoRepository.getAllPhotos(limit: 1, sortOrder: SortOrder.newest);
    if (lastImages.isEmpty){
      return Center(
        child: Text(
          'No image captured yet.',
          style: TextStyle(color: Colors.white),
          textAlign: TextAlign.center,
        ),
      );
    } 

    // Get photoPath
    final lastImageInfo = lastImages.first;
    final _lastImage = File(lastImageInfo.photoPath);
    return  Center(child: Image.file(_lastImage!, fit: BoxFit.contain));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nice to see you today!'),
        backgroundColor: Colors.grey[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.camera_alt, size: 60, color: Colors.white),
                  const SizedBox(height: 8),
                  const Text(
                    'Obtain some plants!',
                    style: TextStyle(color: Colors.white),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _getImageFromCamera,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Take a Picture'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[700],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: FutureBuilder(
                  future: _getLastImage(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    return snapshot.data ?? Container();
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
