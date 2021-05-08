import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:dearplant/constants/music_theme.dart';
import 'package:dearplant/models/music_theme_model.dart';
import 'package:get/get.dart';

import 'app_data.dart';

var _player = AssetsAudioPlayer.newPlayer();

class SoundController {
  static String soundPath = defaultMusicThemes.soundPath;

  static play() async {
    _player.open(
      Audio(soundPath),
      autoStart: true,
      showNotification: false,
      loopMode: LoopMode.single,
    );
  }

  static setVolume(double volume) {
    // link_dialog.dart timerCallback 함수에서 사용
    _player.setVolume(volume);
  }

  static changeMusic(MusicThemeModel m) {
    soundPath = m.soundPath;
    _player.stop();
    AppData appData = Get.find<AppData>();

    if (Get.find<AppData>().isMusicPlaying && !(Get.find<AppData>().isMuted)) {
      _player.open(
        Audio(m.soundPath),
        autoStart: true,
        showNotification: true,
      );
    }
  }

  static stop() {
    _player.stop();
  }
}
