import 'package:fluent_ui/fluent_ui.dart';

class SettingsScreen extends StatelessWidget {
  final bool autoStartEnabled;
  final bool isDarkTheme;
  final bool notificationsEnabled;
  final VoidCallback onToggleAutoStart;
  final VoidCallback onToggleTheme;
  final VoidCallback onToggleNotifications;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

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
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 26.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          
          const SizedBox(height: 10),
          const Text(
            'Налаштування',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          // Автозапуск
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : Colors.grey[20],
              border: Border.all(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1d1d1d)
                : Colors.grey[40],
              width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  autoStartEnabled ? FluentIcons.play : FluentIcons.play,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Автозапуск',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Запускати додаток разом із системою',
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
          
          const SizedBox(height: 8),
          
          // Сповіщення
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : Colors.grey[20],
              border: Border.all(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1d1d1d)
                : Colors.grey[40],
              width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  notificationsEnabled ? FluentIcons.ringer : FluentIcons.ringer_off,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Push-сповіщення',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Сповіщення при зміні рівня глюкози',
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
          
          const SizedBox(height: 8),
          
          // Тема
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : Colors.grey[20],
              border: Border.all(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1d1d1d)
                : Colors.grey[40],
              width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  isDarkTheme ? FluentIcons.color : FluentIcons.brightness,
                  color: Colors.white,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Темна тема іконок',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Використовувати темні іконки в треї',
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
          
          const SizedBox(height: 8),
          
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2B2B2B)
                : Colors.grey[20],
              border: Border.all(
              color: FluentTheme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1d1d1d)
                : Colors.grey[40],
              width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                // Оновити дані
                Container(
                  width: double.infinity,
                  height: 35,
                  child: Button(
                    onPressed: onRefresh,
                    child: Text('Оновити дані'),
                  ),
                ),
                
                const SizedBox(height: 10),

                // Вийти з акаунта
                Container(
                  width: double.infinity,
                  height: 35,
                  child: FilledButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStatePropertyAll(Colors.red.darker),
                    ),
                    onPressed: onLogout,
                    child: Text('Вийти з акаунта', style: TextStyle(color: Colors.white)),
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