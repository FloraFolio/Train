import 'package:sqflite/sqflite.dart';
import 'package:flora_folio/data/repositories/user_setting_repository.dart';
import 'package:flora_folio/data/database/database_helper.dart';

class UserSettingRepositoryImpl implements UserSettingRepository{
  final DatabaseHelper _dbHelper;

  /// 构造函数
  UserSettingRepositoryImpl({
    DatabaseHelper? dbHelper,
  }) : 
  _dbHelper = dbHelper ?? DatabaseHelper.instance;


  @override
  Future<void> saveApiKey(String apiKey) async {
    final db = await _dbHelper.database;
    await db.insert(
      'settings',
      {'key': 'gemini_api_key', 'value': apiKey},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  @override
  Future<String?> getApiKey() async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['gemini_api_key'],
      limit: 1,
    );
    return result.isEmpty ? null : result.first['value'] as String?;
  }
}