import 'package:uuid/uuid.dart';
import 'package:flora_folio/data/models/species.dart';
import 'package:flora_folio/data/repositories/species_repository.dart';
import 'package:flora_folio/data/database/database_helper.dart';

/// 植物种类仓库实现
class SpeciesRepositoryImpl implements SpeciesRepository {
  final DatabaseHelper _dbHelper;
  final Uuid _uuid = const Uuid();

  /// 构造函数
  SpeciesRepositoryImpl({
    DatabaseHelper? dbHelper,
  }) : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  @override
  Future<String> addSpecies({
    required String name,
    String? description,
    String? introduction,
    String? taxonomyPath,
    Map<String, dynamic>? taxonomyData,
  }) async {
    final db = await _dbHelper.database;
    
    // 首先尝试通过分类路径查找
    if (taxonomyPath != null && taxonomyPath.isNotEmpty && taxonomyPath != 'unknown') {
      final speciesList = await getSpeciesByTaxonomyPath(taxonomyPath);
      if (speciesList.isNotEmpty) {
        return speciesList.first.speciesId;
      }
    }
    
    // 然后检查是否已存在同名种类
    final existingSpecies = await getSpeciesByName(name);
    if (existingSpecies != null) {
      // 如果存在同名种类但没有分类路径，则更新它
      if (taxonomyPath != null && taxonomyPath.isNotEmpty && 
          (!existingSpecies.metadata.containsKey('taxonomy_path') || 
           existingSpecies.metadata['taxonomy_path'] == null ||
           existingSpecies.metadata['taxonomy_path'] == 'unknown')) {
        
        // 创建更新的元数据
        final metadata = Map<String, dynamic>.from(existingSpecies.metadata);
        metadata['taxonomy_path'] = taxonomyPath;
        
        if (taxonomyData != null) {
          metadata['taxonomyData'] = taxonomyData;
        }
        
        // 更新种类记录
        final updatedSpecies = existingSpecies.copyWith(
          description: description ?? existingSpecies.description,
          metadata: metadata,
        );
        
        await updateSpecies(updatedSpecies);
      }
      
      return existingSpecies.speciesId;
    }
    
    // 生成唯一的种类ID
    final speciesId = _uuid.v4();
    
    // 准备元数据
    final metadata = <String, dynamic>{};
    if (taxonomyPath != null) {
      metadata['taxonomy_path'] = taxonomyPath;
    }
    if (taxonomyData != null) {
      metadata['taxonomyData'] = taxonomyData;
    }
    
    // 创建种类记录
    final now = DateTime.now();
    final species = Species(
      speciesId: speciesId,
      name: name,
      description: description,
      metadata: metadata,
      createdAt: now,
    );
    
    // 插入数据库
    await db.insert('species', species.toMap());
    
    return speciesId;
  }

  @override
  Future<Species?> getSpeciesById(String speciesId) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'species',
      where: 'species_id = ?',
      whereArgs: [speciesId],
    );
    
    if (maps.isNotEmpty) {
      return Species.fromMap(maps.first);
    }
    
    return null;
  }

  @override
  Future<Species?> getSpeciesByName(String name) async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'species',
      where: 'name = ?',
      whereArgs: [name],
    );
    
    if (maps.isNotEmpty) {
      return Species.fromMap(maps.first);
    }
    
    return null;
  }
  
  @override
  Future<List<Species>> getSpeciesByTaxonomyPath(String taxonomyPath) async {
    final db = await _dbHelper.database;
    
    // 使用JSON查询查找包含特定分类路径的记录
    // 注意：这种方法在SQLite中可能效率不高，但可以工作
    final maps = await db.query(
      'species',
      where: "metadata LIKE ?",
      whereArgs: ["%taxonomy_path%$taxonomyPath%"],
    );
    
    return maps.map((map) => Species.fromMap(map)).toList();
  }

  @override
  Future<List<Species>> getAllSpecies() async {
    final db = await _dbHelper.database;
    
    final maps = await db.query(
      'species',
      orderBy: 'name ASC',
    );
    
    return maps.map((map) => Species.fromMap(map)).toList();
  }

  @override
  Future<bool> updateSpecies(Species species) async {
    final db = await _dbHelper.database;
    
    final count = await db.update(
      'species',
      species.toMap(),
      where: 'species_id = ?',
      whereArgs: [species.speciesId],
    );
    
    return count > 0;
  }

  @override
  Future<bool> deleteSpecies(String speciesId) async {
    final db = await _dbHelper.database;
    
    final count = await db.delete(
      'species',
      where: 'species_id = ?',
      whereArgs: [speciesId],
    );
    
    return count > 0;
  }
} 