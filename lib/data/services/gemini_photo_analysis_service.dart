import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flora_folio/data/services/photo_analysis_service.dart';
import 'package:flora_folio/data/repositories/species_repository.dart';

/// 使用Gemini API的照片分析服务
class GeminiPhotoAnalysisService implements PhotoAnalysisService {
  final String _apiKey;
  final String _apiEndpoint;
  final SpeciesRepository _speciesRepository;
  final String _model;

  /// 构造函数
  GeminiPhotoAnalysisService({
    required String apiKey,
    String? apiEndpoint,
    required SpeciesRepository speciesRepository,
    String? model,
  }) : 
    _apiKey = apiKey,
    _apiEndpoint = apiEndpoint ?? 'https://generativelanguage.googleapis.com/v1beta/models',
    _speciesRepository = speciesRepository,
    _model = model ?? 'gemini-1.5-flash';

  @override
  Future<PhotoAnalysisResult> analyzePhoto(File photoFile) async {
    try {
      // 读取照片数据
      final imageBytes = await photoFile.readAsBytes();
      
      // 使用更结构化的提示词
      final prompt = """请分析这张植物图片，并以JSON格式返回以下信息：
1. species: 植物的界门科目纲属种，Json格式，每个分类级别请提供英文和拉丁学名（如有）
2. introduction: 植物的简介，包含植物分类、原产地、用途等
3. detailed_description: 图片中的植物详细描述，越详细越好，这块儿不用分点，合在一起描述就行

请以JSON格式返回，确保键名为英文，值也为英文描述。不要添加任何JSON外的说明文字。""";

      // 调用Gemini API
      final textResponse = await _generateContent(
        prompt: prompt,
        imageBytes: imageBytes,
      );
      
      // 保存原始响应用于调试（可选）
      // File('debug_gemini_response.txt').writeAsStringSync(textResponse);
      
      try {
        // 尝试直接解析JSON
        final Map<String, dynamic> plantData = jsonDecode(textResponse);
        
        // 确认必要的字段存在
        if (plantData.containsKey('species')) {
          // 提取分类层级信息
          final taxonomyInfo = _extractTaxonomyInfo(plantData['species']);
          
          // 获取简介和详细描述
          final introduction = plantData['introduction'] ?? '无简介';
          final detailedDescription = plantData['detailed_description'] ?? '无详细描述';
          
          // 添加到species表，让仓库决定是创建新记录还是更新现有记录
          // 仓库会处理重复种类的情况，并决定是否用更详细的信息更新现有记录
          final speciesId = await _speciesRepository.addSpecies(
            name: taxonomyInfo.displayName,
            description: detailedDescription,
            introduction: introduction,
            taxonomyPath: taxonomyInfo.taxonomyPath,
            taxonomyData: taxonomyInfo.taxonomyData,
          );
          
          // 构建包含分类信息的完整数据
          final completeData = Map<String, dynamic>.from(plantData);
          completeData['taxonomy_path'] = taxonomyInfo.taxonomyPath;
          completeData['display_name'] = taxonomyInfo.displayName;
          
          // 返回成功结果
          return PhotoAnalysisResult.success(
            speciesId: speciesId,
            speciesName: taxonomyInfo.displayName,
            description: detailedDescription,
            introduction: introduction,
            data: completeData,
          );
        } else {
          // 找不到物种信息
          return PhotoAnalysisResult.failure(
            errorMessage: '无法从AI响应中提取植物信息',
            data: plantData,
          );
        }
      } catch (jsonError) {
        // JSON解析失败，尝试提取信息
        try {
          final extractedData = _extractDataFromText(textResponse);
          
          if (extractedData.containsKey('species')) {
            // 尝试从提取的数据中获取分类信息
            final taxonomyInfo = _extractTaxonomyInfo(extractedData['species']);
            
            // 获取简介和详细描述
            final introduction = extractedData['introduction'] ?? '无简介';
            final detailedDescription = extractedData['detailed_description'] ?? '无详细描述';
            
            // 添加到species表，让仓库决定是创建新记录还是更新现有记录
            final speciesId = await _speciesRepository.addSpecies(
              name: taxonomyInfo.displayName,
              description: detailedDescription,
              introduction: introduction,
              taxonomyPath: taxonomyInfo.taxonomyPath,
              taxonomyData: taxonomyInfo.taxonomyData,
            );
            
            // 构建包含分类信息的完整数据
            extractedData['taxonomy_path'] = taxonomyInfo.taxonomyPath;
            extractedData['display_name'] = taxonomyInfo.displayName;
            
            // 返回成功结果
            return PhotoAnalysisResult.success(
              speciesId: speciesId,
              speciesName: taxonomyInfo.displayName,
              description: detailedDescription,
              introduction: introduction,
              data: extractedData,
            );
          } else {
            // 找不到物种信息但有其他数据，尝试作为未知物种处理
            if (extractedData.isNotEmpty) {
              // 创建一个未知物种的记录
              final taxonomyInfo = TaxonomyInfo(
                displayName: extractedData['name'] ?? '未知植物',
                taxonomyPath: 'unknown',
                taxonomyData: {'未知': true},
              );
              
              final description = extractedData['description'] ?? 
                                  extractedData['detailed_description'] ?? '无详细描述';
              final introduction = extractedData['introduction'] ?? '无简介';
              
              // 添加到species表
              final speciesId = await _speciesRepository.addSpecies(
                name: taxonomyInfo.displayName,
                description: description,
                introduction: introduction,
                taxonomyPath: taxonomyInfo.taxonomyPath,
                taxonomyData: taxonomyInfo.taxonomyData,
              );
              
              // 返回结果
              return PhotoAnalysisResult.success(
                speciesId: speciesId,
                speciesName: taxonomyInfo.displayName,
                description: description,
                introduction: introduction,
                data: extractedData,
              );
            }
            
            return PhotoAnalysisResult.failure(
              errorMessage: '解析AI响应失败: $jsonError',
              data: {'raw_response': textResponse},
            );
          }
        } catch (e) {
          return PhotoAnalysisResult.failure(
            errorMessage: '提取植物信息失败: $e',
            data: {'raw_response': textResponse},
          );
        }
      }
    } catch (e) {
      return PhotoAnalysisResult.failure(
        errorMessage: '照片分析过程出错: $e',
      );
    }
  }

