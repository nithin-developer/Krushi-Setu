import 'package:dio/dio.dart';
import 'package:krushi_setu/core/constants/app_constants.dart';
import 'package:krushi_setu/core/storage/local_storage.dart';

class DioClient {
  late final Dio _dio;
  bool _isRefreshing = false;

  DioClient() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = LocalStorage.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        if (error.response?.statusCode == 401 && !_isRefreshing) {
          _isRefreshing = true;
          try {
            final refreshToken = LocalStorage.refreshToken;
            if (refreshToken == null) {
               _isRefreshing = false;
               return handler.next(error);
            }
            
            // Call refresh endpoint
            final response = await _dio.post('/auth/refresh', data: {
              'refresh_token': refreshToken,
            });
            
            if (response.statusCode == 200) {
              final newAccessToken = response.data['access_token'];
              final newRefreshToken = response.data['refresh_token'];
              
              await LocalStorage.saveTokens(newAccessToken, newRefreshToken);
              
              // Retry the original request
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              
              final cloneReq = await _dio.request(
                error.requestOptions.path,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                ),
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
              );
              
              _isRefreshing = false;
              return handler.resolve(cloneReq);
            }
          } catch (e) {
            _isRefreshing = false;
            // Refresh failed, maybe logout
            await LocalStorage.clearTokens();
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Dio get dio => _dio;
}
