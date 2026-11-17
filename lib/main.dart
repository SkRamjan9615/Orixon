import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';

import 'app/orixon_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSize = 150;
  PaintingBinding.instance.imageCache.maximumSizeBytes = 32 << 20;
  await SystemChrome.setPreferredOrientations(const []);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  MediaKit.ensureInitialized();
  runApp(const OrixonApp());
}
