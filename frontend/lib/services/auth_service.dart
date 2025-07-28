import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'http_client.dart';

class AuthService extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  
  // Platform-specific storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _sharedPreferences;
  
  Map<String, dynamic>? _currentUser;
  String? _accessToken;
  String? _refreshToken;
  bool _isLoading = false;
  DateTime? _loginTimestamp;
  bool _isInitialized = false;
  
  // Session duration in days
  static const int _sessionDurationDays = 7;
  
  // Environment detection
  static bool get isProductionWeb => kIsWeb && !kDebugMode;
  static bool get isDevelopmentWeb => kIsWeb && kDebugMode;
  static bool get isMobile => !kIsWeb;

  Map<String, dynamic>? get currentUser => _currentUser;
  String? get accessToken => _accessToken;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _accessToken != null && !_isSessionExpired();
  bool get isInitialized => _isInitialized;

  AuthService() {
    _initializeStorage();
  }

  /// Initialize platform-specific storage
  Future<void> _initializeStorage() async {
    try {
      debugPrint('AuthService: Starting storage initialization');
      debugPrint('AuthService: Environment - Web: $kIsWeb, Debug: $kDebugMode, Production: $isProductionWeb');
      
      if (kIsWeb) {
        debugPrint('AuthService: Initializing SharedPreferences for web');
        _sharedPreferences = await SharedPreferences.getInstance();
        debugPrint('AuthService: SharedPreferences initialized successfully');
        
        // Test SharedPreferences functionality
        await _testSharedPreferences();
      } else {
        debugPrint('AuthService: Using FlutterSecureStorage for mobile');
      }
      
      await _loadStoredAuth();
      _isInitialized = true;
      notifyListeners();
      
      debugPrint('AuthService: Storage initialization completed');
      debugPrint('AuthService: Final session state: ${getSessionInfo()}');
    } catch (e) {
      debugPrint('AuthService: Error initializing storage: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Test SharedPreferences functionality in web mode
  Future<void> _testSharedPreferences() async {
    if (!kIsWeb || _sharedPreferences == null) return;
    
    try {
      debugPrint('AuthService: Testing SharedPreferences functionality...');
      
      // Test write
      await _sharedPreferences!.setString('_test_key', 'test_value');
      
      // Test read
      final testValue = _sharedPreferences!.getString('_test_key');
      
      // Test delete
      await _sharedPreferences!.remove('_test_key');
      
      if (testValue == 'test_value') {
        debugPrint('AuthService: ✅ SharedPreferences test passed');
      } else {
        debugPrint('AuthService: ❌ SharedPreferences test failed - read returned: $testValue');
      }
    } catch (e) {
      debugPrint('AuthService: ❌ SharedPreferences test failed with error: $e');
    }
  }

  /// Check if current session is expired (older than 7 days)
  bool _isSessionExpired() {
    if (_loginTimestamp == null) {
      debugPrint('AuthService: No login timestamp found, session expired');
      return true;
    }
    
    final now = DateTime.now();
    final difference = now.difference(_loginTimestamp!);
    final isExpired = difference.inDays >= _sessionDurationDays;
    
    debugPrint('AuthService: Session age: ${difference.inDays} days, Expired: $isExpired');
    debugPrint('AuthService: Login timestamp: ${_loginTimestamp!.toIso8601String()}');
    debugPrint('AuthService: Current time: ${now.toIso8601String()}');
    
    return isExpired;
  }

  /// Load stored authentication data from platform-specific storage
  Future<void> _loadStoredAuth() async {
    try {
      debugPrint('AuthService: Loading stored authentication data');
      debugPrint('AuthService: Environment: ${_getEnvironmentInfo()}');
      
      if (kIsWeb) {
        await _loadFromSharedPreferences();
      } else {
        await _loadFromSecureStorage();
      }
      
      // Check if session is expired and clear if necessary
      if (_isSessionExpired()) {
        debugPrint('AuthService: Session expired, clearing stored auth');
        await _clearStoredAuth();
      } else if (_accessToken != null) {
        debugPrint('AuthService: Valid session found, user authenticated');
        debugPrint('AuthService: Session info: ${getSessionInfo()}');
      } else {
        debugPrint('AuthService: No valid session found');
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Error loading stored auth: $e');
      await _clearStoredAuth();
      notifyListeners();
    }
  }

  /// Get environment information for debugging
  String _getEnvironmentInfo() {
    if (isProductionWeb) return 'Production Web';
    if (isDevelopmentWeb) return 'Development Web';
    if (isMobile) return 'Mobile';
    return 'Unknown';
  }

  /// Load auth data from SharedPreferences (Web)
  Future<void> _loadFromSharedPreferences() async {
    if (_sharedPreferences == null) {
      debugPrint('AuthService: SharedPreferences not initialized');
      return;
    }
    
    debugPrint('AuthService: Loading from SharedPreferences');
    
    // Read all required values from SharedPreferences
    _accessToken = _sharedPreferences!.getString('access_token');
    _refreshToken = _sharedPreferences!.getString('refresh_token');
    final userStr = _sharedPreferences!.getString('user');
    final timestampStr = _sharedPreferences!.getString('login_timestamp');
    
    debugPrint('AuthService: Loaded from SharedPreferences:');
    debugPrint('  - Access token: ${_accessToken != null ? 'Present (${_accessToken!.length} chars)' : 'Missing'}');
    debugPrint('  - Refresh token: ${_refreshToken != null ? 'Present (${_refreshToken!.length} chars)' : 'Missing'}');
    debugPrint('  - User data: ${userStr != null ? 'Present' : 'Missing'}');
    debugPrint('  - Timestamp: ${timestampStr ?? 'Missing'}');
    
    // Parse user data if available
    if (userStr != null) {
      try {
        _currentUser = json.decode(userStr);
        debugPrint('AuthService: User data parsed successfully: ${_currentUser!.keys}');
      } catch (e) {
        debugPrint('AuthService: Error parsing user data: $e');
        _currentUser = null;
      }
    }
    
    // Parse timestamp if available
    if (timestampStr != null) {
      try {
        _loginTimestamp = DateTime.parse(timestampStr);
        debugPrint('AuthService: Timestamp parsed successfully: ${_loginTimestamp!.toIso8601String()}');
      } catch (e) {
        debugPrint('AuthService: Error parsing timestamp: $e');
        _loginTimestamp = null;
      }
    }
  }

  /// Load auth data from FlutterSecureStorage (Mobile)
  Future<void> _loadFromSecureStorage() async {
    debugPrint('AuthService: Loading from SecureStorage');
    
    _accessToken = await _secureStorage.read(key: 'access_token');
    _refreshToken = await _secureStorage.read(key: 'refresh_token');
    final userStr = await _secureStorage.read(key: 'user');
    final timestampStr = await _secureStorage.read(key: 'login_timestamp');
    
    debugPrint('AuthService: Loaded from SecureStorage:');
    debugPrint('  - Access token: ${_accessToken != null ? 'Present (${_accessToken!.length} chars)' : 'Missing'}');
    debugPrint('  - Refresh token: ${_refreshToken != null ? 'Present (${_refreshToken!.length} chars)' : 'Missing'}');
    debugPrint('  - User data: ${userStr != null ? 'Present' : 'Missing'}');
    debugPrint('  - Timestamp: ${timestampStr ?? 'Missing'}');
    
    if (userStr != null) {
      try {
        _currentUser = json.decode(userStr);
        debugPrint('AuthService: User data parsed successfully: ${_currentUser!.keys}');
      } catch (e) {
        debugPrint('AuthService: Error parsing user data: $e');
        _currentUser = null;
      }
    }
    if (timestampStr != null) {
      try {
        _loginTimestamp = DateTime.parse(timestampStr);
        debugPrint('AuthService: Timestamp parsed successfully: ${_loginTimestamp!.toIso8601String()}');
      } catch (e) {
        debugPrint('AuthService: Error parsing timestamp: $e');
        _loginTimestamp = null;
      }
    }
  }

  /// Store authentication data in platform-specific storage
  Future<void> _storeAuth({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
  }) async {
    _loginTimestamp = DateTime.now();
    final timestampString = _loginTimestamp!.toIso8601String();
    
    debugPrint('AuthService: Storing authentication data');
    debugPrint('AuthService: Login timestamp: $timestampString');
    
    try {
      if (kIsWeb) {
        await _storeInSharedPreferences(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
          timestamp: timestampString,
        );
      } else {
        await _storeInSecureStorage(
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
          timestamp: timestampString,
        );
      }
      
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _currentUser = user;
      
      debugPrint('AuthService: Auth data stored successfully');
      debugPrint('AuthService: Session info after storage: ${getSessionInfo()}');
    } catch (e) {
      debugPrint('AuthService: Error storing auth data: $e');
      throw Exception('Failed to store authentication data: $e');
    }
  }

  /// Store auth data in SharedPreferences (Web)
  Future<void> _storeInSharedPreferences({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
    required String timestamp,
  }) async {
    if (_sharedPreferences == null) {
      throw Exception('SharedPreferences not initialized');
    }
    
    debugPrint('AuthService: Storing auth data in SharedPreferences');
    
    // Store all required values in SharedPreferences
    await _sharedPreferences!.setString('access_token', accessToken);
    await _sharedPreferences!.setString('refresh_token', refreshToken);
    await _sharedPreferences!.setString('user', json.encode(user));
    await _sharedPreferences!.setString('login_timestamp', timestamp);
    
    // Verify the data was stored correctly
    final storedAccessToken = _sharedPreferences!.getString('access_token');
    final storedRefreshToken = _sharedPreferences!.getString('refresh_token');
    final storedUser = _sharedPreferences!.getString('user');
    final storedTimestamp = _sharedPreferences!.getString('login_timestamp');
    
    debugPrint('AuthService: Verification - Access token stored: ${storedAccessToken != null}');
    debugPrint('AuthService: Verification - Refresh token stored: ${storedRefreshToken != null}');
    debugPrint('AuthService: Verification - User stored: ${storedUser != null}');
    debugPrint('AuthService: Verification - Timestamp stored: ${storedTimestamp != null}');
    
    if (storedAccessToken == null || storedRefreshToken == null || 
        storedUser == null || storedTimestamp == null) {
      throw Exception('Failed to store all required authentication data');
    }
    
    debugPrint('AuthService: Auth data stored in SharedPreferences successfully');
  }

  /// Store auth data in FlutterSecureStorage (Mobile)
  Future<void> _storeInSecureStorage({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> user,
    required String timestamp,
  }) async {
    debugPrint('AuthService: Storing auth data in SecureStorage');
    
    await _secureStorage.write(key: 'access_token', value: accessToken);
    await _secureStorage.write(key: 'refresh_token', value: refreshToken);
    await _secureStorage.write(key: 'user', value: json.encode(user));
    await _secureStorage.write(key: 'login_timestamp', value: timestamp);
    
    debugPrint('AuthService: Auth data stored in SecureStorage successfully');
  }

  /// Clear stored authentication data from platform-specific storage
  Future<void> _clearStoredAuth() async {
    try {
      debugPrint('AuthService: Clearing stored authentication data');
      
      if (kIsWeb) {
        await _clearFromSharedPreferences();
      } else {
        await _clearFromSecureStorage();
      }
      
      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
      _loginTimestamp = null;
      
      debugPrint('AuthService: Auth data cleared successfully');
      notifyListeners();
    } catch (e) {
      debugPrint('AuthService: Error clearing auth data: $e');
    }
  }

  /// Clear auth data from SharedPreferences (Web)
  Future<void> _clearFromSharedPreferences() async {
    if (_sharedPreferences != null) {
      await _sharedPreferences!.remove('access_token');
      await _sharedPreferences!.remove('refresh_token');
      await _sharedPreferences!.remove('user');
      await _sharedPreferences!.remove('login_timestamp');
      debugPrint('AuthService: Auth data cleared from SharedPreferences');
    }
  }

  /// Clear auth data from FlutterSecureStorage (Mobile)
  Future<void> _clearFromSecureStorage() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user');
    await _secureStorage.delete(key: 'login_timestamp');
    debugPrint('AuthService: Auth data cleared from SecureStorage');
  }

  /// Check if all required auth data exists (for web validation)
  bool _hasAllRequiredAuthData() {
    return _accessToken != null && 
           _refreshToken != null && 
           _loginTimestamp != null;
  }

  /// Get session info for debugging
  Map<String, dynamic> getSessionInfo() {
    return {
      'isAuthenticated': isAuthenticated,
      'hasAccessToken': _accessToken != null,
      'hasRefreshToken': _refreshToken != null,
      'hasLoginTimestamp': _loginTimestamp != null,
      'hasAllRequiredData': _hasAllRequiredAuthData(),
      'loginTimestamp': _loginTimestamp?.toIso8601String(),
      'sessionAge': _loginTimestamp != null 
          ? DateTime.now().difference(_loginTimestamp!).inDays 
          : null,
      'isExpired': _isSessionExpired(),
      'platform': kIsWeb ? 'Web' : 'Mobile',
      'isInitialized': _isInitialized,
    };
  }

  /// Refresh user data from backend
  Future<void> refreshUserData() async {
    try {
      final response = await _httpClient.get('/user/profile');
      
      if (response['status'] == 'success') {
        _currentUser = response['data'];
        
        // Update stored user data
        if (kIsWeb) {
          if (_sharedPreferences != null) {
            await _sharedPreferences!.setString('user', json.encode(_currentUser));
          }
        } else {
          await _secureStorage.write(key: 'user', value: json.encode(_currentUser));
        }
        
        notifyListeners();
      }
    } catch (e) {
      debugPrint('AuthService: Error refreshing user data: $e');
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String username,
    String? profilePicture,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthService: Sending registration request to /auth/register');
      final response = await _httpClient.post('/auth/register', {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'password': password,
        if (profilePicture != null) 'profilePicture': profilePicture,
      });

      if (response['status'] == 'success' && response['data'] != null) {
        await _storeAuth(
          accessToken: response['data']['accessToken'],
          refreshToken: response['data']['refreshToken'],
          user: response['data']['user'],
        );
        debugPrint('AuthService: Registration successful, auth stored');
      } else {
        throw Exception(response['message'] ?? 'Registration failed');
      }
    } catch (e) {
      debugPrint('AuthService: Registration error: $e');
      throw Exception('Registration failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthService: Attempting login for: $email');
      
      // Test connection first
      final connectionTest = await _httpClient.testConnection();
      debugPrint('AuthService: Connection test result: $connectionTest');
      
      if (!connectionTest) {
        throw Exception('Cannot connect to server. Please check your internet connection.');
      }
      
      final response = await _httpClient.post('/auth/login', {
        'email': email,
        'password': password,
      });

      if (response['status'] == 'success' && response['data'] != null) {
        await _storeAuth(
          accessToken: response['data']['accessToken'],
          refreshToken: response['data']['refreshToken'],
          user: response['data']['user'],
        );
        debugPrint('AuthService: Login successful, session started');
        debugPrint('AuthService: Current auth state: ${getSessionInfo()}');
      } else {
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      debugPrint('AuthService: Login error: $e');
      throw Exception('Login failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
      debugPrint('AuthService: Login process completed, final auth state: ${getSessionInfo()}');
    }
  }

  Future<void> refreshToken() async {
    if (_refreshToken == null) {
      debugPrint('AuthService: No refresh token available');
      throw Exception('No refresh token available');
    }

    try {
      debugPrint('AuthService: Attempting token refresh');
      final response = await _httpClient.post('/auth/refresh-token', {
        'refreshToken': _refreshToken,
      });

      if (response['success'] == true && response['data'] != null) {
        await _storeAuth(
          accessToken: response['data']['accessToken'],
          refreshToken: response['data']['refreshToken'],
          user: _currentUser!,
        );
        debugPrint('AuthService: Token refresh successful');
      } else {
        debugPrint('AuthService: Token refresh failed, clearing auth');
        await _clearStoredAuth();
        throw Exception(response['message'] ?? 'Token refresh failed');
      }
    } catch (e) {
      debugPrint('AuthService: Token refresh error: $e');
      await _clearStoredAuth();
      throw Exception('Token refresh failed: $e');
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      debugPrint('AuthService: Logging out user');
      if (_accessToken != null) {
        await _httpClient.post('/auth/logout', {});
      }
    } catch (e) {
      debugPrint('AuthService: Logout error: $e');
    } finally {
      await _clearStoredAuth();
      _isLoading = false;
      notifyListeners();
      debugPrint('AuthService: Logout completed');
    }
  }

  Future<void> getCurrentUser() async {
    if (_accessToken == null) {
      debugPrint('AuthService: No access token for getCurrentUser');
      return;
    }

    try {
      debugPrint('AuthService: Fetching current user data');
      final response = await _httpClient.get('/auth/me');
      if (response['success'] == true && response['data'] != null) {
        _currentUser = response['data'];
        notifyListeners();
        debugPrint('AuthService: Current user data updated');
      } else {
        debugPrint('AuthService: Failed to get current user, clearing auth');
        await _clearStoredAuth();
      }
    } catch (e) {
      debugPrint('AuthService: Error getting current user: $e');
      await _clearStoredAuth();
    }
  }

  Future<void> updateProfile(Map<String, dynamic> updates) async {
    if (_currentUser == null) throw Exception('Not authenticated');

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _httpClient.put(
        '/users/${_currentUser!['_id']}',
        updates,
      );

      if (response['success'] == true && response['data'] != null) {
        _currentUser = response['data'];
        notifyListeners();
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _httpClient.post('/auth/reset-password', {
        'email': email,
      });

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmPasswordReset({
    required String token,
    required String newPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _httpClient.post('/auth/confirm-reset', {
        'token': token,
        'newPassword': newPassword,
      });

      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Password reset failed');
      }
    } catch (e) {
      throw Exception('Password reset failed: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}