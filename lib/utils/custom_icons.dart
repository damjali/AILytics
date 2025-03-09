import 'package:flutter/widgets.dart';

/// Custom icons for the application
///
/// This class provides custom icons that are used in the application
/// based on the Tabler Icons set used in the original design
class CustomIcons {
  CustomIcons._();

  // Using Flutter's built-in icons as substitutes for Tabler icons

  /// Arrow left icon (equivalent to ti-arrow-left)
  static const IconData arrowLeft = IconData(0xe092, fontFamily: 'MaterialIcons');

  /// Lock icon (equivalent to ti-lock)
  static const IconData lock = IconData(0xe3ae, fontFamily: 'MaterialIcons');

  /// Key icon (equivalent to ti-key)
  static const IconData key = IconData(0xe3ae, fontFamily: 'MaterialIcons');
}