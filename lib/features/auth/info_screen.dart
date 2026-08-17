import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() =>  InfoScreenState();
}

class InfoScreenState extends State<InfoScreen> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text('info screen')
      ),
    );
  }
}
