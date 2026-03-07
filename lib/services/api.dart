import 'dart:convert';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class LibreLinkService {
  static const String baseUrl = 'https://api-eu.libreview.io';
  static const String _defaultApiVersion = '4.16.0';
  
  static final LibreLinkService _instance = LibreLinkService._internal();
  factory LibreLinkService() => _instance;
  LibreLinkService._internal();
  
  String? _authToken;
  String? _patientId;
  String? _userId;
  String _apiVersion = _defaultApiVersion;

  bool testMode = false;

  Map<String, String> get _baseHeaders => {
    'accept-encoding': 'gzip',
    'cache-control': 'no-cache',
    'connection': 'Keep-Alive',
    'content-type': 'application/json',
    'product': 'llu.android',
    'version': _apiVersion,
  };

  Map<String, String> get _authHeaders => {
    ..._baseHeaders,
    if (_authToken != null) 'authorization': 'Bearer $_authToken',
    if (_userId != null) 'account-id': _generateAccountIdHash(_userId!),
  };

  String _generateAccountIdHash(String userId) {
    var bytes = utf8.encode(userId);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  bool _isOutdatedVersionResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return false;
      return decoded['status'] == 920;
    } catch (_) {
      return false;
    }
  }

  String? _extractMinimumVersion(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) return null;
      final data = decoded['data'];
      if (data is! Map<String, dynamic>) return null;
      final minimumVersion = data['minimumVersion'];
      if (minimumVersion is String && minimumVersion.trim().isNotEmpty) {
        return minimumVersion.trim();
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  bool _isLowerVersion(String current, String required) {
    List<int> parseVersion(String value) {
      final numeric = RegExp(r'^\d+(\.\d+)*').firstMatch(value.trim())?.group(0) ?? value.trim();
      return numeric
          .split('.')
          .map((part) => int.tryParse(part) ?? 0)
          .toList(growable: false);
    }

    final currentParts = parseVersion(current);
    final requiredParts = parseVersion(required);
    final maxLen = currentParts.length > requiredParts.length ? currentParts.length : requiredParts.length;

    for (int i = 0; i < maxLen; i++) {
      final currentValue = i < currentParts.length ? currentParts[i] : 0;
      final requiredValue = i < requiredParts.length ? requiredParts[i] : 0;
      if (currentValue < requiredValue) return true;
      if (currentValue > requiredValue) return false;
    }
    return false;
  }

  Future<http.Response> _getWithVersionGuard(Uri uri, Map<String, String> headers) async {
    var response = await http.get(uri, headers: headers);

    if (_isOutdatedVersionResponse(response)) {
      final minimumVersion = _extractMinimumVersion(response);
      if (minimumVersion != null && _isLowerVersion(_apiVersion, minimumVersion)) {
        print('API version is outdated ($_apiVersion). Updating to minimumVersion: $minimumVersion');
        _apiVersion = minimumVersion;
        response = await http.get(uri, headers: headers);
      }
    }

    return response;
  }

  Future<http.Response> _postWithVersionGuard(
    Uri uri,
    Map<String, String> headers,
    String body,
  ) async {
    var response = await http.post(
      uri,
      headers: headers,
      body: body,
    );

    if (_isOutdatedVersionResponse(response)) {
      final minimumVersion = _extractMinimumVersion(response);
      if (minimumVersion != null && _isLowerVersion(_apiVersion, minimumVersion)) {
        print('API version is outdated ($_apiVersion). Updating to minimumVersion: $minimumVersion');
        _apiVersion = minimumVersion;
        response = await http.post(
          uri,
          headers: headers,
          body: body,
        );
      }
    }

    return response;
  }

  Future<bool> login(String email, String password) async {
    if (email.trim().toLowerCase() == 'test@liubquanti.click' && password == '1234567890') {
      testMode = true;
      _authToken = 'test_token';
      _userId = 'test_user';
      _patientId = 'test_patient';
      return true;
    }

    try {
      final response = await _postWithVersionGuard(
        Uri.parse('$baseUrl/llu/auth/login'),
        _baseHeaders,
        jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 0) {
          _authToken = data['data']['authTicket']['token'];
          _userId = data['data']['user']['id'];
          
          print('User ID: $_userId');
          print('Account ID Hash: ${_generateAccountIdHash(_userId!)}');
          
          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('auth_token', _authToken!);
            await prefs.setString('user_id', _userId!);
            await prefs.setString('email', email);
            print('Credentials saved successfully');
          } catch (e) {
            print('Error saving credentials: $e');
          }
          
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<bool> loadSavedCredentials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      
      print('Loading credentials...');
      print('Loaded auth token: $token');
      print('Loaded user ID: $userId');
      
      if (token != null && userId != null) {
        _authToken = token;
        _userId = userId;
        print('Credentials loaded successfully');
        return true;
      } else {
        print('Missing saved credentials');
        return false;
      }
    } catch (e) {
      print('Error loading saved credentials: $e');
      return false;
    }
  }

  Future<List<dynamic>?> getConnections() async {
    if (testMode) {
      return [
        {
          'patientId': 'test_patient',
          'firstName': 'Nikole',
          'lastName': 'Adalwin',
        }
      ];
    }
    
    print('getConnections called');
    print('Current state - auth: $_authToken, user: $_userId');
    
    if (_authToken == null || _userId == null) {
      print('Missing auth token or user ID for connections request');
      return null;
    }

    try {
      print('Making connections request with headers: ${_authHeaders}');
      
      final response = await _getWithVersionGuard(
        Uri.parse('$baseUrl/llu/connections'),
        _authHeaders,
      );

      print('Connections response status: ${response.statusCode}');
      print('Connections response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 0) {
          final connections = data['data'] as List;
          if (connections.isNotEmpty) {
            _patientId = connections[0]['patientId'];
            print('Patient ID set to: $_patientId');
          }
          return connections;
        }
      }
      return null;
    } catch (e) {
      print('Get connections error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> getGlucoseData() async {
    if (testMode) {
      try {
        final jsonStr = await _loadTestData();
        final data = jsonDecode(jsonStr);
        return data['data'];
      } catch (e) {
        print('Test mode: error loading testdata.json: $e');
        return null;
      }
    }
    
    print('getGlucoseData called');
    print('Current state - auth: $_authToken, patient: $_patientId, user: $_userId');
    
    if (_authToken == null || _patientId == null || _userId == null) {
      print('Missing required data for glucose request - auth: $_authToken, patient: $_patientId, user: $_userId');
      
      if (_authToken != null && _userId != null && _patientId == null) {
        print('Trying to get connections to retrieve patient ID...');
        final connections = await getConnections();
        if (connections == null || _patientId == null) {
          print('Failed to get patient ID');
          return null;
        }
      } else {
        return null;
      }
    }

    try {
      print('Making glucose data request with headers: ${_authHeaders}');
      
      final response = await _getWithVersionGuard(
        Uri.parse('$baseUrl/llu/connections/$_patientId/graph'),
        _authHeaders,
      );

      print('Glucose data response status: ${response.statusCode}');
      print('Glucose data response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 0) {
          return data['data'];
        }
      } else {
        print('Glucose data request failed with status: ${response.statusCode}');
        print('Response headers: ${response.headers}');
      }
      return null;
    } catch (e) {
      print('Get glucose data error: $e');
      return null;
    }
  }

  Future<List<dynamic>?> getLogbook() async {
    if (testMode) {
      return [];
    }
    if (_authToken == null || _patientId == null) return null;
    try {
      final response = await _getWithVersionGuard(
        Uri.parse('$baseUrl/llu/connections/$_patientId/logbook'),
        _authHeaders,
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 0) {
          return data['data'] as List<dynamic>;
        }
      }
      return null;
    } catch (e) {
      print('Get logbook error: $e');
      return null;
    }
  }

  Future<void> logout() async {
    print('Logging out...');
    _authToken = null;
    _patientId = null;
    _userId = null;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      await prefs.remove('user_id');
      await prefs.remove('email');
      print('Logout completed');
    } catch (e) {
      print('Error during logout: $e');
    }
  }

  bool get isLoggedIn => _authToken != null && _userId != null;
  
  String? get currentAuthToken => _authToken;
  String? get currentUserId => _userId;
  String? get currentPatientId => _patientId;

  Future<String> _loadTestData() async {
    return await Future.delayed(const Duration(milliseconds: 100), () async {
      return await DefaultAssetBundle.of(globalContext!).loadString('assets/data/testdata.json');
    });
  }

  static BuildContext? globalContext;
}