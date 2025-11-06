import 'package:resiwash/common/views/AppBar.dart';
import 'package:flutter/material.dart';

class MyMachinesPage extends StatelessWidget {
  const MyMachinesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBarComponent(actions: [], title: "My Machines"),
      body: Center(
        child: const Text(
          'Welcome to My Machines Page!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
