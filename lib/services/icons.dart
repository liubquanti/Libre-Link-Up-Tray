import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

class SimpleIconService {
  static final SimpleIconService _instance = SimpleIconService._internal();
  factory SimpleIconService() => _instance;
  SimpleIconService._internal();

  bool _isDarkTheme = true;
  final Map<String, String> _iconCache = {};

  bool get isDarkTheme => _isDarkTheme;

  void setTheme(bool isDark) {
    _isDarkTheme = isDark;
  }

  Future<String> getGlucoseIconPath(int glucoseValue, int? trendArrow) async {
    final cacheKey = '${glucoseValue}_${trendArrow}_${_isDarkTheme ? 'dark' : 'light'}';
    
    if (_iconCache.containsKey(cacheKey)) {
      return _iconCache[cacheKey]!;
    }

    final themeFolder = _isDarkTheme ? 'white' : 'black';
    final assetPath = 'assets/tray/$themeFolder/${glucoseValue}.ico';
    
    try {
      await rootBundle.load(assetPath);
      _iconCache[cacheKey] = assetPath;
      return assetPath;
    } catch (e) {
      final generatedPath = await generateGlucoseIcon(glucoseValue, trendArrow);
      _iconCache[cacheKey] = generatedPath;
      return generatedPath;
    }
  }

  Future<String> generateGlucoseIcon(int glucoseValue, int? trendArrow) async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      final size = const Size(32, 32);

      final textColor = _isDarkTheme ? Colors.white : Colors.black;
      final backgroundColor = Colors.transparent;
      
      final backgroundPaint = Paint()
        ..color = backgroundColor
        ..style = PaintingStyle.fill;
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), backgroundPaint);

      double fontSize = 14;
      if (glucoseValue > 999) fontSize = 8;
      else if (glucoseValue > 99) fontSize = 10;
      else if (glucoseValue > 9) fontSize = 12;

      final textPainter = TextPainter(
        text: TextSpan(
          text: glucoseValue.toString(),
          style: TextStyle(
            color: textColor,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            fontFamily: 'Consolas',
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      
      final textOffset = Offset(
        (size.width - textPainter.width) / 2,
        (size.height - textPainter.height) / 2 - 3,
      );
      
      textPainter.paint(canvas, textOffset);

      if (trendArrow != null) {
        String arrowText = '';
        Color arrowColor = textColor;
        
        switch (trendArrow) {
          case 1: 
            arrowText = '🡑'; 
            arrowColor = Colors.red;
            break;
          case 2: 
            arrowText = '🡕'; 
            arrowColor = Colors.orange;
            break;
          case 3: 
            arrowText = '🡒'; 
            arrowColor = textColor;
            break;
          case 4: 
            arrowText = '🡖'; 
            arrowColor = Colors.blue;
            break;
          case 5: 
            arrowText = '🡓'; 
            arrowColor = Colors.purple;
            break;
        }
        
        if (arrowText.isNotEmpty) {
          final arrowPainter = TextPainter(
            text: TextSpan(
              text: arrowText,
              style: TextStyle(
                color: arrowColor,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          
          arrowPainter.layout();
          
          final arrowOffset = Offset(
            size.width - arrowPainter.width - 1,
            size.height - arrowPainter.height - 1,
          );
          
          arrowPainter.paint(canvas, arrowOffset);
        }
      }

      final picture = recorder.endRecording();
      final image = await picture.toImage(size.width.toInt(), size.height.toInt());
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData != null) {
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final iconFile = File(path.join(tempDir.path, 'glucose_${glucoseValue}_${timestamp}.png'));
        await iconFile.writeAsBytes(byteData.buffer.asUint8List());
        
        return iconFile.path;
      }
    } catch (e) {
      print('Error generating icon: $e');
    }
    
    return _isDarkTheme ? 'assets/tray/white/default.png' : 'assets/tray/black/default.png';
  }

  void clearCache() {
    _iconCache.clear();
  }
}