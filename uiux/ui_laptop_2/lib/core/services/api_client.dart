import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ApiClient {
  ApiClient({String? baseUrl})
      : _dio = Dio(
          BaseOptions(
            // ── LAN SETUP ──────────────────────────────────────────────────
            // This fallback is only used if null is passed in (shouldn't
            // happen in practice — the app always reads from SettingsService).
            //
            // Physical device on same Wi-Fi as your laptop:
            //   'http://192.168.x.x:8000'   ← your laptop's LAN IP
            //
            // Android emulator  → 'http://10.0.2.2:8000'
            // iOS simulator     → 'http://localhost:8000'
            //
            // Change via the app at runtime:
            //   Dashboard → ⚙ tune icon → Advanced Settings → Backend URL
            baseUrl: baseUrl ?? 'http://10.0.2.2:8000',
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 60),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Attach Firebase ID token on every request if user is signed in.
          final user = FirebaseAuth.instance.currentUser;
          if (user != null) {
            try {
              final token = await user.getIdToken();
              options.headers['Authorization'] = 'Bearer $token';
            } catch (e) {
              // Token refresh failed — proceed without header; backend will 401.
            }
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  final Dio _dio;

  Future<Response<dynamic>> get(String path,
          {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<dynamic>> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response<dynamic>> put(String path, {dynamic data}) =>
      _dio.put(path, data: data);

  Future<Response<dynamic>> delete(String path) => _dio.delete(path);
}