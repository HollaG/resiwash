import 'package:google_fonts/google_fonts.dart';
import 'package:resiwash/asset-export.dart';
import 'package:resiwash/common/views/AppBar.dart';
import 'package:resiwash/common/views/homeMainCard.dart';
import 'package:flutter/material.dart';
import 'package:resiwash/views/home/homeHeader.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    getData();
  }

  void getData() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBarComponent(actions: [], title: "ResiWash"),
      body: Column(children: [HomeHeader(username: "Marcus")]),
    );
  }
}
