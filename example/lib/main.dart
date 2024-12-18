import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frc/frc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Frc.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: Home());
  }
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Wrap(
          children: [
            ElevatedButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const FaceDetectionView();
                  }));
                },
                child: const Text('Camera View'))
          ],
        ),
      ),
    );
  }
}

class FaceDetectionView extends StatefulWidget {
  const FaceDetectionView({super.key});

  @override
  State<FaceDetectionView> createState() => _FaceDetectionViewState();
}

class _FaceDetectionViewState extends State<FaceDetectionView> {
  File? _capturedImage;
  Uint8List? imageFile;

  late FRCController controller;

  @override
  void initState() {
    controller = FRCController(
      autoCapture: true,
      onCapture: (image, img) {
        setState(() {
          _capturedImage = image;
          imageFile = img;
        });
      },
      onFaceDetected: (Face? face) {
        //Do something
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('example app')),
      body: Builder(
        builder: (context) {
          if (_capturedImage != null || imageFile != null) {
            return Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 700,
                    width: 200,
                    child: Column(
                      children: [
                        Image.file(_capturedImage!, width: double.maxFinite, fit: BoxFit.fitWidth),
                        const SizedBox(height: 10),
                        Image.memory(imageFile!, width: 200, height: 200),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await controller.startImageStream();
                            setState(() {
                              _capturedImage = null;
                              imageFile = null;
                            });
                          },
                          child: const Text(
                            'Capture Again',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return FaceCamera(
            controller: controller,
            messageBuilder: (context, face) {
              if (face == null) {
                return _message('Place your face in the camera');
              }
              if (!face.wellPositioned) {
                return _message('Center your face in the square');
              }
              return const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }

  Widget _message(String msg) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 55, vertical: 15),
        child: Text(
          msg,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5, fontWeight: FontWeight.w400),
        ),
      );

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}
