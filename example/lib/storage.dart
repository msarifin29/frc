import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Interface which is used to persist
abstract class Storage {
  /// Returns value for key
  Uint8List? read(String key);

  /// Persists key value pair
  Future<void> write(String key, List<double> embedding);

  /// Deletes key value pair
  Future<void> delete(String key);

  /// Clears all key value pairs from storage
  Future<void> clear();
}

class LocaleStorage implements Storage {
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

  @override
  Future<bool> delete(String key) async {
    try {
      return await _sharedPref.remove(key);
    } catch (e) {
      throw Exception('Failed to delete ${e.toString()}');
    }
  }

  @override
  Future<bool> clear() async {
    try {
      return _sharedPref.clear();
    } catch (e) {
      throw Exception('Failed to clear ${e.toString()}');
    }
  }

  @override
  Uint8List? read(String key) {
    try {
      final data = _sharedPref.getString(key);
      if (data == null) return null;
      return base64Decode(data);
    } catch (e) {
      throw Exception('Failed to read ${e.toString()}');
    }
  }

  @override
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
