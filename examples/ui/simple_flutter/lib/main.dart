import 'package:flutter/material.dart';
import 'package:lib.app.dart/app.dart';
import 'package:lib.widgets/application_deprecated.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gesture Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Gesture Demo - Multiple Process'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int leftCounter = 0;
  int rightCounter = 0;

  List<MaterialColor> colors = <MaterialColor>[
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.purple
  ];

  void _onLeftDismissed(DismissDirection direction) {
    setState(() {
      leftCounter++;
    });
  }

  void _onRightDismissed(DismissDirection direction) {
    setState(() {
      rightCounter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Dismissible(
                      key: Key('left$leftCounter'),
                      onDismissed: _onLeftDismissed,
                      resizeDuration: null,
                      child: Card(
                        child: Container(
                            width: 300.0,
                            height: 300.0,
                            color: colors[leftCounter % colors.length]),
                      )),
                  Text('Left, $leftCounter')
                ]),
            Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Dismissible(
                      key: Key('right$rightCounter'),
                      onDismissed: _onRightDismissed,
                      resizeDuration: null,
                      child: Card(
                          child: Container(
                        width: 300.0,
                        height: 300.0,
                        child: ApplicationWidget(
                            url:
                                'fuchsia-pkg://fuchsia.com/simple_flutter#meta/leaf_flutter.cmx',
                            launcher:
                                StartupContext.fromStartupInfo().launcher),
                      ))),
                  Text('Right, $rightCounter')
                ]),
          ],
        ),
      ),
    );
  }
}
