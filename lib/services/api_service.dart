import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
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

  // Initialize - Load saved tokens
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
    } catch (e) {
      print('Error saving tokens: $e');
    }
  }

  // Clear tokens (logout)
  Future<void> clearTokens() async {
    try {
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
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
          'errors': data['errors'],
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Logout user
  Future<void> logout() async {
    await clearTokens();
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
          'message': data['message'] ?? 'Failed to get cards',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  /// Update business card
  Future<Map<String, dynamic>> updateCard(
    String id,
    Map<String, dynamic> updates,
  ) async {
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
      return {'success': false, 'message': 'Network error: $e'};
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
}
