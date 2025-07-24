import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

class LibreLinkService {
  static const String baseUrl = 'https://api-eu.libreview.io';
  
  static final LibreLinkService _instance = LibreLinkService._internal();
  factory LibreLinkService() => _instance;
  LibreLinkService._internal();
  
  String? _authToken;
  String? _patientId;
  String? _userId;

  Map<String, String> get _baseHeaders => {
    'accept-encoding': 'gzip',
    'cache-control': 'no-cache',
    'connection': 'Keep-Alive',
    'content-type': 'application/json',
    'product': 'llu.android',
    'version': '4.12.0',
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

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/llu/auth/login'),
        headers: _baseHeaders,
        body: jsonEncode({
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
    print('getConnections called');
    print('Current state - auth: $_authToken, user: $_userId');
    
    if (_authToken == null || _userId == null) {
      print('Missing auth token or user ID for connections request');
      return null;
    }

    try {
      print('Making connections request with headers: ${_authHeaders}');
      
      final response = await http.get(
        Uri.parse('$baseUrl/llu/connections'),
        headers: _authHeaders,
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
      
      final response = await http.get(
        Uri.parse('$baseUrl/llu/connections/$_patientId/graph'),
        headers: _authHeaders,
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
}