/// API配置
class ApiConfig {
  /// Gemini API密钥
  static const String geminiApiKey = "AIzaSyBcrJRFBp4nVLQ1nQ3lB0pO23cvdpf7SJ8";
  
  /// Gemini API端点
  static const String geminiApiEndpoint = "https://generativelanguage.googleapis.com/v1beta/models";
  
  /// 是否为开发环境
  static const bool isDevelopment = true;
  
  /// 获取实际API密钥，在生产环境中可以使用其他方式获取
  static String getGeminiApiKey() {
    // 在实际应用中，可以使用更安全的方式获取API密钥
    // 例如从安全存储或环境变量中获取
    return geminiApiKey;
  }
}

/// 提示：
/// 1. 请替换上面的 "YOUR_GEMINI_API_KEY" 为您的实际API密钥
/// 2. 不要将包含实际API密钥的文件提交到版本控制系统
/// 3. 考虑使用环境变量或安全的密钥管理服务来存储API密钥 