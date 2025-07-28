import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';
import 'auth_service.dart';

// Import dart:io for mobile
import 'dart:io' if (dart.library.html) 'dart:html' as io;

class HttpClient {
  // Updated base URL to be more reliable for web development
  static const String baseUrl = "http://127.0.0.1:3000/api";
  
  // Platform-specific storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _sharedPreferences;
  
  bool _isRefreshing = false;
  final List<Future Function()> _pendingRequests = [];

  HttpClient() {
    _initializeStorage();
  }

  /// Initialize platform-specific storage
  Future<void> _initializeStorage() async {
    if (kIsWeb) {
      _sharedPreferences = await SharedPreferences.getInstance();
      debugPrint('HttpClient: Initialized SharedPreferences for web');
    } else {
      debugPrint('HttpClient: Using FlutterSecureStorage for mobile');
    }
  }

  /// Get JWT token from secure storage
  Future<String?> getToken() async {
    try {
      debugPrint('HttpClient: Getting token...');
      String? token;
      
      if (kIsWeb) {
        debugPrint('HttpClient: Getting token from SharedPreferences');
        if (_sharedPreferences == null) {
          debugPrint('HttpClient: SharedPreferences is null, initializing...');
          _sharedPreferences = await SharedPreferences.getInstance();
        }
        token = _sharedPreferences?.getString('access_token');
        debugPrint('HttpClient: Token from SharedPreferences: ${token != null ? 'Present (${token.length} chars)' : 'Missing'}');
      } else {
        debugPrint('HttpClient: Getting token from SecureStorage');
        token = await _secureStorage.read(key: 'access_token');
        debugPrint('HttpClient: Token from SecureStorage: ${token != null ? 'Present (${token.length} chars)' : 'Missing'}');
      }
      
      if (token != null) {
        debugPrint('HttpClient: Token found: ${token.substring(0, 20)}...');
      } else {
        debugPrint('HttpClient: No token found');
      }
      
      return token;
    } catch (e) {
      debugPrint('HttpClient: Error getting token: $e');
      return null;
    }
  }

