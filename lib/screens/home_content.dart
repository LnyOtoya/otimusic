import 'package:flutter/material.dart';
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

      // 并行加载数据
      await Future.wait([
        _loadRandomSongs(),
        _loadRecentAlbums(),
        _loadTopSongs(),
      ]);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRandomSongs() async {
    if (_airsonicService != null) {
      _randomSongs = await _airsonicService!.getRandomSongs(count: 8);
    }
  }

  Future<void> _loadRecentAlbums() async {
    if (_airsonicService != null) {
      _recentAlbums = await _airsonicService!.getRecentAlbums(count: 5);
    }
  }

  Future<void> _loadTopSongs() async {
    if (_airsonicService != null) {
      _topSongs = await _airsonicService!.getTopPlayedSongs(
        count: 5,
        period: 'all',
      );

      // 如果热门歌曲为空，使用最近添加的歌曲
      if (_topSongs.isEmpty && _recentAlbums.isNotEmpty) {
        _topSongs = await _airsonicService!.getRecentAddedSongs(
          count: 5,
          recentAlbums: _recentAlbums,
        );
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
            ),
            ElevatedButton(
              onPressed: () => _initData(),
              child: const Text('重试'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 顶部栏
          Container(
            height: 100,
            padding: const EdgeInsets.only(top: 20, left: 16, right: 16, bottom: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
                    );
                  },
                  child: const CircleAvatar(
                    radius: 20,
                    child: Icon(Icons.person, size: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
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
                    onPressed: () => setState(() => _selectedFilter = 0),
                    child: Text(
                      '全部',
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
                    onPressed: () => setState(() => _selectedFilter = 1),
                    child: Text(
                      '音乐',
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

          // 内容区域
          _selectedFilter == 0 ? _buildAllContent() : _buildMusicContent(),

          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAllContent() {
    return Column(
      children: [
        // 随机歌曲
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.5,
            padding: const EdgeInsets.only(bottom: 8),
            children: List.generate(
              _randomSongs.length,
              (index) => _buildRandomSongItem(_randomSongs[index], index),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // 新发行专辑
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
                  itemCount: _recentAlbums.length,
                  itemBuilder: (context, index) => _buildAlbumItem(
                    _recentAlbums[index],
                    index,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // 最常播放
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
                  itemCount: _topSongs.length,
                  itemBuilder: (context, index) => _buildTopSongItem(
                    _topSongs[index],
                    index,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
        // 随机歌曲列表
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _randomSongs.length,
            itemBuilder: (context, index) => _buildMusicListItem(
              _randomSongs[index],
              index,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRandomSongItem(XmlElement song, int index) {
    final title = song.getAttribute('title') ?? '未知标题';
    final artist = song.getAttribute('artist') ?? '未知艺术家';
    final coverArt = song.getAttribute('coverArt') ?? '';
    final coverUrl = _airsonicService?.getCoverArtUrl(coverArt) ?? '';

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
                  image: coverUrl.isNotEmpty
                      ? NetworkImage(coverUrl)
                      : const NetworkImage('https://picsum.photos/seed/album/100'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              coverUrl.isNotEmpty ? coverUrl : 'https://picsum.photos/seed/album$index/300',
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            albumName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            artist,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

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
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              coverUrl.isNotEmpty ? coverUrl : 'https://picsum.photos/seed/played$index/300',
              height: 150,
              width: 150,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            '$artist · 播放 $playCount 次',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMusicListItem(XmlElement song, int index) {
    final title = song.getAttribute('title') ?? '未知标题';
    final artist = song.getAttribute('artist') ?? '未知艺术家';
    final album = song.getAttribute('album') ?? '未知专辑';
    final duration = _airsonicService?.formatDuration(
      int.tryParse(song.getAttribute('duration') ?? '0') ?? 0,
    ) ?? '0:00';
    final coverArt = song.getAttribute('coverArt') ?? '';
    final coverUrl = _airsonicService?.getCoverArtUrl(coverArt) ?? '';

    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.network(
          coverUrl.isNotEmpty ? coverUrl : 'https://picsum.photos/seed/song$index/100',
          width: 50,
          height: 50,
          fit: BoxFit.cover,
        ),
      ),
      title: Text(title),
      subtitle: Text('$artist · $album'),
      trailing: Text(duration),
      onTap: () {
        // 导航到播放页面
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const PlayerScreen()),
        );
      },
    );
  }
}
