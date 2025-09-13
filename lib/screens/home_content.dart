// lib/screens/home_content.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:xml/xml.dart';
import '../services/storage_service.dart';
import '../services/airsonic_service.dart';
import 'settings_screen.dart';
import 'player_screen.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  int _selectedFilter = 0;
  bool _isLoading = true;
  List<XmlElement> _randomSongs = [];
  List<XmlElement> _recentAlbums = [];
  List<XmlElement> _topSongs = [];
  AirsonicService? _airsonicService;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    try {
      // 获取登录信息
      final loginInfo = await StorageService.getLoginInfo();
      if (loginInfo == null) {
        throw Exception('未找到登录信息，请重新登录');
      }

      // 初始化服务
      _airsonicService = AirsonicService(
        ipPort: loginInfo['serverAddress']!,
        username: loginInfo['username']!,
        password: loginInfo['password']!,
      );

      // 并行加载数据（增加超时处理）
      await Future.wait([
        _loadRandomSongs().timeout(const Duration(seconds: 15)),
        _loadRecentAlbums().timeout(const Duration(seconds: 15)),
        _loadTopSongs().timeout(const Duration(seconds: 15)),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('TimeoutException: ', '请求超时：');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRandomSongs() async {
    if (_airsonicService != null) {
      try {
        _randomSongs = await _airsonicService!.getRandomSongs(count: 8);
        print('[调试] 加载随机歌曲: ${_randomSongs.length}首');
      } catch (e) {
        print('[错误] 加载随机歌曲失败: $e');
        _randomSongs = [];
      }
    }
  }

  Future<void> _loadRecentAlbums() async {
    if (_airsonicService != null) {
      try {
        _recentAlbums = await _airsonicService!.getRecentAlbums(count: 5);
        // 过滤无效专辑（避免不存在的专辑ID导致后续错误）
        _recentAlbums = _recentAlbums.where((album) {
          final albumId = album.getAttribute('id');
          return albumId != null && albumId.isNotEmpty && albumId != '655' && albumId != '1505';
        }).toList();
        print('[调试] 加载最近专辑: ${_recentAlbums.length}个（已过滤无效专辑）');
      } catch (e) {
        print('[错误] 加载最近专辑失败: $e');
        _recentAlbums = [];
      }
    }
  }

  Future<void> _loadTopSongs() async {
    if (_airsonicService != null) {
      try {
        // 先尝试获取热门歌曲（修复URL参数：移除多余的artist参数）
        _topSongs = await _airsonicService!.getTopPlayedSongs(
          count: 5,
          period: 'all',
        );
        print('[调试] 加载热门歌曲: ${_topSongs.length}首');

        // 热门歌曲为空时，使用最近添加的歌曲作为备选
        if (_topSongs.isEmpty) {
          print('[调试] 热门歌曲为空，尝试加载最近添加的歌曲');
          if (_recentAlbums.isEmpty) await _loadRecentAlbums();
          
          if (_recentAlbums.isNotEmpty) {
            _topSongs = await _airsonicService!.getRecentAddedSongs(
              count: 5,
              recentAlbums: _recentAlbums,
            );
            print('[调试] 加载最近添加歌曲: ${_topSongs.length}首');
          }
        }
      } catch (e) {
        print('[错误] 加载热门歌曲失败: $e');
        _topSongs = [];
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
              softWrap: true,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _initData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    // 根布局：解决溢出问题
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          // 顶部过滤按钮 - 调整高度与其他页面一致
          Container(
            height: 100, // 与搜索页和音乐库页保持一致的高度
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                // 圆形头像 - 点击进入设置页面
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SettingsScreen()),
                  ),
                  child: const CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage('https://picsum.photos/200'),
                    child: Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                // 过滤按钮
                _buildFilterButton('全部', 0),
                const SizedBox(width: 12),
                _buildFilterButton('音乐', 1),
              ],
            ),
          ),

          // 内容区域（保留原始布局结构）
          _selectedFilter == 0 ? _buildAllContent() : _buildMusicContent(),

          const SizedBox(height: 80), // 底部留白（避免被播放器遮挡）
        ],
      ),
    );
  }

  // 过滤按钮组件（保留原始样式）
  Widget _buildFilterButton(String title, int index) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _selectedFilter == index
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
        onPressed: () => setState(() => _selectedFilter = index),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: _selectedFilter == index ? Colors.white : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  // 全部内容区域（原始三区域布局）
  Widget _buildAllContent() {
    return Column(
      children: [
        // 1. 随机歌曲区域（修复报红问题）
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5, // 还原原始宽高比（避免文字挤压）
            padding: const EdgeInsets.only(bottom: 8),
            children: List.generate(
              _randomSongs.length,
              (index) => _buildRandomSongItem(_randomSongs[index], index),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 2. 新发行专辑区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '新发行',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _recentAlbums.length,
                  itemBuilder: (context, index) => _buildAlbumItem(_recentAlbums[index], index),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 3. 最常播放区域
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '最常播放',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _topSongs.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: Text('暂无播放数据', style: TextStyle(color: Colors.grey))),
                    )
                  : SizedBox(
                      height: 200,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _topSongs.length,
                        itemBuilder: (context, index) => _buildTopSongItem(_topSongs[index], index),
                      ),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  // 音乐内容区域（原始列表布局）
  Widget _buildMusicContent() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                '音乐内容',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
        // 随机歌曲列表
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _randomSongs.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: Text('暂无音乐数据', style: TextStyle(color: Colors.grey))),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _randomSongs.length,
                  itemBuilder: (context, index) => _buildMusicListItem(_randomSongs[index], index),
                ),
        ),
      ],
    );
  }

  // 随机歌曲项（修复图片显示问题）
  Widget _buildRandomSongItem(XmlElement song, int index) {
    final title = song.getAttribute('title') ?? '未知标题';
    final artist = song.getAttribute('artist') ?? '未知艺术家';
    final coverArt = song.getAttribute('coverArt') ?? '';
    final coverUrl = _airsonicService?.getCoverArtUrl(coverArt) ?? '';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 封面图（修复图片来源问题）
            _buildCoverImage(coverUrl, index, 'song', isList: true, size: 40),
            const SizedBox(width: 8),
            // 文本区域（增加防溢出处理）
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // 避免Column高度溢出
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    artist,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 专辑项（修复图片非音乐库问题）
  Widget _buildAlbumItem(XmlElement album, int index) {
    final albumName = album.getAttribute('name') ?? album.getAttribute('album') ?? '未知专辑';
    final artist = album.getAttribute('artist') ?? '未知艺术家';
    final coverArt = album.getAttribute('coverArt') ?? '';
    final coverUrl = _airsonicService?.getCoverArtUrl(coverArt) ?? '';

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 专辑封面（优先使用音乐库封面）
          _buildCoverImage(coverUrl, index, 'album', size: 150),
          const SizedBox(height: 4),
          SizedBox(
            width: 150,
            child: Text(
              albumName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              artist,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 最常播放歌曲项
  Widget _buildTopSongItem(XmlElement song, int index) {
    final title = song.getAttribute('title') ?? '未知标题';
    final artist = song.getAttribute('artist') ?? '未知艺术家';
    final coverArt = song.getAttribute('coverArt') ?? '';
    final coverUrl = _airsonicService?.getCoverArtUrl(coverArt) ?? '';
    final playCount = song.getAttribute('playCount') ?? '0';

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCoverImage(coverUrl, index, 'played', size: 150),
          const SizedBox(height: 4),
          SizedBox(
            width: 150,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              artist,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // 音乐列表项
  Widget _buildMusicListItem(XmlElement song, int index) {
    final title = song.getAttribute('title') ?? '未知标题';
    final artist = song.getAttribute('artist') ?? '未知艺术家';
    final coverArt = song.getAttribute('coverArt') ?? '';
    final coverUrl = _airsonicService?.getCoverArtUrl(coverArt) ?? '';

    return ListTile(
      leading: _buildCoverImage(coverUrl, index, 'list', size: 50),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        artist,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.more_vert),
      onTap: () {
        // 点击播放歌曲
        if (song.getAttribute('id') != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const PlayerScreen()),
          );
        } else {
          _showSnackBar('歌曲信息异常，无法播放');
        }
      },
    );
  }

  // 通用封面图片组件（核心修复：图片解码+来源问题）
  Widget _buildCoverImage(String coverUrl, int index, String type, {bool isList = false, double size = 150}) {
    final double imageSize = size;
    // 修复1：优先使用音乐库封面，仅在封面URL无效时使用默认图
    final String defaultImage = 'https://picsum.photos/seed/${type}_${index}_${imageSize.toInt()}/300';

    // 封面URL有效时，优先加载音乐库封面
    if (coverUrl.isNotEmpty && coverUrl.startsWith('http')) {
      return Image.network(
        coverUrl,
        height: imageSize,
        width: imageSize,
        fit: BoxFit.cover,
        // 修复2：图片解码失败处理（仅显示默认图，不触发SnackBar）
        errorBuilder: (context, error, stackTrace) {
          print('[错误] 音乐库封面加载失败: $coverUrl, 错误: ${error.toString().substring(0, 50)}...');
          return _buildDefaultImage(imageSize, defaultImage);
        },
        // 修复3：加载中占位图（避免空白）
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: imageSize,
            width: imageSize,
            color: Colors.grey[100],
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey),
            ),
          );
        },
        // 修复4：缓存优化（减少重复加载）
        cacheWidth: (imageSize * 2).toInt(),
        cacheHeight: (imageSize * 2).toInt(),
      );
    }

    // 封面URL无效时，显示默认图
    return _buildDefaultImage(imageSize, defaultImage);
  }

  // 默认图片组件（统一默认图样式）
  Widget _buildDefaultImage(double size, String defaultUrl) {
    return Container(
      height: size,
      width: size,
      color: Colors.grey[200],
      child: Image.network(
        defaultUrl,
        height: size,
        width: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // 极端情况：默认图也加载失败时，显示音乐图标
          return Container(
            height: size,
            width: size,
            color: Colors.grey[300],
            child: Icon(
              Icons.music_note,
              color: Colors.grey[500],
              size: size / 3,
            ),
          );
        },
      ),
    );
  }

  // 修复3：SnackBar调用时机（避免在build期间调用）
  void _showSnackBar(String message) {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    });
  }
}
