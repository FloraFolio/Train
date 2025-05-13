import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flora_folio/data/services/photo_analysis_service.dart';
import 'package:flora_folio/data/repositories/species_repository.dart';

/// Photo analysis service implementation using Gemini API
class GeminiPhotoAnalysisService implements PhotoAnalysisService {
  final String _apiKey;
  final String _apiEndpoint;
  final SpeciesRepository _speciesRepository;
  final String _model;

  /// Constructor
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
      // Read image data
      final imageBytes = await photoFile.readAsBytes();
      
      // Structured prompt template
      final prompt = """Please analyze this plant image and return the following information in JSON format:
1. species: Plant taxonomy hierarchy in JSON format with English and Latin names (where available)
2. introduction: Brief introduction including classification, origin, uses
3. detailed_description: Comprehensive description of the plant in the image

Return only a well-formatted JSON object with English keys. Avoid any explanatory text outside the JSON structure.""";

      // Call Gemini API
      final textResponse = await _generateContent(
        prompt: prompt,
        imageBytes: imageBytes,
      );
      
      try {
        // Direct JSON parsing attempt
        final Map<String, dynamic> plantData = jsonDecode(textResponse);
        
        if (plantData.containsKey('species')) {
          final taxonomyInfo = _extractTaxonomyInfo(plantData['species']);
          
          final introduction = plantData['introduction'] ?? 'No introduction';
          final detailedDescription = plantData['detailed_description'] ?? 'No detailed description';
          
          final speciesId = await _speciesRepository.addSpecies(
            name: taxonomyInfo.displayName,
            description: detailedDescription,
            introduction: introduction,
            taxonomyPath: taxonomyInfo.taxonomyPath,
            taxonomyData: taxonomyInfo.taxonomyData,
          );
          
          final completeData = Map<String, dynamic>.from(plantData);
          completeData['taxonomy_path'] = taxonomyInfo.taxonomyPath;
          completeData['display_name'] = taxonomyInfo.displayName;
          
          return PhotoAnalysisResult.success(
            speciesId: speciesId,
            speciesName: taxonomyInfo.displayName,
            description: detailedDescription,
            introduction: introduction,
            data: completeData,
          );
        } else {
          return PhotoAnalysisResult.failure(
            errorMessage: 'Failed to extract species data from AI response',
            data: plantData,
          );
        }
      } catch (jsonError) {
        try {
          final extractedData = _extractDataFromText(textResponse);
          
          if (extractedData.containsKey('species')) {
            final taxonomyInfo = _extractTaxonomyInfo(extractedData['species']);
            final introduction = extractedData['introduction'] ?? 'No introduction';
            final detailedDescription = extractedData['detailed_description'] ?? 'No detailed description';
            
            final speciesId = await _speciesRepository.addSpecies(
              name: taxonomyInfo.displayName,
              description: detailedDescription,
              introduction: introduction,
              taxonomyPath: taxonomyInfo.taxonomyPath,
              taxonomyData: taxonomyInfo.taxonomyData,
            );
            
            extractedData['taxonomy_path'] = taxonomyInfo.taxonomyPath;
            extractedData['display_name'] = taxonomyInfo.displayName;
            
            return PhotoAnalysisResult.success(
              speciesId: speciesId,
              speciesName: taxonomyInfo.displayName,
              description: detailedDescription,
              introduction: introduction,
              data: extractedData,
            );
          } else {
            if (extractedData.isNotEmpty) {
              final taxonomyInfo = TaxonomyInfo(
                displayName: extractedData['name'] ?? 'Unknown Plant',
                taxonomyPath: 'unknown',
                taxonomyData: {'unknown': true},
              );
              
              final description = extractedData['description'] ?? 
                                extractedData['detailed_description'] ?? 'No detailed description';
              final introduction = extractedData['introduction'] ?? 'No introduction';
              
              final speciesId = await _speciesRepository.addSpecies(
                name: taxonomyInfo.displayName,
                description: description,
                introduction: introduction,
                taxonomyPath: taxonomyInfo.taxonomyPath,
                taxonomyData: taxonomyInfo.taxonomyData,
              );
              
              return PhotoAnalysisResult.success(
                speciesId: speciesId,
                speciesName: taxonomyInfo.displayName,
                description: description,
                introduction: introduction,
                data: extractedData,
              );
            }
            
            return PhotoAnalysisResult.failure(
              errorMessage: 'Failed to parse AI response: $jsonError',
              data: {'raw_response': textResponse},
            );
          }
        } catch (e) {
          return PhotoAnalysisResult.failure(
            errorMessage: 'Plant data extraction failed: $e',
            data: {'raw_response': textResponse},
          );
        }
      }
    } catch (e) {
      return PhotoAnalysisResult.failure(
        errorMessage: 'Photo analysis process failed: $e',
      );
    }
  }

  /// Extracts taxonomy information from structured data
  TaxonomyInfo _extractTaxonomyInfo(dynamic speciesData) {
    String displayName = 'Unknown Plant';
    String taxonomyPath = 'unknown';
    Map<String, dynamic> taxonomyData = {};
    
    try {
      if (speciesData is Map) {
        taxonomyData = Map<String, dynamic>.from(speciesData);
        
        final String kingdom = _getValueOrDefault(speciesData, 'kingdom', '');
        final String phylum = _getValueOrDefault(speciesData, 'phylum', '');
        final String className = _getValueOrDefault(speciesData, 'class', '');
        final String order = _getValueOrDefault(speciesData, 'order', '');
        final String family = _getValueOrDefault(speciesData, 'family', '');
        final String genus = _getValueOrDefault(speciesData, 'genus', '');
        final String species = _getValueOrDefault(speciesData, 'species', '');
        
        List<String> pathParts = [];
        if (kingdom.isNotEmpty) pathParts.add(_sanitizePath(kingdom));
        if (phylum.isNotEmpty) pathParts.add(_sanitizePath(phylum));
        if (className.isNotEmpty) pathParts.add(_sanitizePath(className));
        if (order.isNotEmpty) pathParts.add(_sanitizePath(order));
        if (family.isNotEmpty) pathParts.add(_sanitizePath(family));
        if (genus.isNotEmpty) pathParts.add(_sanitizePath(genus));
        if (species.isNotEmpty) pathParts.add(_sanitizePath(species));
        
        taxonomyPath = pathParts.isNotEmpty ? pathParts.join('/') : 'unknown';
        
        displayName = species.isNotEmpty
            ? species
            : genus.isNotEmpty
                ? genus
                : family.isNotEmpty
                    ? family
                    : order.isNotEmpty
                        ? order
                        : className.isNotEmpty
                            ? className
                            : phylum.isNotEmpty
                                ? phylum
                                : kingdom.isNotEmpty
                                    ? kingdom
                                    : displayName;
      } else if (speciesData is String) {
        displayName = speciesData;
        taxonomyPath = 'unknown/${_sanitizePath(displayName)}';
        taxonomyData = {'species': displayName};
      }
    } catch (e) {
      print('Taxonomy extraction error: $e');
    }
    
    return TaxonomyInfo(
      displayName: displayName,
      taxonomyPath: taxonomyPath,
      taxonomyData: taxonomyData,
    );
  }
  
  String _getValueOrDefault(Map<dynamic, dynamic> data, String key, String defaultValue) {
    return data.containsKey(key) ? data[key].toString() : defaultValue;
  }
  
  String _sanitizePath(String path) {
    return path
        .replaceAll(RegExp(r'[\\/*?:"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'_{2,}'), '_')
        .trim();
  }

  Future<String> _generateContent({
    required String prompt,
    required List<int> imageBytes,
  }) async {
    final base64Image = base64Encode(imageBytes);
    
    final uri = Uri.parse('$_apiEndpoint/$_model:generateContent?key=$_apiKey');
    
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
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestBody),
    );
    
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      
      if (jsonResponse.containsKey('candidates') && 
          (jsonResponse['candidates'] as List).isNotEmpty) {
        
        final candidate = jsonResponse['candidates'][0];
        if (candidate['content']?['parts'] is List && 
            (candidate['content']['parts'] as List).isNotEmpty) {
          
          return candidate['content']['parts'][0]['text'];
        }
      }
      
      throw Exception('Failed to extract text content from API response');
    } else {
      throw Exception('API request failed: ${response.statusCode}\n${response.body}');
    }
  }

  /// Fallback data extraction from raw text
  Map<String, dynamic> _extractDataFromText(String text) {
    final Map<String, dynamic> result = {};
    try {
      // 优先尝试提取完整JSON结构
      final jsonRegExp = RegExp(r'```json\n([\s\S]+?)\n```');  // 支持多行匹配
      final jsonMatch = jsonRegExp.firstMatch(text);
      
      if (jsonMatch != null) {
        return jsonDecode(jsonMatch.group(1)!);
      }
      // Fallback 1: 提取带{}的JSON对象
      final fallbackJsonRegExp = RegExp(r'\{[\s\S]+\}', multiLine: true);
      final fallbackJsonMatch = fallbackJsonRegExp.firstMatch(text);
      if (fallbackJsonMatch != null) {
        return jsonDecode(fallbackJsonMatch.group(0)!);
      }
    } catch (_) {}
    // Fallback 2: 使用改进的正则表达式提取关键字段
    try {
      // 增强型的species数据提取（支持嵌套结构）
      final speciesRegExp = RegExp(
        r'"species"\s*:\s*(\{(?:[^{}]|(?R))*\})',
        caseSensitive: false,
      );
      final speciesMatch = speciesRegExp.firstMatch(text);
      if (speciesMatch != null) {
        result['species'] = jsonDecode(speciesMatch.group(1)!);
      }
      // 增强introduction匹配（支持多行）
      final introMatch = RegExp(
        r'"introduction"\s*:\s*"((?:\\"|[^"])*)"',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      result['introduction'] = introMatch?.group(1)?.trim() ?? '';
      // 增强detailed_description匹配（支持多行）
      final descMatch = RegExp(
        r'"detailed_description"\s*:\s*"((?:\\"|[^"])*)"',
        caseSensitive: false,
        multiLine: true,
      ).firstMatch(text);
      result['detailed_description'] = descMatch?.group(1)?.trim() ?? '';
      // 如果没有找到完整数据，尝试最后的手段
      if (result.isEmpty) {
        _enhancedTextExtraction(text, result);
      }
    } catch (e) {
      print('Regex extraction error: $e');
    }
    return result;
  }
}

