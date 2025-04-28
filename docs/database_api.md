# Flora Folio 数据库存储接口文档

## 数据库设计

### 1. 核心数据实体

Flora Folio 应用存储了以下核心数据：
- 植物照片
- 照片元数据，包含照片ID、种类ID、描述文本

### 2. 存储策略

采用混合存储方案：
- **SQLite数据库**：存储结构化数据及索引
- **文件系统**：存储照片文件
- **JSON处理**：在数据库中以TEXT字段存储照片的元数据

### 3. 数据库表设计

#### `plant_photos` 表
```sql
CREATE TABLE plant_photos (
  photo_id TEXT PRIMARY KEY,    -- 照片唯一标识符
  species_id TEXT,              -- 植物种类ID (可能为空，等待AI解析)
  description TEXT,             -- 照片描述文本 (可能为空，等待AI解析)
  introduction TEXT,            -- 植物简介 (可能为空，等待AI解析)
  photo_path TEXT NOT NULL,     -- 照片在文件系统中的路径
  status TEXT NOT NULL,         -- 照片解析状态：ANALYZING, SUCCESS, FAILED
  metadata TEXT,                -- JSON元数据（存储为TEXT）
  created_at INTEGER NOT NULL,  -- 创建时间戳
  updated_at INTEGER            -- 更新时间戳
);

-- 创建种类ID索引用于快速查询
CREATE INDEX idx_species_id ON plant_photos(species_id);
-- 创建状态索引用于查询解析中的照片
CREATE INDEX idx_status ON plant_photos(status);
```

#### `species` 表 (用于种类管理)
```sql
CREATE TABLE species (
  species_id TEXT PRIMARY KEY,  -- 种类唯一标识符
  name TEXT NOT NULL,           -- 种类名称
  description TEXT,             -- 种类详细描述
  introduction TEXT,            -- 种类简介
  metadata TEXT,                -- 元数据（包含分类信息等）
  created_at INTEGER NOT NULL   -- 创建时间戳
);
```

### 4. 文件系统结构

```
/app_documents/
  /photos/
    /{photo_id}.jpg           -- 照片文件
  /metadata/                   -- (可选，用于大型JSON数据)
    /{photo_id}.json          -- 备份的JSON元数据文件
```

### 5. JSON 数据结构

```json
{
  "photo_id": "uuid-string",        -- 照片唯一标识符
  "species_id": "species-uuid",     -- 植物种类ID
  "description": "植物描述文本",      -- 照片描述
  "status": "ANALYZING",            -- 照片解析状态：ANALYZING, SUCCESS, FAILED
  "metadata": {                     -- 额外元数据
    "location": {
      "latitude": 40.7128,
      "longitude": -74.0060
    },
    "captured_at": "2023-06-15T14:30:00Z",
    "tags": ["indoor", "flowering"],
    "custom_attributes": {}         -- 可扩展的自定义属性
  }
}
```

## API 接口文档

### 植物照片仓库接口 (PlantPhotoRepository)

#### 1. 新增照片接口

##### 函数签名
```dart
Future<String> addPlantPhoto({
  required File photoFile,
  String? speciesId,
  String? description,
  PhotoStatus status = PhotoStatus.ANALYZING,
  Map<String, dynamic>? additionalMetadata,
});
```

##### 参数说明
- `photoFile`: 照片文件对象
- `speciesId`: 植物种类ID (可选，可能等待AI解析后再设置)
- `description`: 可选的照片描述 (可选，可能等待AI解析后再设置)
- `status`: 照片解析状态，默认为ANALYZING
- `additionalMetadata`: 可选的额外元数据

##### 返回值
- 成功：返回新创建的照片ID（String）
- 失败：抛出异常

##### 处理流程
1. 生成唯一的`photo_id`
2. 保存照片到文件系统
3. 构建完整的JSON元数据
4. 在数据库中插入记录，状态为ANALYZING
5. 返回照片ID

#### 2. 更新照片解析结果接口

##### 函数签名
```dart
Future<bool> updatePhotoAnalysisResult({
  required String photoId,
  String? speciesId,
  String? description,
  String? introduction,
  required PhotoStatus status,
  Map<String, dynamic>? additionalMetadata,
});
```

##### 参数说明
- `photoId`: 要更新的照片ID
- `speciesId`: AI解析后获得的植物种类ID
- `description`: AI解析后获得的详细描述
- `introduction`: AI解析后获得的植物简介
- `status`: 照片解析状态（SUCCESS或FAILED）
- `additionalMetadata`: 可选的额外元数据

