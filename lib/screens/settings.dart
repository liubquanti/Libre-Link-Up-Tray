import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

class SettingsScreen extends StatelessWidget {
  static const String trayIconColorModeSystem = 'system';
  static const String trayIconColorModeBlack = 'black';
  static const String trayIconColorModeWhite = 'white';

  final bool autoStartEnabled;
  final String trayIconColorMode;
  final bool notificationsEnabled;
  final bool showChartPoints;
  final bool showChartGridValues;
  final VoidCallback onToggleAutoStart;
  final ValueChanged<String?> onTrayIconColorModeChanged;
  final VoidCallback onToggleNotifications;
  final VoidCallback onToggleChartPoints;
  final VoidCallback onToggleChartGridValues;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onShowAbout;

  const SettingsScreen({
    super.key,
    required this.autoStartEnabled,
    required this.trayIconColorMode,
    required this.notificationsEnabled,
    required this.showChartPoints,
    required this.showChartGridValues,
    required this.onToggleAutoStart,
    required this.onTrayIconColorModeChanged,
    required this.onToggleNotifications,
    required this.onToggleChartPoints,
    required this.onToggleChartGridValues,
    required this.onRefresh,
    required this.onLogout,
    required this.onShowAbout,
  });

  String _modeLabel(String mode) {
    switch (mode) {
      case trayIconColorModeBlack:
        return 'Black';
      case trayIconColorModeWhite:
        return 'White';
      case trayIconColorModeSystem:
      default:
        return 'System';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: 18),
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
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
            child: Row(
              children: [
                Icon(
                  FluentSystemIcons.ic_fluent_play_regular,
                  size: 20,
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFffffff)
                    : const Color(0xFF1b1b1b),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-start',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Start the app with the system',
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  checked: autoStartEnabled,
                  onChanged: (value) => onToggleAutoStart(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 5),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
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
            child: Row(
              children: [
                Icon(
                  FluentSystemIcons.ic_fluent_alert_regular,
                  size: 20,
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFffffff)
                    : const Color(0xFF1b1b1b),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push notifications',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Notifications for glucose changes',
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  checked: notificationsEnabled,
                  onChanged: (value) => onToggleNotifications(),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 5),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
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
            child: Row(
              children: [
                Icon(
                  FluentSystemIcons.ic_fluent_color_regular,
                  size: 20,
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFffffff)
                    : const Color(0xFF1b1b1b),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Tray icon color',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Color of glucose value in tray',
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 130,
                  child: ComboBox<String>(
                    value: trayIconColorMode,
                    isExpanded: true,
                    items: [
                      trayIconColorModeSystem,
                      trayIconColorModeBlack,
                      trayIconColorModeWhite,
                    ]
                        .map(
                          (mode) => ComboBoxItem<String>(
                            value: mode,
                            child: Text(_modeLabel(mode)),
                          ),
                        )
                        .toList(),
                    onChanged: onTrayIconColorModeChanged,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
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
            child: Row(
              children: [
                Icon(
                  FluentSystemIcons.ic_fluent_data_histogram_regular,
                  size: 20,
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFffffff)
                    : const Color(0xFF1b1b1b),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chart points',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Show points on glucose graph',
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  checked: showChartPoints,
                  onChanged: (value) => onToggleChartPoints(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(15),
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
            child: Row(
              children: [
                Icon(
                  FluentSystemIcons.ic_fluent_grid_regular,
                  size: 20,
                  color: FluentTheme.of(context).brightness == Brightness.dark
                    ? const Color(0xFFffffff)
                    : const Color(0xFF1b1b1b),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chart values',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Show values on grid lines',
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  checked: showChartGridValues,
                  onChanged: (value) => onToggleChartGridValues(),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),
          
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onShowAbout,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
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
              child: Row(
                children: [
                  Icon(
                    FluentSystemIcons.ic_fluent_info_regular,
                    size: 20,
                    color: FluentTheme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFffffff)
                      : const Color(0xFF1b1b1b),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'App information',
                          style: theme.typography.body?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        Text(
                          'Version and developer',
                          style: theme.typography.caption,
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    FluentSystemIcons.ic_fluent_chevron_right_regular,
                    size: 16,
                    color: FluentTheme.of(context).brightness == Brightness.dark
                      ? const Color(0xFFffffff)
                      : const Color(0xFF1b1b1b),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 5),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
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
                SizedBox(
                  width: double.infinity,
                  height: 31,
                  child: Button(
                    onPressed: onRefresh,
                    child: const Text('Refresh data'),
                  ),
                ),
                
                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  height: 31,
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red.darker),
                    ),
                    onPressed: onLogout,
                    child: const Text('Logout', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}