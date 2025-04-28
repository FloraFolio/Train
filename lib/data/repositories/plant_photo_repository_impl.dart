import 'dart:io';
import 'package:uuid/uuid.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flora_folio/data/models/plant_photo.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository.dart';
import 'package:flora_folio/data/database/database_helper.dart';
import 'package:flora_folio/data/database/file_storage_service.dart';

/// 植物照片仓库实现
class PlantPhotoRepositoryImpl implements PlantPhotoRepository {
  final DatabaseHelper _dbHelper;
  final FileStorageService _fileStorage;
  final Uuid _uuid = const Uuid();

  /// 构造函数
  PlantPhotoRepositoryImpl({
    DatabaseHelper? dbHelper,
    FileStorageService? fileStorage,
  }) : 
    _dbHelper = dbHelper ?? DatabaseHelper.instance,
    _fileStorage = fileStorage ?? FileStorageService();

  @override
  Future<String> addPlantPhoto({
    required File photoFile,
    String? speciesId,
    String? description,
    String? introduction,
    PhotoStatus status = PhotoStatus.ANALYZING,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final db = await _dbHelper.database;
    
    // 生成唯一的照片ID
    final photoId = _uuid.v4();
    
    // 保存照片到文件系统
    final photoPath = await _fileStorage.savePhotoFile(photoFile, photoId);
    
    // 准备元数据
    final metadata = additionalMetadata ?? {};
    
    // 创建照片记录
    final now = DateTime.now();
    final photo = PlantPhoto(
      photoId: photoId,
      speciesId: speciesId,
      description: description,
      introduction: introduction,
      photoPath: photoPath,
      status: status,
      metadata: metadata,
      createdAt: now,
    );
    
    // 插入数据库
    await db.insert('plant_photos', photo.toMap());
    
    return photoId;
  }

  @override
  Future<bool> updatePhotoAnalysisResult({
    required String photoId,
    String? speciesId,
    String? description,
    String? introduction,
    required PhotoStatus status,
    Map<String, dynamic>? additionalMetadata,
  }) async {
    final db = await _dbHelper.database;
    
    // 获取当前照片记录
    final photo = await getPhotoById(photoId);
    if (photo == null) {
      return false;
    }
    
    // 更新元数据
    final metadata = Map<String, dynamic>.from(photo.metadata);
    if (additionalMetadata != null) {
      metadata.addAll(additionalMetadata);
    }
    
    // 创建更新后的照片记录
    final updatedPhoto = photo.copyWith(
      speciesId: speciesId,
      description: description,
      introduction: introduction,
      status: status,
      metadata: metadata,
      updatedAt: DateTime.now(),
    );
    
    // 更新数据库
    final count = await db.update(
      'plant_photos',
      updatedPhoto.toMap(),
      where: 'photo_id = ?',
      whereArgs: [photoId],
    );
    
    return count > 0;
  }

  @override
  Future<PlantPhoto?> getPhotoById(String photoId) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'plant_photos',
      where: 'photo_id = ?',
      whereArgs: [photoId],
    );
    
    if (maps.isNotEmpty) {
      return PlantPhoto.fromMap(maps.first);
    }
    
    return null;
  }

  @override
  Future<List<PlantPhoto>> getPhotosBySpeciesId(
    String speciesId, {
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  }) async {
    final db = await _dbHelper.database;
    
    // 构建查询
    String orderBy = _getSortOrderString(sortOrder);
    
    final maps = await db.query(
      'plant_photos',
      where: 'species_id = ?',
      whereArgs: [speciesId],
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => PlantPhoto.fromMap(map)).toList();
  }

  @override
  Future<List<PlantPhoto>> getPhotosByStatus(
    PhotoStatus status, {
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  }) async {
    final db = await _dbHelper.database;
    
    // 构建查询
    String orderBy = _getSortOrderString(sortOrder);
    
    final maps = await db.query(
      'plant_photos',
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => PlantPhoto.fromMap(map)).toList();
  }

  @override
  Future<List<PlantPhoto>> getAllPhotos({
    int? limit,
    int? offset,
    SortOrder sortOrder = SortOrder.newest,
  }) async {
    final db = await _dbHelper.database;
    
    // 构建查询
    String orderBy = _getSortOrderString(sortOrder);
    
    final maps = await db.query(
      'plant_photos',
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
    
    return maps.map((map) => PlantPhoto.fromMap(map)).toList();
  }

  @override
  Future<bool> deletePhoto(String photoId) async {
    final db = await _dbHelper.database;
    
    // 获取照片记录
    final photo = await getPhotoById(photoId);
    if (photo == null) {
      return false;
    }
    
    // 删除文件
    await _fileStorage.deletePhotoFiles(photoId);
    
    // 从数据库删除记录
    final count = await db.delete(
      'plant_photos',
      where: 'photo_id = ?',
      whereArgs: [photoId],
    );
    
    return count > 0;
  }

  /// 根据排序枚举获取排序字符串
  String _getSortOrderString(SortOrder sortOrder) {
    switch (sortOrder) {
      case SortOrder.newest:
        return 'created_at DESC';
      case SortOrder.oldest:
        return 'created_at ASC';
      case SortOrder.nameAsc:
        return 'description ASC';
      case SortOrder.nameDesc:
        return 'description DESC';
    }
  }
} 