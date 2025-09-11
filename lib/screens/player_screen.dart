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
  // 歌词区域控制器
  final DraggableScrollableController _lyricsController = DraggableScrollableController();
  // 主动画控制器
  late AnimationController _animationController;
  // 歌词是否全屏显示
  bool _isLyricsFullScreen = false;
  // 播放器主体透明度动画
  late Animation<double> _playerOpacityAnimation;
  // 歌词区域圆角动画
  late Animation<double> _lyricsRadiusAnimation;

  @override
  void initState() {
    super.initState();
    // 初始化动画控制器，延长动画时间至400ms使过渡更平滑
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // 播放器主体透明度动画：全屏歌词时渐隐，底部歌词时渐显
    _playerOpacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 歌词区域圆角动画：全屏歌词时圆角渐变为0，底部时渐变为24
    _lyricsRadiusAnimation = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    // 监听歌词控制器状态变化，平滑处理过渡
    _lyricsController.addListener(() {
      // 动态更新动画进度，根据歌词区域高度比例
      _animationController.value = _lyricsController.size;

      // 当拖动超过50%高度时，切换到全屏状态
      if (_lyricsController.size > 0.5 && !_isLyricsFullScreen) {
        setState(() => _isLyricsFullScreen = true);
      }
      // 当拖动低于50%高度时，切换到底部状态
      else if (_lyricsController.size <= 0.5 && _isLyricsFullScreen) {
        setState(() => _isLyricsFullScreen = false);
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _lyricsController.dispose();
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

  // 构建拖动手柄，添加状态栏高度的顶部间距
  Widget _buildDragHandle(ColorScheme colorScheme) {
    // 获取状态栏高度
    final statusBarHeight = MediaQuery.of(context).padding.top;
    
    return Padding(
      // 添加状态栏高度的顶部间距，避免与挖孔重叠
      padding: EdgeInsets.only(top: statusBarHeight + 8),
      child: GestureDetector(
        onVerticalDragUpdate: (details) {
          final currentSize = _lyricsController.size;
          final newSize = currentSize + (details.delta.dy * -0.001);
          
          // 限制在0.15-1.0范围内，防止超出边界导致异常
          if (newSize >= 0.15 && newSize <= 1.0) {
            _lyricsController.jumpTo(newSize);
          }
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          width: 40,
          height: 6,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withOpacity(0.5),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Stack(
        children: [
          // 播放器主体内容（带动画过渡）
          AnimatedBuilder(
            animation: _playerOpacityAnimation,
            builder: (context, child) {
              return Opacity(
                // 透明度随动画变化，解决切换时的白屏感
                opacity: _playerOpacityAnimation.value,
                child: IgnorePointer(
                  // 全屏歌词时忽略播放器交互
                  ignoring: _isLyricsFullScreen,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                // 顶部导航栏
                Padding(
                  padding: const EdgeInsets.only(top: 40, left: 16, right: 16, bottom: 20),
                  child: Row(
                    children: [
                      // 返回按钮
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios, color: colorScheme.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      // 中间专辑信息
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '播放自"专辑"',
                              style: TextStyle(
                                color: colorScheme.onSurface.withOpacity(0.7),
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'Winter Dreams',
                              style: TextStyle(
                                color: colorScheme.onSurface,
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
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        'https://picsum.photos/seed/current/600',
                        fit: BoxFit.cover,
                        // 预加载图片避免白屏
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

                const SizedBox(height: 30),

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

                const SizedBox(height: 30),

                // 进度条
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
                        onChanged: (value) => setState(() => _currentProgress = value.toInt()),
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

                const SizedBox(height: 20),

                // 播放控制按钮
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 播放模式
                      IconButton(
                        icon: Icon(
                          _playMode == 0 
                              ? Icons.repeat 
                              : Icons.shuffle, 
                          color: colorScheme.onSurface,
                          size: 24,
                        ),
                        onPressed: () => setState(() => _playMode = _playMode == 0 ? 1 : 0),
                      ),
                      const SizedBox(width: 20),
                      // 上一曲
                      IconButton(
                        icon: Icon(Icons.skip_previous, color: colorScheme.onSurface, size: 32),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 20),
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
                            color: colorScheme.onPrimary,
                            size: 32,
                          ),
                          onPressed: () => setState(() => _isPlaying = !_isPlaying),
                        ),
                      ),
                      const SizedBox(width: 20),
                      // 下一曲
                      IconButton(
                        icon: Icon(Icons.skip_next, color: colorScheme.onSurface, size: 32),
                        onPressed: () {},
                      ),
                      const SizedBox(width: 20),
                      // 添加到歌单
                      IconButton(
                        icon: Icon(Icons.playlist_add, color: colorScheme.onSurface, size: 24),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 可拖动的歌词区域（带动画过渡）
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return DraggableScrollableSheet(
                controller: _lyricsController,
                initialChildSize: 0.15,
                minChildSize: 0.15,
                maxChildSize: 1.0,
                snap: true,
                snapSizes: const [0.15, 1.0],
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      // 圆角随动画平滑变化
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(_lyricsRadiusAnimation.value),
                      ),
                      // 阴影随动画强度变化
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15 * (1 - _animationController.value)),
                          blurRadius: 15,
                          spreadRadius: 2,
                        ),
                      ],
                      border: Border(
                        top: BorderSide(
                          color: colorScheme.onSurface.withOpacity(0.05 * (1 - _animationController.value)),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: !_isLyricsFullScreen
                        ? const EdgeInsets.symmetric(horizontal: 16)
                        : EdgeInsets.zero,
                    child: Column(
                      children: [
                        // 拖动手柄
                        _buildDragHandle(colorScheme),
                        
                        // 歌词标题（全屏时显示，带动画）
                        if (_isLyricsFullScreen)
                          FadeTransition(
                            opacity: ReverseAnimation(_playerOpacityAnimation),
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                '歌词',
                                style: TextStyle(
                                  color: colorScheme.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        
                        // 歌词内容（可滚动）
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            // 增加底部内边距，使歌词区域远离控制按钮
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 120, // 增加底部间距，远离控制按钮
                            ),
                            itemCount: 20,
                            itemBuilder: (context, index) {
                              bool isCurrent = index == 10;

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 16,
                                ),
                                child: Text(
                                  _getLyricText(index),
                                  style: TextStyle(
                                    color: isCurrent 
                                        ? colorScheme.primary 
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
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  // 生成歌词文本示例
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
      'Your light will guide me where I belong'
    ];
    
    return lyrics[index % lyrics.length];
  }
}