void _enhancedTextExtraction(String text, Map<String, dynamic> result) {
  // 智能名称识别
  final namePatterns = [
    RegExp(r'(?:This is|It is) (?:an? |the )?(.+?)[,\.]', caseSensitive: false),
    RegExp(r'(?:species|identified as):?\s*([^\n,]+)', caseSensitive: false),
  ];
  
  for (final pattern in namePatterns) {
    final match = pattern.firstMatch(text);
    if (match != null && !result.containsKey('species')) {
      result['species'] = match.group(1)?.trim();
      break;
    }
  }
  // 动态字段填充
  final fieldPattern = RegExp(r'("?\w+"?)\s*:\s*"?([^"\n]+)"?');
  for (final match in fieldPattern.allMatches(text)) {
    final key = match.group(1)?.replaceAll('"', '') ?? '';
    final value = match.group(2)?.trim() ?? '';
    if (!result.containsKey(key) && value.isNotEmpty) {
      result[key] = value;
    }
  }
}
/// Taxonomy information data container
class TaxonomyInfo {
  final String displayName;
  final String taxonomyPath;
  final Map<String, dynamic> taxonomyData;
  
  TaxonomyInfo({
    required this.displayName,
    required this.taxonomyPath,
    required this.taxonomyData,
  });
}
