import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'sim/sim_bloc.dart';
import 'sim/sim_bloc_provider.dart';
import './conversations/threads.dart';

class App extends StatefulWidget {
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _bloc = SimCardsBloc();
  late final Future<void> _load;

  @override
  void initState() {
    super.initState();
    _load = _bloc.loadSimCards();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _load,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return SimCardsBlocProvider(
            simCardBloc: _bloc,
            child: new MaterialApp(
              title: 'Flutter SMS',
              home: new Threads(),
            ),
          );
        } else {
          return SizedBox.expand(child: CircularProgressIndicator());
        }
      },
    );
  }
}
