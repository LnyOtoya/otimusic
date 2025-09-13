// lib/widgets/mini_player.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/player_screen.dart';
import '../services/audio_service.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AudioService>(
      builder: (context, audioService, child) {
        final currentSong = audioService.currentSong;
        if (currentSong == null) {
          // 没有播放歌曲时显示默认状态或隐藏
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final title = currentSong.getAttribute('title') ?? '未知标题';
        final artist = currentSong.getAttribute('artist') ?? '未知艺术家';

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PlayerScreen(),
              ),
            );
          },
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            color: colorScheme.surface,
            child: Row(
              children: [
                // 歌曲封面
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Image.network(
                    audioService.coverUrl ?? 'https://picsum.photos/seed/current/100',
                    height: 50,
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                      Image.network('https://picsum.photos/seed/current/100'),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // 歌曲信息
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        artist,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurface.withOpacity(0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // 播放控制按钮
                IconButton(
                  icon: Icon(Icons.skip_previous, color: colorScheme.onSurface),
                  onPressed: () => audioService.skipPrevious(),
                ),
                
                IconButton(
                  icon: Icon(
                    audioService.isPlaying ? Icons.pause : Icons.play_arrow, 
                    size: 24, 
                    color: colorScheme.onSurface
                  ),
                  onPressed: () => audioService.togglePlayPause(),
                ),
                
                IconButton(
                  icon: Icon(Icons.skip_next, color: colorScheme.onSurface),
                  onPressed: () => audioService.skipNext(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
