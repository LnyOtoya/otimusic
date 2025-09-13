import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ImageLoader {
  // 从 Subsonic API 加载封面图（处理二进制流）
  static Future<ImageProvider?> loadCoverArt(String coverArtId) async {
    try {
      // 替换为你的 Subsonic 服务器地址
      final url = "http://192.168.2.164:4040/rest/getCoverArt.view?"
          "u=admin&p=admin&v=1.15.0&c=otimusic&id=$coverArtId&size=300";
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // 验证是否为图片数据（检查文件头）
        final bytes = response.bodyBytes;
        if (bytes.isNotEmpty && _isValidImage(bytes)) {
          return MemoryImage(bytes);
        }
      }
      print("[警告] 封面图加载失败：状态码 ${response.statusCode}");
    } catch (e) {
      print("[错误] 封面图加载异常：$e");
    }
    // 加载失败时返回默认图片
    return const AssetImage("assets/default_cover.png");
  }

  // 验证图片文件头（避免非图片数据导致解码失败）
  static bool _isValidImage(Uint8List bytes) {
    if (bytes.length < 4) return false;
    // JPG 头：FF D8 FF；PNG 头：89 50 4E 47
    return (bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF) ||
           (bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47);
  }
}
