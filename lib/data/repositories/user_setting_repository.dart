abstract class UserSettingRepository {
  /// 保存API密钥
  Future<void> saveApiKey(String apiKey);
  /// 获取API密钥
  Future<String?> getApiKey();
}