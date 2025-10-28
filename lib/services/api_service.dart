import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:infinicard/services/contact_storage_service.dart';

class ApiService {
  // Health check configuration
  Timer? _healthCheckTimer;
  static const Duration _healthCheckInterval = Duration(seconds: 30);
  bool _isHealthy = true;

  /// Get user info (profile)
  Future<Map<String, dynamic>?> getUserInfo() async {
    final result = await getProfile();
    if (result['success'] == true && result['data'] != null) {
      return result['data'] as Map<String, dynamic>;
    }
    return null;
  }

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // API Base URL - Use 10.0.2.2 for Android Emulator (maps to localhost on host)
  // For physical devices, use your computer's local IP (e.g., http://192.168.1.100:3000/api)
  static const String baseUrl =
  // 'https://truthful-vivienne-bishopless.ngrok-free.dev/api';
  'https://truthful-vivienne-bishopless.ngrok-free.dev/api';
  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';
  static const String _userNameKey = 'user_name';

  // Current tokens
  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;

  // Get headers with authorization
  Map<String, String> _getHeaders({bool includeAuth = false}) {
    final headers = {'Content-Type': 'application/json'};

    if (includeAuth && _accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }

    return headers;
  }

  // Generic message shown to users for unexpected errors.
  // Detailed error information should not be exposed to end-users.
  static const String _genericErrorMessage =
      'Something went wrong. Please try again.';

  /// Check API health
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/health'), headers: _getHeaders())
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

  /// Start periodic health checks
  void _startHealthCheck() {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = Timer.periodic(_healthCheckInterval, (timer) async {
      if (_accessToken != null) {
        final healthy = await checkHealth();

        if (!healthy && _isHealthy) {
          // Connection lost
          _isHealthy = false;
          print('Connection lost, attempting to reconnect...');
        } else if (healthy && !_isHealthy) {
          // Connection restored, re-authenticate
          _isHealthy = true;
          print('Connection restored, re-authenticating...');
          await _reAuthenticate();
        }
      }
    });
  }

  /// Re-authenticate user if tokens exist
  Future<void> _reAuthenticate() async {
    try {
      if (_accessToken != null) {
        // Try to get profile to verify token is still valid
        final result = await getProfile();
        if (result['success'] == true) {
          print('Re-authentication successful');
        } else {
          print('Token invalid, user needs to login again');
          await clearTokens();
        }
      }
    } catch (e) {
      print('Re-authentication failed: $e');
    }
  }

  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString(_accessTokenKey);
      _refreshToken = prefs.getString(_refreshTokenKey);

      if (_accessToken != null) {
        final userId = prefs.getString(_userIdKey);
        final userEmail = prefs.getString(_userEmailKey);
        final userName = prefs.getString(_userNameKey);
        _currentUser = {'id': userId, 'email': userEmail, 'username': userName};

        // Start health monitoring
        _startHealthCheck();

        return true;
      }

