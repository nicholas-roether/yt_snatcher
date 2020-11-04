import 'package:yt_snatcher/screens/download/download_screen.dart';
import 'package:yt_snatcher/screens/home/home_screen.dart';
import 'package:yt_snatcher/screens/video_info/video_info_screen.dart';
import 'package:yt_snatcher/screens/play/play_screen.dart';
import 'package:yt_snatcher/screens/settings/settings_screen.dart';

var routes = {
  HomeScreen.ROUTENAME: (context) => HomeScreen(),
  VideoInfoScreen.ROUTENAME: (context) => VideoInfoScreen(),
  DownloadScreen.ROUTENAME: (context) => DownloadScreen(),
  PlayScreen.ROUTENAME: (context) => PlayScreen(),
  SettingsScreen.ROUTENAME: (context) => SettingsScreen()
};
