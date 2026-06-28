import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../constants/constants.dart';

class ApiService {
  late final Dio _dio;
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;

  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept-Language': 'zh',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final box = Hive.box('settings');
        final token = box.get('auth_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        final lang = box.get('language_code', defaultValue: 'zh');
        options.headers['Accept-Language'] = lang;
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          // Token expired - redirect to login
        }
        handler.next(error);
      },
    ));
  }

  Future<Response> post(String path, {dynamic data}) =>
      _dio.post(path, data: data);

  Future<Response> get(String path, {Map<String, dynamic>? params}) =>
      _dio.get(path, queryParameters: params);

  Future<Response> upload(String path, FormData data) =>
      _dio.post(path, data: data);

  // Auth
  Future<Response> sendCode(String email) =>
      post('/auth/send-code', data: {'email': email});

  Future<Response> register(String email, String password, String code) =>
      post('/auth/register', data: {
        'email': email,
        'password': password,
        'verification_code': code,
      });

  Future<Response> login(String email, String password) =>
      post('/auth/login', data: {'email': email, 'password': password});

  // Couple
  Future<Response> createCouple() => post('/couple/create');
  Future<Response> joinCouple(String code) =>
      post('/couple/join', data: {'invitation_code': code});

  // Timeline
  Future<Response> getTimeline({String? cursor}) =>
      get('/timeline', params: cursor != null ? {'cursor': cursor} : null);

  // Moments
  Future<Response> createMoment(Map<String, dynamic> data) =>
      post('/moments', data: data);
}