##### 返回值
- 成功：返回true
- 失败：抛出异常

##### 处理流程
1. 在数据库中查询指定ID的照片记录
2. 更新记录的种类ID、描述、状态和元数据
3. 更新更新时间字段
4. 保存更改

#### 3. 按照单个照片ID查询接口

##### 函数签名
```dart
Future<PlantPhoto?> getPhotoById(String photoId);
```

##### 参数说明
- `photoId`: 要查询的照片ID

##### 返回值
- 成功：返回`PlantPhoto`对象，包含照片信息和元数据
- 未找到：返回`null`
- 失败：抛出异常

##### 处理流程
1. 在数据库中查询指定ID的照片记录
2. 如果找到，构建并返回`PlantPhoto`对象
3. 如果未找到，返回`null`

#### 4. 按照植物种类ID查询接口

##### 函数签名
```dart
Future<List<PlantPhoto>> getPhotosBySpeciesId(
  String speciesId, {
  int? limit,
  int? offset,
  SortOrder sortOrder = SortOrder.newest,
});
```

##### 参数说明
- `speciesId`: 植物种类ID
- `limit`: 可选，限制返回结果数量
- `offset`: 可选，结果偏移量（用于分页）
- `sortOrder`: 可选，排序方式（默认按最新时间排序）

##### 返回值
- 成功：返回`PlantPhoto`对象列表
- 未找到：返回空列表
- 失败：抛出异常

##### 处理流程
1. 构建查询条件（WHERE species_id = ?）
2. 添加排序、分页参数
3. 执行查询
4. 将结果映射为`PlantPhoto`对象列表

#### 5. 按照照片状态查询接口

##### 函数签名
```dart
Future<List<PlantPhoto>> getPhotosByStatus(
  PhotoStatus status, {
  int? limit,
  int? offset,
  SortOrder sortOrder = SortOrder.newest,
});
```

##### 参数说明
- `status`: 照片解析状态（ANALYZING, SUCCESS, FAILED）
- `limit`: 可选，限制返回结果数量
- `offset`: 可选，结果偏移量（用于分页）
- `sortOrder`: 可选，排序方式（默认按最新时间排序）

##### 返回值
- 成功：返回`PlantPhoto`对象列表
- 未找到：返回空列表
- 失败：抛出异常

##### 处理流程
1. 构建查询条件（WHERE status = ?）
2. 添加排序、分页参数
3. 执行查询
4. 将结果映射为`PlantPhoto`对象列表

#### 6. 获取所有照片接口

##### 函数签名
```dart
Future<List<PlantPhoto>> getAllPhotos({
  int? limit,
  int? offset,
  SortOrder sortOrder = SortOrder.newest,
});
```

##### 参数说明
- `limit`: 可选，限制返回结果数量
- `offset`: 可选，结果偏移量（用于分页）
- `sortOrder`: 可选，排序方式（默认按最新时间排序）

##### 返回值
- 成功：返回`PlantPhoto`对象列表
- 未找到：返回空列表
- 失败：抛出异常

##### 处理流程
1. 构建查询
2. 添加排序、分页参数
3. 执行查询
4. 将结果映射为`PlantPhoto`对象列表

#### 7. 删除照片接口

##### 函数签名
```dart
Future<bool> deletePhoto(String photoId);
```

##### 参数说明
- `photoId`: 要删除的照片ID

##### 返回值
- 成功：返回`true`
- 失败：返回`false`或抛出异常

##### 处理流程
1. 在数据库中查询指定ID的照片记录
2. 删除文件系统中的照片文件
3. 从数据库中删除照片记录
4. 返回操作结果

### 照片分析服务接口 (PhotoAnalysisService)

#### 1. 照片分析接口

##### 函数签名
```dart
Future<PhotoAnalysisResult> analyzePhoto(File photoFile);
```

##### 参数说明
- `photoFile`: 要分析的照片文件

##### 返回值
- 成功：返回`PhotoAnalysisResult`对象，包含分析结果
- 失败：返回带有错误信息的`PhotoAnalysisResult`对象

##### 处理流程
1. 读取照片数据
2. 调用AI模型进行分析
3. 解析API响应
4. 构建并返回分析结果

### 照片管理服务接口 (PhotoManagerService)

#### 1. 处理新照片接口

##### 函数签名
```dart
Future<String> processNewPhoto(File photoFile);
```

##### 参数说明
- `photoFile`: 要处理的照片文件

##### 返回值
- 成功：返回新创建的照片ID（String）
- 失败：抛出异常

