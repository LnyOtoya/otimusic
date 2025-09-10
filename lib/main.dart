import 'package:flutter/material.dart';
// 确保导入路径正确，根据你的项目结构调整
import 'screens/home_screen.dart'; 

void main() {
  runApp(const OtimusicApp());
}

class OtimusicApp extends StatelessWidget {
  const OtimusicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Otimusic',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple),
      ),
      // 确保这里使用的是正确的类名，且该类在导入的文件中存在
      home: const HomeScreen(),
    );
  }
}