  /// 提取分类层级信息
  TaxonomyInfo _extractTaxonomyInfo(dynamic speciesData) {
    // 默认值
    String displayName = '未知植物';
    String taxonomyPath = 'unknown';
    Map<String, dynamic> taxonomyData = {};
    
    try {
      if (speciesData is Map) {
        // 从分类对象中提取信息
        taxonomyData = Map<String, dynamic>.from(speciesData);
        
        // 提取各个分类级别
        final String kingdom = _getValueOrDefault(speciesData, '界', '');
        final String phylum = _getValueOrDefault(speciesData, '门', '');
        final String className = _getValueOrDefault(speciesData, '纲', '');
        final String order = _getValueOrDefault(speciesData, '目', '');
        final String family = _getValueOrDefault(speciesData, '科', '');
        final String genus = _getValueOrDefault(speciesData, '属', '');
        final String species = _getValueOrDefault(speciesData, '种', '');
        
        // 构建分类路径
        List<String> pathParts = [];
        if (kingdom.isNotEmpty) pathParts.add(_sanitizePath(kingdom));
        if (phylum.isNotEmpty) pathParts.add(_sanitizePath(phylum));
        if (className.isNotEmpty) pathParts.add(_sanitizePath(className));
        if (order.isNotEmpty) pathParts.add(_sanitizePath(order));
        if (family.isNotEmpty) pathParts.add(_sanitizePath(family));
        if (genus.isNotEmpty) pathParts.add(_sanitizePath(genus));
        if (species.isNotEmpty) pathParts.add(_sanitizePath(species));
        
        // 如果没有足够的分类信息，使用默认路径
        if (pathParts.isEmpty) {
          taxonomyPath = 'unknown';
        } else {
          taxonomyPath = pathParts.join('/');
        }
        
        // 设置显示名称，优先使用种名，然后是属名，再往上层级
        if (species.isNotEmpty) {
          displayName = species;
        } else if (genus.isNotEmpty) {
          displayName = genus;
        } else if (family.isNotEmpty) {
          displayName = family;
        } else if (order.isNotEmpty) {
          displayName = order;
        } else if (className.isNotEmpty) {
          displayName = className;
        } else if (phylum.isNotEmpty) {
          displayName = phylum;
        } else if (kingdom.isNotEmpty) {
          displayName = kingdom;
        }
      } else if (speciesData is String) {
        // 如果是字符串，直接使用
        displayName = speciesData;
        taxonomyPath = 'unknown/${_sanitizePath(displayName)}';
        taxonomyData = {'种': displayName};
      }
    } catch (e) {
      // 捕获任何错误，并使用默认值
      print('提取分类信息时出错: $e');
    }
    
    return TaxonomyInfo(
      displayName: displayName,
      taxonomyPath: taxonomyPath,
      taxonomyData: taxonomyData,
    );
  }
  
