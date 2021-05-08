import 'package:dearplant/constants/music_theme.dart';
import 'package:dearplant/controllers/sound_controller.dart';
import 'package:dearplant/models/music_theme_model.dart';
import 'package:get/get.dart';

double gDelayedVolume = 0;

class AppData extends GetxController {
  MusicThemeModel _selectedMusic = defaultMusicThemes;
  bool _isMusicPlaying = false;
  bool _isConnected = false;
  bool _isMuted = false;

  bool get isMuted {
    return _isMuted;
  }

  set isMuted(bool value) {
    _isMuted = value;
    update();
  }

  bool get isConnected {
    return _isConnected;
  }

  set isConnected(bool value) {
    _isConnected = value;
    update();
  }

  bool get isMusicPlaying {
    return _isMusicPlaying;
  }

  set isMusicPlaying(bool value) {
    _isMusicPlaying = value;
    update();
  }

  MusicThemeModel get selectedMusic {
    return _selectedMusic;
  }

  set selectedMusic(MusicThemeModel newMusic) {
    _selectedMusic = newMusic;
    SoundController.soundPath = newMusic.soundPath;
    update();
  }
}
