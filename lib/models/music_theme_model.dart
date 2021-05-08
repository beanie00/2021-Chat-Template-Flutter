import 'package:flutter/cupertino.dart';

class MusicThemeModel {
  final String imagePath;
  final String imageHighQualityPath;
  final String soundPath;
  AssetImage cachedImageWidgetHighQuality =
      AssetImage('assets/images/high_quality/bird.png'); // default cached image

  MusicThemeModel({
    @required this.imagePath,
    @required this.imageHighQualityPath,
    @required this.soundPath,
  });
}
