import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

/// 数据库助手类，负责管理SQLite数据库
class DatabaseHelper {
  static const _databaseName = "flora_folio.db";
  static const _databaseVersion = 2;  // 更新版本号

  // 单例模式
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  // 数据库对象
  static Database? _database;

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    // 获取应用文档目录
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, _databaseName);
    
    // 创建并初始化数据库
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 植物照片表
    await db.execute('''
      CREATE TABLE plant_photos (
        photo_id TEXT PRIMARY KEY,
        species_id TEXT,
        description TEXT,
        photo_path TEXT NOT NULL,
        status TEXT NOT NULL,
        metadata TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER
      )
    ''');

    // 创建种类ID索引用于快速查询
    await db.execute(
      'CREATE INDEX idx_species_id ON plant_photos(species_id)'
    );

    // 创建状态索引用于查询解析中的照片
    await db.execute(
      'CREATE INDEX idx_status ON plant_photos(status)'
    );

    // 植物种类表 - 添加metadata字段
    await db.execute('''
      CREATE TABLE species (
        species_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT,
        metadata TEXT,
        created_at INTEGER NOT NULL
      )
    ''');
  }
  
  /// 处理数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // 版本1到版本2的升级：添加metadata字段到species表
      try {
        await db.execute('ALTER TABLE species ADD COLUMN metadata TEXT');
        print('数据库升级成功: 添加metadata字段到species表');
      } catch (e) {
        print('数据库升级错误: $e');
      }
    }
  }
} 