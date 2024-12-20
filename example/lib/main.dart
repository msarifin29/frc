import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frc/frc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Frc.initialize();
  await LocaleStorage.init();
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
          spacing: 50,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const FaceDetectionView();
                }));
              },
              child: const Text('Camera View'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const RecognitionView();
                }));
              },
              child: const Text('Recognition View'),
            ),
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
  late RecognizerHandler service;
  late LocaleStorage localeStorage;

  @override
  void initState() {
    service = RecognizerHandler('assets/mobile_face_net.tflite');
    localeStorage = LocaleStorage();

    controller = FRCController(
      autoCapture: true,
      onCapture: (image, img) {
        if (img != null) {
          localeStorage.write('sample', uint8ListToListDouble(img));
        }
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

  List<double> uint8ListToListDouble(Uint8List? uint8List) {
    if (uint8List == null || uint8List.isEmpty) return [];

    return uint8List.map((e) => e / 255.0).toList();
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
                        Image.memory(imageFile!, width: 200, height: 200),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await controller.startImageStream();
                            await LocaleStorage().clear();

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
    service.close();
    super.dispose();
  }
}

class RecognitionView extends StatefulWidget {
  const RecognitionView({super.key});

  @override
  State<RecognitionView> createState() => RecognitionViewState();
}

class RecognitionViewState extends State<RecognitionView> {
  Uint8List? imageFile;

  late FRCController controller;
  late RecognizerHandler service;
  double similarity = 0.0;

  @override
  void initState() {
    service = RecognizerHandler('assets/mobile_face_net.tflite');
    controller = FRCController(
      autoCapture: true,
      onCapture: (image, img) async {
        setState(() => imageFile = img);
      },
    );
    super.initState();
  }

  void compare(Uint8List? input) async {
    if (input != null) {
      similarity = await service.compareImages(input, 'sample');

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('example app')),
      body: Builder(
        builder: (context) {
          if (imageFile != null) {
            compare(imageFile);

            return Center(
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  SizedBox(
                    height: 700,
                    width: 200,
                    child: Column(
                      children: [
                        Text('Similarity $similarity'),
                        Image.memory(imageFile!, width: 200, height: 200),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () async {
                            await controller.startImageStream();

                            setState(() => imageFile = null);
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
    service.close();
    super.dispose();
  }
}
