/// 照片分析状态枚举
enum PhotoStatus {
  /// 正在解析（等待AI分析）
  ANALYZING,
  
  /// 解析成功（AI已成功识别）
  SUCCESS,
  
  /// 解析失败（AI无法识别或发生错误）
  FAILED
}

/// 照片状态扩展，用于转换枚举和字符串
extension PhotoStatusExtension on PhotoStatus {
  /// 获取状态字符串表示
  String get value {
    switch (this) {
      case PhotoStatus.ANALYZING:
        return 'ANALYZING';
      case PhotoStatus.SUCCESS:
        return 'SUCCESS';
      case PhotoStatus.FAILED:
        return 'FAILED';
    }
  }
  
  /// 从字符串解析状态枚举
  static PhotoStatus fromString(String value) {
    switch (value) {
      case 'ANALYZING':
        return PhotoStatus.ANALYZING;
      case 'SUCCESS':
        return PhotoStatus.SUCCESS;
      case 'FAILED':
        return PhotoStatus.FAILED;
      default:
        throw ArgumentError('Invalid status value: $value');
    }
  }
}

/// 排序枚举
enum SortOrder {
  newest,
  oldest,
  nameAsc,
  nameDesc,
} 