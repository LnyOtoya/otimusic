import 'package:flutter/material.dart';
import 'settings_screen.dart'; // 导入设置页面

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // 添加选中状态变量，0表示"全部"，1表示"音乐"，默认选中"全部"
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏 - 增加顶部间距，远离状态栏
          Container(
            height: 100, // 增加高度，为顶部间距留出空间
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                // 可点击的头像，点击进入设置页面
                GestureDetector(
                  onTap: () {
                    // 导航到设置页面
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundImage: const NetworkImage('https://picsum.photos/200'),
                    child: const Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // 根据选中状态改变背景色
                    color: _selectedFilter == 0
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 0; // 选中"全部"
                      });
                    },
                    child: Text(
                      '全部',
                      // 根据选中状态改变文字颜色
                      style: TextStyle(
                        color: _selectedFilter == 0 ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    // 根据选中状态改变背景色
                    color: _selectedFilter == 1
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(40, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedFilter = 1; // 选中"音乐"
                      });
                    },
                    child: Text(
                      '音乐',
                      // 根据选中状态改变文字颜色
                      style: TextStyle(
                        color: _selectedFilter == 1 ? Colors.white : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),

          // 根据选中的筛选条件显示不同内容
          _selectedFilter == 0 ? _buildAllContent() : _buildMusicContent(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // "全部"内容区域
  Widget _buildAllContent() {
    return Column(
      children: [
        // 随机歌曲两列展示区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            padding: const EdgeInsets.only(bottom: 8),
            children: List.generate(
              8,
              (index) => _buildRandomSongItem(index),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 新发行区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '新发行',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildHorizontalItem(
                    context,
                    index,
                    '新发行专辑 $index',
                    '艺术家 $index',
                    'https://picsum.photos/seed/new$index/300',
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 最常播放区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '最常播放',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 5,
                  itemBuilder: (context, index) => _buildHorizontalItem(
                    context,
                    index,
                    '最常播放歌曲 $index',
                    '艺术家 $index',
                    'https://picsum.photos/seed/played$index/300',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // "音乐"内容区域（目前与"全部"内容相同，您可以根据需要修改）
  Widget _buildMusicContent() {
    return Column(
      children: [
        // 这里可以放只显示音乐的内容
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '音乐内容',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              // 这里可以添加音乐专属内容
              Text('这里是仅显示音乐的内容区域'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRandomSongItem(int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                image: DecorationImage(
                  image: NetworkImage('https://picsum.photos/seed/album$index/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '歌曲名 $index 这是一段很长的歌曲名用来测试换行效果',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: TextAlign.left,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHorizontalItem(
    BuildContext context,
    int index,
    String title,
    String subtitle,
    String imageUrl,
  ) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              imageUrl,
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              subtitle,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.left,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
