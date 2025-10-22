import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:pushengage_flutter_sdk/model/trigger_campaign.dart';
import 'package:pushengage_flutter_sdk/pushengage_flutter_sdk.dart';
import 'package:pushengage_flutter_sdk_example/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    PushEngage.setAppId("YOUR_APP_ID");
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'PushEngage',
      debugShowCheckedModeBanner: false,
      home: Home(),
    );
  }
}
