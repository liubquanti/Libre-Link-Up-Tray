import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_notifier/local_notifier.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'services/api.dart';
import 'services/icons.dart';
import 'screens/login.dart';
import 'screens/settings.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (defaultTargetPlatform.supportsAccentColor) {
    SystemTheme.fallbackColor = Colors.blue;
    await SystemTheme.accentColor.load();
  }
  
  await localNotifier.setup(
    appName: 'LibreLinkUpTray',
    shortcutPolicy: ShortcutPolicy.requireCreate,
  );
  
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  
  launchAtStartup.setup(
    appName: packageInfo.appName,
    appPath: Platform.resolvedExecutable,
    packageName: 'liubquanti.librelinkup.tray',
  );
  
  bool isEnabled = await launchAtStartup.isEnabled();
  if (!isEnabled) {
    await launchAtStartup.enable();
  }
  
  await windowManager.ensureInitialized();
  
  WindowOptions windowOptions = const WindowOptions(
    size: Size(950, 665),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: Size(450, 665),
  );
  
  windowManager.waitUntilReadyToShow(windowOptions, () async {
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
  Widget build(BuildContext context) {
    LibreLinkService.globalContext = context; // <-- додати

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
      title: 'LibreLinkUpTray',
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
      home: const MyHomePage(title: 'LibreLinkUpTray'),
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
  Timer? _alertTimer;
  Map<String, dynamic>? _glucoseData;
  bool _isInitialized = false;
  bool _isBlinking = false;
  bool _showAlert = false;
  bool _autoStartEnabled = false;
  bool _hasShownWindowOnStartup = false;
  bool _showSettings = false;
  
  bool _wasOutOfRange = false;
  int? _lastGlucoseValue;
  bool _notificationsEnabled = true;
  
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
      await _checkAutoStartStatus();
      setState(() {
        _isInitialized = true;
      });
      
      if (!_isLoggedIn && !_hasShownWindowOnStartup) {
        _hasShownWindowOnStartup = true;
        await windowManager.show();
        await windowManager.focus();
      } else if (_isLoggedIn) {
        print('Already logged in - keeping window hidden');
        await windowManager.hide();
      }
    } catch (e) {
      print('Initialization error: $e');
      setState(() {
        _isInitialized = true;
      });
      if (!_hasShownWindowOnStartup) {
        _hasShownWindowOnStartup = true;
        await windowManager.show();
        await windowManager.focus();
      }
    }
  }

  Future<void> _checkAutoStartStatus() async {
    try {
      final isEnabled = await launchAtStartup.isEnabled();
      setState(() {
        _autoStartEnabled = isEnabled;
      });
    } catch (e) {
      print('Error checking auto-start status: $e');
    }
  }

  Future<void> _toggleAutoStart() async {
    try {
      if (_autoStartEnabled) {
        await launchAtStartup.disable();
      } else {
        await launchAtStartup.enable();
      }
      await _checkAutoStartStatus();
      
      await _updateTrayContextMenu();
    } catch (e) {
      print('Error toggling auto-start: $e');
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('Error'),
          content: const Text('Failed to change auto-start settings'),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: InfoBarSeverity.error,
        );
      });
    }
  }

  void _toggleNotifications() {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
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
          print('Auto login successful - running in background');
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
        await _checkForNotifications();
        await _updateTrayIcon();
      }
    } catch (e) {
      print('Update glucose data error: $e');
    }
  }

  Future<void> _checkForNotifications() async {
    if (!_notificationsEnabled || _glucoseData == null) return;

    final connection = _glucoseData!['connection'];
    final glucoseMeasurement = connection['glucoseMeasurement'];
    if (glucoseMeasurement == null) return;

    final value = glucoseMeasurement['Value'] as int;
    final targetLow = connection['targetLow']?.toDouble() ?? 70.0;
    final targetHigh = connection['targetHigh']?.toDouble() ?? 180.0;
    final firstName = connection['firstName'] ?? 'User';

    final isCurrentlyOutOfRange = value < targetLow || value > targetHigh;

    if (_lastGlucoseValue == null) {
      _lastGlucoseValue = value;
      _wasOutOfRange = isCurrentlyOutOfRange;
      return;
    }

    if (_wasOutOfRange != isCurrentlyOutOfRange) {
      if (isCurrentlyOutOfRange) {
        await _showGlucoseAlert(value, targetLow, targetHigh, firstName, true);
      } else {
        await _showGlucoseAlert(value, targetLow, targetHigh, firstName, false);
      }
    } else if (isCurrentlyOutOfRange && _lastGlucoseValue != value) {
      final difference = (value - _lastGlucoseValue!).abs();
      if (difference >= 20) {
        await _showGlucoseAlert(value, targetLow, targetHigh, firstName, true);
      }
    }

    _lastGlucoseValue = value;
    _wasOutOfRange = isCurrentlyOutOfRange;
  }

  Future<void> _showGlucoseAlert(int value, double targetLow, double targetHigh, String firstName, bool isOutOfRange) async {
    String title;
    String body;
    
    if (isOutOfRange) {
      if (value < targetLow) {
        title = 'Low glucose!';
        body = '$firstName: $value mg/dL (target: ${targetLow.toInt()}-${targetHigh.toInt()})';
      } else {
        title = 'High glucose!';
        body = '$firstName: $value mg/dL (target: ${targetLow.toInt()}-${targetHigh.toInt()})';
      }
    } else {
      title = 'Glucose normal';
      body = '$firstName: $value mg/dL';
    }

    final notification = LocalNotification(
      title: title,
      body: body,
    );

    notification.onShow = () {
      print('Notification shown: $title');
    };

    notification.onClick = () {
      print('Notification clicked: $title');
      _showWindow();
    };

    notification.onClose = (closeReason) {
      print('Notification closed: $title - $closeReason');
    };

    await notification.show();
  }

  bool _isGlucoseOutOfRange() {
    if (_glucoseData == null) return false;
    
    final connection = _glucoseData!['connection'];
    final glucoseMeasurement = connection['glucoseMeasurement'];
    if (glucoseMeasurement == null) return false;
    
    final value = glucoseMeasurement['Value'] as int;
    final targetLow = connection['targetLow']?.toDouble() ?? 70.0;
    final targetHigh = connection['targetHigh']?.toDouble() ?? 180.0;
    
    return value < targetLow || value > targetHigh;
  }

  void _startBlinking() {
    if (_isBlinking) return;
    
    _isBlinking = true;
    _showAlert = true;
    
    _alertTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isGlucoseOutOfRange()) {
        _stopBlinking();
        return;
      }
      
      setState(() {
        _showAlert = !_showAlert;
      });
      
      if (_showAlert) {
        await trayManager.setIcon('assets/tray/alert.ico');
      } else {
        await _setNormalGlucoseIcon();
      }
    });
  }

  void _stopBlinking() {
    _alertTimer?.cancel();
    _alertTimer = null;
    _isBlinking = false;
    _showAlert = false;
    _updateTrayIcon();
  }

  Future<void> _setNormalGlucoseIcon() async {
    if (_glucoseData != null) {
      final glucoseMeasurement = _glucoseData!['connection']['glucoseMeasurement'];
      if (glucoseMeasurement != null) {
        final value = glucoseMeasurement['Value'] as int;
        final trendArrow = glucoseMeasurement['TrendArrow'] as int?;
        final iconPath = await _iconService.getGlucoseIconPath(value, trendArrow);
        await trayManager.setIcon(iconPath);
      }
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
            case 1: trendText = '🡓'; break;
            case 2: trendText = '🡖'; break;
            case 3: trendText = '🡒'; break;
            case 4: trendText = '🡕'; break;
            case 5: trendText = '🡑'; break;
          }
          
          await trayManager.setToolTip("$value mg/dL $trendText");
          
          if (_isGlucoseOutOfRange()) {
            if (!_isBlinking) {
              _startBlinking();
            }
          } else {
            if (_isBlinking) {
              _stopBlinking();
            } else {
              final iconPath = await _iconService.getGlucoseIconPath(value, trendArrow);
              await trayManager.setIcon(iconPath);
            }
          }
          
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

  Future<void> _updateTrayContextMenu() async {
    await trayManager.setContextMenu(
      Menu(
        items: [
          MenuItem(label: "Show app", onClick: (menuItem) => _showWindow()),
          MenuItem(label: "Refresh data", onClick: (menuItem) => _updateGlucoseData()),
          MenuItem(label: "Toggle theme", onClick: (menuItem) => _toggleTheme()),
          MenuItem(label: _notificationsEnabled ? "Disable notifications" : "Enable notifications", onClick: (menuItem) => _toggleNotifications()),
          MenuItem(label: _autoStartEnabled ? "Disable auto-start" : "Enable auto-start", onClick: (menuItem) => _toggleAutoStart()),
          MenuItem(label: "Logout", onClick: (menuItem) => _logout()),
          MenuItem(label: "Exit", onClick: (menuItem) => _exitApp()),
        ],
      ),
    );
  }

  Future<void> _initTray() async {
    try {
      await trayManager.setToolTip("LibreLinkUpTray");
      
      try {
        await trayManager.setIcon('assets/tray/load.ico');
      } catch (iconError) {
        print('Warning: Could not set initial tray icon: $iconError');
      }
      
      await _updateTrayContextMenu();
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
    _alertTimer?.cancel();
    trayManager.destroy();
    windowManager.destroy();
  }

  void _logout() async {
    try {
      await _service.logout();
      _updateTimer?.cancel();
      _alertTimer?.cancel();
      setState(() {
        _isLoggedIn = false;
        _glucoseData = null;
        _isBlinking = false;
        _showAlert = false;
        _showSettings = false;
        _wasOutOfRange = false;
        _lastGlucoseValue = null;
      });
      await trayManager.setIcon('assets/tray/load.ico');
      await trayManager.setToolTip("LibreLinkUpTray");
      
      _showWindow();
    } catch (e) {
      print('Logout error: $e');
    }
  }

  void _onLoginSuccess() {
    setState(() {
      _isLoggedIn = true;
    });
    _startPeriodicUpdate();
    windowManager.hide();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  Widget _buildCustomTitleBar() {
    final theme = FluentTheme.of(context);
    
    return Container(
      height: 35,
      decoration: BoxDecoration(
        color: theme.micaBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: theme.brightness == Brightness.dark 
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onPanStart: (details) {
                windowManager.startDragging();
              },
              onTapDown: (details) {
              },
              child: Container(
                height: 32,
                width: double.infinity,
                padding: const EdgeInsets.only(left: 10),
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.centerLeft,
                    child: Row(
                    children: [
                      Image.asset(
                      'assets/icon/icon.png',
                      width: 16,
                      height: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                      'LibreLinkUpTray',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: theme.brightness == Brightness.dark 
                          ? Colors.white
                          : Colors.black,
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isLoggedIn) ...[
                Container(
                  width: 45,
                  height: 32,
                  child: IconButton(
                    icon: Icon(
                      _showSettings ? FluentIcons.home : FluentIcons.settings,
                      size: 13,
                      color: FluentTheme.of(context).brightness == Brightness.dark
                        ? const Color(0xFFffffff)
                        : const Color(0xFF1b1b1b),
                    ),
                    onPressed: () {
                      setState(() {
                        _showSettings = !_showSettings;
                      });
                    },
                  ),
                ),
              ],
              WindowCaptionButton.minimize(
                brightness: theme.brightness,
                onPressed: () => windowManager.minimize(),
              ),
              WindowCaptionButton.close(
                brightness: theme.brightness,
                onPressed: () => windowManager.hide(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return NavigationView(
        content: Column(
          children: [
            _buildCustomTitleBar(),
            const Expanded(
              child: ScaffoldPage(
                content: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ProgressRing(),
                      SizedBox(height: 16),
                      Text('Initializing...'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!_isLoggedIn) {
      return Column(
        children: [
          _buildCustomTitleBar(),
          Expanded(
            child: LoginScreen(onLoginSuccess: _onLoginSuccess),
          ),
        ],
      );
    }

    return NavigationView(
      content: Column(
        children: [
          _buildCustomTitleBar(),
          Expanded(
            child: ScaffoldPage(
              padding: EdgeInsets.zero,
              content: _showSettings 
                  ? SettingsScreen(
                      autoStartEnabled: _autoStartEnabled,
                      isDarkTheme: _iconService.isDarkTheme,
                      notificationsEnabled: _notificationsEnabled,
                      onToggleAutoStart: _toggleAutoStart,
                      onToggleTheme: _toggleTheme,
                      onToggleNotifications: _toggleNotifications,
                      onRefresh: _updateGlucoseData,
                      onLogout: _logout,
                    )
                  : _glucoseData == null
                      ? const Center(child: ProgressRing())
                      : _buildGlucoseDisplay(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlucoseDisplay() {
    final connection = _glucoseData!['connection'];
    final glucoseMeasurement = connection['glucoseMeasurement'];
    final graphData = _glucoseData!['graphData'] as List?;
    final activeSensors = _glucoseData!['activeSensors'] as List?;
    
    if (glucoseMeasurement == null) {
      return const Center(
        child: Text(
          'No glucose data',
          style: TextStyle(fontSize: 18),
        ),
      );
    }

    final value = glucoseMeasurement['Value'];
    final timestamp = glucoseMeasurement['Timestamp'];
    final trendArrow = glucoseMeasurement['TrendArrow'];
    final isHigh = glucoseMeasurement['isHigh'];
    final isLow = glucoseMeasurement['isLow'];
    final targetLow = connection['targetLow']?.toDouble() ?? 70.0;
    final targetHigh = connection['targetHigh']?.toDouble() ?? 180.0;

    Color trendColor = Colors.grey;
    IconData? trendDisplayArrow;
    switch (trendArrow) {
      case 1: 
        trendDisplayArrow = FluentIcons.down;
        trendColor = Colors.red.darker;
        break;
      case 2: 
        trendDisplayArrow = FluentIcons.arrow_down_right8;
        trendColor = Colors.red.darker;
        break;
      case 3: 
        trendDisplayArrow = FluentIcons.forward;
        trendColor = SystemTheme.accentColor.accent;
        break;
      case 4: 
        trendDisplayArrow = FluentIcons.arrow_up_right;
        trendColor = Colors.red.darker;
        break;
      case 5: 
        trendDisplayArrow = FluentIcons.up;
        trendColor = Colors.red.darker;
        break;
    }

    Color glucoseColor = _getGlucoseColor(value, targetLow, targetHigh);

    Color valueColor = FluentTheme.of(context).brightness == Brightness.dark 
        ? Colors.white 
        : Colors.black;
    if (isHigh) valueColor = Colors.red.darker;
    if (isLow) valueColor = Colors.red.darker;

    List<dynamic> combinedData = [];
    if (graphData != null) {
      combinedData.addAll(graphData);
    }
    
    if (combinedData.isEmpty || 
        combinedData.last['Value'] != value || 
        combinedData.last['Timestamp'] != timestamp) {
      combinedData.add({
        'Value': value,
        'Timestamp': timestamp,
        'FactoryTimestamp': timestamp,
        'isCurrent': true,
      });
    }

    Map<String, dynamic>? currentSensor;
    if (activeSensors != null && activeSensors.isNotEmpty) {
      currentSensor = activeSensors.first;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26.0),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '${connection['firstName']} ${connection['lastName']}',
              style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: glucoseColor.withOpacity(0.2),
              border: Border.all(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1d1d1d)
                : const Color(0xFFe5e5e5),
              width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
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
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        const SizedBox(height: 8),
                        if (trendDisplayArrow != null) 
                        Icon(
                          trendDisplayArrow,
                          color: trendColor,
                          size: 24,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'mg/dL',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Last update: ${formatApiDate(timestamp)}',
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  height: 15, 
                  decoration: BoxDecoration(
                    color: glucoseColor,
                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          if (combinedData.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: FluentTheme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF2B2B2B)
                  : const Color(0xFFFBFBFB),
                border: Border.all(
                color: FluentTheme.of(context).brightness == Brightness.dark
                  ? const Color(0xFF1d1d1d)
                  : const Color(0xFFe5e5e5),
                width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 200,
                    child: InteractiveGlucoseChart(
                      data: combinedData,
                      targetLow: connection['targetLow']?.toDouble() ?? 70.0,
                      targetHigh: connection['targetHigh']?.toDouble() ?? 180.0,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 8),

          if (currentSensor != null) ...[
            _buildSensorWidget(currentSensor),
          ],
        ],
      ),
    );
  }

  Widget _buildSensorWidget(Map<String, dynamic> sensorData) {
    final sensor = sensorData['sensor'] as Map<String, dynamic>;
    final device = sensorData['device'] as Map<String, dynamic>?;
    
    final pt = sensor['pt'] as int? ?? 4;
    final sn = sensor['sn'] as String? ?? 'Unknown';
    final activationTimestamp = sensor['a'] as int?;
    final isActive = device?['s'] as bool? ?? true;
    
    String sensorImage;
    String sensorName;
    switch (pt) {
      case 3:
        sensorImage = 'assets/sensors/sensor2.png';
        sensorName = 'Libre 2 Sensor';
        break;
      case 4:
        sensorImage = 'assets/sensors/sensor3.png';
        sensorName = 'Libre 3 Sensor';
        break;
      default:
        sensorImage = 'assets/sensors/sensor2.png';
        sensorName = 'Libre Sensor';
    }
    
    String activationDate = 'Unknown';
    int daysSinceActivation = 0;
    if (activationTimestamp != null) {
      final activationDateTime = DateTime.fromMillisecondsSinceEpoch(activationTimestamp * 1000);
      final now = DateTime.now();
      daysSinceActivation = now.difference(activationDateTime).inDays;
      activationDate = '${activationDateTime.day.toString().padLeft(2, '0')}.${activationDateTime.month.toString().padLeft(2, '0')}.${activationDateTime.year} ${activationDateTime.hour.toString().padLeft(2, '0')}:${activationDateTime.minute.toString().padLeft(2, '0')}';
    }
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: FluentTheme.of(context).brightness == Brightness.dark
          ? const Color(0xFF2B2B2B)
          : const Color(0xFFFBFBFB),
        border: Border.all(
        color: FluentTheme.of(context).brightness == Brightness.dark
          ? const Color(0xFF1d1d1d)
          : const Color(0xFFe5e5e5),
        width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Image.asset(
                sensorImage,
                height: 80,
                width: 80,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: isActive ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          sensorName,
                          style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sn,
                      style: const TextStyle(
                      fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activationDate,
                      style: const TextStyle(
                      fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
            LayoutBuilder(
            builder: (context, constraints) {
              return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(14, (index) {
                final isActive = index < 14 - daysSinceActivation;
                return Container(
                width: (constraints.maxWidth - 13 * 5) / 14,
                decoration: BoxDecoration(
                  color: isActive 
                  ? SystemTheme.accentColor.accent
                  : FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF1d1d1d)
                    : const Color(0xFFe5e5e5),
                  borderRadius: BorderRadius.circular(10),
                ),
                height: 10,
                );
              }),
              );
            },
            ),
        ],
      ),
    );
  }

  Color _getGlucoseColor(int value, double targetLow, double targetHigh) {
    const int LOW = 70;
    const int HIGH = 240;
    
    if (value < LOW) {
      return Colors.red;
    }
    
    if (value > HIGH) {
      return Colors.orange;
    }
    
    if ((value < targetLow && value >= LOW) || (value > targetHigh && value <= HIGH)) {
      return Colors.yellow;
    }
    
    return Colors.green;
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    _themeCheckTimer?.cancel();
    _alertTimer?.cancel();
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
                  data: widget.data,
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
                      color: SystemTheme.accentColor.accent,
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
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_hoveredValue mg/dL',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                     'Unknown';
    
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
  final List<dynamic> data;
  final double minValue;
  final double maxValue;
  final double targetLow;
  final double targetHigh;
  final bool isDark;
  final Offset? hoveredPoint;

  GlucoseChartPainter({
    required this.points,
    required this.data,
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
      ..color = SystemTheme.accentColor.accent.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final targetLowY = size.height - ((targetLow - minValue) / (maxValue - minValue)) * size.height;
    final targetHighY = size.height - ((targetHigh - minValue) / (maxValue - minValue)) * size.height;

    canvas.drawRect(
      Rect.fromLTRB(0, targetHighY, size.width, targetLowY),
      targetRange,
    );

    final targetLinePaint = Paint()
      ..color = SystemTheme.accentColor.accent
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

    paint.color = isDark ? const Color(0xFFFBFBFB) : const Color(0xFF2B2B2B);
    canvas.drawPath(path, paint);

    for (int i = 0; i < positions.length; i++) {
      final value = points[i];
      final isCurrent = data.length > i && data[i]['isCurrent'] == true;
      
      Color pointColor;
      
      if (value < targetLow) {
        pointColor = Colors.red.darker;
      } else if (value > targetHigh) {
        pointColor = Colors.red.darker;
      } else {
        pointColor = SystemTheme.accentColor.accent;
      }

      pointPaint.color = pointColor;
      
      final pointRadius = isCurrent ? 5.0 : 3.0;
      canvas.drawCircle(positions[i], pointRadius, pointPaint);
      
      if (isCurrent) {
        final ringPaint = Paint()
          ..color = pointColor.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(positions[i], 8, ringPaint);
      }
    }

    if (hoveredPoint != null) {
      final hoverPaint = Paint()
        ..color = (isDark ? const Color(0xFFFBFBFB) : const Color(0xFF2B2B2B)).withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(hoveredPoint!, 6, hoverPaint);
      
      final hoverLinePaint = Paint()
        ..color = (isDark ? const Color(0xFFFBFBFB) : const Color(0xFF2B2B2B)).withOpacity(0.5)
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

String formatApiDate(String apiDate) {
  try {
    final regex = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2}):(\d{2}) ([AP]M)');
    final match = regex.firstMatch(apiDate);
    if (match != null) {
      final month = int.parse(match.group(1)!);
      final day = int.parse(match.group(2)!);
      final year = int.parse(match.group(3)!);
      var hour = int.parse(match.group(4)!);
      final minute = int.parse(match.group(5)!);
      final second = int.parse(match.group(6)!);
      final ampm = match.group(7)!;

      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      final dt = DateTime(year, month, day, hour, minute, second);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
  } catch (e) {
    print('Date parse error: $e');
  }
  return apiDate;
}
