import 'package:flutter/material.dart';

class Myself extends StatefulWidget {
  const Myself({super.key});

  @override
  State<StatefulWidget> createState() => MyselfState();
}

class MyselfState extends State<Myself> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("我的"),
      ),
    );
  }
}