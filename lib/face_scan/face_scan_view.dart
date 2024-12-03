import 'dart:async';
import 'dart:io';

import 'package:face_camera/face_camera.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:step_progress_indicator/step_progress_indicator.dart';

class FaceScanView extends StatefulWidget {
  const FaceScanView({super.key});

  @override
  State<FaceScanView> createState() => _FaceScanViewState();
}

class _FaceScanViewState extends State<FaceScanView> {
  late FaceCameraController _controller;
  bool _isFaceClear = false;
  bool _isCapturing = false;
  double _progress = 0.0;
  double _savedProgress = 0.0;
  Timer? _timer;
  Face? _lastDetectedFace;
  bool _isLoading = false;
  bool _isImageClicked = false;

  @override
  void initState() {
    super.initState();
    _initFaceCameraController();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _initFaceCameraController() {
    _controller = FaceCameraController(
      autoCapture: false,
      enableAudio: false,
      defaultFlashMode: CameraFlashMode.off,
      defaultCameraLens: CameraLens.front,
      onFaceDetected: (Face? face) {
        _lastDetectedFace = face;

        if (face != null) {
          bool isClear = _isFaceClearCondition(face);

          if (isClear) {
            if (!_isFaceClear) {
              setState(() {
                _isFaceClear = true;
                _startLoading(resume: true);
              });
            } else if (_isLoading) {
              _checkFacePositionDuringLoading();
            }
          } else {
            _stopLoading();
          }
        } else {
          _resetLoading();
        }
      },
      onCapture: (File? image) {
        if (image != null) {
          setState(() {
            _isCapturing = false;
            _progress = 0.0;
            _savedProgress = 0.0;
            _isImageClicked = true;
          });

          print('Image captured: $image');

          Future.delayed(const Duration(seconds: 2), () {
            // Navigate to the next screen
            // kAppNavigatorKey.currentContext?.pushNamed(uploadIdRoute);
          });
        }
      },
    );
  }

  bool _isFaceClearCondition(Face face) {
    bool isBoundingBoxValid =
        face.boundingBox.width > 120 && face.boundingBox.height > 100;
    bool isConfidenceHigh = face.trackingId != null;

    bool isFaceStraight = face.headEulerAngleX!.abs() < 10 &&
        face.headEulerAngleY!.abs() < 10 &&
        face.headEulerAngleZ!.abs() < 10;

    return isBoundingBoxValid && isConfidenceHigh && isFaceStraight;
  }

  void _startLoading({bool resume = false}) {
    if (_isCapturing) return;

    setState(() {
      _isLoading = true;
    });

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_lastDetectedFace == null ||
          !_isFaceClearCondition(_lastDetectedFace!)) {
        _stopLoading();
        return;
      }

      setState(() {
        _progress = resume ? _progress + 0.01 : _savedProgress + 0.01;
        _savedProgress = _progress;
      });

      if (_progress >= 1.0) {
        _timer?.cancel();
        _captureImage();
      }
    });
  }

  void _checkFacePositionDuringLoading() {
    if (_lastDetectedFace != null &&
        !_isFaceClearCondition(_lastDetectedFace!)) {
      _stopLoading();
    }
  }

  void _captureImage() {
    setState(() {
      _isCapturing = true;
      _isLoading = false;
    });
    _controller.captureImage();
  }

  void _stopLoading() {
    _timer?.cancel();
    setState(() {
      _isFaceClear = false;
      _isLoading = false;
    });
  }

  void _resetLoading() {
    _stopLoading();
    setState(() {
      _progress = 0.0;
      _savedProgress = 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const ProgressIndicatorWidget(
          currentStep: 8,
        ),
      ),
      body: Padding(
        padding: BaseTheme.screenPadding,
        child: Column(
          children: [
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Scanning Face',
                // style: context.textTheme.headlineSmall?.copyWith(
                //   color: context.colorScheme.onSurface,
                // ),
              ),
            ),
            const Gap(100),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 200,
                  width: 200,
                  child: CircularProgressIndicator(
                    value: _progress,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _isCapturing
                          ? Colors.blue
                          : (_isLoading ? Colors.green : Colors.red),
                    ),
                    strokeWidth: 4.0,
                  ),
                ),
                ClipOval(
                  child: Container(
                    height: 180,
                    width: 180,
                    color: Colors.white,
                    child: FittedBox(
                      fit: BoxFit.fill,
                      child: SizedBox(
                        width: 200,
                        height: 200,
                        child: SmartFaceCamera(
                          showControls: false,
                          controller: _controller,
                          indicatorShape: IndicatorShape.square,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(40),
            Text(
              _isImageClicked
                  ? 'Success'
                  : _progress > 0
                      ? '${(_progress * 100).toInt()}%'
                      : '',
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontSize: 20,
              ),
            ),
            const Gap(8),
            Text(
              _isImageClicked
                  ? 'Face scanned successfully!'
                  : _progress > 0
                      ? 'Please wait...'
                      : "",
              style: const TextStyle(
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProgressIndicatorWidget extends StatelessWidget {
  final int currentStep;
  final double size;

  const ProgressIndicatorWidget({
    super.key,
    required this.currentStep,
    this.size = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    double percentage = (currentStep / 10) * 100;

    return Row(
      children: [
        Flexible(
          flex: 2,
          child: StepProgressIndicator(
            totalSteps: 10,
            currentStep: currentStep,
            size: size,
            padding: 1,
            selectedColor: Colors.black,
            unselectedColor: Colors.green,
            roundedEdges: const Radius.circular(10),
            selectedSize: 8,
            unselectedSize: 8,
          ),
        ),
        const Gap(10),
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            color: Colors.black,
            fontSize: 15,
          ),
          // style: context.textTheme.bodyMedium?.copyWith(
          //   // color: context.colorScheme.onSurface,
          //   // fontWeight: FontWeight.w800,
          // ),
        ),
      ],
    );
  }
}

abstract class BaseTheme {
  static const double unit = 8;
  static const double padding = unit * 2;
  static const double buttonRadius = 40;
  static const double borderRadius = 12;
  static const double size = 10;
  static const double verticlePaddingBtn = 10;
  static const double horizontalPaddingBtn = 24;
  static const EdgeInsetsGeometry screenPadding = EdgeInsets.symmetric(
    vertical: padding,
    horizontal: 18,
  );
  static const circularRadius = Radius.circular(buttonRadius);
  // Theme independent colors
  static const Color iconColor = Color(0xFF878787);
  // Shadows
  static final defaultShadow = BoxShadow(
    offset: const Offset(0, 0),
    blurRadius: 24,
    color: Colors.black.withOpacity(0),
  );
}
