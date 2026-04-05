import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/app_constants.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  late Dio _dio;
  final _storage = const FlutterSecureStorage();

  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(milliseconds: AppConstants.connectTimeout),
      receiveTimeout: const Duration(milliseconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: AppConstants.storageTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        return handler.next(response);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          // Token expired, clear storage
          await _storage.delete(key: AppConstants.storageTokenKey);
        }
        return handler.next(error);
      },
    ));
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: AppConstants.storageTokenKey, value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: AppConstants.storageTokenKey);
  }

  Future<void> clearToken() async {
    await _storage.delete(key: AppConstants.storageTokenKey);
  }

  // Auth endpoints
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/auth/register', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/auth/login', data: data);
    if (response.data['success'] == true) {
      await saveToken(response.data['token']);
    }
    return response.data;
  }

  Future<Map<String, dynamic>> changePassword(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/auth/change-password', data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final response = await _dio.get('/api/auth/me');
    return response.data;
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/auth/logout');
    } catch (e) {
      // Ignore errors on logout
    }
    await clearToken();
  }

  // Application endpoints
  Future<Map<String, dynamic>> createApplication(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/api/applications', data: data);
    return response.data;
  }

  Future<List<dynamic>> listApplications({String? status}) async {
    final query = status != null ? '?status=$status' : '';
    final response = await _dio.get('/api/applications$query');
    return response.data['applications'];
  }

  Future<Map<String, dynamic>> getApplication(String id) async {
    final response = await _dio.get('/api/applications/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> updateApplication(
      String id, Map<String, dynamic> data) async {
    final response = await _dio.put('/api/applications/$id', data: data);
    return response.data;
  }

  // NEW: Delete application
  Future<Map<String, dynamic>> deleteApplication(String id) async {
    final response = await _dio.delete('/api/applications/$id');
    return response.data;
  }

  Future<Map<String, dynamic>> submitApplication(String id) async {
    final response = await _dio.post('/api/applications/$id/submit');
    return response.data;
  }

  // Document endpoints
  Future<Map<String, dynamic>> getUploadUrl(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/documents/upload-url', data: data);
    return response.data;
  }

  Future<void> uploadDocument(
      String uploadKey, List<int> fileBytes, String contentType) async {
    await _dio.put(
      '/api/documents/upload/$uploadKey',
      data: Stream.fromIterable(fileBytes.map((e) => [e])),
      options: Options(
        headers: {'Content-Type': contentType},
      ),
    );
  }

  Future<List<int>> getDocument(String id) async {
    final response = await _dio.get(
      '/api/documents/$id',
      options: Options(responseType: ResponseType.bytes),
    );
    return response.data;
  }

  Future<void> deleteDocument(String id) async {
    await _dio.delete('/api/documents/$id');
  }

  // Pre-qualify application
  Future<void> preQualify(
      String applicationId, Map<String, dynamic> preQualData) async {
    await _dio.post('/api/applications/$applicationId/pre-qualify', data: {
      'pre_qualification_data': preQualData,
    });
  }

  // FIXED: Get risk readiness - handles non-200 responses
  Future<Map<String, dynamic>> getRiskReadiness(String applicationId) async {
    try {
      final response =
          await _dio.post('/api/applications/$applicationId/risk-readiness');
      return response.data;
    } on DioException catch (e) {
      // If the response has data, return it (even if status code is not 200)
      if (e.response?.data != null) {
        return e.response?.data as Map<String, dynamic>;
      }
      rethrow;
    }
  }

  // Get sites list
  Future<List<dynamic>> getSites() async {
    final response = await _dio.get('/api/sites');
    return response.data['sites'];
  }

  // Get site details
  Future<Map<String, dynamic>> getSite(String siteId) async {
    final response = await _dio.get('/api/sites/$siteId');
    return response.data;
  }

  // Create inspection
  Future<Map<String, dynamic>> createInspection(
      Map<String, dynamic> data) async {
    final response = await _dio.post('/api/inspections', data: data);
    return response.data;
  }

  // Create renewal
  Future<Map<String, dynamic>> createRenewal(String siteId) async {
    final response =
        await _dio.post('/api/renewals', data: {'site_id': siteId});
    return response.data;
  }

  // Get expiring licenses
  Future<List<dynamic>> getExpiringLicenses() async {
    final response = await _dio.get('/api/compliance/expiring');
    return response.data['expiring'];
  }

  // Get pending renewals (officer)
  Future<List<dynamic>> getPendingRenewals() async {
    final response = await _dio.get('/api/renewals/pending');
    return response.data['renewals'];
  }

  // Approve renewal (officer)
  Future<void> approveRenewal(String renewalId, String newExpiryDate) async {
    await _dio.post('/api/renewals/$renewalId/approve', data: {
      'new_expiry_date': newExpiryDate,
    });
  }

  // Officer endpoints
  Future<List<dynamic>> getPendingApplications() async {
    final response = await _dio.get('/api/officer/pending');
    return response.data['applications'];
  }

  Future<Map<String, dynamic>> approveApplication(
      String id, String notes) async {
    final response = await _dio.post('/api/officer/approve', data: {
      'application_id': id,
      'notes': notes,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> rejectApplication(
      String id, String reason) async {
    final response = await _dio.post('/api/officer/reject', data: {
      'application_id': id,
      'reason': reason,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> requestInfo(String id, String message,
      {int deadlineDays = 7}) async {
    final response = await _dio.post('/api/officer/request-info', data: {
      'application_id': id,
      'message': message,
      'deadline_days': deadlineDays,
    });
    return response.data;
  }

  // Admin endpoints
  Future<List<dynamic>> listOfficers() async {
    final response = await _dio.get('/api/admin/officers');
    return response.data['officers'];
  }

  Future<Map<String, dynamic>> createOfficer(Map<String, dynamic> data) async {
    final response = await _dio.post('/api/admin/officers', data: data);
    return response.data;
  }
}
