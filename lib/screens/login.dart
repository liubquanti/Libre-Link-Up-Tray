import 'package:fluent_ui/fluent_ui.dart';
import '../services/api.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  
  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  final LibreLinkService _service = LibreLinkService();

  @override
  void initState() {
    super.initState();
    _tryAutoLogin();
  }

  Future<void> _tryAutoLogin() async {
    print('=== LoginScreen: Trying auto login ===');
    final success = await _service.loadSavedCredentials();
    if (success) {
      print('LoginScreen: Credentials loaded, verifying with connections...');
      final connections = await _service.getConnections();
      if (connections != null) {
        print('LoginScreen: Auto login successful');
        widget.onLoginSuccess();
      } else {
        print('LoginScreen: Auto login failed - connections returned null');
      }
    } else {
      print('LoginScreen: No saved credentials found');
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    print('=== LoginScreen: Attempting manual login ===');
    print('LoginScreen: Email: ${_emailController.text.trim()}');

    final success = await _service.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      print('LoginScreen: Login successful, getting connections...');
      final connections = await _service.getConnections();
      if (connections != null) {
        print('LoginScreen: Connections retrieved successfully');
        widget.onLoginSuccess();
      } else {
        print('LoginScreen: Login successful but failed to get connections');
        await displayInfoBar(context, builder: (context, close) {
          return InfoBar(
            title: const Text('Помилка з\'єднання'),
            content: const Text('Успішний вхід, але не вдалося отримати з\'єднання. Перевірте налаштування акаунта.'),
            action: IconButton(
              icon: const Icon(FluentIcons.clear),
              onPressed: close,
            ),
            severity: InfoBarSeverity.error,
          );
        });
      }
    } else {
      print('LoginScreen: Login failed');
      await displayInfoBar(context, builder: (context, close) {
        return InfoBar(
          title: const Text('Помилка входу'),
          content: const Text('Невірний email або пароль'),
          action: IconButton(
            icon: const Icon(FluentIcons.clear),
            onPressed: close,
          ),
          severity: InfoBarSeverity.error,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      content: ScaffoldPage(
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/icon/icon.png',
                  width: 80,
                  height: 80,
                ),
                const SizedBox(height: 5),
                const Text(
                  'LibreLinkUpTray',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 5),
                
                Text(
                  'Увійдіть до свого облікового запису',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[100],
                  ),
                ),
                
                const SizedBox(height: 10),

                SizedBox(
                  width: 350,
                  child: Column(
                    children: [
                      InfoLabel(
                        label: 'Email',
                        child: TextBox(
                          controller: _emailController,
                          placeholder: 'Введіть ваш email',
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      
                      const SizedBox(height: 10),
                      
                      InfoLabel(
                        label: 'Пароль',
                        child: PasswordBox(
                          controller: _passwordController,
                          placeholder: 'Введіть ваш пароль',

                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: ProgressRing(strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Увійти...'),
                                  ],
                                )
                              : const Text('Увійти'),
                        ),
                      ),
                    ]
                  )
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}