import 'package:flutter/material.dart';

/// Comprehensive responsive design utility for making the app work perfectly
/// across all device sizes (Pixel 8a, Vivo T3x 5G, and all other devices)
class ResponsiveUtils {
  final BuildContext context;

  ResponsiveUtils(this.context);

  // Screen dimensions
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  double get screenDiagonal => _calculateDiagonal();

  // Device type detection
  bool get isSmallPhone => screenWidth < 360;
  bool get isMediumPhone => screenWidth >= 360 && screenWidth < 400;
  bool get isLargePhone => screenWidth >= 400 && screenWidth < 600;
  bool get isTablet => screenWidth >= 600;

  // Scale factors based on design baseline (Pixel 8a: 412x915)
  static const double _baselineWidth = 412.0;
  static const double _baselineHeight = 915.0;

  double get widthScale => screenWidth / _baselineWidth;
  double get heightScale => screenHeight / _baselineHeight;
  double get averageScale => (widthScale + heightScale) / 2;

  // Calculate diagonal for more accurate scaling
  double _calculateDiagonal() {
    return (screenWidth * screenWidth + screenHeight * screenHeight) / 
           (_baselineWidth * _baselineWidth + _baselineHeight * _baselineHeight);
  }

  /// Responsive width - scales based on screen width
  double width(double pixels) {
    return pixels * widthScale;
  }

  /// Responsive height - scales based on screen height
  double height(double pixels) {
    return pixels * heightScale;
  }

  /// Responsive size - scales based on average of width and height
  /// Use this for dimensions that should scale proportionally
  double size(double pixels) {
    return pixels * averageScale;
  }

  /// Responsive font size with min/max constraints
  double fontSize(double pixels, {double? min, double? max}) {
    double scaled = pixels * averageScale;
    
    if (min != null && scaled < min) return min;
    if (max != null && scaled > max) return max;
    
    return scaled;
  }

  /// Responsive padding - horizontal
  EdgeInsets horizontalPadding(double pixels) {
    return EdgeInsets.symmetric(horizontal: width(pixels));
  }

  /// Responsive padding - vertical
  EdgeInsets verticalPadding(double pixels) {
    return EdgeInsets.symmetric(vertical: height(pixels));
  }

  /// Responsive padding - all sides
  EdgeInsets allPadding(double pixels) {
    return EdgeInsets.all(size(pixels));
  }

  /// Responsive padding - custom
  EdgeInsets padding({
    double? left,
    double? top,
    double? right,
    double? bottom,
    double? horizontal,
    double? vertical,
    double? all,
  }) {
    if (all != null) {
      return EdgeInsets.all(size(all));
    }
    
    if (horizontal != null || vertical != null) {
      return EdgeInsets.symmetric(
        horizontal: horizontal != null ? width(horizontal) : 0,
        vertical: vertical != null ? height(vertical) : 0,
      );
    }

    return EdgeInsets.only(
      left: left != null ? width(left) : 0,
      top: top != null ? height(top) : 0,
      right: right != null ? width(right) : 0,
      bottom: bottom != null ? height(bottom) : 0,
    );
  }

  /// Responsive border radius
  BorderRadius borderRadius(double pixels) {
    return BorderRadius.circular(size(pixels));
  }

  /// Responsive icon size
  double iconSize(double pixels) {
    return size(pixels).clamp(16.0, 48.0);
  }

  /// Responsive avatar size
  double avatarSize(double pixels) {
    return size(pixels).clamp(24.0, 80.0);
  }

  /// Responsive button height
  double buttonHeight(double pixels) {
    return height(pixels).clamp(40.0, 60.0);
  }

  /// Responsive card elevation
  double elevation(double value) {
    return value * averageScale;
  }

  /// Responsive spacing
  SizedBox spacingHeight(double pixels) {
    return SizedBox(height: height(pixels));
  }

  SizedBox spacingWidth(double pixels) {
    return SizedBox(width: width(pixels));
  }

  /// Get responsive text style
  TextStyle textStyle({
    required double fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
    double? letterSpacing,
  }) {
    return TextStyle(
      fontSize: this.fontSize(fontSize, min: 10, max: 40),
      fontWeight: fontWeight,
      color: color,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Responsive container constraints
  BoxConstraints containerConstraints({
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return BoxConstraints(
      minWidth: minWidth != null ? width(minWidth) : 0,
      maxWidth: maxWidth != null ? width(maxWidth) : double.infinity,
      minHeight: minHeight != null ? height(minHeight) : 0,
      maxHeight: maxHeight != null ? height(maxHeight) : double.infinity,
    );
  }

  /// Get device-specific multiplier for custom adjustments
  double get deviceMultiplier {
    if (isSmallPhone) return 0.85;
    if (isMediumPhone) return 0.95;
    if (isLargePhone) return 1.0;
    return 1.1; // Tablet
  }

  /// Responsive grid columns based on screen width
  int get gridColumns {
    if (screenWidth < 360) return 1;
    if (screenWidth < 600) return 2;
    if (screenWidth < 900) return 3;
    return 4;
  }

  /// Safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(context).padding;
}

/// Extension method for easy access to ResponsiveUtils
extension ResponsiveContext on BuildContext {
  ResponsiveUtils get responsive => ResponsiveUtils(this);
}

/// Predefined responsive breakpoints
class ResponsiveBreakpoints {
  static const double smallPhone = 360;
  static const double mediumPhone = 400;
  static const double largePhone = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
}

/// Helper function to get value based on screen size
T responsiveValue<T>(BuildContext context, {
  required T mobile,
  T? tablet,
  T? desktop,
}) {
  final width = MediaQuery.of(context).size.width;
  
  if (width >= ResponsiveBreakpoints.desktop && desktop != null) {
    return desktop;
  }
  
  if (width >= ResponsiveBreakpoints.tablet && tablet != null) {
    return tablet;
  }
  
  return mobile;
}
