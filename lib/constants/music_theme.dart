import 'package:dearplant/models/music_theme_model.dart';

final defaultMusicThemes = MusicThemes.bird;

List<MusicThemeModel> gMusicThemeList = [
  MusicThemes.bird,
  MusicThemes.river,
  MusicThemes.cricket,
  MusicThemes.forest,
  MusicThemes.ocean,
  MusicThemes.bath,
  MusicThemes.rain,
  MusicThemes.oven,
  MusicThemes.fire,
];

class MusicThemes {
  static MusicThemeModel bath = MusicThemeModel(
      imagePath: 'assets/images/bathtub_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/bathtub.png',
      soundPath: 'assets/sounds/bathtub1.mp3');
  static MusicThemeModel bird = MusicThemeModel(
      imagePath: 'assets/images/bird_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/bird.png',
      soundPath: 'assets/sounds/bird1.mp3');
  static MusicThemeModel cricket = MusicThemeModel(
      imagePath: 'assets/images/cricket_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/cricket.png',
      soundPath: 'assets/sounds/cricket1.mp3');
  static MusicThemeModel fire = MusicThemeModel(
      imagePath: 'assets/images/fire_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/campfire.png',
      soundPath: 'assets/sounds/campfire1.mp3');
  static MusicThemeModel forest = MusicThemeModel(
      imagePath: 'assets/images/forest_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/forest.png',
      soundPath: 'assets/sounds/forest1.mp3');
  static MusicThemeModel ocean = MusicThemeModel(
      imagePath: 'assets/images/ocean_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/ocean.png',
      soundPath: 'assets/sounds/ocean1.mp3');
  static MusicThemeModel oven = MusicThemeModel(
      imagePath: 'assets/images/oven_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/oven.png',
      soundPath: 'assets/sounds/oven1.mp3');
  static MusicThemeModel rain = MusicThemeModel(
      imagePath: 'assets/images/rain_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/rain.png',
      soundPath: 'assets/sounds/rain1.mp3');
  static MusicThemeModel river = MusicThemeModel(
      imagePath: 'assets/images/river_small.webp',
      imageHighQualityPath: 'assets/images/high_quality/river.png',
      soundPath: 'assets/sounds/river1.mp3');
}
