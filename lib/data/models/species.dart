import 'dart:convert';

/// 植物种类数据模型
class Species {
  /// 种类唯一标识符
  final String speciesId;
  
  /// 种类名称
  final String name;
  
  /// 种类详细描述
  final String? description;
  
  /// 种类简介
  final String? introduction;
  
  /// 元数据
  final Map<String, dynamic> metadata;
  
  /// 创建时间
  final DateTime createdAt;

  /// 构造函数
  Species({
    required this.speciesId,
    required this.name,
    this.description,
    this.introduction,
    Map<String, dynamic>? metadata,
    required this.createdAt,
  }) : metadata = metadata ?? {};

  /// 从数据库Map创建对象
  factory Species.fromMap(Map<String, dynamic> map) {
    Map<String, dynamic> metadata = {};
    if (map.containsKey('metadata') && map['metadata'] != null) {
      // 尝试解析JSON元数据
      try {
        if (map['metadata'] is String) {
          metadata = jsonDecode(map['metadata']);
        } else if (map['metadata'] is Map) {
          metadata = Map<String, dynamic>.from(map['metadata']);
        }
      } catch (e) {
        print('解析Species元数据失败: $e');
      }
    }
    
    return Species(
      speciesId: map['species_id'],
      name: map['name'],
      description: map['description'],
      introduction: map['introduction'],
      metadata: metadata,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }

  /// 转换为Map用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'species_id': speciesId,
      'name': name,
      'description': description,
      'introduction': introduction,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }
  
  /// 创建对象副本，应用指定的修改
  Species copyWith({
    String? name,
    String? description,
    String? introduction,
    Map<String, dynamic>? metadata,
  }) {
    return Species(
      speciesId: this.speciesId,
      name: name ?? this.name,
      description: description ?? this.description,
      introduction: introduction ?? this.introduction,
      metadata: metadata ?? this.metadata,
      createdAt: this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Species{speciesId: $speciesId, name: $name}';
  }
} 