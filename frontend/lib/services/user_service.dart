import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'http_client.dart';

class UserService extends ChangeNotifier {
  final HttpClient _httpClient = HttpClient();
  
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _userSettings;
  bool _isLoading = false;
  String? _error;

  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get userSettings => _userSettings;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch user profile from backend
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _httpClient.get('/user/profile');
      
      if (response['status'] == 'success') {
        _userProfile = response['data'];
        notifyListeners();
        return _userProfile;
      } else {
        _error = 'Failed to fetch profile: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error fetching profile: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user profile
  Future<bool> updateProfile({
    required String firstName,
    required String lastName,
    required String email,
    required String username,
    required String phoneNumber,
    String? currency,
    String? language,
    String? theme,
    bool? emailNotifications,
    bool? pushNotifications,
    String? bio,
    String? dateOfBirth,
    Map<String, String>? address,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final body = <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'username': username,
        'phoneNumber': phoneNumber,
      };

      // Add settings only if provided
      if (currency != null || language != null || theme != null || emailNotifications != null || pushNotifications != null) {
        final settings = <String, dynamic>{};
        if (currency != null) settings['currency'] = currency;
        if (language != null) settings['language'] = language;
        if (theme != null) settings['theme'] = theme;
        if (emailNotifications != null || pushNotifications != null) {
          settings['notifications'] = <String, dynamic>{};
          if (emailNotifications != null) settings['notifications']['email'] = emailNotifications;
          if (pushNotifications != null) settings['notifications']['push'] = pushNotifications;
        }
        body['settings'] = settings;
      }

      // Add optional fields if provided
      if (bio != null && bio.isNotEmpty) body['bio'] = bio;
      // Always send dateOfBirth to handle both setting and clearing
      body['dateOfBirth'] = dateOfBirth;
      if (address != null) body['address'] = address;

      final response = await _httpClient.put('/user/profile', body);
      
      if (response['status'] == 'success') {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating profile: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload profile picture
  Future<bool> uploadProfilePicture(dynamic imageFile) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final success = await _uploadProfilePicture(imageFile);
      
      if (success) {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to upload profile picture';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error uploading profile picture: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Upload profile picture (internal method)
  Future<bool> _uploadProfilePicture(dynamic imageFile) async {
    try {
      if (kIsWeb) {
        // Web: use XFile and http.MultipartRequest
        final uri = Uri.parse('http://localhost:3000/api/user/profile/picture');
        final request = http.MultipartRequest('POST', uri);
        
        // Handle XFile, File, and Uint8List types for web
        Uint8List bytes;
        String filename;
        String contentType;
        
        try {
          if (imageFile is Uint8List) {
            // Direct bytes from cropper - detect file type from bytes
            bytes = imageFile;
            
            // Detect file type from magic bytes
            if (bytes.length >= 2) {
              if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
                // JPEG magic bytes
                filename = 'profile_picture.jpg';
                contentType = 'image/jpeg';
              } else if (bytes.length >= 8 && 
                         bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 &&
                         bytes[4] == 0x0D && bytes[5] == 0x0A && bytes[6] == 0x1A && bytes[7] == 0x0A) {
                // PNG magic bytes
                filename = 'profile_picture.png';
                contentType = 'image/png';
              } else {
                // Default to JPEG
                filename = 'profile_picture.jpg';
                contentType = 'image/jpeg';
              }
            } else {
              filename = 'profile_picture.jpg';
              contentType = 'image/jpeg';
            }
            
            debugPrint('Using Uint8List bytes: ${bytes.length} bytes, type: $contentType');
          } else if (imageFile is XFile) {
            bytes = await imageFile.readAsBytes();
            filename = imageFile.name;
            contentType = imageFile.mimeType ?? 'image/jpeg';
            debugPrint('Using XFile: $filename, type: $contentType');
          } else if (imageFile is File) {
            // For web, try to read bytes safely
            try {
              bytes = await imageFile.readAsBytes();
              filename = imageFile.path.split('/').last;
              contentType = 'image/jpeg'; // Default for File objects
              debugPrint('Using File: $filename');
            } catch (e) {
              // If File.readAsBytes fails on web, try alternative approach
              debugPrint('Web file read failed, trying alternative: $e');
              throw Exception('Web file operation not supported. Please try on mobile.');
            }
          } else {
            throw Exception('Unsupported file type for web upload: ${imageFile.runtimeType}');
          }
        } catch (e) {
          if (e.toString().contains('namespace')) {
            throw Exception('Web file operation not supported. Please try on mobile or use a different browser.');
          }
          rethrow;
        }
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'profilePicture',
            bytes,
            filename: filename,
            contentType: MediaType.parse(contentType),
          ),
        );
        
        // Add auth header if needed
        final token = await _httpClient.getToken();
        if (token != null) {
          request.headers['Authorization'] = 'Bearer $token';
        }
        
        final response = await request.send();
        final respStr = await response.stream.bytesToString();
        final respJson = respStr.isNotEmpty ? _httpClient.parseJsonResponse(http.Response(respStr, response.statusCode)) : {};
        return response.statusCode == 200 && (respJson['status'] == 'success');
      } else if (imageFile is File) {
        // Mobile/desktop: use existing logic
        final response = await _httpClient.uploadFile(
          '/user/profile/picture',
          {}, // No additional fields
          {'profilePicture': imageFile}, // File with field name
        );
        return response['status'] == 'success';
      } else {
        throw Exception('Unsupported file type for upload');
      }
    } catch (e) {
      _error = 'Error uploading profile picture: $e';
      return false;
    }
  }

  /// Fetch user settings
  Future<Map<String, dynamic>?> fetchUserSettings() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _httpClient.get('/user/settings');
      
      if (response['status'] == 'success') {
        _userSettings = response['data'];
        notifyListeners();
        return _userSettings;
      } else {
        _error = 'Failed to fetch settings: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error fetching settings: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user settings
  Future<bool> updateUserSettings({
    String? currency,
    String? language,
    bool? emailNotifications,
    bool? pushNotifications,
    String? theme,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final body = <String, dynamic>{};
      if (currency != null) body['currency'] = currency;
      if (language != null) body['language'] = language;
      if (emailNotifications != null) body['notifications'] = {'email': emailNotifications};
      if (pushNotifications != null) body['notifications'] = {'push': pushNotifications};
      if (theme != null) body['theme'] = theme;

      final response = await _httpClient.put('/user/settings', body);
      
      if (response['status'] == 'success') {
        _userSettings = response['data'];
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update settings: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating settings: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user password
  Future<bool> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final body = {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      };

      final response = await _httpClient.put('/user/password', body);
      
      if (response['status'] == 'success') {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update password: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error updating password: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _httpClient.get('/user/profile');
      
      if (response['status'] == 'success') {
        notifyListeners();
        return response['data'];
      } else {
        _error = 'Failed to get profile: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return null;
      }
    } catch (e) {
      _error = 'Error getting profile: $e';
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Delete user account
  Future<bool> deleteAccount() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _httpClient.delete('/user/account');
      
      if (response['status'] == 'success') {
        _userProfile = null;
        _userSettings = null;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to delete account: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error deleting account: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clear() {
    _userProfile = null;
    _userSettings = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Remove profile picture
  Future<bool> removeProfilePicture() async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final response = await _httpClient.delete('/user/profile/picture');
      
      if (response['status'] == 'success') {
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to remove profile picture: ${response['message'] ?? 'Unknown error'}';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error removing profile picture: $e';
      notifyListeners();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
} 