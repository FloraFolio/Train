// 独立的Gemini API测试脚本
// 使用方法: dart bin/gemini_test.dart /path/to/your/plant_image.jpg

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'api_config.dart';

void main(List<String> arguments) async {
  // 检查API密钥是否已设置
  if (ApiConfig.geminiApiKey == "YOUR_GEMINI_API_KEY" || 
      ApiConfig.geminiApiKey.isEmpty) {
    print('错误: API密钥未设置，请在 bin/api_config.dart 文件中设置您的Gemini API密钥');
    exit(1);
  }

  if (arguments.isEmpty) {
    print('错误: 请提供植物图片路径');
    print('使用方法: dart bin/gemini_test.dart /path/to/your/plant_image.jpg');
    exit(1);
  }

  final String imagePath = arguments[0];
  final File imageFile = File(imagePath);
  
  if (!await imageFile.exists()) {
    print('错误: 图片文件不存在 - $imagePath');
    exit(1);
  }
  
  print('开始分析图片: $imagePath');
  
  try {
    // 读取图片数据
    final imageBytes = await imageFile.readAsBytes();
    print('图片大小: ${imageBytes.length} 字节');
    
    // 使用更结构化的提示词
    final prompt = """请分析这张植物图片，并以JSON格式返回以下信息：
1. species: 植物的界门科目纲属种，Json格式
2. introduction: 植物的简介，包含植物分类、原产地、用途等
3. detailed_description: 图片中的植物详细描述，越详细越好，这块儿不用分点，合在一起描述就行

请以JSON格式返回，确保键名为英文，值为中文描述。不要添加任何JSON外的说明文字。""";
    
    print('使用提示词: $prompt');
    
    // 使用Gemini 1.5 Flash模型
    print('使用模型: gemini-1.5-flash');
    
    // 调用API
    final result = await generateContent(
      prompt: prompt, 
      imageBytes: imageBytes,
      apiKey: ApiConfig.geminiApiKey
    );
    
    // 保存原始响应
    final responseFile = File('bin/gemini_response.txt');
    await responseFile.writeAsString(result, encoding: utf8);
    print('原始响应已保存至: ${responseFile.absolute.path}');
    
    // 尝试解析JSON输出
    try {
      final Map<String, dynamic>? jsonData = await extractJsonData(result);
      if (jsonData != null) {
        print('\n===== 植物信息(JSON格式) =====');
        print('种属: ${jsonData['species']}');
        print('简介: ${jsonData['introduction']}');
        print('详细描述: ${jsonData['detailed_description']}');
        print('=============================\n');
        
        // 保存结构化数据
        final jsonFile = File('bin/plant_info.json');
        await jsonFile.writeAsString(
          const JsonEncoder.withIndent('  ').convert(jsonData),
          encoding: utf8
        );
        print('结构化数据已保存至: ${jsonFile.absolute.path}');
      } else {
        print('无法从响应中提取有效的JSON数据');
        print('原始响应: $result');
      }
    } catch (e) {
      print('解析JSON时出错: $e');
      print('原始响应内容: $result');
    }
    
  } catch (e) {
    print('发生错误: $e');
    exit(1);
  }
}

/// 使用Gemini API的generate_content方法
Future<String> generateContent({
  required String prompt,
  required List<int> imageBytes,
  required String apiKey,
  String model = 'gemini-1.5-flash',
}) async {
  // 准备图片
  final base64Image = base64Encode(imageBytes);
  
  // API请求URI
  final uri = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey'
  );
  
  print('发送请求到: $uri');
  
  // 构建请求体，与Python示例类似
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
  
  try {
    // 发送请求
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(requestBody),
    );
    
    print('API响应状态码: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      // 解析响应
      try {
        final jsonResponse = jsonDecode(response.body);
        
        // 保存原始响应用于调试
        File('bin/debug_response.json').writeAsStringSync(
          const JsonEncoder.withIndent('  ').convert(jsonResponse),
          encoding: utf8
        );
        print('调试响应已保存至: bin/debug_response.json');
        
        // 尝试提取文本内容
        if (jsonResponse.containsKey('candidates') && 
            jsonResponse['candidates'] is List && 
            jsonResponse['candidates'].isNotEmpty) {
          
          final candidate = jsonResponse['candidates'][0];
          if (candidate.containsKey('content') && 
              candidate['content'].containsKey('parts') && 
              candidate['content']['parts'] is List && 
              candidate['content']['parts'].isNotEmpty) {
            
            final text = candidate['content']['parts'][0]['text'];
            print('成功提取API响应文本，长度: ${text.length} 字符');
            return text;
          }
        }
        
        // 如果无法提取文本，记录详细错误信息并返回整个响应
        print('警告: 无法从API响应中提取文本内容');
        print('响应结构: ${jsonResponse.keys.join(', ')}');
        if (jsonResponse.containsKey('candidates')) {
          print('候选项数量: ${jsonResponse['candidates'].length}');
        }
        
        return jsonEncode(jsonResponse);
        
      } catch (e) {
        print('解析API响应时出错: $e');
        // 保存原始响应体以便调试
        File('bin/error_response.txt').writeAsStringSync(response.body, encoding: utf8);
        print('错误响应已保存至: bin/error_response.txt');
        
        return response.body;
      }
    } else {
      // 保存错误响应以便调试
      File('bin/error_response.txt').writeAsStringSync(response.body, encoding: utf8);
      print('错误响应已保存至: bin/error_response.txt');
      
      return '请求失败，状态码: ${response.statusCode}\n响应内容: ${response.body}';
    }
  } catch (e) {
    print('请求过程中发生错误: $e');
    return '请求过程中发生错误: $e';
  }
}

/// Cleans JSON response by removing markdown code block formatting if present
String cleanJsonResponse(String text) {
  // Check if the text is wrapped in markdown code blocks like ```json ... ```
  final codeBlockPattern = RegExp(r'^```(?:json)?\s+([\s\S]*?)```$', multiLine: true);
  final match = codeBlockPattern.firstMatch(text);
  
  if (match != null && match.groupCount >= 1) {
    // Return just the content inside the code block
    return match.group(1)!.trim();
  }
  
  // If no code block formatting found, return the original text
  return text;
}

/// MediaType类，用于设置文件MIME类型
class MediaType {
  final String type;
  final String subtype;
  
  const MediaType(this.type, this.subtype);
  
  @override
  String toString() => '$type/$subtype';
}

/// 从响应中提取JSON数据
Future<Map<String, dynamic>?> extractJsonData(String responseText) async {
  try {
    // 首先检查是否有markdown代码块标记，去掉它们
    String processedText = cleanJsonResponse(responseText);
    
    // 尝试直接解析为JSON
    try {
      return json.decode(processedText);
    } catch (e) {
      print('直接解析JSON失败，尝试从文本中提取JSON...');
      print('解析错误: $e');
      print('处理后的文本: $processedText');
    }

    // 在文本中查找JSON对象(任何在 { 和 } 之间的内容)
    final jsonPattern = RegExp(r'({[\s\S]*})');
    final match = jsonPattern.firstMatch(processedText);
    
    if (match != null) {
      final jsonText = match.group(1);
      try {
        return json.decode(jsonText!);
      } catch (e) {
        print('提取的JSON解析失败: $e');
        print('提取的文本: $jsonText');
      }
    }
    
    print('响应中未找到JSON对象。');
    return null;
  } catch (e) {
    print('提取JSON数据时出错: $e');
    return null;
  }
} 