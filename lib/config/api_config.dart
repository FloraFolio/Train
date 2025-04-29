import 'dart:io';

/// API配置
class ApiConfig {
  /// 私有变量存储API密钥
  static String? geminiApiKey;

  /// 初始化方法（需要在应用启动时调用）
  static Future<void> initialize() async {
    try {
      final file = File('api.txt');
      geminiApiKey = (await file.readAsString()).trim();
    } catch (e) {
      throw Exception('Failed to load API key: $e');
    }
  }
  
  /// Gemini API端点
  static const String geminiApiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro-vision:generateContent";
  
  /// 是否为开发环境
  static const bool isDevelopment = true;
  
  /// 获取实际API密钥，在生产环境中可以使用其他方式获取
  static String getGeminiApiKey() {
    if (geminiApiKey == null) {
      throw Exception('API key not initialized. Call ApiConfig.initialize() first');
    }
    return geminiApiKey!;
    // 在实际应用中，可以使用更安全的方式获取API密钥
    // 例如从安全存储或环境变量中获取
  }
}

/// 提示：
/// 1. 请替换上面的 "YOUR_GEMINI_API_KEY" 为您的实际API密钥
/// 2. 不要将包含实际API密钥的文件提交到版本控制系统
/// 3. 考虑使用环境变量或安全的密钥管理服务来存储API密钥 