import 'package:fluent_ui/fluent_ui.dart';

class SettingsScreen extends StatelessWidget {
  final bool autoStartEnabled;
  final bool isDarkTheme;
  final VoidCallback onToggleAutoStart;
  final VoidCallback onToggleTheme;
  final VoidCallback onRefresh;
  final VoidCallback onLogout;

  const SettingsScreen({
    super.key,
    required this.autoStartEnabled,
    required this.isDarkTheme,
    required this.onToggleAutoStart,
    required this.onToggleTheme,
    required this.onRefresh,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final theme = FluentTheme.of(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Налаштування',
            style: theme.typography.title,
          ),
          
          const SizedBox(height: 24),
          
          // Автозапуск
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  autoStartEnabled ? FluentIcons.play_solid : FluentIcons.play,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Автозапуск',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w600,
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
          
          const SizedBox(height: 16),
          
          // Тема
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.brightness == Brightness.dark
                    ? Colors.white.withOpacity(0.08)
                    : Colors.black.withOpacity(0.08),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isDarkTheme ? FluentIcons.color_solid : FluentIcons.brightness,
                  color: theme.accentColor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Темна тема іконок',
                        style: theme.typography.body?.copyWith(
                          fontWeight: FontWeight.w600,
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
          
          const SizedBox(height: 24),
          
          Text(
            'Дії',
            style: theme.typography.subtitle,
          ),
          
          const SizedBox(height: 16),
          
          // Оновити дані
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            child: Button(
              onPressed: onRefresh,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(FluentIcons.refresh, size: 16),
                  SizedBox(width: 8),
                  Text('Оновити дані'),
                ],
              ),
            ),
          ),
          
          // Вийти з акаунта
          Container(
            width: double.infinity,
            child: FilledButton(
              style: ButtonStyle(
                backgroundColor: WidgetStatePropertyAll(Colors.red),
              ),
              onPressed: onLogout,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(FluentIcons.sign_out, size: 16, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Вийти з акаунта', style: TextStyle(color: Colors.white)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}