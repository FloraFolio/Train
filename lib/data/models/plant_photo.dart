import 'dart:convert';
import 'package:flora_folio/data/models/photo_status.dart';

/// 植物照片数据模型
class PlantPhoto {
  /// 照片唯一标识符
  final String photoId;
  
  /// 植物种类ID (可能为空，等待AI解析)
  final String? speciesId;
  
  /// 照片详细描述文本 (可能为空，等待AI解析)
  final String? description;
  
  /// 植物简介 (可能为空，等待AI解析)
  final String? introduction;
  
  /// 照片在文件系统中的路径
  final String photoPath;
  
  /// 照片解析状态
  final PhotoStatus status;
  
  /// 照片元数据
  final Map<String, dynamic> metadata;
  
  /// 创建时间
  final DateTime createdAt;
  
  /// 更新时间
  final DateTime? updatedAt;

  /// 构造函数
  PlantPhoto({
    required this.photoId,
    this.speciesId,
    this.description,
    this.introduction,
    required this.photoPath,
    required this.status,
    required this.metadata,
    required this.createdAt,
    this.updatedAt,
  });

  /// 从数据库Map创建对象
  factory PlantPhoto.fromMap(Map<String, dynamic> map) {
    return PlantPhoto(
      photoId: map['photo_id'],
      speciesId: map['species_id'],
      description: map['description'],
      introduction: map['introduction'],
      photoPath: map['photo_path'],
      status: PhotoStatusExtension.fromString(map['status']),
      metadata: map['metadata'] != null ? jsonDecode(map['metadata']) : {},
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  /// 转换为Map用于数据库存储
  Map<String, dynamic> toMap() {
    return {
      'photo_id': photoId,
      'species_id': speciesId,
      'description': description,
      'introduction': introduction,
      'photo_path': photoPath,
      'status': status.value,
      'metadata': jsonEncode(metadata),
      'created_at': createdAt.millisecondsSinceEpoch,
      'updated_at': updatedAt?.millisecondsSinceEpoch,
    };
  }

  /// 创建带更新信息的新对象
  PlantPhoto copyWith({
    String? photoId,
    String? speciesId,
    String? description,
    String? introduction,
    String? photoPath,
    PhotoStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlantPhoto(
      photoId: photoId ?? this.photoId,
      speciesId: speciesId ?? this.speciesId,
      description: description ?? this.description,
      introduction: introduction ?? this.introduction,
      photoPath: photoPath ?? this.photoPath,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'PlantPhoto{photoId: $photoId, speciesId: $speciesId, status: $status}';
  }
} 