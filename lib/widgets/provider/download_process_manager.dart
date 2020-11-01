import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yt_snatcher/services/download_manager.dart';
import 'package:yt_snatcher/services/youtube-dl.dart';
import 'package:yt_snatcher/services/youtube.dart';

class DuplicateDownloadError extends Error {
  final String id;
  final DownloadType type;

  DuplicateDownloadError(this.id, this.type);

  @override
  String toString() {
    return "$id has already been downloaded with type $type";
  }
}

class DownloadProcess {
  final Downloader downloader;
  final VideoMeta meta;
  final DownloadType type;

  DownloadProcess(this.meta, this.downloader, this.type);

  Future<Download> start() => downloader.download();
}

class DownloadService extends InheritedWidget {
  static final _ytdl = YoutubeDL();
  static final _dlm = DownloadManager();
  final void Function(DownloadProcess process) add;
  final void Function(DownloadProcess process) remove;
  final List<DownloadProcess> currentDownloads;

  DownloadService({
    Key key,
    @required Widget child,
    @required this.add,
    @required this.remove,
    this.currentDownloads = const [],
  })  : assert(currentDownloads != null),
        assert(add != null),
        assert(remove != null),
        super(key: key, child: child);

  Future<bool> _checkDuplicate(String id, DownloadType type) async {
    if (currentDownloads.any(
      (d) => d.meta.id == id && d.type == type,
    )) return false;
    return _dlm.checkDuplicate(id, type);
  }

  Future<Download> _download<D extends Downloader>(
    DownloaderSet dlset,
    DownloadType type, [
    FutureOr<D> Function(DownloaderSet<D>) selector,
  ]) async {
    if (await _checkDuplicate(dlset.video.id, type))
      throw DuplicateDownloadError(dlset.video.id, type);
    var downloader = await selector?.call(dlset) ?? dlset.best();
    var process = DownloadProcess(dlset.video, downloader, type);
    add(process);
    var dl = await downloader.download().catchError((e) {
      remove(process);
      throw e;
    });
    remove(process);
    return dl;
  }

  Future<Download> downloadVideo(
    String id, [
    FutureOr<VideoDownloader> Function(VideoDownloaderSet) selector,
  ]) async =>
      _download<VideoDownloader>(
        await _ytdl.prepare(id).asVideo(),
        DownloadType.VIDEO,
        selector,
      );

  Future<Download> downloadMusic(
    String id, [
    FutureOr<MusicDownloader> Function(MusicDownloaderSet) selector,
  ]) async =>
      _download<MusicDownloader>(
        await _ytdl.prepare(id).asMusic(),
        DownloadType.MUSIC,
        selector,
      );

  DownloadProcess getDownload(String id, DownloadType type) {
    return currentDownloads.firstWhere(
      (dl) => dl.meta.id == id && dl.type == type,
    );
  }

  @override
  bool updateShouldNotify(DownloadService old) =>
      true; // TODO provide better condition as a rebuilt has major performance impact

  static DownloadService of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DownloadService>();
  }
}

class DownloadProcessManager extends StatefulWidget {
  final Widget child;
  final Key serviceKey;

  DownloadProcessManager({Key key, this.serviceKey, @required this.child})
      : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return DownloadProcessManagerState();
  }
}

class DownloadProcessManagerState extends State<DownloadProcessManager> {
  List<DownloadProcess> _processes = [];

  void _add(DownloadProcess process) => setState(() => _processes.add(process));
  void _remove(DownloadProcess process) =>
      setState(() => _processes.remove(process));

  @override
  Widget build(BuildContext context) {
    return DownloadService(
      key: widget.serviceKey,
      child: widget.child,
      add: (p) => _add(p),
      remove: (p) => _remove(p),
      currentDownloads: _processes,
    );
  }
}
