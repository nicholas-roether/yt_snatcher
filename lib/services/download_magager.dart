import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:yt_snatcher/services/files.dart' as fs;
import 'package:yt_snatcher/services/youtube.dart' as yt;

enum DownloadType { VIDEO, MUSIC }

class DownloadMeta {
  final yt.VideoMeta videoMeta;
  final String id;
  final String filename;
  final File metaFile;
  DownloadType type;
  DateTime downloadDate;
  DateTime watchDate;

  DownloadMeta(
    this.videoMeta,
    this.id,
    this.filename,
    this.metaFile,
    this.type, [
    this.downloadDate,
    this.watchDate,
  ]) {
    if (downloadDate == null) downloadDate = DateTime.now();
    if (watchDate == null) watchDate = downloadDate;
  }

  String toJson() {
    return jsonEncode({
      "videoMeta": videoMeta.toJson(),
      "id": id,
      "filename": filename,
      "type": type.index,
      "downloadDate": downloadDate.millisecondsSinceEpoch,
      "watchDate": watchDate.millisecondsSinceEpoch
    });
  }

  Future<void> delete() async {
    await metaFile?.delete();
  }

  factory DownloadMeta.fromJson(String json, File file) {
    var data = jsonDecode(json);
    return DownloadMeta(
      data["videoMeta"] != null
          ? yt.VideoMeta.fromJson(data["videoMeta"])
          : null,
      data["id"],
      data["filename"],
      file,
      data["type"] != null ? DownloadType.values[data["type"]] : null,
      data["downloadDate"] != null
          ? DateTime.fromMicrosecondsSinceEpoch(data["downloadDate"])
          : null,
      data["watchDate"] != null
          ? DateTime.fromMicrosecondsSinceEpoch(data["watchDate"])
          : null,
    );
  }
}

class Download {
  final DownloadMeta meta;
  final File mediaFile;
  // TODO thumbnail files

  Download(this.meta, this.mediaFile);

  Future<Uint8List> getMedia() async {
    var data = await mediaFile.readAsBytes();
    return data;
  }

  Future<void> delete() async {
    await Future.wait([
      meta?.delete(),
      mediaFile?.delete(),
    ]);
  }
}

class UnknownDownloadException {
  final String id;

  UnknownDownloadException(this.id);

  @override
  String toString() => "The download with id $id does not exist in this set.";
}

abstract class DownloadSet {
  final fs.FileManager _fileManager;
  final List<DownloadMeta> _meta;
  final String _mediaPath;

  DownloadSet(this._mediaPath, this._meta, this._fileManager);

  List<String> get ids => _meta.map((e) => e.id).toList();

  Future<Download> getDownload(String id) async {
    var meta = _meta.firstWhere((e) => e.id == id);
    if (meta == null) throw UnknownDownloadException(id);
    var media = await _getMedia(meta.filename);
    return Download(meta, media);
  }

  bool _validateDownload(Download d) =>
      d.mediaFile == null ||
      d.meta == null ||
      d.meta.videoMeta == null ||
      (d.meta.type == DownloadType.VIDEO && !d.mediaFile.path.endsWith(".mp4"));

  Future<List<Download>> getDownloads() async {
    return (await Future.wait(_meta.map((meta) async {
      return Download(meta, await _getMedia(meta.filename));
    }).toList()))
        .where((d) {
      var valid = _validateDownload(d);
      if (valid) d.delete();
      return !valid;
    }).toList();
  }

  Future<File> _getMedia(String filename) {
    if (filename == null) return null;
    return _fileManager.getExistingLocalFile(_mediaPath, filename);
  }
}

class VideoDownloadSet extends DownloadSet {
  VideoDownloadSet(List<DownloadMeta> meta, fs.FileManager fileManager)
      : super(fs.FileManager.VIDEO_PATH, meta, fileManager);
}

class MusicDownloadSet extends DownloadSet {
  MusicDownloadSet(List<DownloadMeta> meta, fs.FileManager fileManager)
      : super(fs.FileManager.MUSIC_PATH, meta, fileManager);
}

class DownloadManager {
  final _fileManager = fs.FileManager();

  static String getFilename(String name, yt.Media media) =>
      "$name.${media.container}";

  Future<List<DownloadMeta>> _extractMetaData(List<File> metaFiles) {
    return Future.wait(metaFiles
        .map((e) async => DownloadMeta.fromJson(await e.readAsString(), e))
        .toList());
  }

  Future<List<DownloadMeta>> _getMetaData(String path) async {
    var metaFiles = await _fileManager.getExistingLocalFiles(
      fs.FileManager.VIDEO_META_PATH,
    );
    return _extractMetaData(metaFiles);
  }

  Future<VideoDownloadSet> getVideos() async {
    return VideoDownloadSet(
      await _getMetaData(fs.FileManager.VIDEO_META_PATH),
      _fileManager,
    );
  }

  Future<MusicDownloadSet> getMusic() async {
    return MusicDownloadSet(
      await _getMetaData(fs.FileManager.MUSIC_META_PATH),
      _fileManager,
    );
  }
}