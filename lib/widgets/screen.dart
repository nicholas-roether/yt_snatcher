import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_conditional_rendering/conditional.dart';
import 'package:yt_snatcher/screens/settings/settings_screen.dart';
import 'package:yt_snatcher/widgets/provider/error_provider.dart';

class Screen extends StatefulWidget {
  final Widget title;
  final Widget content;
  final bool showSettings;
  final Widget navigationBar;
  final Widget fab;

  Screen({
    @required this.title,
    @required this.content,
    this.navigationBar,
    this.showSettings = true,
    this.fab,
  });

  @override
  State<StatefulWidget> createState() {
    return ScreenState();
  }
}

class ScreenState extends State<Screen> {
  static final List<GlobalKey<ScaffoldState>> _scaffoldKeys = [];
  static StreamSubscription _subscription;

  static onError(Object error, ThemeData theme) {
    _scaffoldKeys.last.currentState.showSnackBar(
      SnackBar(
        content: Text(error.toString()),
        backgroundColor: theme.colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    var key = GlobalKey<ScaffoldState>();
    _scaffoldKeys.add(key);
    if (_subscription == null) {
      var theme = Theme.of(context);
      _subscription =
          ErrorProvider.of(context).stream.listen((e) => onError(e, theme));
    }
    return Scaffold(
      key: key,
      appBar: AppBar(title: widget.title, actions: [
        Conditional.single(
          context: context,
          conditionBuilder: (context) => widget.showSettings,
          widgetBuilder: (context) => (IconButton(
            icon: Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(
              context,
              SettingsScreen.ROUTENAME,
            ),
          )),
          fallbackBuilder: (context) => Container(),
        ),
      ]),
      body: widget.content,
      bottomNavigationBar: widget.navigationBar,
      floatingActionButton: widget.fab,
    );
  }

  @override
  void dispose() {
    _scaffoldKeys.removeLast();
    if (_scaffoldKeys.length == 0) _subscription?.cancel();
    super.dispose();
  }
}
