import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:math' as math;
import 'services/api.dart';
import 'services/icons.dart';
import 'screens/login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configure system theme
  if (defaultTargetPlatform.supportsAccentColor) {
    SystemTheme.fallbackColor = Colors.blue;
    await SystemTheme.accentColor.load();
  }
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 600),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.normal,
    minimumSize: Size(450, 600),
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });
  
  windowManager.setPreventClose(true);
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    // Listen for system theme changes
    SystemTheme.onChange.listen((event) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    // Convert system accent color to FluentUI AccentColor
    final systemAccent = AccentColor.swatch({
      'darkest': SystemTheme.accentColor.darkest,
      'darker': SystemTheme.accentColor.darker,
      'dark': SystemTheme.accentColor.dark,
      'normal': SystemTheme.accentColor.accent,
      'light': SystemTheme.accentColor.light,
      'lighter': SystemTheme.accentColor.lighter,
      'lightest': SystemTheme.accentColor.lightest,
    });

    return FluentApp(
      title: 'LibreLink Up Tray',
      theme: FluentThemeData(
        brightness: Brightness.light,
        accentColor: systemAccent,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      darkTheme: FluentThemeData(
        brightness: Brightness.dark,
        accentColor: systemAccent,
        visualDensity: VisualDensity.standard,
        focusTheme: FocusThemeData(
          glowFactor: is10footScreen(context) ? 2.0 : 0.0,
        ),
      ),
      home: const MyHomePage(title: 'LibreLink Up Tray'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
  
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>
    with WindowListener, TrayListener {
  final LibreLinkService _service = LibreLinkService();
  final SimpleIconService _iconService = SimpleIconService();
  bool _isLoggedIn = false;
  Timer? _updateTimer;
  Timer? _themeCheckTimer;
  Map<String, dynamic>? _glucoseData;
  bool _isInitialized = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _initTray();
      windowManager.addListener(this);
      await _checkLoginStatus();
      _startThemeMonitoring();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  void _startThemeMonitoring() {
    _themeCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkThemeChange();
    });
  }

  void _checkThemeChange() {
    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    if (isDark != _iconService.isDarkTheme) {
      _iconService.setTheme(isDark);
      _iconService.clearCache();
      _updateTrayIcon();
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      final success = await _service.loadSavedCredentials();
      if (success) {
        final connections = await _service.getConnections();
        if (connections != null) {
          setState(() {
            _isLoggedIn = true;
          });
          _startPeriodicUpdate();
        }
      }
    } catch (e) {
      print('Check login status error: $e');
    }
  }

  void _startPeriodicUpdate() {
    _updateGlucoseData();
    _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateGlucoseData();
    });
  }

  Future<void> _updateGlucoseData() async {
    try {
      final data = await _service.getGlucoseData();
      if (data != null) {
        setState(() {
          _glucoseData = data;
        });
        await _updateTrayIcon();
      }
    } catch (e) {
      print('Update glucose data error: $e');
    }
  }

  Future<void> _updateTrayIcon() async {
    try {
      if (_glucoseData != null) {
        final glucoseMeasurement = _glucoseData!['connection']['glucoseMeasurement'];
        if (glucoseMeasurement != null) {
          final value = glucoseMeasurement['Value'] as int;
          final trendArrow = glucoseMeasurement['TrendArrow'] as int?;
          
          String trendText = '';
          switch (trendArrow) {
            case 1: trendText = '↑↑'; break;
            case 2: trendText = '↑'; break;
            case 3: trendText = '→'; break;
            case 4: trendText = '↓'; break;
            case 5: trendText = '↓↓'; break;
          }
          
          final iconPath = await _iconService.getGlucoseIconPath(value, trendArrow);
          await trayManager.setIcon(iconPath);
          await trayManager.setToolTip("Глюкоза: $value mg/dL $trendText");
          
          print('Updated tray icon with glucose: $value, trend: $trendText, theme: ${_iconService.isDarkTheme ? 'dark' : 'light'}');
        }
      }
    } catch (e) {
      print('Update tray icon error: $e');
    }
  }

  @override
  void onWindowClose() async {
    windowManager.hide();
  }

  @override
  void onTrayIconMouseDown() {
    _showWindow();
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setToolTip("LibreLink Up Tray");
      
      try {
        final iconPath = await _iconService.getGlucoseIconPath(100, 3);
        await trayManager.setIcon(iconPath);
      } catch (iconError) {
        print('Warning: Could not set initial tray icon: $iconError');
      }
      
      await trayManager.setContextMenu(
        Menu(
          items: [
            MenuItem(label: "Показати додаток", onClick: (menuItem) => _showWindow()),
            MenuItem(label: "Оновити дані", onClick: (menuItem) => _updateGlucoseData()),
            MenuItem(label: "Перемкнути тему", onClick: (menuItem) => _toggleTheme()),
            MenuItem(label: "Вийти з акаунта", onClick: (menuItem) => _logout()),
            MenuItem(label: "Закрити", onClick: (menuItem) => _exitApp()),
          ],
        ),
      );
      trayManager.addListener(this);
    } catch (e) {
      print('Error initializing tray: $e');
    }
  }

  void _toggleTheme() {
    _iconService.setTheme(!_iconService.isDarkTheme);
    _iconService.clearCache();
    _updateTrayIcon();
  }

  void _showWindow() {
    windowManager.show();
    windowManager.focus();
  }

  void _exitApp() {
    _updateTimer?.cancel();
    _themeCheckTimer?.cancel();
    trayManager.destroy();
    windowManager.destroy();
  }

  void _logout() async {
    try {
      await _service.logout();
      _updateTimer?.cancel();
      setState(() {
        _isLoggedIn = false;
        _glucoseData = null;
      });
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
    _startPeriodicUpdate();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const NavigationView(
        content: ScaffoldPage(
          content: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ProgressRing(),
                SizedBox(height: 16),
                Text('Ініціалізація...'),
              ],
            ),
          ),
        ),
      );
    }

    if (!_isLoggedIn) {
      return LoginScreen(onLoginSuccess: _onLoginSuccess);
    }

    return NavigationView(
      appBar: NavigationAppBar(
        automaticallyImplyLeading: false,
        actions: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                icon: Icon(_iconService.isDarkTheme ? FluentIcons.color_solid : FluentIcons.brightness),
                onPressed: _toggleTheme,
              ),
            ),
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                icon: const Icon(FluentIcons.refresh),
                onPressed: _updateGlucoseData,
              ),
            ),
            SizedBox(
              height: 40,
              width: 40,
              child: IconButton(
                icon: const Icon(FluentIcons.sign_out),
                onPressed: _logout,
              ),
            ),
          ],
        ),
      ),
      content: ScaffoldPage(
        padding: EdgeInsets.zero,
        content: _glucoseData == null
            ? const Center(child: ProgressRing())
            : _buildGlucoseDisplay(),
      ),
    );
  }

  Widget _buildGlucoseDisplay() {
    final connection = _glucoseData!['connection'];
    final glucoseMeasurement = connection['glucoseMeasurement'];
    final graphData = _glucoseData!['graphData'] as List?;
    
    if (glucoseMeasurement == null) {
      return const Center(
        child: Text(
          'Немає даних про глюкозу',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final value = glucoseMeasurement['Value'];
    final timestamp = glucoseMeasurement['Timestamp'];
    final trendArrow = glucoseMeasurement['TrendArrow'];
    final isHigh = glucoseMeasurement['isHigh'];
    final isLow = glucoseMeasurement['isLow'];

    Color trendColor = Colors.grey;
    IconData? trendDisplayArrow;
    switch (trendArrow) {
      case 1: 
        trendDisplayArrow = FluentIcons.down;
        trendColor = Colors.red;
        break;
      case 2: 
        trendDisplayArrow = FluentIcons.arrow_down_right8;
        trendColor = Colors.orange;
        break;
      case 3: 
        trendDisplayArrow = FluentIcons.forward;
        trendColor = Colors.blue;
        break;
      case 4: 
        trendDisplayArrow = FluentIcons.arrow_up_right;
        trendColor = Colors.orange;
        break;
      case 5: 
        trendDisplayArrow = FluentIcons.up;
        trendColor = Colors.red;
        break;
    }

    Color valueColor = FluentTheme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black;
    if (isHigh) valueColor = Colors.red;
    if (isLow) valueColor = Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(
            '${connection['firstName']} ${connection['lastName']}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).brightness == Brightness.dark
                  ? Colors.grey[160]
                  : Colors.grey[20],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: valueColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      children: [
                        const Text(
                          'mg/dL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (trendDisplayArrow != null) 
                          Icon(
                            trendDisplayArrow,
                            color: trendColor,
                            size: 24,
                          ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Останнє оновлення: $timestamp',
                  style: const TextStyle(fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          if (graphData != null && graphData.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FluentTheme.of(context).brightness == Brightness.dark
                    ? Colors.grey[160]
                    : Colors.grey[20],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    child: InteractiveGlucoseChart(
                      data: graphData,
                      targetLow: connection['targetLow']?.toDouble() ?? 70.0,
                      targetHigh: connection['targetHigh']?.toDouble() ?? 180.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _themeCheckTimer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }
}

class InteractiveGlucoseChart extends StatefulWidget {
  final List<dynamic> data;
  final double targetLow;
  final double targetHigh;

  const InteractiveGlucoseChart({
    super.key,
    required this.data,
    required this.targetLow,
    required this.targetHigh,
  });

  @override
  State<InteractiveGlucoseChart> createState() => _InteractiveGlucoseChartState();
}

class _InteractiveGlucoseChartState extends State<InteractiveGlucoseChart> {
  Offset? _hoveredPoint;
  String? _hoveredValue;
  String? _hoveredTime;
  Size? _containerSize;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) return const SizedBox();

    final points = widget.data.map((item) {
      final value = (item['Value'] as num).toDouble();
      return value;
    }).toList();

    final minValue = math.min(points.reduce(math.min) - 20, widget.targetLow - 20);
    final maxValue = math.max(points.reduce(math.max) + 20, widget.targetHigh + 20);

    return LayoutBuilder(
      builder: (context, constraints) {
        _containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            MouseRegion(
              onHover: (event) {
                _updateHoveredPoint(event.localPosition, points, minValue, maxValue);
              },
              onExit: (event) {
                setState(() {
                  _hoveredPoint = null;
                  _hoveredValue = null;
                  _hoveredTime = null;
                });
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: GlucoseChartPainter(
                  points: points,
                  minValue: minValue,
                  maxValue: maxValue,
                  targetLow: widget.targetLow,
                  targetHigh: widget.targetHigh,
                  isDark: FluentTheme.of(context).brightness == Brightness.dark,
                  hoveredPoint: _hoveredPoint,
                ),
              ),
            ),
            
            if (_hoveredPoint != null && _hoveredValue != null && _hoveredTime != null && _containerSize != null)
              Positioned(
                left: _calculateTooltipLeft(),
                top: _calculateTooltipTop(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: FluentTheme.of(context).brightness == Brightness.dark
                        ? Colors.grey[180]
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: FluentTheme.of(context).brightness == Brightness.dark
                          ? Colors.grey[120]
                          : Colors.grey[80],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$_hoveredValue mg/dL',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _hoveredTime!,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[100],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  double _calculateTooltipLeft() {
    const tooltipWidth = 90.0;
    const margin = 10.0;
    
    if (_hoveredPoint!.dx + tooltipWidth + margin > _containerSize!.width) {
      return _hoveredPoint!.dx - tooltipWidth - margin;
    } else {
      return _hoveredPoint!.dx + margin;
    }
  }

  double _calculateTooltipTop() {
    const tooltipHeight = 50.0;
    const margin = 10.0;
    
    if (_hoveredPoint!.dy - tooltipHeight - margin < 0) {
      return _hoveredPoint!.dy + margin;
    } else {
      return _hoveredPoint!.dy - tooltipHeight - margin;
    }
  }

  void _updateHoveredPoint(Offset position, List<double> points, double minValue, double maxValue) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;
    
    if (position.dx < 0 || position.dx > size.width) return;
    
    final stepX = size.width / (points.length - 1);
    final pointIndex = (position.dx / stepX).round().clamp(0, points.length - 1);
    
    final x = pointIndex * stepX;
    final y = size.height - ((points[pointIndex] - minValue) / (maxValue - minValue)) * size.height;
    
    final dataItem = widget.data[pointIndex];
    final value = points[pointIndex].toInt();
    final timestamp = dataItem['Timestamp'] as String? ?? 
                     dataItem['FactoryTimestamp'] as String? ?? 
                     'Невідомо';
    
    setState(() {
      _hoveredPoint = Offset(x, y);
      _hoveredValue = value.toString();
      _hoveredTime = _formatTimestamp(timestamp);
    });
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime? dateTime;
      
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        final parts = timestamp.split(' ');
        if (parts.length >= 2) {
          final datePart = parts[0];
          final timePart = parts[1];
          final amPm = parts.length > 2 ? parts[2] : '';
          
          final dateComponents = datePart.split('/');
          if (dateComponents.length == 3) {
            final month = int.parse(dateComponents[0]);
            final day = int.parse(dateComponents[1]);
            final year = int.parse(dateComponents[2]);
            
            final timeComponents = timePart.split(':');
            if (timeComponents.length >= 2) {
              var hour = int.parse(timeComponents[0]);
              final minute = int.parse(timeComponents[1]);
              
              if (amPm.toUpperCase() == 'PM' && hour != 12) {
                hour += 12;
              } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
                hour = 0;
              }
              
              dateTime = DateTime(year, month, day, hour, minute);
            }
          }
        }
      }
      
      if (dateTime != null) {
        final hour = dateTime.hour.toString().padLeft(2, '0');
        final minute = dateTime.minute.toString().padLeft(2, '0');
        final day = dateTime.day.toString().padLeft(2, '0');
        final month = dateTime.month.toString().padLeft(2, '0');
        
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final measurementDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
        
        if (measurementDate.isAtSameMomentAs(today)) {
          return '$hour:$minute';
        } else {
          return '$day.$month $hour:$minute';
        }
      }
    } catch (e) {
      print('Error parsing timestamp: $e');
    }
    
    return timestamp;
  }
}

class GlucoseChartPainter extends CustomPainter {
  final List<double> points;
  final double minValue;
  final double maxValue;
  final double targetLow;
  final double targetHigh;
  final bool isDark;
  final Offset? hoveredPoint;

  GlucoseChartPainter({
    required this.points,
    required this.minValue,
    required this.maxValue,
    required this.targetLow,
    required this.targetHigh,
    required this.isDark,
    this.hoveredPoint,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final pointPaint = Paint()
      ..style = PaintingStyle.fill;

    final targetRange = Paint()
      ..color = Colors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final targetLowY = size.height - ((targetLow - minValue) / (maxValue - minValue)) * size.height;
    final targetHighY = size.height - ((targetHigh - minValue) / (maxValue - minValue)) * size.height;

    canvas.drawRect(
      Rect.fromLTRB(0, targetHighY, size.width, targetLowY),
      targetRange,
    );

    final targetLinePaint = Paint()
      ..color = Colors.green.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawLine(Offset(0, targetLowY), Offset(size.width, targetLowY), targetLinePaint);
    canvas.drawLine(Offset(0, targetHighY), Offset(size.width, targetHighY), targetLinePaint);

    if (points.isEmpty) return;

    final stepX = size.width / (points.length - 1);
    final positions = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i] - minValue) / (maxValue - minValue)) * size.height;
      positions.add(Offset(x, y));
    }

    final path = Path();
    if (positions.isNotEmpty) {
      path.moveTo(positions.first.dx, positions.first.dy);
      for (int i = 1; i < positions.length; i++) {
        path.lineTo(positions[i].dx, positions[i].dy);
      }
    }

    paint.color = isDark ? Colors.white : Colors.blue;
    canvas.drawPath(path, paint);

    for (int i = 0; i < positions.length; i++) {
      final value = points[i];
      Color pointColor;
      
      if (value < targetLow) {
        pointColor = Colors.red;
      } else if (value > targetHigh) {
        pointColor = Colors.red;
      } else {
        pointColor = Colors.green;
      }

      pointPaint.color = pointColor;
      canvas.drawCircle(positions[i], 3, pointPaint);
    }

    if (hoveredPoint != null) {
      final hoverPaint = Paint()
        ..color = (isDark ? Colors.white : Colors.blue).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(hoveredPoint!, 6, hoverPaint);
      
      final hoverLinePaint = Paint()
        ..color = (isDark ? Colors.white : Colors.blue).withOpacity(0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      
      canvas.drawLine(
        Offset(hoveredPoint!.dx, 0),
        Offset(hoveredPoint!.dx, size.height),
        hoverLinePaint,
      );
    }

    final gridPaint = Paint()
      ..color = (isDark ? Colors.white : Colors.grey).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 5; i++) {
      final y = (size.height / 5) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    for (int i = 0; i <= 6; i++) {
      final x = (size.width / 6) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
