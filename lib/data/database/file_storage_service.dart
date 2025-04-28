import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

/// 文件存储服务，管理照片和元数据文件的存储
class FileStorageService {
  /// 获取照片目录
  Future<Directory> get _photosDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final photosDir = Directory('${appDir.path}/photos');
    
    // 确保目录存在
    if (!await photosDir.exists()) {
      await photosDir.create(recursive: true);
    }
    
    return photosDir;
  }

  /// 获取元数据目录
  Future<Directory> get _metadataDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final metadataDir = Directory('${appDir.path}/metadata');
    
    // 确保目录存在
    if (!await metadataDir.exists()) {
      await metadataDir.create(recursive: true);
    }
    
    return metadataDir;
  }

  /// 保存照片文件，返回存储路径
  Future<String> savePhotoFile(File photoFile, String photoId) async {
    final photosDir = await _photosDirectory;
    final newPath = path.join(photosDir.path, '$photoId.jpg');
    
    // 复制文件到新位置
    final savedFile = await photoFile.copy(newPath);
    return savedFile.path;
  }

  /// 删除照片文件
  Future<void> deletePhotoFile(String photoPath) async {
    final file = File(photoPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// 删除与照片ID关联的所有文件
  Future<void> deletePhotoFiles(String photoId) async {
    try {
      final photosDir = await _photosDirectory;
      final metadataDir = await _metadataDirectory;
      
      // 删除照片文件
      final photoFile = File(path.join(photosDir.path, '$photoId.jpg'));
      if (await photoFile.exists()) {
        await photoFile.delete();
      }
      
      // 删除元数据文件（如果存在）
      final metadataFile = File(path.join(metadataDir.path, '$photoId.json'));
      if (await metadataFile.exists()) {
        await metadataFile.delete();
      }
    } catch (e) {
      print('删除照片文件失败: $e');
    }
  }

  /// 获取照片文件
  Future<File?> getPhotoFile(String photoId) async {
    final photosDir = await _photosDirectory;
    final filePath = path.join(photosDir.path, '$photoId.jpg');
    final file = File(filePath);
    
    if (await file.exists()) {
      return file;
    }
    return null;
  }
} 