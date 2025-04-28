import 'package:flora_folio/data/models/species.dart';

/// 植物种类仓库接口
abstract class SpeciesRepository {
  /// 添加新的植物种类
  Future<String> addSpecies({
    required String name,
    String? description,
    String? introduction,
    String? taxonomyPath,
    Map<String, dynamic>? taxonomyData,
  });

  /// 根据ID获取植物种类
  Future<Species?> getSpeciesById(String speciesId);

  /// 根据名称获取植物种类
  Future<Species?> getSpeciesByName(String name);

  /// 根据分类路径获取植物种类
  Future<List<Species>> getSpeciesByTaxonomyPath(String taxonomyPath);

  /// 获取所有植物种类
  Future<List<Species>> getAllSpecies();

  /// 更新植物种类
  Future<bool> updateSpecies(Species species);

  /// 删除植物种类
  Future<bool> deleteSpecies(String speciesId);
} 