##### 处理流程
1. 添加照片到数据库，状态为ANALYZING
2. 异步启动AI分析任务（不等待完成）
3. 返回照片ID

#### 2. 获取照片接口

##### 函数签名
```dart
Future<PlantPhoto?> getPhoto(String photoId);
```

##### 参数说明
- `photoId`: 要获取的照片ID

##### 返回值
- 成功：返回`PlantPhoto`对象
- 未找到：返回`null`
- 失败：抛出异常

##### 处理流程
1. 调用仓库的getPhotoById方法
2. 返回查询结果

#### 3. 获取所有照片接口

##### 函数签名
```dart
Future<List<PlantPhoto>> getAllPhotos({
  int? limit,
  int? offset,
  SortOrder sortOrder = SortOrder.newest,
});
```

##### 参数说明
- `limit`: 可选，限制返回结果数量
- `offset`: 可选，结果偏移量（用于分页）
- `sortOrder`: 可选，排序方式（默认按最新时间排序）

##### 返回值
- 成功：返回`PlantPhoto`对象列表
- 未找到：返回空列表
- 失败：抛出异常

##### 处理流程
1. 调用仓库的getAllPhotos方法
2. 返回查询结果

#### 4. 获取指定状态的照片接口

##### 函数签名
```dart
Future<List<PlantPhoto>> getPhotosByStatus(
  PhotoStatus status, {
  int? limit,
  int? offset,
  SortOrder sortOrder = SortOrder.newest,
});
```

##### 参数说明
- `status`: 照片解析状态
- `limit`: 可选，限制返回结果数量
- `offset`: 可选，结果偏移量（用于分页）
- `sortOrder`: 可选，排序方式（默认按最新时间排序）

##### 返回值
- 成功：返回`PlantPhoto`对象列表
- 未找到：返回空列表
- 失败：抛出异常

##### 处理流程
1. 调用仓库的getPhotosByStatus方法
2. 返回查询结果

#### 5. 获取指定种类的照片接口

##### 函数签名
```dart
Future<List<PlantPhoto>> getPhotosBySpecies(
  String speciesId, {
  int? limit,
  int? offset,
  SortOrder sortOrder = SortOrder.newest,
});
```

##### 参数说明
- `speciesId`: 植物种类ID
- `limit`: 可选，限制返回结果数量
- `offset`: 可选，结果偏移量（用于分页）
- `sortOrder`: 可选，排序方式（默认按最新时间排序）

##### 返回值
- 成功：返回`PlantPhoto`对象列表
- 未找到：返回空列表
- 失败：抛出异常

##### 处理流程
1. 调用仓库的getPhotosBySpeciesId方法
2. 返回查询结果

#### 6. 删除照片接口

##### 函数签名
```dart
Future<bool> deletePhoto(String photoId);
```

##### 参数说明
- `photoId`: 要删除的照片ID

##### 返回值
- 成功：返回`true`
- 失败：返回`false`或抛出异常

##### 处理流程
1. 调用仓库的deletePhoto方法
2. 返回操作结果

## 数据模型

### 照片状态枚举

```dart
enum PhotoStatus {
  ANALYZING,  // 正在解析（等待AI分析）
  SUCCESS,    // 解析成功（AI已成功识别）
  FAILED      // 解析失败（AI无法识别或发生错误）
}

// 照片状态扩展，用于转换枚举和字符串
extension PhotoStatusExtension on PhotoStatus {
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
```

### PlantPhoto 数据模型

```dart
class PlantPhoto {
  final String photoId;
  final String? speciesId;  // 可空，因为可能等待AI解析
  final String? description; // 可空，因为可能等待AI解析
  final String? introduction; // 可空，因为可能等待AI解析
  final String photoPath;
  final PhotoStatus status;  // 照片解析状态
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  // 构造函数
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

  // 从JSON/Map创建对象
  factory PlantPhoto.fromMap(Map<String, dynamic> map) {
    return PlantPhoto(
      photoId: map['photo_id'],
      speciesId: map['species_id'],
      description: map['description'],
      introduction: map['introduction'],
      photoPath: map['photo_path'],
      status: PhotoStatusExtension.fromString(map['status']),
      metadata: jsonDecode(map['metadata'] ?? '{}'),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['updated_at'])
          : null,
    );
  }

  // 转换为Map用于数据库存储
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
}

// 排序枚举
enum SortOrder {
  newest,
  oldest,
  nameAsc,
  nameDesc,
}
```

### 照片分析结果模型

```dart
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
```
