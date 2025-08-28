import 'package:fluent_ui/fluent_ui.dart';
import 'package:fluentui_icons/fluentui_icons.dart';

class SettingsScreen extends StatelessWidget {
  final bool autoStartEnabled;
  final bool isDarkTheme;
  final bool notificationsEnabled;
  final VoidCallback onToggleAutoStart;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleNotifications;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;
  final VoidCallback onShowAbout;

  const SettingsScreen({
    super.key,
    required this.autoStartEnabled,
    required this.isDarkTheme,
    required this.notificationsEnabled,
    required this.onToggleAutoStart,
    required this.onToggleTheme,
    required this.onToggleNotifications,
    required this.onRefresh,
    required this.onLogout,
    required this.onShowAbout,
  });

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
                        'Dark icon theme',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        'Use dark tray icons',
                        style: theme.typography.caption,
                      ),
                    ],
                  ),
                ),
                ToggleSwitch(
                  checked: isDarkTheme,
                  onChanged: (value) => onToggleTheme(),
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