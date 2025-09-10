import 'package:flutter/material.dart';
import '../screens/player_screen.dart';

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      // 点击迷你播放器进入完整播放页
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
                'https://picsum.photos/seed/current/100',
                height: 50,
                width: 50,
                fit: BoxFit.cover,
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
                    'Frozen Tides',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'B-Lion',
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
              onPressed: () {
                // 上一首功能
              },
            ),
            
            IconButton(
              icon: Icon(Icons.pause, size: 24, color: colorScheme.onSurface),
              onPressed: () {
                // 播放/暂停功能
              },
            ),
            
            IconButton(
              icon: Icon(Icons.skip_next, color: colorScheme.onSurface),
              onPressed: () {
                // 下一首功能
              },
            ),
          ],
        ),
      ),
    );
  }
}
