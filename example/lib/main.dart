import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:frc/frc.dart';
import 'package:frc_example/storage.dart';

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
      appBar: AppBar(title: const Text('Example')),
      body: Center(
        child: Wrap(
          spacing: 50,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const RegisterPage();
                }));
              },
              child: const Text('Register'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return const RecognitionPage();
                }));
              },
              child: const Text('Recognition'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
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
      centerPosition: true,
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
          return FaceCameraCircle(
            controller: controller,
            autoDisableCaptureControl: true,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    service.close();
    super.dispose();
  }
}

class RecognitionPage extends StatefulWidget {
  const RecognitionPage({super.key});

  @override
  State<RecognitionPage> createState() => RecognitionPageState();
}

class RecognitionPageState extends State<RecognitionPage> {
  Uint8List? imageFile;

  late FRCController controller;
  late RecognizerHandler service;
  double similarity = 0.0;

  @override
  void initState() {
    service = RecognizerHandler('assets/mobile_face_net.tflite');
    controller = FRCController(onCapture: (image, img) {});
    super.initState();
  }

  void compare(Uint8List? input) async {
    final localeImage = LocaleStorage().read('sample');
    if (input != null && localeImage != null) {
      similarity = await service.compareImages(input, localeImage);

      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            showCaptureControl: true,
            captureControl: (file, img) {
              setState(() => imageFile = img);
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    service.close();
    super.dispose();
  }
}
