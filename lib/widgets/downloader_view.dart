import 'package:flutter/material.dart';
import 'package:yt_snatcher/services/youtube-dl.dart';
import 'package:yt_snatcher/services/youtube.dart';
import 'package:yt_snatcher/widgets/download_progress_indicator.dart';

class DownloaderView extends StatefulWidget {
  final Downloader downloader;
  final VideoMeta meta;
  final bool pending;

  DownloaderView({
    @required this.downloader,
    @required this.meta,
    this.pending = false,
  });

  @override
  State<StatefulWidget> createState() {
    return DownloaderViewState();
  }
}

class DownloaderViewState extends State<DownloaderView> {
  double _progress = 0;
  String _stage = "Preparing";

  @override
  Widget build(BuildContext context) {
    if (widget.downloader != null) {
      widget.downloader.progressStream.listen(
        (event) => setState(() {
          _progress = event.progress;
          _stage = event.stage;
        }),
      );
    }
    return Padding(
      child: DownloadProgressIndicator(
        title: widget.meta?.title ?? "Loading...",
        subtitle: widget.meta?.channelName ?? "",
        progress: widget.pending ? null : _progress,
        stage: widget.pending ? "Pending" : _stage,
        thumbnailUrl: widget.meta?.thumbnails?.mediumRes ?? null,
        semanticName: widget.meta?.title ?? "content",
        bgColor: widget.pending ? Colors.grey : null,
      ),
      padding: EdgeInsets.all(4),
    );
  }
}
