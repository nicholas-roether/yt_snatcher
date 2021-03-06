import 'dart:async';

import 'package:flutter/material.dart';
import 'package:yt_snatcher/services/downloader.dart';
import 'package:yt_snatcher/services/youtube.dart' as yt;
import 'package:yt_snatcher/services/download_manager.dart' as dlm;
import 'downloader.dart' as dl;

class DownloadProgress {
  final double progress;
  final String stage;

  DownloadProgress(this.progress, this.stage);
}

abstract class MediaDownloader {
  final dl.Downloader _downloader;
  final yt.VideoMeta _meta;
  DownloadProcess _downloadProcess;
  int _byteCount = 0;
  String _stage = "Preparing";
  final StreamController<DownloadProgress> _progressStreamController =
      StreamController.broadcast();

  MediaDownloader(this._meta, this._downloader);

  int get byteCount => _byteCount;
  String get stage => _stage;
  DownloadProcess get process => _downloadProcess;

  Stream<DownloadProgress> get progressStream =>
      _progressStreamController.stream;

  void _progressEvent(double progress, String stage) {
    if (_progressStreamController.isClosed) return;
    var evt = DownloadProgress(progress, stage);
    _progressStreamController.add(evt);
  }

  Future<dl.DownloadProcess> _download();

  Future<dlm.Download> download() async {
    _downloadProcess = await _download();
    return _downloadProcess.done;
  }

  @mustCallSuper
  void _completed() {
    _progressStreamController.close();
  }

  int get _size;

  double get progress => _byteCount == null ? null : _byteCount / _size;
}

class VideoDownloader extends MediaDownloader {
  yt.VideoMedia _video;
  yt.AudioMedia _audio;

  VideoDownloader(
    yt.VideoMeta meta,
    this._video,
    this._audio,
    dl.Downloader downloader,
  ) : super(meta, downloader);

  @override
  Future<dl.DownloadProcess> _download() async {
    var process = await _downloader.downloadVideo(
      _meta.id,
      _meta,
      _video,
      _audio,
      (int bytes, String stage) {
        _stage = stage;
        if (bytes == null) {
          _progressEvent(_byteCount = null, stage);
          return;
        }
        if (_byteCount == null) _byteCount = 0;
        _byteCount += bytes;
        _progressEvent(progress, stage);
      },
    );
    process.done.then((dl) => _completed());
    return process;
  }

  @override
  int get _size => _video.size + _audio.size;
}

class MusicDownloader extends MediaDownloader {
  yt.AudioMedia _media;
  MusicDownloader(yt.VideoMeta meta, this._media, dl.Downloader downloader)
      : super(meta, downloader);

  @override
  Future<dl.DownloadProcess> _download() async {
    var process = await _downloader.downloadMusic(
      _meta.id,
      _meta,
      _media,
      (int bytes) {
        _byteCount += bytes;
        _stage = stage;
        _progressEvent(_byteCount / (_media.size), "Loading");
      },
    );
    process.done.then((dl) => _completed());
    return process;
  }

  @override
  int get _size => _media.size;
}

abstract class DownloaderSet<D extends MediaDownloader> {
  final yt.Video video;
  final dl.Downloader _downloader;

  DownloaderSet(this.video, this._downloader);

  D best([String maxRes]); // TODO [String maxRes]
  D smallest([String minRes]); // TODO [String minRes]
}

class VideoDownloaderSet extends DownloaderSet<VideoDownloader> {
  VideoDownloaderSet(yt.Video video, dl.Downloader downloader)
      : super(video, downloader);

  @override
  VideoDownloader best([String maxRes]) {
    return VideoDownloader(
      video,
      video.videoStreams.highestResolution(),
      video.audioStreams.highestBitrate(),
      _downloader,
    );
  }

  @override
  VideoDownloader smallest([String minRes]) {
    return VideoDownloader(
      video,
      video.videoStreams.smallestSize(),
      video.audioStreams.smallestSize(),
      _downloader,
    );
  }
}

class MusicDownloaderSet extends DownloaderSet<MusicDownloader> {
  MusicDownloaderSet(yt.Video video, dl.Downloader downloader)
      : super(video, downloader);

  @override
  MusicDownloader best([String maxRes]) {
    return MusicDownloader(
      video,
      video.audioStreams.highestBitrate(),
      _downloader,
    );
  }

  @override
  MusicDownloader smallest([String minRes]) {
    return MusicDownloader(
      video,
      video.audioStreams.smallestSize(),
      _downloader,
    );
  }
}

class PreDownload {
  String id;
  yt.Youtube _yt;
  dl.Downloader _downloader;

  PreDownload(this.id, this._yt, this._downloader);

  Future<yt.Video> _getVideo() => _yt.getVideo(id);

  Future<DownloaderSet> asVideo() async {
    return VideoDownloaderSet(await _getVideo(), _downloader);
  }

  Future<DownloaderSet> asMusic() async {
    return MusicDownloaderSet(await _getVideo(), _downloader);
  }
}

class YoutubeDL {
  final _yt = yt.Youtube();
  final _downloader = dl.Downloader();

  PreDownload prepare(String id) => PreDownload(id, _yt, _downloader);

  void close() => _yt.close();
}