      return false;
    } catch (e) {
      print('Error initializing ApiService: $e');
      return false;
    }
  }

  // Save tokens to storage
  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    Map<String, dynamic> user,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_userIdKey, user['id'] ?? '');
      await prefs.setString(_userEmailKey, user['email'] ?? '');
      await prefs.setString(_userNameKey, user['username'] ?? '');

      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _currentUser = user;

      // Start health monitoring after successful login
      _startHealthCheck();
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // Clear tokens (logout)
  Future<void> clearTokens() async {
    try {
      // Stop health checks
      _healthCheckTimer?.cancel();
      _healthCheckTimer = null;
      _isHealthy = true;

      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_userIdKey);
      await prefs.remove(_userEmailKey);
      await prefs.remove(_userNameKey);

      _accessToken = null;
      _refreshToken = null;
      _currentUser = null;
    } catch (e) {
      print('Error clearing tokens: $e');
    }
  }

  // Check if user is authenticated
  bool get isAuthenticated => _accessToken != null;

  // Get current user
  Map<String, dynamic>? get currentUser => _currentUser;

  // Get health status
  bool get isHealthy => _isHealthy;

  // Dispose timer when no longer needed
  void dispose() {
    _healthCheckTimer?.cancel();
  }

  // ========== AUTHENTICATION ENDPOINTS ==========

  /// Register new user
  Future<Map<String, dynamic>> register({
    required String email,
    required String username,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: _getHeaders(),
        body: jsonEncode({
          'email': email,
          'username': username,
          'password': password,
          'fullName': fullName,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // Save tokens
        await _saveTokens(
          data['data']['accessToken'],
          data['data']['refreshToken'],
          data['data']['user'],
        );
        return {'success': true, 'user': data['data']['user']};
      } else {
        // Defensive: ensure errors is always a list
        final errors = (data['errors'] is List)
            ? data['errors']
            : (data['errors'] != null ? [data['errors']] : []);
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'errors': errors,
        };
      }
    } catch (e) {
      // Log detailed error for devs; show a generic message to users.
      print('ApiService error (register): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Login user
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save tokens
        await _saveTokens(
          data['data']['accessToken'],
          data['data']['refreshToken'],
          data['data']['user'],
        );

        return {'success': true, 'user': data['data']['user']};
      } else {
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      }
    } catch (e) {
      print('ApiService error (login): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Logout user
  Future<void> logout() async {
    // Clear auth tokens and user info
    await clearTokens();

    // Clear local contact cache (CSV cache)
    try {
      final storage = ContactStorageService();
      await storage.clearCache();
    } catch (e) {
      print('Error clearing contact storage cache: $e');
    }

    // Clear all SharedPreferences (app user data)
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      print('Error clearing shared preferences: $e');
    }
  }

  /// Get user profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get profile',
        };
      }
    } catch (e) {
      print('ApiService error (getProfile): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Update profile
  Future<Map<String, dynamic>> updateProfile({String? fullName}) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({if (fullName != null) 'fullName': fullName}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update profile',
        };
      }
    } catch (e) {
      print('ApiService error (updateProfile): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Upload profile image/avatar
  ///
  /// Notes/assumptions: The backend expects a multipart/form-data POST to
  /// /auth/profile/avatar with field name 'avatar'. If your backend uses a
  /// different path or field name, adjust accordingly.
  Future<Map<String, dynamic>> uploadProfileImage(String filePath) async {
    try {
      final uri = Uri.parse('$baseUrl/auth/profile/avatar');

      final request = http.MultipartRequest('POST', uri);
      // Attach auth header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      final file = File(filePath);
      final multipartFile = await http.MultipartFile.fromPath(
        'avatar',
        file.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Optionally refresh local profile cache
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload profile image',
        };
      }
    } catch (e) {
      print('ApiService error (uploadProfileImage): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to change password',
        };
      }
    } catch (e) {
      print('ApiService error (changePassword): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  // ========== BUSINESS CARDS ENDPOINTS ==========

  /// Get all business cards
  Future<Map<String, dynamic>> getCards({
    String? search,
    bool? favorite,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null) queryParams['search'] = search;
      if (favorite != null) queryParams['favorite'] = favorite.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        '$baseUrl/cards',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        // Include Authorization header only when an access token exists.
        headers: _getHeaders(includeAuth: _accessToken != null),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get cards',
        };
      }
    } catch (e) {
      print('ApiService error (getCards): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Get card by ID
  Future<Map<String, dynamic>> getCard(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards/$id'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get card',
        };
      }
    } catch (e) {
      print('ApiService error (getCard): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Get public card by ID (no authentication required)
  /// This is used for sharing - anyone with the link can view the card
  Future<Map<String, dynamic>> getPublicCard(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards/public/$id'),
        headers: _getHeaders(includeAuth: false),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get card',
        };
      }
    } catch (e) {
      print('ApiService error (getPublicCard): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Create business card
  Future<Map<String, dynamic>> createCard({
    required String fullName,
    String? jobTitle,
    String? companyName,
    String? email,
    String? phone,
    String? website,
    String? address,
    String? notes,
    String? color,
    bool? isFavorite,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cards'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'fullName': fullName,
          if (jobTitle != null) 'jobTitle': jobTitle,
          if (companyName != null) 'companyName': companyName,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (website != null) 'website': website,
          if (address != null) 'address': address,
          if (notes != null) 'notes': notes,
          if (color != null) 'color': color,
          if (isFavorite != null) 'isFavorite': isFavorite,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create card',
        };
      }
    } catch (e) {
      print('ApiService error (createCard): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Update business card
  Future<Map<String, dynamic>> updateCard(
    String id,
    Map<String, dynamic> updates,
  ) async {
    if (updates.isEmpty) {
      return {'success': false, 'message': 'No updates provided'};
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/cards/$id'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode(updates),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update card',
        };
      }
    } catch (e) {
      print('ApiService error (updateCard): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Delete business card
  Future<Map<String, dynamic>> deleteCard(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/cards/$id'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete card',
        };
      }
    } catch (e) {
      print('ApiService error (deleteCard): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Toggle favorite status
  Future<Map<String, dynamic>> toggleFavoriteCard(String id) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/cards/$id/favorite'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to toggle favorite',
        };
      }
    } catch (e) {
      print('ApiService error (toggleFavoriteCard): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Search cards
  Future<Map<String, dynamic>> searchCards(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cards/search?q=$query'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data'], 'count': data['count']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to search cards',
        };
      }
    } catch (e) {
      print('ApiService error (searchCards): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  // ========== NOTIFICATIONS ENDPOINTS ==========

  /// Fetch notifications
  Future<List<Map<String, dynamic>>> getNotifications() async {
    final url = Uri.parse('$baseUrl/notifications');
    final response = await http.get(
      url,
      headers: _getHeaders(includeAuth: true),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
    }
    throw Exception('Failed to fetch notifications');
  }

  /// Mark notification as read
  Future<bool> markNotificationAsRead(String id) async {
    final url = Uri.parse('$baseUrl/notifications/$id/read');
    final response = await http.patch(
      url,
      headers: _getHeaders(includeAuth: true),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  /// Delete notification
  Future<bool> deleteNotification(String id) async {
    final url = Uri.parse('$baseUrl/notifications/$id');
    final response = await http.delete(
      url,
      headers: _getHeaders(includeAuth: true),
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['success'] == true;
    }
    return false;
  }

  // ========== DISCOVER ENDPOINTS ==========

  /// Get professionals for discover page
  Future<Map<String, dynamic>> getProfessionals({
    String? location,
    String? field,
    String? search,
    int? limit,
    int? offset,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (location != null && location != 'All') {
        queryParams['location'] = location;
      }
      if (field != null && field != 'All') queryParams['field'] = field;
      if (search != null) queryParams['search'] = search;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (offset != null) queryParams['offset'] = offset.toString();

      final uri = Uri.parse(
        '$baseUrl/discover/professionals',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data['data'],
          'pagination': data['pagination'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get professionals',
        };
      }
    } catch (e) {
      print('ApiService error (getProfessionals): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Send connection request
  Future<Map<String, dynamic>> sendConnectionRequest({
    required String receiverId,
    String? message,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/discover/connections/request'),
        headers: _getHeaders(includeAuth: true),
        body: jsonEncode({
          'receiverId': receiverId,
          if (message != null) 'message': message,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send connection request',
        };
      }
    } catch (e) {
      print('ApiService error (sendConnectionRequest): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Get user's connections
  Future<Map<String, dynamic>> getConnections({String? status}) async {
    try {
      final queryParams = <String, String>{};
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$baseUrl/discover/connections',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get connections',
        };
      }
    } catch (e) {
      print('ApiService error (getConnections): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Accept connection request
  Future<Map<String, dynamic>> acceptConnection(String connectionId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/discover/connections/$connectionId/accept'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to accept connection',
        };
      }
    } catch (e) {
      print('ApiService error (acceptConnection): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Reject connection request
  Future<Map<String, dynamic>> rejectConnection(String connectionId) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/discover/connections/$connectionId/reject'),
        headers: _getHeaders(includeAuth: true),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to reject connection',
        };
      }
    } catch (e) {
      print('ApiService error (rejectConnection): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Get available locations
  Future<Map<String, dynamic>> getLocations() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discover/locations'),
        headers: _getHeaders(includeAuth: _accessToken != null),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get locations',
        };
      }
    } catch (e) {
      print('ApiService error (getLocations/getFields): $e');
      return {'success': false, 'message': _genericErrorMessage};
    }
  }

  /// Get available fields
  Future<Map<String, dynamic>> getFields() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discover/fields'),
        headers: _getHeaders(includeAuth: _accessToken != null),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to get fields',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }
}
