import 'dart:io';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flora_folio/data/models/plant_photo.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository.dart';
import 'package:flora_folio/data/services/photo_analysis_service.dart';

/// 照片管理服务，整合照片上传、分析和更新的流程
class PhotoManagerService {
  final PlantPhotoRepository _photoRepository;
  final PhotoAnalysisService _analysisService;

  /// 构造函数
  PhotoManagerService({
    required PlantPhotoRepository photoRepository,
    required PhotoAnalysisService analysisService,
  }) : 
    _photoRepository = photoRepository,
    _analysisService = analysisService;

  /// 处理新照片：保存到本地并启动分析
  Future<String> processNewPhoto(File photoFile) async {
    // 1. 添加照片到数据库，状态为正在分析
    final photoId = await _photoRepository.addPlantPhoto(
      photoFile: photoFile,
      status: PhotoStatus.ANALYZING,
    );
    
    // 2. 启动AI分析任务（不等待完成）
    _analyzePhotoAsync(photoId, photoFile);
    
    return photoId;
  }

  /// 异步分析照片
  Future<void> _analyzePhotoAsync(String photoId, File photoFile) async {
    try {
      // 3. 调用Gemini API进行分析
      final analysisResult = await _analysisService.analyzePhoto(photoFile);
      
      // 4. 更新照片记录
      if (analysisResult.success) {
        // 分析成功
        await _photoRepository.updatePhotoAnalysisResult(
          photoId: photoId,
          speciesId: analysisResult.speciesId,
          description: analysisResult.description,
          introduction: analysisResult.introduction,
          status: PhotoStatus.SUCCESS,
          additionalMetadata: analysisResult.data,
        );
      } else {
        // 分析失败
        await _photoRepository.updatePhotoAnalysisResult(
          photoId: photoId,
          status: PhotoStatus.FAILED,
          additionalMetadata: {
            'error': analysisResult.errorMessage,
            ...analysisResult.data,
          },
        );
      }
    } catch (e) {
      // 处理异常
      await _photoRepository.updatePhotoAnalysisResult(
        photoId: photoId,
        status: PhotoStatus.FAILED,
        additionalMetadata: {'error': e.toString()},
      );
    }
  }

  /// 获取照片
  Future<PlantPhoto?> getPhoto(String photoId) {
    return _photoRepository.getPhotoById(photoId);
  }

  /// 获取所有照片
  Future<List<PlantPhoto>> getAllPhotos({
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  }) {
    return _photoRepository.getAllPhotos(
      limit: limit,
      offset: offset,
      sortOrder: sortOrder,
    );
  }

  /// 获取指定状态的照片
  Future<List<PlantPhoto>> getPhotosByStatus(
    PhotoStatus status, {
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  }) {
    return _photoRepository.getPhotosByStatus(
      status,
      limit: limit,
      offset: offset,
      sortOrder: sortOrder,
    );
  }

  /// 获取指定种类的照片
  Future<List<PlantPhoto>> getPhotosBySpecies(
    String speciesId, {
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  }) {
    return _photoRepository.getPhotosBySpeciesId(
      speciesId,
      limit: limit,
      offset: offset,
      sortOrder: sortOrder,
    );
  }

  /// 删除照片
  Future<bool> deletePhoto(String photoId) {
    return _photoRepository.deletePhoto(photoId);
  }
} 