  /// Get default headers with authentication
  Future<Map<String, String>> _getHeaders({bool includeContentType = true}) async {
    final token = await getToken();
    final headers = <String, String>{
      'Accept': 'application/json',
      if (includeContentType) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    
    debugPrint('HttpClient: Headers prepared:');
    debugPrint('  - Accept: ${headers['Accept']}');
    debugPrint('  - Content-Type: ${headers['Content-Type']}');
    debugPrint('  - Authorization: ${headers['Authorization'] != null ? 'Bearer ${token!.substring(0, 20)}...' : 'Missing'}');
    
    return headers;
  }

  /// Handle HTTP response with error checking and token refresh
  Future<http.Response> _handleResponse(http.Response response, BuildContext? context) async {
    if (response.statusCode == 401) {
      // Token expired, try to refresh if context is available
      if (context != null) {
        try {
          final authService = Provider.of<AuthService>(context, listen: false);
          
          if (!_isRefreshing) {
            _isRefreshing = true;
            try {
              await authService.refreshToken();
              _isRefreshing = false;
              
              // Retry all pending requests
              for (var request in _pendingRequests) {
                await request();
              }
              _pendingRequests.clear();
              
              // Retry the current request
              return await _retryRequest(response.request!);
            } catch (e) {
              _isRefreshing = false;
              _pendingRequests.clear();
              await authService.logout();
              throw HttpException('Session expired. Please login again.');
            }
          } else {
            // Add request to pending queue
            final completer = Completer<http.Response>();
            _pendingRequests.add(() async {
              final retryResponse = await _retryRequest(response.request!);
              completer.complete(retryResponse);
            });
            return completer.future;
          }
        } catch (e) {
          debugPrint('HttpClient: Error during token refresh: $e');
          throw HttpException('Authentication failed. Please login again.');
        }
      } else {
        // No context available, check if token exists
        final token = await getToken();
        if (token == null) {
        throw HttpException('Authentication required. Please login again.');
        } else {
          // Token exists but request failed, might be expired
          throw HttpException('Authentication token expired. Please login again.');
        }
      }
    }
    
    // Check for other error status codes
    if (response.statusCode >= 400) {
      String errorMessage = 'Request failed';
      try {
        final errorData = json.decode(response.body);
        errorMessage = errorData['message'] ?? errorData['error'] ?? errorMessage;
      } catch (e) {
        errorMessage = 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
      }
      throw HttpException(errorMessage, uri: response.request?.url);
    }
    
    return response;
  }

  /// Retry request with new token
  Future<http.Response> _retryRequest(http.BaseRequest request) async {
    final headers = await _getHeaders(includeContentType: false);
    final newRequest = http.Request(request.method, request.url)
      ..headers.addAll(headers)
      ..body = request is http.Request ? request.body : '';

    final streamedResponse = await newRequest.send();
    return await http.Response.fromStream(streamedResponse);
  }

  /// Parse JSON response with error handling
  Map<String, dynamic> parseJsonResponse(http.Response response) {
    try {
      return json.decode(response.body);
    } catch (e) {
      throw HttpException('Invalid JSON response: ${response.body}', uri: response.request?.url);
    }
  }

  /// Check if authentication is ready
  Future<bool> _isAuthReady() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      debugPrint('HttpClient: Error checking auth readiness: $e');
      return false;
    }
  }

  /// GET request
  Future<Map<String, dynamic>> get(String path, {BuildContext? context}) async {
    // Check if auth is ready before making request
    final authReady = await _isAuthReady();
    if (!authReady) {
      debugPrint('HttpClient: Auth not ready, waiting...');
      // Wait a bit for auth to be ready
      await Future.delayed(const Duration(milliseconds: 200));
    }
    
    final headers = await _getHeaders(includeContentType: false);
    
    debugPrint('HttpClient: GET $baseUrl$path');
    
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    final handledResponse = await _handleResponse(response, context);
    return parseJsonResponse(handledResponse);
  }

  /// POST request
  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> data, {BuildContext? context}) async {
    final headers = await _getHeaders();
    
    debugPrint('HttpClient: POST $baseUrl$path');
    debugPrint('HttpClient: Request headers: $headers');
    debugPrint('HttpClient: Request data: $data');
    
    final jsonBody = json.encode(data);
    debugPrint('HttpClient: Request body (JSON): $jsonBody');
    debugPrint('HttpClient: Request body length: ${jsonBody.length}');

    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: jsonBody,
    );

    debugPrint('HttpClient: Response status: ${response.statusCode}');
    debugPrint('HttpClient: Response body: ${response.body}');

    final handledResponse = await _handleResponse(response, context);
    return parseJsonResponse(handledResponse);
  }

  /// PUT request
  Future<Map<String, dynamic>> put(String path, Map<String, dynamic> data, {BuildContext? context}) async {
    final headers = await _getHeaders();
    
    debugPrint('HttpClient: PUT $baseUrl$path');
    debugPrint('HttpClient: PUT request headers: $headers');
    debugPrint('HttpClient: PUT request body: ${json.encode(data)}');

    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(data),
    );

    debugPrint('HttpClient: PUT response status: ${response.statusCode}');
    debugPrint('HttpClient: PUT response body: ${response.body}');

    final handledResponse = await _handleResponse(response, context);
    return parseJsonResponse(handledResponse);
  }

  /// DELETE request
  Future<Map<String, dynamic>> delete(String path, {BuildContext? context}) async {
    final headers = await _getHeaders(includeContentType: false);
    
    debugPrint('HttpClient: DELETE $baseUrl$path');

    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    final handledResponse = await _handleResponse(response, context);
    return parseJsonResponse(handledResponse);
  }

  /// File upload using multipart/form-data
  Future<Map<String, dynamic>> uploadFile(
    String path, 
    Map<String, String> fields, 
    Map<String, dynamic> files, 
    {BuildContext? context}
  ) async {
    // TODO: Implement file upload for web and mobile
    // For now, return an error to avoid compilation issues
    throw UnimplementedError('File upload not implemented yet');
  }

  /// Raw response methods for cases where you need the full response
  Future<http.Response> getRaw(String path, {BuildContext? context}) async {
    final headers = await _getHeaders(includeContentType: false);
    
    final response = await http.get(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    return _handleResponse(response, context);
  }

  Future<http.Response> postRaw(String path, Map<String, dynamic> data, {BuildContext? context}) async {
    final headers = await _getHeaders();
    
    final response = await http.post(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(data),
    );

    return _handleResponse(response, context);
  }

  Future<http.Response> putRaw(String path, Map<String, dynamic> data, {BuildContext? context}) async {
    final headers = await _getHeaders();
    
    final response = await http.put(
      Uri.parse('$baseUrl$path'),
      headers: headers,
      body: json.encode(data),
    );

    return _handleResponse(response, context);
  }

  Future<http.Response> deleteRaw(String path, {BuildContext? context}) async {
    final headers = await _getHeaders(includeContentType: false);
    
    final response = await http.delete(
      Uri.parse('$baseUrl$path'),
      headers: headers,
    );

    return _handleResponse(response, context);
  }

  /// Test basic connectivity
  Future<bool> testConnection() async {
    try {
      debugPrint('HttpClient: Testing connection to $baseUrl');
      
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
        headers: {'Accept': 'application/json'},
      );
      
      debugPrint('HttpClient: Test response status: ${response.statusCode}');
      debugPrint('HttpClient: Test response body: ${response.body}');
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('HttpClient: Connection test failed: $e');
      return false;
    }
  }
}

class HttpException implements Exception {
  final String message;
  final Uri? uri;

  HttpException(this.message, {this.uri});

  @override
  String toString() => 'HttpException: $message${uri != null ? ' ($uri)' : ''}';
} 