import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

void main() async {
  // 获取用户输入
  stdout.write('请输入IP和端口（例如：192.168.2.164:4040）：');
  String ipPort = stdin.readLineSync()!.trim();
  
  stdout.write('请输入用户名：');
  String username = stdin.readLineSync()!.trim();
  
  stdout.write('请输入密码：');
  String password = stdin.readLineSync()!.trim();

  try {
    // 测试服务器连接
    await testConnection(ipPort, username, password);
    
    // 获取20首随机歌曲
    List<XmlElement> randomSongs = await getRandomSongs(
      ipPort: ipPort,
      username: username,
      password: password,
      count: 20 // 获取20首歌曲
    );
    
    if (randomSongs.isEmpty) {
      print('\n未找到任何歌曲');
      return;
    }
    
    // 显示歌曲信息
    print('\n==================== 随机20首歌曲 ====================\n');
    for (int i = 0; i < randomSongs.length; i++) {
      var song = randomSongs[i];
      String title = song.getAttribute('title') ?? '未知标题';
      String artist = song.getAttribute('artist') ?? '未知艺术家';
      String album = song.getAttribute('album') ?? '未知专辑';
      String duration = formatDuration(int.tryParse(song.getAttribute('duration') ?? '0') ?? 0);
      String format = song.getAttribute('format') ?? '未知格式';
      String songId = song.getAttribute('id') ?? '';
      
      // 生成播放链接
      String playUrl = generatePlayUrl(
        ipPort: ipPort,
        username: username,
        password: password,
        songId: songId
      );
      
      // 输出歌曲信息
      print('${i + 1}. $title');
      print('   艺术家: $artist');
      print('   专辑: $album');
      print('   时长: $duration');
      print('   格式: $format');
      print('   播放链接: $playUrl\n');
    }

  } catch (e) {
    print('\n错误: $e');
  }
}

/// 测试服务器连接
Future<void> testConnection(String ipPort, String username, String password) async {
  String baseUrl = ipPort.startsWith('http') ? ipPort : 'http://$ipPort';
  Uri url = Uri.parse('$baseUrl/rest/ping.view').replace(queryParameters: {
    'u': username,
    'p': password,
    'v': '1.15.0',
    'c': 'multi_song_fetcher',
  });

  final response = await http.get(url);
  if (response.statusCode != 200) {
    throw Exception('无法连接到服务器，状态码: ${response.statusCode}');
  }

  final document = XmlDocument.parse(response.body);
  final root = document.rootElement;
  
  if (root.getAttribute('status') != 'ok') {
    final error = root.findElements('error').firstOrNull;
    throw Exception('服务器连接失败: ${error?.getAttribute('message') ?? '未知错误'}');
  }
  
  print('✅ 服务器连接成功！API版本: ${root.getAttribute('version')}');
}

/// 获取指定数量的随机歌曲
Future<List<XmlElement>> getRandomSongs({
  required String ipPort,
  required String username,
  required String password,
  required int count,
}) async {
  String baseUrl = ipPort.startsWith('http') ? ipPort : 'http://$ipPort';
  Uri url = Uri.parse('$baseUrl/rest/getRandomSongs.view').replace(queryParameters: {
    'u': username,
    'p': password,
    'v': '1.15.0',
    'c': 'multi_song_fetcher',
    'size': count.toString(), // 歌曲数量
  });

  final response = await http.get(url);
  
  if (response.statusCode == 200) {
    final document = XmlDocument.parse(response.body);
    final root = document.rootElement;
    
    if (root.getAttribute('status') == 'ok') {
      // 获取随机歌曲列表
      return root.findElements('randomSongs').firstOrNull?.findElements('song').toList() ?? [];
    } else {
      final error = root.findElements('error').firstOrNull;
      throw Exception('API错误: ${error?.getAttribute('message') ?? '未知错误'}');
    }
  } else {
    throw Exception('请求失败，状态码: ${response.statusCode}');
  }
}

/// 生成播放链接
String generatePlayUrl({
  required String ipPort,
  required String username,
  required String password,
  required String songId,
}) {
  String baseUrl = ipPort.startsWith('http') ? ipPort : 'http://$ipPort';
  return '$baseUrl/rest/stream.view?u=$username&p=$password&id=$songId&v=1.15.0';
}

/// 格式化时长（秒 -> 分:秒）
String formatDuration(int seconds) {
  int minutes = seconds ~/ 60;
  int remainingSeconds = seconds % 60;
  return '${minutes}:${remainingSeconds.toString().padLeft(2, '0')}';
}
