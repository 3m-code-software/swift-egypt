import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants.dart';

class LocaleProvider extends ChangeNotifier {
  final FlutterSecureStorage _storage;
  String _locale = AppConstants.defaultLocale;
  bool _isDark = false;

  LocaleProvider(this._storage);

  String get locale => _locale;
  bool get isDark => _isDark;
  bool get isRtl => _locale == 'ar';

  Future<void> loadLocale() async {
    final saved = await _storage.read(key: AppConstants.storageKeyLocale);
    if (saved != null) {
      _locale = saved;
    }
    notifyListeners();
  }

  Future<void> setLocale(String locale) async {
    _locale = locale;
    await _storage.write(key: AppConstants.storageKeyLocale, value: locale);
    notifyListeners();
  }

  Future<void> toggleLocale() async {
    _locale = _locale == 'ar' ? 'en' : 'ar';
    await _storage.write(key: AppConstants.storageKeyLocale, value: _locale);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    notifyListeners();
  }
}
