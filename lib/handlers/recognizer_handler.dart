// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class RecognizerHandler {
  final String modelPath;

  late Interpreter interpreter;

  static const int width = 112;
  static const int height = 112;

  RecognizerHandler(this.modelPath) {
    _loadModel();
  }

  Future<void> _loadModel() async {
    final options = InterpreterOptions();
    if (Platform.isAndroid) options.addDelegate(XNNPackDelegate());

    if (Platform.isIOS) options.addDelegate(GpuDelegate());

    try {
      interpreter = await Interpreter.fromAsset(modelPath, options: options);
    } catch (e) {
      throw Exception('Failed to load model ${e.toString()}');
    }
  }

  Float32List _preprocessImage(img.Image inputImage) {
    final resizedImage = img.copyResize(inputImage, width: width, height: height);
    Float32List normalizedData = Float32List(width * height * 3);

    int index = 0;
    for (int y = 0; y < width; y++) {
      for (int x = 0; x < height; x++) {
        final pixel = resizedImage.getPixel(x, y);

        // Normalize pixel values: (value - 127.5) / 127.5
        normalizedData[index++] = (pixel.r - 127.5) / 127.5; // Red channel
        normalizedData[index++] = (pixel.g - 127.5) / 127.5; // Green channel
        normalizedData[index++] = (pixel.b - 127.5) / 127.5; // Blue channel
      }
    }

    return normalizedData;
  }

  List<double> _runInference(Float32List inputTensor) {
    final input = inputTensor.reshape([1, height, width, 3]);
    final output = List<double>.filled(192, 0).reshape([1, 192]);

    interpreter.run(input, output);
    return List<double>.from(output.first);
  }

  double _cosineSimilarity(List<dynamic> a, List<dynamic> b) {
    if (a.length != b.length) {
      throw Exception('Embeddings must have the same length.');
    }

    double dotProduct = 0, magnitudeA = 0, magnitudeB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      magnitudeA += a[i] * a[i];
      magnitudeB += b[i] * b[i];
    }

    return dotProduct / (sqrt(magnitudeA) * sqrt(magnitudeB));
  }

  Future<img.Image?> _decodeImage(Uint8List? data) async {
    return data == null ? null : img.decodeImage(data);
  }

  Future<double> compareImages(Uint8List inputImageData, Uint8List storedImageData) async {
    img.Image? inputImage = await _decodeImage(inputImageData);
    final storedImage = await _decodeImage(storedImageData);

    if (inputImage == null || storedImage == null) {
      throw Exception('Failed to decode one or both images.');
    }

    final inputEmbeddings = _runInference(_preprocessImage(inputImage));
    final storedEmbeddings = _runInference(_preprocessImage(storedImage));

    return _cosineSimilarity(inputEmbeddings, storedEmbeddings);
  }

  void close() {
    interpreter.close();
  }
}
