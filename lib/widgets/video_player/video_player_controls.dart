import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yt_snatcher/widgets/video_player/video_player_controller.dart';
import 'package:yt_snatcher/widgets/video_player/video_player_controls_bottom.dart';
import 'package:yt_snatcher/widgets/video_player/video_player_controls_center.dart';
import 'package:yt_snatcher/widgets/video_player/video_player_controls_top.dart';

class VideoPlayerControls extends StatefulWidget {
  final YtsVideoPlayerController controller;
  final bool showControlsImmediately;
  final bool fullscreen;
  final void Function() onBack;

  VideoPlayerControls({
    @required this.controller,
    this.showControlsImmediately = true,
    this.fullscreen = false,
    this.onBack,
  });

  @override
  State<StatefulWidget> createState() => VideoPlayerControlsState();
}

class VideoPlayerControlsState extends State<VideoPlayerControls>
    with SingleTickerProviderStateMixin {
  static const _HIDE_TIMEOUT = Duration(seconds: 4);
  static const _SHOW_HIDE_DURATION = Duration(milliseconds: 100);
  AnimationController _showHideAnimation;
  bool _shown = false;
  bool _playing = false;
  Timer _hideTimer;

  @override
  void initState() {
    _showHideAnimation = AnimationController(
      vsync: this,
      duration: _SHOW_HIDE_DURATION,
    );
    widget.showControlsImmediately ? _show() : _hide();
    widget.controller.addListener(_onControllerUpdate);
    super.initState();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() async {
    final playing = widget.controller.isPlaying;
    if (!this.mounted) return;
    if (playing != _playing) {
      _playing = playing;
      if (_playing) _scheduleHide();
    }
  }

  void _show() {
    _hideTimer?.cancel();
    _shown = true;
    if (_playing) _scheduleHide();
  }

  void _hide() {
    _hideTimer?.cancel();
    _shown = false;
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_HIDE_TIMEOUT, () {
      if (_playing) setState(() => _hide());
    });
  }

  void _onTap() {
    setState(() => _shown ? _hide() : _show());
  }

  @override
  Widget build(BuildContext context) {
    _showHideAnimation.animateTo(_shown ? 1 : 0);
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => _onTap(),
      child: AnimatedBuilder(
        animation: _showHideAnimation,
        builder: (context, child) {
          return Container(
            color: Colors.black26.withAlpha(
              (_showHideAnimation.value * 70).round(),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: VideoPlayerControlsTop(
                visible: _shown,
                onBack: () => widget.onBack?.call(),
                animation: _showHideAnimation.drive(Tween(begin: 1, end: 0)),
                fullscreen: widget.fullscreen,
              ),
            ),
            Align(
              alignment: Alignment.center,
              child: VideoPlayerControlsCenter(
                controller: widget.controller,
                visible: _shown,
                onPressed: () => _scheduleHide(),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoPlayerControlsBottom(
                controller: widget.controller,
                expanded: _shown,
                animationDuration: _SHOW_HIDE_DURATION,
                fullscreen: widget.fullscreen,
                onDragStart: () => _hideTimer?.cancel(),
                onDragEnd: () => _scheduleHide(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
