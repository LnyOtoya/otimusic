import 'package:flutter/material.dart';

class MusicLibraryScreen extends StatefulWidget {
  const MusicLibraryScreen({super.key});

  @override
  State<MusicLibraryScreen> createState() => _MusicLibraryScreenState();
}

class _MusicLibraryScreenState extends State<MusicLibraryScreen> {
  // 当前选中的分类：0-歌单，1-专辑，2-艺人
  int _selectedCategory = 0;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏 - 与其他页面保持一致
          Container(
            height: 80,
            padding: const EdgeInsets.only(top: 32, left: 16, right: 16, bottom: 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: const NetworkImage('https://picsum.photos/200'),
                  child: const Icon(Icons.person, size: 20),
                ),
                const SizedBox(width: 16),
                const Text(
                  '音乐库',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // 分类按钮区域
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _buildCategoryButton('歌单', 0),
                const SizedBox(width: 12),
                _buildCategoryButton('专辑', 1),
                const SizedBox(width: 12),
                _buildCategoryButton('艺人', 2),
              ],
            ),
          ),

          // 根据选中的分类显示不同内容
          _selectedCategory == 0 
              ? _buildPlaylistsSection()
              : _selectedCategory == 1
                  ? _buildAlbumsSection()
                  : _buildArtistsSection(),

          const SizedBox(height: 80), // 给底部播放器留空间
        ],
      ),
    );
  }

  // 构建分类按钮
  Widget _buildCategoryButton(String title, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _selectedCategory == index 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
      ),
      child: TextButton(
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(50, 28),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () {
          setState(() {
            _selectedCategory = index;
          });
        },
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: _selectedCategory == index 
                ? Colors.white 
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // 歌单展示区域
  Widget _buildPlaylistsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(
              6,
              (index) => _buildPlaylistItem(index),
            ),
          ),
        ],
      ),
    );
  }

  // 专辑展示区域
  Widget _buildAlbumsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 0.8,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: List.generate(
              6,
              (index) => _buildAlbumItem(index),
            ),
          ),
        ],
      ),
    );
  }

  // 艺人展示区域 - 列表形式
  Widget _buildArtistsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 10, // 10位艺人示例
            itemBuilder: (context, index) => _buildArtistItem(index),
          ),
        ],
      ),
    );
  }

  // 构建歌单项
  Widget _buildPlaylistItem(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            height: 100,
            child: GridView.count(
              crossAxisCount: 2,
              physics: const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              mainAxisSpacing: 0,
              crossAxisSpacing: 0,
              childAspectRatio: 1.0,
              children: List.generate(
                4,
                (imgIndex) => Image.network(
                  'https://picsum.photos/seed/playlist${index}img$imgIndex/200',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '我的歌单 $index',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '${(index + 1) * 5} 首歌曲',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  // 构建专辑项
  Widget _buildAlbumItem(int index) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            'https://picsum.photos/seed/album$index/300',
            width: double.infinity,
            height: 100,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '专辑名称 $index',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          '艺术家 $index',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // 构建艺人项 - 列表形式，不显示图片
  Widget _buildArtistItem(int index) {
    // 艺人名称示例列表
    final List<String> artistNames = [
      '周杰伦', '林俊杰', 'Taylor Swift', 'Ed Sheeran', 
      '陈奕迅', '王菲', 'Coldplay', '五月天', 'Bruno Mars', ' Adele'
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey,
            width: 0.2,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 艺人名称
          Text(
            artistNames[index],
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          // 右侧箭头图标
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
          ),
        ],
      ),
    );
  }
}
