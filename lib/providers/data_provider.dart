// data_provider.dart - Create this new file
import 'package:flutter/foundation.dart';

class DataProvider extends ChangeNotifier {
  Map<String, dynamic>? _processedData;
  String? _fileName;

  Map<String, dynamic>? get processedData => _processedData;
  String? get fileName => _fileName;
  bool get hasData => _processedData != null;

  void setData(Map<String, dynamic> data, String name) {
    _processedData = data;
    _fileName = name;
    notifyListeners();
  }

  void clearData() {
    _processedData = null;
    _fileName = null;
    notifyListeners();
  }
}