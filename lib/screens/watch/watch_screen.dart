import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yt_snatcher/services/download_manager.dart';
import 'package:yt_snatcher/widgets/screen.dart';
import 'package:yt_snatcher/widgets/video_info_view.dart';
import 'package:yt_snatcher/widgets/video_player/video_player.dart';

class WatchScreen extends StatefulWidget {
  static const ROUTENAME = "/watch";

  @override
  State<StatefulWidget> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  @override
  void dispose() {
    _onBack();
    super.dispose();
  }

  void _onBack() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    Download dl = ModalRoute.of(context).settings.arguments;
    Widget content;
    if (dl == null || dl.meta.type == DownloadType.MUSIC)
      content = Center(child: Text("No video found"));
    content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VideoPlayer(
          url: dl.mediaFile.path,
          type: VideoSourceType.FILE,
          overlaysWhenPortrait: [SystemUiOverlay.bottom],
          onBack: _onBack,
        ),
        Expanded(
          child: SingleChildScrollView(child: VideoInfoView(dl.meta.videoMeta)),
        ),
        // TODO playlists, recommendations, ...
      ],
    );
    return Screen(
      title: Text("Watch Video"),
      showAppBar: false,
      content: content,
    );
  }
}
