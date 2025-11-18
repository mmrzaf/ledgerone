import 'package:flutter/material.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Starter',
      home: Scaffold(
        body: Center(child: Text('v0.1 Skeleton')),
      ),
    );
  }
}
