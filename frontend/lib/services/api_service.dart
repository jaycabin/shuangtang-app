import 'package:dio/dio.dart';
import 'package:hive/hive.dart';
import '../constants/constants.dart';

/// 双糖 REST API 服务层 — 调用 Go 后端所有接口
class ApiService {
  late final Dio _dio;
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final box = Hive.box('settings');
        final token = box.get(AppConstants.tokenKey);
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        final lang = box.get(AppConstants.languageKey, defaultValue: 'zh');
        options.headers['Accept-Language'] = lang;
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          Hive.box('settings').delete(AppConstants.tokenKey);
        }
        handler.next(error);
      },
    ));
  }

  // ========== Auth ==========
  Future<Map<String, dynamic>> sendCode(String email) =>
      _post('/auth/send-code', {'email': email});

  Future<Map<String, dynamic>> register(String email, String password, String code, {String nickname = ''}) =>
      _post('/auth/register', {'email': email, 'password': password, 'verification_code': code, 'nickname': nickname});

  Future<Map<String, dynamic>> login(String email, String password) async {
    final r = await _post('/auth/login', {'email': email, 'password': password});
    if (r['data'] != null) {
      await Hive.box('settings').put(AppConstants.tokenKey, r['data']['token']);
      await Hive.box('settings').put(AppConstants.userKey, r['data']['user']);
    }
    return r;
  }

  Future<Map<String, dynamic>> forgotPassword(String email) =>
      _post('/auth/forgot-password', {'email': email});

  Future<Map<String, dynamic>> resetPassword(String email, String code, String newPass) =>
      _post('/auth/reset-password', {'email': email, 'code': code, 'new_password': newPass});

  // ========== Couple ==========
  Future<Map<String, dynamic>> getCoupleInfo() => _get('/couple/info');
  Future<Map<String, dynamic>> createCouple({String nickname = ''}) => _post('/couple/create', {'nickname': nickname});
  Future<Map<String, dynamic>> joinCouple(String code) => _post('/couple/join', {'invitation_code': code});

  // ========== Moments ==========
  Future<Map<String, dynamic>> getTimeline({String? cursor}) =>
      _get('/timeline', params: cursor != null ? {'cursor': cursor} : null);

  Future<Map<String, dynamic>> createMoment(Map<String, dynamic> data) =>
      _post('/moments', data);

  // ========== Anniversaries ==========
  Future<Map<String, dynamic>> getAnniversaries() => _get('/anniversaries');
  Future<Map<String, dynamic>> createAnniversary(Map<String, dynamic> data) => _post('/anniversaries', data);

  // ========== Check-in ==========
  Future<Map<String, dynamic>> getCheckInTasks() => _get('/checkin/tasks');
  Future<Map<String, dynamic>> doCheckIn(String taskId) => _post('/checkin/$taskId', {});
  Future<Map<String, dynamic>> claimWish(String id) => _post('/wishlist/$id/claim', {});
  Future<Map<String, dynamic>> completeWish(String id) => _post('/wishlist/$id/complete', {});
  Future<Map<String, dynamic>> readSecretMessage(String id) => _post('/secret-messages/$id/read', {});

  // ========== Secret Messages ==========
  Future<Map<String, dynamic>> getSecretMessages() => _get('/secret-messages');
  Future<Map<String, dynamic>> sendSecretMessage(String content) => _post('/secret-messages', {'content': content});
  Future<Map<String, dynamic>> readSecretMessage(String id) => _post('/secret-messages/$id/read', {});

  // ========== Albums ==========
  Future<Map<String, dynamic>> getAlbums() => _get('/albums');

  Future<Map<String, dynamic>> uploadPhoto(String filePath) async {
    final form = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath),
    });
    final r = await _dio.post('/albums/upload', data: form);
    return r.data;
  }

  // ========== Alarms ==========
  Future<Map<String, dynamic>> createAlarm(Map<String, dynamic> data) => _post('/alarms', data);

  // ========== Helpers ==========
  Future<Map<String, dynamic>> _get(String path, {Map<String, dynamic>? params}) async {
    final r = await _dio.get(path, queryParameters: params);
    return r.data;
  }

  Future<Map<String, dynamic>> _post(String path, dynamic data) async {
    final r = await _dio.post(path, data: data);
    return r.data;
  }
}
