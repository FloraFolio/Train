import 'dart:io';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flora_folio/data/models/plant_photo.dart';

/// 植物照片仓库接口
abstract class PlantPhotoRepository {
  /// 添加新的植物照片
  Future<String> addPlantPhoto({
    required File photoFile,
    String? speciesId,
    String? description,
    String? introduction,
    PhotoStatus status = PhotoStatus.ANALYZING,
    Map<String, dynamic>? additionalMetadata,
  });

  /// 更新照片解析结果
  Future<bool> updatePhotoAnalysisResult({
    required String photoId,
    String? speciesId,
    String? description,
    String? introduction,
    required PhotoStatus status,
    Map<String, dynamic>? additionalMetadata,
  });

  /// 根据ID获取照片
  Future<PlantPhoto?> getPhotoById(String photoId);

  /// 根据植物种类ID获取照片列表
  Future<List<PlantPhoto>> getPhotosBySpeciesId(
    String speciesId, {
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  });

  /// 根据照片状态获取照片列表
  Future<List<PlantPhoto>> getPhotosByStatus(
    PhotoStatus status, {
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  });

  /// 获取所有照片
  Future<List<PlantPhoto>> getAllPhotos({
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  });

  /// 删除照片
  Future<bool> deletePhoto(String photoId);
} 