import 'package:flutter/material.dart';
import 'package:yt_snatcher/widgets/consumer.dart';
import 'package:yt_snatcher/screens/home/ongoing_download_view.dart';
import 'package:yt_snatcher/widgets/provider/download_process_manager.dart';

class DownloadProcessesDisplay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<DownloadService>(
      builder: (context, inherited, child) {
        var processes = inherited.currentDownloads;
        if (processes.isEmpty)
          return Center(
              child: Text(
            "No downloads are currently active.",
            style: TextStyle(fontStyle: FontStyle.italic),
          ));
        return ListView.builder(
          itemBuilder: (context, i) {
            var process = processes[i];
            return OngoingDownloadView(
              ongoingDownload: process,
            );
          },
          itemCount: processes.length,
        );
      },
    );
  }
}
