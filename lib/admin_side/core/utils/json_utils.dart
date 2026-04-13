import 'dart:convert';

class JsonUtils {
  static String encodeList(List<Map<String, dynamic>> list) {
    return jsonEncode(list);
  }
  
  static List<Map<String, dynamic>> decodeList(String jsonString) {
    if (jsonString.isEmpty) return [];
    
    try {
      final List<dynamic> decoded = jsonDecode(jsonString);
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }
  
  static String encodeMap(Map<String, dynamic> map) {
    return jsonEncode(map);
  }
  
  static Map<String, dynamic> decodeMap(String jsonString) {
    if (jsonString.isEmpty) return {};
    
    try {
      return jsonDecode(jsonString);
    } catch (e) {
      return {};
    }
  }
}