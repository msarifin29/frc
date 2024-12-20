# Face Recognition Camera(FRC)

## Setup
* Download model [here](example/assets/mobile_face_net.tflite)

* Add model `mobile_face_net.flite` in `pubspec.yaml`
```yaml
  assets:
    - assets/
```

* Create a function to save and read in locale storage. In this case using `shared_preferences` packages.

```yaml
flutter pub add shared_preferences
```
or 
```yaml
dependencies:  
  # add shared_preferences to your dependencies
  shared_preferences:
```
Example code:
```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

class LocaleStorage  {
  static LocaleStorage? _instance;
  static late SharedPreferences _sharedPref;

  LocaleStorage() {
    init();
  }

  static Future<LocaleStorage> init() async {
    if (_instance != null) return _instance!;
    _sharedPref = await SharedPreferences.getInstance();
    return _instance = LocaleStorage();
  }

  Uint8List? read(String key) {
    try {
      final data = _sharedPref.getString(key);
      if (data == null) return null;
      return base64Decode(data);
    } catch (e) {
      throw Exception('Failed to read ${e.toString()}');
    }
  }

  Future<void> write(String key, List<double> embedding) async {
    try {
      String base64String = base64Encode(byteData(embedding));
      await _sharedPref.setString(key, base64String);
    } catch (e) {
      throw Exception('Failed to write ${e.toString()}');
    }
  }

  Uint8List byteData(List<double> embedding) {
    final value = Uint8List.fromList(
      embedding.map((e) => (e * 255).clamp(0, 255).toInt()).toList(),
    );
    return value;
  }
}

```

## Usage

* Initialize in `main.dart`
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Frc.initialize();
  await LocaleStorage().init();
  runApp(const MyApp());
}
```

* Load model from asset
```dart
RecognizerHandler('assets/mobile_face_net.tflite')
```

* Save image to local as Uint8List
```dart
LocaleStorage().write('sample', uint8ListToListDouble(img));

List<double> uint8ListToListDouble(Uint8List? uint8List) {
    if (uint8List == null || uint8List.isEmpty) return [];
    return uint8List.map((e) => e / 255.0).toList();
  }
```

* Compare image from input and locale
```dart
final localeImage = LocaleStorage().read('sample');

await RecognizerHandler()compareImages(input, localeImage);
```

Full example [here](example/lib/main.dart)