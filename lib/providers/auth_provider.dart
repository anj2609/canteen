import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../core/api_service.dart';
import '../core/constants.dart';
import '../core/storage_service.dart';
import '../models/user_model.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    User? user,
    bool clearUser = false,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      user: clearUser ? null : (user ?? this.user),
      error: error,
    );
  }
}

class AuthController extends StateNotifier<AuthState> {
  final ApiService _apiService;

  AuthController(this._apiService) : super(AuthState());

  Future<void> checkAuthStatus() async {
    final token = storageService.getString(AppConstants.authTokenKey);
    if (token != null && !JwtDecoder.isExpired(token)) {
      // Token exists and is valid
      state = AuthState(isAuthenticated: true, isLoading: true);
      try {
        await fetchProfile();
      } catch (e) {
        // Profile fetch failed - clear auth
        await signOut();
      }
    } else {
      // No token or expired
      if (token != null) {
        // Clear expired token
        await signOut();
      }
      state = AuthState(isAuthenticated: false, isLoading: false);
    }
  }

  Future<void> fetchProfile() async {
    // The API doesn't have a /users/me endpoint
    // We already have user data from the JWT token in verifyOtp
    // So we just need to maintain the authenticated state
    try {
      if (state.user != null) {
        state = state.copyWith(isLoading: false, error: null);
      } else {
        // If we have a token but no user, decode it again
        final token = storageService.getString(AppConstants.authTokenKey);
        if (token != null && !JwtDecoder.isExpired(token)) {
          Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

          // Retrieve all stored user data
          final storedEmail = storageService.getString(
            AppConstants.userEmailKey,
          );
          final storedName = storageService.getString(AppConstants.userNameKey);
          final storedId = storageService.getString(AppConstants.userIdKey);
          final storedRole = storageService.getString(AppConstants.userRoleKey);

          final user = User(
            id: storedId ?? decodedToken['id'] ?? decodedToken['_id'] ?? '',
            email: storedEmail ?? decodedToken['email'] ?? 'user@example.com',
            name: storedName ?? decodedToken['name'] ?? 'User',
            role: storedRole ?? decodedToken['role'] ?? 'user',
          );
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            user: user,
          );
        } else {
          // Token expired or invalid - sign out
          await signOut();
        }
      }
    } catch (e) {
      debugPrint('Fetch profile failed: $e');
      state = state.copyWith(isLoading: false, error: null);
    }
  }

  Future<bool> sendOtp(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiService.client.post(
        '/auth/email/send-otp',
        data: {'email': email},
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Failed to send OTP';
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data is String) {
        errorMessage = data;
      } else if (e.message != null) {
        errorMessage = e.message!;
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Unexpected error: $e');
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiService.client.post(
        '/auth/email/verify-otp',
        data: {'email': email, 'otp': otp},
      );

      final token = response.data['token'];
      if (token == null) throw Exception('No token received');

      await storageService.setString(AppConstants.authTokenKey, token);

      // Decode Token to get User Details
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Expected claims: { id: "...", email: "...", role: "...", name: "..." }
      // If name is missing, use email part.
      final userEmail = decodedToken['email'] ?? email;
      final userName = decodedToken['name'] ?? email.split('@')[0];

      final user = User(
        id: decodedToken['id'] ?? decodedToken['_id'] ?? '',
        email: userEmail,
        name: userName,
        role: decodedToken['role'] ?? 'user',
      );

      // Store all user data persistently
      await storageService.setString(AppConstants.userEmailKey, userEmail);
      await storageService.setString(AppConstants.userNameKey, userName);
      await storageService.setString(AppConstants.userIdKey, user.id);
      await storageService.setString(AppConstants.userRoleKey, user.role);

      state = AuthState(isAuthenticated: true, isLoading: false, user: user);
      return true;
    } on DioException catch (e) {
      String errorMessage = 'Invalid OTP';
      final data = e.response?.data;
      if (data is Map && data.containsKey('message')) {
        errorMessage = data['message'];
      } else if (data is String) {
        errorMessage = data;
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
      return false;
    }
  }

  Future<void> signOut() async {
    await storageService.remove(AppConstants.authTokenKey);
    await storageService.remove(AppConstants.userEmailKey);
    await storageService.remove(AppConstants.userNameKey);
    await storageService.remove(AppConstants.userIdKey);
    await storageService.remove(AppConstants.userRoleKey);
    state = AuthState(isAuthenticated: false);
  }

  Future<bool> deleteAccount() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      await _apiService.client.delete('/auth/me');

      // Clear all local data
      await storageService.remove(AppConstants.authTokenKey);
      await storageService.remove(AppConstants.userEmailKey);
      await storageService.remove(AppConstants.userNameKey);
      await storageService.remove(AppConstants.userIdKey);
      await storageService.remove(AppConstants.userRoleKey);

      // Reset state
      state = AuthState(isAuthenticated: false);

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: ${e.toString()}',
      );
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(ApiService());
});
