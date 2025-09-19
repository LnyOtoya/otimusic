import 'package:flutter/material.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> with SingleTickerProviderStateMixin {
  // 播放状态控制
  bool _isPlaying = true;
  // 播放模式：0-顺序播放，1-随机播放
  int _playMode = 0;
  // 当前播放进度（秒）
  int _currentProgress = 85;
  // 总时长（秒）
  final int _totalDuration = 237;
  // 页面控制器，用于实现左右滑动切换
  late PageController _pageController;
  // 当前页面索引：0-播放页，1-歌词页
  int _currentPage = 0;
  // 动画控制器
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    // 初始化页面控制器
    _pageController = PageController(initialPage: 0);
    
    // 初始化动画控制器（用于页面切换过渡）
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // 格式化时间（秒 -> mm:ss）
  String _formatDuration(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  // 显示底部操作菜单
  void _showActionMenu() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildActionMenuItem(Icons.download, '下载'),
            _buildActionMenuItem(Icons.playlist_add, '加入列表'),
            _buildActionMenuItem(Icons.info, '查看歌曲'),
          ],
        ),
      ),
    );
  }

  // 构建菜单列表项
  Widget _buildActionMenuItem(IconData icon, String text) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.onSurface),
      title: Text(text),
      onTap: () => Navigator.pop(context),
    );
  }

  // 切换到歌词页面（带动画）
  void _switchToLyrics() {
    setState(() => _currentPage = 1);
    _pageController.animateToPage(
      1,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 切换到播放页面（带动画）
  void _switchToPlayer() {
    setState(() => _currentPage = 0);
    _pageController.animateToPage(
      0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // 生成歌词文本（模拟真实歌词数据）
  String _getLyricText(int index) {
    final List<String> lyrics = [
      'Verse 1:',
      'I\'m drifting through the frozen tides',
      'Lost in a dream, where time collides',
      'The stars align, they guide my way',
      'Through endless nights, to a brand new day',
      '',
      'Pre-Chorus:',
      'Frozen tides, carry me home',
      'Where the ice melts, and hearts are known',
      'In the silence, I hear your voice',
      'A distant song, making my choice',
      '',
      'Chorus:',
      'Frozen tides, won\'t you set me free?',
      'I\'m caught in between what used to be',
      'Memories fade like footprints in snow',
      'But your love remains, a constant glow',
      '',
      'Verse 2:',
      'The moon reflects on crystal waves',
      'A thousand promises, a thousand graves',
      'I sail alone but not for long',
      'Your light will guide me where I belong',
      '',
      'Outro:',
      'Frozen tides, carry me home...',
      'Frozen tides, set me free...'
    ];
    
    return index < lyrics.length ? lyrics[index] : '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // 主页面容器（左右滑动切换播放页/歌词页）
          PageView(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            physics: const BouncingScrollPhysics(),
            children: [
              // 1. 播放页面（保持完整功能）
              _buildPlayerPage(colorScheme),
              
              // 2. 歌词页面（简化版，移除进度条和控制栏）
              _buildLyricsPage(colorScheme),
            ],
          ),
          
          // 页面指示器（顶部居中，不与内容重叠）
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 播放页指示器（可点击切换）
                GestureDetector(
                  onTap: _switchToPlayer,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == 0 ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                // 歌词页指示器（可点击切换）
                GestureDetector(
                  onTap: _switchToLyrics,
                  child: Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: _currentPage == 1 ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 构建播放页面（保持原有完整功能）
  Widget _buildPlayerPage(ColorScheme colorScheme) {
    return Column(
      children: [
        // 顶部导航栏（下移避免与指示器重叠）
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            right: 16,
            bottom: 30,
          ),
          child: Row(
            children: [
              // 返回按钮
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              // 中间专辑信息
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '播放自"专辑"',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Winter Dreams',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // 更多选项按钮
              IconButton(
                icon: Icon(Icons.more_vert, color: colorScheme.onSurface),
                onPressed: _showActionMenu,
              ),
            ],
          ),
        ),

        // 专辑封面
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: AspectRatio(
            aspectRatio: 1.0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                'https://picsum.photos/seed/current/600',
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: colorScheme.primary,
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),

        // 歌曲信息
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Text(
                'Frozen Tides',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'B-Lion',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // 进度条（播放页保留）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Slider(
                value: _currentProgress.toDouble(),
                min: 0,
                max: _totalDuration.toDouble(),
                activeColor: colorScheme.primary,
                inactiveColor: colorScheme.onSurface.withOpacity(0.2),
                onChanged: (value) {
                  setState(() {
                    _currentProgress = value.toInt();
                  });
                },
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(_currentProgress),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    _formatDuration(_totalDuration),
                    style: TextStyle(
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 30),

        // 播放控制按钮（播放页保留）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 播放模式
              IconButton(
                icon: Icon(
                  _playMode == 0 ? Icons.repeat : Icons.shuffle,
                  color: colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () {
                  setState(() {
                    _playMode = _playMode == 0 ? 1 : 0;
                  });
                },
              ),

              // 上一首
              IconButton(
                icon: Icon(Icons.skip_previous, color: colorScheme.onSurface, size: 32),
                onPressed: () {},
              ),

              // 播放/暂停
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPlaying = !_isPlaying;
                    });
                  },
                ),
              ),

              // 下一首
              IconButton(
                icon: Icon(Icons.skip_next, color: colorScheme.onSurface, size: 32),
                onPressed: () {},
              ),

              // 播放列表
              IconButton(
                icon: Icon(Icons.playlist_play, color: colorScheme.onSurface, size: 24),
                onPressed: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 构建歌词页面（简化版：移除进度条和底部控制栏）
  Widget _buildLyricsPage(ColorScheme colorScheme) {
    return Column(
      children: [
        // 顶部导航栏（与播放页对齐）
        Padding(
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 40,
            left: 16,
            right: 16,
            bottom: 30,
          ),
          child: Row(
            children: [
              // 返回按钮（返回上一页，而非切换页面）
              IconButton(
                icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
                onPressed: () => Navigator.pop(context),
              ),
              // 中间标题（歌词页标题）
              const Expanded(
                child: Text(
                  '歌词',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // 占位图标（保持布局平衡，与播放页对齐）
              IconButton(
                icon: Icon(Icons.more_vert, color: Colors.transparent),
                onPressed: () {},
              ),
            ],
          ),
        ),

        // 歌曲信息（简化展示，与播放页风格统一）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              Text(
                'Frozen Tides',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                'B-Lion',
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.7),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // 歌词内容（占满剩余空间，可滚动）
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            itemCount: 25, // 匹配歌词数组长度
            itemBuilder: (context, index) {
              // 标记当前播放的歌词行（模拟）
              bool isCurrent = index == 10;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  _getLyricText(index),
                  style: TextStyle(
                    color: isCurrent 
                        ? colorScheme.primary  // 当前行高亮
                        : colorScheme.onSurface.withOpacity(0.8),
                    fontSize: isCurrent ? 18 : 16,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),

        // 底部留白（替代原控制栏，保持页面平衡）
        const SizedBox(height: 32),
      ],
    );
  }
}
