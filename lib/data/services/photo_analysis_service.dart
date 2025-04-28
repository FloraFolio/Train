import 'dart:io';

/// 照片分析结果
class PhotoAnalysisResult {
  /// 分析是否成功
  final bool success;
  
  /// 植物种类ID（成功时有效）
  final String? speciesId;
  
  /// 植物名称（成功时有效）
  final String? speciesName;
  
  /// 详细描述文本（成功时有效）
  final String? description;
  
  /// 植物简介（成功时有效）
  final String? introduction;
  
  /// 完整的分析结果数据
  final Map<String, dynamic> data;
  
  /// 错误信息（失败时有效）
  final String? errorMessage;

  /// 构造函数
  PhotoAnalysisResult({
    required this.success,
    this.speciesId,
    this.speciesName,
    this.description,
    this.introduction,
    required this.data,
    this.errorMessage,
  });

  /// 创建成功结果
  factory PhotoAnalysisResult.success({
    required String speciesId,
    required String speciesName,
    required String description,
    required String introduction,
    required Map<String, dynamic> data,
  }) {
    return PhotoAnalysisResult(
      success: true,
      speciesId: speciesId,
      speciesName: speciesName,
      description: description,
      introduction: introduction,
      data: data,
    );
  }

  /// 创建失败结果
  factory PhotoAnalysisResult.failure({
    required String errorMessage,
    Map<String, dynamic>? data,
  }) {
    return PhotoAnalysisResult(
      success: false,
      data: data ?? {'error': errorMessage},
      errorMessage: errorMessage,
    );
  }
}

/// 照片分析服务接口
abstract class PhotoAnalysisService {
  /// 分析照片
  Future<PhotoAnalysisResult> analyzePhoto(File photoFile);
} 