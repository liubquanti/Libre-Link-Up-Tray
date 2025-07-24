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
  String? _errorMessage;

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
      _errorMessage = null;
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
        setState(() {
          _errorMessage = 'Успішний вхід, але не вдалося отримати з\'єднання. Перевірте налаштування акаунта.';
        });
      }
    } else {
      print('LoginScreen: Login failed');
      setState(() {
        _errorMessage = 'Невірний email або пароль';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NavigationView(
      appBar: NavigationAppBar(
        title: const Text('Вхід до LibreLink'),
        automaticallyImplyLeading: false,
      ),
      content: ScaffoldPage(
        content: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: Icon(
                    FluentIcons.health,
                    size: 64,
                    color: Colors.blue,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                const Text(
                  'LibreLink Up Tray',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  'Увійдіть до свого облікового запису',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[100],
                  ),
                ),
                
                const SizedBox(height: 32),
                
                InfoLabel(
                  label: 'Email',
                  child: TextBox(
                    controller: _emailController,
                    placeholder: 'Введіть ваш email',
                    keyboardType: TextInputType.emailAddress,
                    prefix: const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Icon(FluentIcons.mail, size: 16),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                InfoLabel(
                  label: 'Пароль',
                  child: PasswordBox(
                    controller: _passwordController,
                    placeholder: 'Введіть ваш пароль',

                  ),
                ),
                
                const SizedBox(height: 24),
                
                if (_errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(FluentIcons.error_badge, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
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
                
                const SizedBox(height: 24),
                
                if (_service.currentAuthToken != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Debug: Auth token exists, User ID: ${_service.currentUserId}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[130],
                        fontFamily: 'Consolas',
                      ),
                    ),
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