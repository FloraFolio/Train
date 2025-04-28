import 'package:flutter/foundation.dart';
import 'package:flora_folio/config/api_config.dart';
import 'package:flora_folio/data/database/database_helper.dart';
import 'package:flora_folio/data/database/file_storage_service.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository_impl.dart';
import 'package:flora_folio/data/repositories/species_repository.dart';
import 'package:flora_folio/data/repositories/species_repository_impl.dart';
import 'package:flora_folio/data/services/gemini_photo_analysis_service.dart';
import 'package:flora_folio/data/services/photo_analysis_service.dart';
import 'package:flora_folio/data/services/photo_manager_service.dart';

/// 服务提供者，负责初始化和提供各种服务
class ServiceProvider {
  // 单例模式
  ServiceProvider._privateConstructor();
  static final ServiceProvider instance = ServiceProvider._privateConstructor();
  
  // 创建懒加载服务实例
  late final DatabaseHelper _databaseHelper = DatabaseHelper.instance;
  late final FileStorageService _fileStorageService = FileStorageService();
  
  // 存储库
  late final PlantPhotoRepository _photoRepository = PlantPhotoRepositoryImpl(
    dbHelper: _databaseHelper,
    fileStorage: _fileStorageService,
  );
  
  late final SpeciesRepository _speciesRepository = SpeciesRepositoryImpl(
    dbHelper: _databaseHelper,
  );
  
  // 服务
  late final PhotoAnalysisService _photoAnalysisService = GeminiPhotoAnalysisService(
    apiKey: ApiConfig.getGeminiApiKey(),
    apiEndpoint: ApiConfig.geminiApiEndpoint,
    speciesRepository: _speciesRepository,
  );
  
  late final PhotoManagerService _photoManagerService = PhotoManagerService(
    photoRepository: _photoRepository,
    analysisService: _photoAnalysisService,
  );
  
  // 公开获取服务的方法
  DatabaseHelper get databaseHelper => _databaseHelper;
  FileStorageService get fileStorageService => _fileStorageService;
  PlantPhotoRepository get photoRepository => _photoRepository;
  SpeciesRepository get speciesRepository => _speciesRepository;
  PhotoAnalysisService get photoAnalysisService => _photoAnalysisService;
  PhotoManagerService get photoManagerService => _photoManagerService;
  
  /// 初始化服务
  Future<void> initialize() async {
    // 确保数据库已初始化
    await _databaseHelper.database;
    
    // 在开发环境打印日志
    if (ApiConfig.isDevelopment) {
      debugPrint('服务初始化完成');
    }
  }
} 