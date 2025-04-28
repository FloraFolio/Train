import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:flora_folio/data/services/photo_manager_service.dart';
import 'package:flora_folio/data/repositories/plant_photo_repository.dart';
import 'package:flora_folio/data/services/photo_analysis_service.dart';
import 'package:flora_folio/data/models/photo_status.dart';
import 'package:flora_folio/data/models/plant_photo.dart';

// 导入生成的 Mock 类
import 'photo_manager_service_test.mocks.dart';

// 生成 Nice Mock 类
@GenerateNiceMocks([
  MockSpec<PlantPhotoRepository>(),
  MockSpec<PhotoAnalysisService>(),
])
void main() {
  // 设置 MockPathProvider 作为测试环境的 PathProvider 实现
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // 使用一个临时路径进行测试
  const String tempPath = '/tmp/test_path';
  final mockPathProvider = MockPathProviderPlatform();
  PathProviderPlatform.instance = mockPathProvider;
  
  group('PhotoManagerService 测试', () {
    
    // Mock 类实例
    late MockPlantPhotoRepository mockPhotoRepository;
    late MockPhotoAnalysisService mockAnalysisService;
    late PhotoManagerService photoManagerService;
    late File testPhotoFile;
    
    // 测试 ID
    const String testPhotoId = 'test-photo-id';
    
    setUp(() async {
      // 初始化 Mock 对象
      mockPhotoRepository = MockPlantPhotoRepository();
      mockAnalysisService = MockPhotoAnalysisService();
      
      // 创建测试对象
      photoManagerService = PhotoManagerService(
        photoRepository: mockPhotoRepository,
        analysisService: mockAnalysisService,
      );

      // 创建测试文件
      testPhotoFile = File('$tempPath/test_image.jpg');
      
      // 设置目录存在
      final directory = Directory(tempPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      
      // 创建测试用的图片文件
      if (!await testPhotoFile.exists()) {
        await testPhotoFile.writeAsString('test image content');
      }
      
      // 设置基本的 mock 行为
      when(mockPhotoRepository.addPlantPhoto(
        photoFile: anyNamed('photoFile'),
        status: anyNamed('status'),
        speciesId: anyNamed('speciesId'),
        description: anyNamed('description'),
        additionalMetadata: anyNamed('additionalMetadata'),
      )).thenAnswer((_) async => testPhotoId);
      
      when(mockPhotoRepository.updatePhotoAnalysisResult(
        photoId: anyNamed('photoId'),
        status: anyNamed('status'),
        speciesId: anyNamed('speciesId'),
        description: anyNamed('description'),
        additionalMetadata: anyNamed('additionalMetadata'),
      )).thenAnswer((_) async => true);
      
      // 默认情况下，模拟分析失败以防止测试互相干扰
      when(mockAnalysisService.analyzePhoto(any))
          .thenAnswer((_) async => PhotoAnalysisResult.failure(
                errorMessage: 'Mocked failure for testing',
                data: {'test': 'data'},
              ));
    });

    tearDown(() async {
      // 清理测试文件
      if (await testPhotoFile.exists()) {
        await testPhotoFile.delete();
      }
    });

    test('processNewPhoto 应该添加照片并启动分析', () async {
      // 调用测试方法
      final resultId = await photoManagerService.processNewPhoto(testPhotoFile);

      // 验证结果
      expect(resultId, equals(testPhotoId));
      
      // 验证 addPlantPhoto 被调用
      verify(mockPhotoRepository.addPlantPhoto(
        photoFile: anyNamed('photoFile'),
        status: PhotoStatus.ANALYZING,
      )).called(1);
      
      // 等待异步操作完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证异步处理发生
      verify(mockAnalysisService.analyzePhoto(any)).called(1);
      
      // 验证更新状态被调用
      verify(mockPhotoRepository.updatePhotoAnalysisResult(
        photoId: testPhotoId,
        status: anyNamed('status'),
        additionalMetadata: anyNamed('additionalMetadata'),
      )).called(1);
    });

    test('_analyzePhotoAsync 应该正确处理成功的分析结果', () async {
      // 为此测试设置成功的分析结果
      final successResult = PhotoAnalysisResult.success(
        speciesId: 'test-species-id',
        speciesName: 'Test Plant',
        description: 'This is a test plant',
        data: {'test': 'data'},
      );
      
      // 重置之前的 mock，设置成功场景
      when(mockAnalysisService.analyzePhoto(any))
          .thenAnswer((_) async => successResult);
      
      // 调用被测试的方法
      await photoManagerService.processNewPhoto(testPhotoFile);
      
      // 等待异步任务完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证分析服务被调用
      verify(mockAnalysisService.analyzePhoto(any)).called(1);
      
      // 验证成功状态更新
      verify(mockPhotoRepository.updatePhotoAnalysisResult(
        photoId: testPhotoId,
        status: PhotoStatus.SUCCESS,
        speciesId: 'test-species-id',
        description: 'This is a test plant',
        additionalMetadata: anyNamed('additionalMetadata'),
      )).called(1);
    });
    
    test('_analyzePhotoAsync 应该正确处理失败的分析结果', () async {
      // 为此测试设置失败的分析结果
      final failureResult = PhotoAnalysisResult.failure(
        errorMessage: 'Test error message',
        data: {'error': 'test error'},
      );
      
      // 设置失败场景
      when(mockAnalysisService.analyzePhoto(any))
          .thenAnswer((_) async => failureResult);
      
      // 调用被测试的方法
      await photoManagerService.processNewPhoto(testPhotoFile);
      
      // 等待异步任务完成
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 验证分析服务被调用
      verify(mockAnalysisService.analyzePhoto(any)).called(1);
      
      // 验证失败状态更新
      verify(mockPhotoRepository.updatePhotoAnalysisResult(
        photoId: testPhotoId,
        status: PhotoStatus.FAILED,
        additionalMetadata: anyNamed('additionalMetadata'),
      )).called(1);
    });
  });
}

// Mock 实现 PathProviderPlatform
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  
  @override
  Future<String?> getTemporaryPath() async {
    return '/tmp/test_path';
  }
  
  @override
  Future<String?> getApplicationSupportPath() async {
    return '/tmp/test_path';
  }
  
  @override
  Future<String?> getLibraryPath() async {
    return '/tmp/test_path';
  }
  
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '/tmp/test_path';
  }
  
  @override
  Future<String?> getExternalStoragePath() async {
    return '/tmp/test_path';
  }
  
  @override
  Future<List<String>?> getExternalCachePaths() async {
    return ['/tmp/test_path'];
  }
  
  @override
  Future<List<String>?> getExternalStoragePaths({
    StorageDirectory? type,
  }) async {
    return ['/tmp/test_path'];
  }
  
  @override
  Future<String?> getDownloadsPath() async {
    return '/tmp/test_path';
  }
} 