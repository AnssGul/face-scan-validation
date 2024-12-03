import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';

import 'login/login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); //Add this

  await FaceCamera.initialize(); //Add this

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Demo',
      home: LoginPage(),
    );
  }
}
