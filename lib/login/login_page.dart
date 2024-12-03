import 'package:flutter/material.dart';
import '../face_scan/face_scan_view.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FaceScanView(),
              ),
            );
          },
          child: const Text('Go to Camera Screen'),
        ),
      ),
    );
  }
}
