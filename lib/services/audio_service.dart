// lib/services/audio_service.dart
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

class AudioService extends ChangeNotifier {
  XmlElement? _currentSong;
  String? _coverUrl;
  bool _isPlaying = false;

  XmlElement? get currentSong => _currentSong;
  String? get coverUrl => _coverUrl;
  bool get isPlaying => _isPlaying;

  void playSong(XmlElement song, String coverUrl) {
    _currentSong = song;
    _coverUrl = coverUrl;
    _isPlaying = true;
    notifyListeners();
  }

  void togglePlayPause() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void skipNext() {
    // 下一首逻辑将在后续实现
    notifyListeners();
  }

  void skipPrevious() {
    // 上一首逻辑将在后续实现
    notifyListeners();
  }
}