  /// 获取分类级别的值，如果不存在则返回默认值
  String _getValueOrDefault(Map<dynamic, dynamic> data, String key, String defaultValue) {
    return data.containsKey(key) ? data[key].toString() : defaultValue;
  }
  
  /// 清理路径字符串，移除不适合文件系统的字符
  String _sanitizePath(String path) {
    // 移除特殊字符，替换为下划线或其他安全字符
    return path
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_') // 文件系统禁止的字符
        .replaceAll(RegExp(r'\s+'), '_')          // 空白字符替换为下划线
        .replaceAll(RegExp(r'_{2,}'), '_')        // 多个连续下划线替换为单个
        .trim();
  }

  /// 使用Gemini API生成内容
  Future<String> _generateContent({
    required String prompt,
    required List<int> imageBytes,
  }) async {
    // 准备图片
    final base64Image = base64Encode(imageBytes);
    
    // API请求URI
    final uri = Uri.parse('$_apiEndpoint/$_model:generateContent?key=$_apiKey');
    print('The request GEmini URI is: $uri !!!!!!!!!!!!!!!!');
    // 构建请求体
    final requestBody = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.4,
        'topK': 32,
        'topP': 1,
        'maxOutputTokens': 4096,
      }
    };
    
    // 发送请求
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      // 解析响应
      final jsonResponse = jsonDecode(response.body);
      
      // 尝试提取文本
      if (jsonResponse.containsKey('candidates') && 
          jsonResponse['candidates'] is List && 
          jsonResponse['candidates'].isNotEmpty) {
        
        final candidate = jsonResponse['candidates'][0];
        if (candidate.containsKey('content') && 
            candidate['content'].containsKey('parts') && 
            candidate['content']['parts'] is List && 
            candidate['content']['parts'].isNotEmpty) {
          
          return candidate['content']['parts'][0]['text'];
        }
      }
      
      throw Exception('无法从API响应中提取文本内容');
    } else {
      throw Exception('API请求失败，状态码: ${response.statusCode}\n响应: ${response.body}');
    }
  }

  /// 从文本中提取数据（当无法直接解析为JSON时）
  Map<String, dynamic> _extractDataFromText(String text) {
    // 尝试提取JSON部分
    final RegExp jsonRegExp = RegExp(r'(\{[^]*\})');
    final match = jsonRegExp.firstMatch(text);
    
    if (match != null) {
      final jsonStr = match.group(1);
      if (jsonStr != null) {
        try {
          return jsonDecode(jsonStr);
        } catch (_) {
          // 忽略错误，继续使用正则表达式提取
        }
      }
    }
    
    // 使用正则表达式提取关键信息
    final Map<String, dynamic> result = {};
    
    // 提取种属
    final speciesMatch = RegExp(r'species.*?[：:]\s*([^\n,\.]+)', caseSensitive: false).firstMatch(text);
    if (speciesMatch != null && speciesMatch.groupCount >= 1) {
      result['species'] = speciesMatch.group(1)?.trim() ?? '未知植物';
    } else {
      // 尝试查找其他可能表示名称的模式
      final nameMatch = RegExp(r'这是(?:一[颗株]|一种)?\s*([^\n,\.]+?)[,\.，。]').firstMatch(text);
      result['species'] = nameMatch?.group(1)?.trim() ?? '未知植物';
    }
    
    // 提取简介
    final introMatch = RegExp(r'introduction.*?[：:]\s*([^\n]+(?:\n[^1-9\n][^\n]*)*)', caseSensitive: false).firstMatch(text);
    result['introduction'] = introMatch?.group(1)?.trim() ?? '';
    
    // 提取详细描述
    final descMatch = RegExp(r'detailed_description.*?[：:]\s*([^\n]+(?:\n[^1-9\n][^\n]*)*)', caseSensitive: false).firstMatch(text);
    result['detailed_description'] = descMatch?.group(1)?.trim() ?? '';
    
    return result;
  }
}

/// 分类信息数据类
class TaxonomyInfo {
  /// 显示名称（通常是种名或最具体的分类级别）
  final String displayName;
  
  /// 分类路径，格式为：界/门/纲/目/科/属/种
  final String taxonomyPath;
  
  /// 完整的分类数据
  final Map<String, dynamic> taxonomyData;
  
  TaxonomyInfo({
    required this.displayName,
    required this.taxonomyPath,
    required this.taxonomyData,
  });
} 