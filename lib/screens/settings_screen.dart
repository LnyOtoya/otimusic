import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // 退出登录方法
  void _logout() async {
    // 显示确认对话框
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    // 如果用户确认退出
    if (confirm == true) {
      // 清除登录信息
      await StorageService.clearLoginInfo();
      // 导航到登录页并移除当前页面栈
      if (mounted) {  // 现在可以安全使用 mounted 属性了
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false, // 移除所有路由
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          // 退出登录选项
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('退出账号'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: _logout,
          ),
          // 其他设置选项
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('应用设置'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 跳转应用设置页面（预留）
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('关于'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // 跳转关于页面（预留）
            },
          ),
        ],
      ),
    );
  }
}
