import 'package:fluent_ui/fluent_ui.dart';
import 'package:window_manager/window_manager.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:system_theme/system_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:launch_at_startup/launch_at_startup.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:fluentui_icons/fluentui_icons.dart';
import 'package:path_drawing/path_drawing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'services/api.dart';
import 'services/icons.dart';
import 'screens/login.dart';
import 'screens/settings.dart';
import 'screens/logbook.dart';
import 'screens/about.dart';

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
    packageName: 'liubquanti.LibreLinkUpTray',
  );
  final prefs = await SharedPreferences.getInstance();
  final storedAutoStart = prefs.getBool('auto_start_enabled') ?? true;
  
  bool isEnabled = await launchAtStartup.isEnabled();
  if (storedAutoStart && !isEnabled) {
    await launchAtStartup.enable();
  } else if (!storedAutoStart && isEnabled) {
    await launchAtStartup.disable();
  }
  
  await windowManager.ensureInitialized();
  final w = prefs.getInt('window_w');
  final h = prefs.getInt('window_h');

  WindowOptions windowOptions = WindowOptions(
    size: (w != null && h != null) ? Size(w.toDouble(), h.toDouble()) : const Size(950, 665),
    center: true,
    backgroundColor: Colors.transparent,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
    minimumSize: const Size(450, 665),
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
    LibreLinkService.globalContext = context;

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
  Timer? _relativeTimeTimer;
  Map<String, dynamic>? _glucoseData;
  bool _isInitialized = false;
  bool _followSystemTheme = true;
  bool _isBlinking = false;
  bool _showAlert = false;
  bool _autoStartEnabled = false;
  bool _hasShownWindowOnStartup = false;
  bool _showSettings = false;
  bool _showLogbook = false;
  bool _showAbout = false;
  bool _isNoDataStale = false;
  bool _noDataBlinkVisible = true;
  
  bool _wasOutOfRange = false;
  int? _lastGlucoseValue;
  bool _notificationsEnabled = true;
  bool _isExiting = false;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      await _loadThemePreference();
      await _loadNotificationPreference();
      await _loadAutoStartPreference();
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

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedFollowSystem = prefs.getBool('tray_icon_follow_system');
    final storedThemeIsDark = prefs.getBool('tray_icon_dark_theme');

    final systemIsDark = WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;

    setState(() {
      _followSystemTheme = storedFollowSystem ?? true;
    });

    final shouldUseDarkTheme = _followSystemTheme
        ? systemIsDark
        : (storedThemeIsDark ?? systemIsDark);

    _iconService.setTheme(shouldUseDarkTheme);
    _iconService.clearCache();
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('tray_icon_dark_theme', _iconService.isDarkTheme);
    await prefs.setBool('tray_icon_follow_system', _followSystemTheme);
  }

  Future<void> _loadNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedNotifications = prefs.getBool('notifications_enabled');
    setState(() {
      _notificationsEnabled = storedNotifications ?? _notificationsEnabled;
    });
  }

  Future<void> _saveNotificationPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', _notificationsEnabled);
  }

  Future<void> _loadAutoStartPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final storedAutoStart = prefs.getBool('auto_start_enabled');
    if (storedAutoStart != null) {
      setState(() {
        _autoStartEnabled = storedAutoStart;
      });
    }
  }

  Future<void> _saveAutoStartPreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_start_enabled', _autoStartEnabled);
  }

  Future<void> _checkAutoStartStatus() async {
    try {
      final isEnabled = await launchAtStartup.isEnabled();
      setState(() {
        _autoStartEnabled = isEnabled;
      });
      await _saveAutoStartPreference();
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
      await _saveAutoStartPreference();
      
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

  void _toggleNotifications() async {
    setState(() {
      _notificationsEnabled = !_notificationsEnabled;
    });
    await _saveNotificationPreference();
    await _updateTrayContextMenu();
  }

  Map<String, double> _getAlarmLimits(Map<String, dynamic> connection) {
    final alarmRules = connection['alarmRules'] as Map<String, dynamic>?;
    final lowRule = alarmRules?['l'] as Map<String, dynamic>?;
    final highRule = alarmRules?['h'] as Map<String, dynamic>?;

    double? lowLimit = _readRuleThreshold(lowRule);
    double? highLimit = _readRuleThreshold(highRule);

    final patientDevice = connection['patientDevice'] as Map<String, dynamic>?;

    lowLimit ??= _asDouble(patientDevice?['ll']);
    highLimit ??= _asDouble(patientDevice?['hl']);

    return {
      'low': lowLimit ?? 70.0,
      'high': highLimit ?? 180.0,
    };
  }

  double? _readRuleThreshold(Map<String, dynamic>? rule) {
    if (rule == null) return null;
    if (rule['on'] == false) return null;

    final threshold = rule['th'];
    if (threshold is num) return threshold.toDouble();
    if (threshold is String) return double.tryParse(threshold);
    return null;
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    final str = value.toString();
    final parsed = DateTime.tryParse(str);
    if (parsed != null) return parsed;

    return _parseFallbackDate(str);
  }

  DateTime? _parseFallbackDate(String apiDate) {
    final regex = RegExp(r'(\d{1,2})/(\d{1,2})/(\d{4}) (\d{1,2}):(\d{2})(?::(\d{2}))? ([AP]M)');
    final match = regex.firstMatch(apiDate);

    if (match == null) return null;

    final month = int.parse(match.group(1)!);
    final day = int.parse(match.group(2)!);
    final year = int.parse(match.group(3)!);
    var hour = int.parse(match.group(4)!);
    final minute = int.parse(match.group(5)!);
    final second = match.group(6) != null ? int.parse(match.group(6)!) : 0;
    final ampm = match.group(7)!;

    if (ampm.toUpperCase() == 'PM' && hour != 12) hour += 12;
    if (ampm.toUpperCase() == 'AM' && hour == 12) hour = 0;

    return DateTime(year, month, day, hour, minute, second);
  }

  void _startThemeMonitoring() {
    _themeCheckTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _checkThemeChange();
    });
  }

  void _checkThemeChange() async {
    if (!_followSystemTheme) return;

    final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    final isDark = brightness == Brightness.dark;
    
    if (isDark != _iconService.isDarkTheme) {
      _iconService.setTheme(isDark);
      _iconService.clearCache();
      _updateTrayIcon();
      await _saveThemePreference();
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
          _startRelativeTimeTicker();
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

  void _startRelativeTimeTicker() {
    _relativeTimeTimer?.cancel();
    _relativeTimeTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_isLoggedIn) return;
      final isStale = _isLastUpdateOverdue();
      setState(() {
        _isNoDataStale = isStale;
        if (isStale) {
          _noDataBlinkVisible = !_noDataBlinkVisible;
        } else {
          _noDataBlinkVisible = true;
        }
      });
    });
  }

  bool _isLastUpdateOverdue() {
    if (_glucoseData == null) return false;

    final connection = _glucoseData!['connection'] as Map<String, dynamic>?;
    if (connection == null) return false;

    final alarmRules = connection['alarmRules'] as Map<String, dynamic>?;
    final ndRule = alarmRules?['nd'] as Map<String, dynamic>?;
    if (ndRule == null) return false;

    final intervalMinutes = _asInt(ndRule['i']);
    if (intervalMinutes == null || intervalMinutes <= 0) return false;

    final measurement = connection['glucoseMeasurement'] as Map<String, dynamic>?;
    final tsRaw = measurement?['Timestamp'] ?? measurement?['FactoryTimestamp'];
    final ts = _parseDateTime(tsRaw);
    if (ts == null) return false;

    final diffMinutes = DateTime.now().difference(ts).inMinutes;
    return diffMinutes >= intervalMinutes;
  }

  Future<void> _updateGlucoseData() async {
    try {
      final data = await _service.getGlucoseData();
      if (data != null) {
        setState(() {
          _glucoseData = data;
          _isNoDataStale = false;
          _noDataBlinkVisible = true;
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

    final connection = _glucoseData!['connection'] as Map<String, dynamic>;
    final glucoseMeasurement = connection['glucoseMeasurement'];
    if (glucoseMeasurement == null) return;

    final value = glucoseMeasurement['Value'] as int;
    final alarmLimits = _getAlarmLimits(connection);
    final lowLimit = alarmLimits['low']!;
    final highLimit = alarmLimits['high']!;
    final firstName = connection['firstName'] ?? 'User';

    final isCurrentlyOutOfRange = value < lowLimit || value > highLimit;

    if (_lastGlucoseValue == null) {
      _lastGlucoseValue = value;
      _wasOutOfRange = isCurrentlyOutOfRange;
      return;
    }

    if (_wasOutOfRange != isCurrentlyOutOfRange) {
      if (isCurrentlyOutOfRange) {
        await _showGlucoseAlert(value, lowLimit, highLimit, firstName, true);
      } else {
        await _showGlucoseAlert(value, lowLimit, highLimit, firstName, false);
      }
    } else if (isCurrentlyOutOfRange && _lastGlucoseValue != value) {
      final difference = (value - _lastGlucoseValue!).abs();
      if (difference >= 20) {
        await _showGlucoseAlert(value, lowLimit, highLimit, firstName, true);
      }
    }

    _lastGlucoseValue = value;
    _wasOutOfRange = isCurrentlyOutOfRange;
  }

  bool _isGlucoseOutOfRange() {
    if (_glucoseData == null) return false;

    final connection = _glucoseData!['connection'] as Map<String, dynamic>;
    final glucoseMeasurement = connection['glucoseMeasurement'];
    if (glucoseMeasurement == null) return false;

    final value = glucoseMeasurement['Value'] as int;
    final alarmLimits = _getAlarmLimits(connection);
    final lowLimit = alarmLimits['low']!;
    final highLimit = alarmLimits['high']!;

    return value < lowLimit || value > highLimit;
  }

  Future<void> _showGlucoseAlert(int value, double lowLimit, double highLimit, String firstName, bool isOutOfRange) async {
    String title;
    String body;

    if (isOutOfRange) {
      if (value < lowLimit) {
        title = 'Low glucose!';
        body = '$firstName: $value mg/dL (limit: ${lowLimit.toInt()}-${highLimit.toInt()})';
      } else {
        title = 'High glucose!';
        body = '$firstName: $value mg/dL (limit: ${lowLimit.toInt()}-${highLimit.toInt()})';
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
    if (_isExiting) return;

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
          MenuItem.separator(),
          MenuItem(label: "Toggle theme", onClick: (menuItem) => _toggleTheme()),
          MenuItem(label: _notificationsEnabled ? "Disable notifications" : "Enable notifications", onClick: (menuItem) => _toggleNotifications()),
          MenuItem(label: _autoStartEnabled ? "Disable auto-start" : "Enable auto-start", onClick: (menuItem) => _toggleAutoStart()),
          MenuItem.separator(),
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

  void _toggleTheme() async {
    _followSystemTheme = false;
    _iconService.setTheme(!_iconService.isDarkTheme);
    _iconService.clearCache();
    await _saveThemePreference();
    setState(() {});
    _updateTrayIcon();
  }

  void _showWindow() {
    windowManager.show();
    windowManager.focus();
  }

  Future<void> _exitApp() async {
    if (_isExiting) return;
    _isExiting = true;

    _updateTimer?.cancel();
    _themeCheckTimer?.cancel();
    _alertTimer?.cancel();
    _relativeTimeTimer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);

    await trayManager.destroy();
    await windowManager.setPreventClose(false);
    await windowManager.close();

    exit(0);
  }

  void _logout() async {
    try {
      await _service.logout();
      _updateTimer?.cancel();
      _alertTimer?.cancel();
      _relativeTimeTimer?.cancel();
      setState(() {
        _isLoggedIn = false;
        _glucoseData = null;
        _isBlinking = false;
        _showAlert = false;
        _showSettings = false;
        _showLogbook = false;
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
    _startRelativeTimeTicker();
    windowManager.hide();
  }

  @override
  void onTrayIconRightMouseDown() {
    trayManager.popUpContextMenu();
  }

  Widget _buildCustomTitleBar() {
    final theme = FluentTheme.of(context);

    Widget leading;
    if (_showSettings || _showLogbook || _showAbout) { // Додаємо _showAbout
      leading = Row(
        children: [
          IconButton(
            icon: const Icon(FluentSystemIcons.ic_fluent_arrow_left_regular, size: 16),
            onPressed: () {
              setState(() {
                if (_showAbout) {
                  _showAbout = false;
                  _showSettings = true; // Повертає на екран налаштувань
                } else {
                  _showSettings = false;
                  _showLogbook = false;
                }
              });
            },
            style: ButtonStyle(
              shape: WidgetStateProperty.all(const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
                side: BorderSide.none,
              )),
            ),
          ),
          const SizedBox(width: 2),
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
      );
    } else {
      leading = Row(
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
      );
    }

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
              child: Container(
                height: 32,
                width: double.infinity,
                padding: (_showSettings || _showLogbook || _showAbout)
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(left: 10),
                color: Colors.transparent,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leading,
                ),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              content: _showAbout
                  ? AboutScreen(
                      onBack: () {
                        setState(() {
                          _showAbout = false;
                          _showSettings = true; // Повертає на екран налаштувань
                        });
                      },
                    )
                  : _showLogbook
                      ? LogbookScreen(
                          onBack: () {
                            setState(() {
                              _showLogbook = false;
                            });
                          },
                          service: _service,
                        )
                      : _showSettings
                          ? SettingsScreen(
                              autoStartEnabled: _autoStartEnabled,
                              isDarkTheme: _iconService.isDarkTheme,
                              notificationsEnabled: _notificationsEnabled,
                              onToggleAutoStart: _toggleAutoStart,
                              onToggleTheme: _toggleTheme,
                              onToggleNotifications: _toggleNotifications,
                              onRefresh: _updateGlucoseData,
                              onLogout: _logout,
                              onShowAbout: () {
                                setState(() {
                                  _showAbout = true;
                                  _showSettings = false;
                                });
                              },
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
    final connection = _glucoseData!['connection'] as Map<String, dynamic>;
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
    final alarmLimits = _getAlarmLimits(connection);
    final lowLimit = alarmLimits['low']!;
    final highLimit = alarmLimits['high']!;

    Color glucoseColor = _getGlucoseColor(value, targetLow, targetHigh);

    Color valueColor = FluentTheme.of(context).brightness == Brightness.dark 
      ? Colors.white 
      : Colors.black;
    if (isHigh) valueColor = Colors.red.darker;
    if (isLow) valueColor = Colors.red.darker;

    Color trendColor = valueColor;
    final lastUpdateBaseColor = FluentTheme.of(context).brightness == Brightness.dark
      ? Colors.white
      : Colors.black;
    IconData? trendDisplayArrow;
    switch (trendArrow) {
      case 1: 
        trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_down_filled;
        break;
      case 2: 
        trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_down_left_filled;
        break;
      case 3: 
        trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_right_filled;
        break;
      case 4: 
        trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_up_right_filled;
        break;
      case 5: 
        trendDisplayArrow = FluentSystemIcons.ic_fluent_arrow_up_filled;
        break;
    }

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${connection['firstName']} ${connection['lastName']}',
                style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(SystemTheme.accentColor.accent),
                ),
                onPressed: () {
                  setState(() {
                    _showLogbook = true;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      FluentSystemIcons.ic_fluent_notebook_filled,
                      size: 19,
                      color: FluentTheme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF000000)
                        : const Color(0xFFFFFFFF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Logbook',
                      style: TextStyle(
                        color: FluentTheme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF000000)
                          : const Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              FilledButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStatePropertyAll(SystemTheme.accentColor.accent),
                ),
                onPressed: () {
                  setState(() {
                    _showSettings = true;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      FluentSystemIcons.ic_fluent_settings_filled,
                      size: 19,
                      color: FluentTheme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF000000)
                        : const Color(0xFFFFFFFF),
                    ),
                  ],
                ),
              ),
            ],
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
                        if (trendDisplayArrow != null) 
                        Transform(
                          alignment: Alignment.center,
                          transform: (trendDisplayArrow == FluentSystemIcons.ic_fluent_arrow_down_left_filled)
                            ? Matrix4.rotationY(math.pi)
                            : Matrix4.identity(),
                          child: Icon(
                            trendDisplayArrow,
                            color: trendColor,
                            size: 36,
                          ),
                        ),
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
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _isNoDataStale
                        ? (_noDataBlinkVisible ? Colors.red : lastUpdateBaseColor)
                        : lastUpdateBaseColor,
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
                    limitLow: lowLimit,      // додати
                    limitHigh: highLimit,    // додати
                  ),
                ),
              ],
            ),
          ),

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
  void onWindowMove() async {
  final position = await windowManager.getPosition();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('window_x', position.dx.toInt());
  await prefs.setInt('window_y', position.dy.toInt());
}

@override
void onWindowResize() async {
  final size = await windowManager.getSize();
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('window_w', size.width.toInt());
  await prefs.setInt('window_h', size.height.toInt());
}

  @override
  void dispose() {
    _updateTimer?.cancel();
    _themeCheckTimer?.cancel();
    _alertTimer?.cancel();
    _relativeTimeTimer?.cancel();
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }
}

class InteractiveGlucoseChart extends StatefulWidget {
  final List<dynamic> data;
  final double targetLow;
  final double targetHigh;
  final double limitLow;   // додати
  final double limitHigh;  // додати

  const InteractiveGlucoseChart({
    super.key,
    required this.data,
    required this.targetLow,
    required this.targetHigh,
    required this.limitLow,
    required this.limitHigh,
  });

  @override
  State<InteractiveGlucoseChart> createState() => _InteractiveGlucoseChartState();
}

class _ChartPoint {
  final double value;
  final DateTime timestamp;
  final bool isCurrent;

  _ChartPoint({required this.value, required this.timestamp, required this.isCurrent});
}

class _InteractiveGlucoseChartState extends State<InteractiveGlucoseChart> {
  Offset? _hoveredPoint;
  String? _hoveredValue;
  String? _hoveredTime;
  Size? _containerSize;
  List<_ChartPoint> _chartPoints = [];
  DateTime? _minTime;
  DateTime? _maxTime;

  @override
  Widget build(BuildContext context) {
    _chartPoints = _prepareChartPoints();
    if (_chartPoints.isEmpty) {
      _minTime = null;
      _maxTime = null;
      return const SizedBox();
    }

    final points = _chartPoints.map((p) => p.value).toList();
    final minCandidate = [
      points.reduce(math.min),
      widget.targetLow,
      widget.limitLow,
    ].reduce(math.min);

    final maxCandidate = [
      points.reduce(math.max),
      widget.targetHigh,
      widget.limitHigh,
    ].reduce(math.max);

    // Add margin so lines and points stay inside the viewport.
    double minValue = minCandidate - 20;
    double maxValue = maxCandidate + 20;

    if (maxValue - minValue < 10) {
      // Avoid zero height chart if limits are very close.
      minValue -= 5;
      maxValue += 5;
    }

    // Prevent negative scale from pushing chart off when values are low.
    if (minValue < 0) minValue = 0;

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(hours: 12));
    _minTime = windowStart;
    _maxTime = now;

    return LayoutBuilder(
      builder: (context, constraints) {
        _containerSize = Size(constraints.maxWidth, constraints.maxHeight);
        
        return Stack(
          children: [
            MouseRegion(
              onHover: (event) {
                _updateHoveredPoint(event.localPosition, minValue, maxValue);
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
                  timestamps: _chartPoints.map((p) => p.timestamp).toList(),
                  minTime: _minTime!,
                  maxTime: _maxTime!,
                  minValue: minValue,
                  maxValue: maxValue,
                  targetLow: widget.targetLow,
                  targetHigh: widget.targetHigh,
                  limitLow: widget.limitLow,     // додати
                  limitHigh: widget.limitHigh,   // додати
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

  void _updateHoveredPoint(Offset position, double minValue, double maxValue) {
    if (_chartPoints.isEmpty || _minTime == null || _maxTime == null) return;

    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    if (position.dx < 0 || position.dx > size.width) return;

    final totalMs = math.max(1, _maxTime!.difference(_minTime!).inMilliseconds);
    final ratio = (position.dx / size.width).clamp(0.0, 1.0);
    final hoverTime = _minTime!.add(Duration(milliseconds: (totalMs * ratio).round()));

    final nearestIndex = _findNearestIndex(hoverTime);
    final point = _chartPoints[nearestIndex];

    DateTime clampedTs = point.timestamp;
    if (clampedTs.isBefore(_minTime!)) clampedTs = _minTime!;
    if (clampedTs.isAfter(_maxTime!)) clampedTs = _maxTime!;

    final pointX = (clampedTs.difference(_minTime!).inMilliseconds / totalMs) * size.width;
    final pointY = size.height - ((point.value - minValue) / (maxValue - minValue)) * size.height;

    setState(() {
      _hoveredPoint = Offset(pointX, pointY);
      _hoveredValue = point.value.toInt().toString();
      _hoveredTime = _formatTimestamp(point.timestamp.toIso8601String());
    });
  }

  int _findNearestIndex(DateTime target) {
    int nearest = 0;
    int smallestDelta = (_chartPoints.first.timestamp.difference(target)).abs().inMilliseconds;

    for (int i = 1; i < _chartPoints.length; i++) {
      final delta = (_chartPoints[i].timestamp.difference(target)).abs().inMilliseconds;
      if (delta < smallestDelta) {
        smallestDelta = delta;
        nearest = i;
      }
    }

    return nearest;
  }

  List<_ChartPoint> _prepareChartPoints() {
    final now = DateTime.now();
    final result = <_ChartPoint>[];

    for (final item in widget.data) {
      final valueRaw = item['Value'];
      if (valueRaw is! num) continue;

      final timestampRaw = item['Timestamp'] ?? item['FactoryTimestamp'];
      final timestamp = _parseTimestamp(timestampRaw);
      if (timestamp == null) continue;

      final boundedTimestamp = timestamp.isAfter(now) ? now : timestamp;
      result.add(
        _ChartPoint(
          value: valueRaw.toDouble(),
          timestamp: boundedTimestamp,
          isCurrent: item['isCurrent'] == true,
        ),
      );
    }

    result.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return result;
  }

  DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;

    try {
      if (timestamp is DateTime) return timestamp;

      final tsString = timestamp.toString();
      DateTime? dateTime;

      try {
        dateTime = DateTime.parse(tsString);
      } catch (_) {
        dateTime = _parseFallback(tsString);
      }

      return dateTime;
    } catch (e) {
      print('Error parsing timestamp: $e');
      return null;
    }
  }

  DateTime? _parseFallback(String timestamp) {
    final parts = timestamp.split(' ');
    if (parts.length < 2) return null;

    final datePart = parts[0];
    final timePart = parts[1];
    final amPm = parts.length > 2 ? parts[2] : '';

    final dateComponents = datePart.split('/');
    if (dateComponents.length != 3) return null;

    final month = int.tryParse(dateComponents[0]);
    final day = int.tryParse(dateComponents[1]);
    final year = int.tryParse(dateComponents[2]);
    if (month == null || day == null || year == null) return null;

    final timeComponents = timePart.split(':');
    if (timeComponents.length < 2) return null;

    var hour = int.tryParse(timeComponents[0]);
    final minute = int.tryParse(timeComponents[1]);
    if (hour == null || minute == null) return null;

    if (amPm.toUpperCase() == 'PM' && hour != 12) {
      hour += 12;
    } else if (amPm.toUpperCase() == 'AM' && hour == 12) {
      hour = 0;
    }

    return DateTime(year, month, day, hour, minute);
  }

  String _formatTimestamp(String timestamp) {
    try {
      DateTime? dateTime;
      
      try {
        dateTime = DateTime.parse(timestamp);
      } catch (e) {
        dateTime = _parseFallback(timestamp);
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
  final List<DateTime> timestamps;
  final DateTime minTime;
  final DateTime maxTime;
  final double minValue;
  final double maxValue;
  final double targetLow;
  final double targetHigh;
  final double limitLow;   // додати
  final double limitHigh;  // додати
  final bool isDark;
  final Offset? hoveredPoint;

  GlucoseChartPainter({
    required this.points,
    required this.data,
    required this.timestamps,
    required this.minTime,
    required this.maxTime,
    required this.minValue,
    required this.maxValue,
    required this.targetLow,
    required this.targetHigh,
    required this.limitLow,
    required this.limitHigh,
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

    // Малюємо червоні лінії для ll та hl
    final limitLinePaint = Paint()
      ..color = Colors.orange.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final limitLowY = size.height - ((limitLow - minValue) / (maxValue - minValue)) * size.height;
    final limitHighY = size.height - ((limitHigh - minValue) / (maxValue - minValue)) * size.height;

    final limitLowPath = Path()
      ..moveTo(0, limitLowY)
      ..lineTo(size.width, limitLowY);
    final limitHighPath = Path()
      ..moveTo(0, limitHighY)
      ..lineTo(size.width, limitHighY);

    canvas.drawPath(
      dashPath(limitLowPath, dashArray: CircularIntervalList<double>(<double>[6, 4])),
      limitLinePaint,
    );
    canvas.drawPath(
      dashPath(limitHighPath, dashArray: CircularIntervalList<double>(<double>[6, 4])),
      limitLinePaint,
    );

    if (points.isEmpty) return;

    final totalMs = math.max(1, maxTime.difference(minTime).inMilliseconds);
    final positions = <Offset>[];

    for (int i = 0; i < points.length; i++) {
      var ts = timestamps[i];
      if (ts.isBefore(minTime)) ts = minTime;
      if (ts.isAfter(maxTime)) ts = maxTime;

      final timeOffset = ts.difference(minTime).inMilliseconds;
      final x = (timeOffset / totalMs) * size.width;
      final y = size.height - ((points[i] - minValue) / (maxValue - minValue)) * size.height;
      positions.add(Offset(x, y));
    }

    final path = Path();
    if (positions.isNotEmpty) {
      path.moveTo(positions.first.dx, positions.first.dy);
      for (int i = 1; i < positions.length; i++) {
        final prevTs = timestamps[i - 1];
        final currTs = timestamps[i];
        final gapMs = currTs.difference(prevTs).inMilliseconds.abs();
        const maxGapMs = 29.9 * 60 * 1000;

        if (gapMs > maxGapMs) {
          path.moveTo(positions[i].dx, positions[i].dy);
        } else {
          path.lineTo(positions[i].dx, positions[i].dy);
        }
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
    DateTime? parsed = DateTime.tryParse(apiDate);

    if (parsed == null) {
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

        parsed = DateTime(year, month, day, hour, minute, second);
      }
    }

    if (parsed == null) return apiDate;

    var diff = DateTime.now().difference(parsed);
    if (diff.isNegative) diff = Duration.zero;

    final seconds = diff.inSeconds;
    if (seconds < 60) {
      if (seconds <= 1) return 'just now';
      return '$seconds seconds ago';
    }

    final minutes = diff.inMinutes;
    if (minutes < 60) {
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }

    final hours = diff.inHours;
    return hours == 1 ? '1 hour ago' : '$hours hours ago';
  } catch (e) {
    print('Date parse error: $e');
  }
  return apiDate;
}
