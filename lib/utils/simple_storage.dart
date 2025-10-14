import 'dart:convert';

/// Simple in-memory storage solution to replace SharedPreferences
/// This avoids any file system dependencies that could trigger storage permissions
class SimpleStorage {
  static final SimpleStorage _instance = SimpleStorage._internal();
  factory SimpleStorage() => _instance;
  SimpleStorage._internal();

  static SimpleStorage get instance => _instance;

  final Map<String, String> _storage = {};

  /// Get a string value
  String? getString(String key) {
    return _storage[key];
  }

  /// Set a string value
  Future<bool> setString(String key, String value) async {
    _storage[key] = value;
    return true;
  }

  /// Remove a specific key
  Future<bool> remove(String key) async {
    _storage.remove(key);
    return true;
  }

  /// Clear all stored data
  Future<bool> clear() async {
    _storage.clear();
    return true;
  }

  /// Check if a key exists
  bool containsKey(String key) {
    return _storage.containsKey(key);
  }

  /// Get all keys
  Set<String> getKeys() {
    return _storage.keys.toSet();
  }
}

/// Compatibility class to mimic SharedPreferences API
class SharedPreferences {
  static SimpleStorage? _instance;

  static Future<SharedPreferences> getInstance() async {
    _instance ??= SimpleStorage.instance;
    return SharedPreferences._();
  }

  SharedPreferences._();

  String? getString(String key) {
    return SimpleStorage.instance.getString(key);
  }

  Future<bool> setString(String key, String value) {
    return SimpleStorage.instance.setString(key, value);
  }

  Future<bool> remove(String key) {
    return SimpleStorage.instance.remove(key);
  }

  Future<bool> clear() {
    return SimpleStorage.instance.clear();
  }

  bool containsKey(String key) {
    return SimpleStorage.instance.containsKey(key);
  }

  Set<String> getKeys() {
    return SimpleStorage.instance.getKeys();
  }
}
