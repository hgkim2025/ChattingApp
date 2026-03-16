import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:chattingapp/util/api/loading_provider.dart';
import 'package:chattingapp/util/db/db_provider.dart';
import 'package:chattingapp/util/log.dart';
import 'package:dio/dio.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

String dioJWT = '';
String dioAuthHeader = 'Bearer';
final bool isLogging = true;
final bool isDebug = kDebugMode;
// final bool isDebug = true;

enum ApiLoadingType {
  global,
  local,
  none;
}

class DioClient {
  // JWT TOKEN이 무조건 있어야 함
  static Dio client = _defaultClient();
  static Dio clientLocalLoading = _defaultClientLocalLoading();
  static Dio clientNoneLoading = _defaultClientNoneLoading();

  static Dio multipartClient = _multipartClient();
  static Dio multipartClientLocalLoading = _multipartClientLocalLoading();
  static Dio multipartClientNoneLoading = _multipartClientNoneLoading();

  static final Dio fileAuthClient = _fileAuthClient();
  static final Dio aliFileClient = _aliFileClient();

  static Dio getClient(ApiLoadingType loadingType) {
    switch (loadingType) {
      case ApiLoadingType.global:
        return client;
      case ApiLoadingType.local:
        return clientLocalLoading;
      case ApiLoadingType.none:
        return clientNoneLoading;
    }
  }

  static Dio getMultipartClient(ApiLoadingType loadingType) {
    switch (loadingType) {
      case ApiLoadingType.global:
        return multipartClient;
      case ApiLoadingType.local:
        return multipartClientLocalLoading;
      case ApiLoadingType.none:
        return multipartClientNoneLoading;
    }
  }

  static Dio _defaultClient() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 10000);
    dio.interceptors.add(PalloInterceptors());
    // debugPrint('DioClient._defaultClient: ${dio.options.headers["Authorization"]}');
    return dio;
  }

  static Dio _defaultClientLocalLoading() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 10000);
    dio.interceptors.add(PalloInterceptors(loadingType: ApiLoadingType.local));
    return dio;
  }

  static Dio _defaultClientNoneLoading() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.options.connectTimeout = const Duration(milliseconds: 10000);
    dio.options.receiveTimeout = const Duration(milliseconds: 10000);
    dio.interceptors.add(PalloInterceptors(loadingType: ApiLoadingType.none));
    return dio;
  }

  static Dio _multipartClient() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.options.connectTimeout = const Duration(milliseconds: 60000);
    dio.options.receiveTimeout = const Duration(milliseconds: 60000);
    dio.interceptors.add(PalloInterceptors());
    return dio;
  }

  static Dio _multipartClientLocalLoading() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.options.connectTimeout = const Duration(milliseconds: 60000);
    dio.options.receiveTimeout = const Duration(milliseconds: 60000);
    dio.interceptors.add(PalloInterceptors(loadingType: ApiLoadingType.none));
    return dio;
  }


  static Dio _multipartClientNoneLoading() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.options.connectTimeout = const Duration(milliseconds: 60000);
    dio.options.receiveTimeout = const Duration(milliseconds: 60000);
    dio.interceptors.add(PalloInterceptors(loadingType: ApiLoadingType.none));
    return dio;
  }

  refreshJWT() {
    Dio dio = Dio();
    dio.options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    dio.interceptors.add(PalloInterceptors());
    client = dio;
  }

  static Dio _fileAuthClient() {
    int millis = DateTime.now().millisecondsSinceEpoch;
    int tokenMillis = millis + 1200;
    var key = utf8.encode('pallo@@fighting^^');
    var bytes = utf8.encode(tokenMillis.toString());
    var hmacSha256 = Hmac(sha256, key);
    Digest sha256Result = hmacSha256.convert(bytes);

    Dio dio = Dio();
    dio.options.headers['token'] = sha256Result;
    dio.options.headers['request_time'] = millis;

    return dio;
  }

  static Dio _aliFileClient() {
    Dio dio = Dio(
      BaseOptions(
        baseUrl:
            'https://alifn.tgclab.com', // 'https://oss-api-gyidqatmja.ap-northeast-2.fcapp.run',
      ),
    );
    return dio;
  }
}

class PalloInterceptors extends Interceptor {
  final ApiLoadingType loadingType;

  PalloInterceptors({this.loadingType = ApiLoadingType.global});

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {

    // 로딩 카운트 증가
    switch (loadingType) {
      case ApiLoadingType.global:
        incrementLoadingCountGlobal();
        break;
      case ApiLoadingType.local:
        incrementLoadingCountLocal();
        break;
      case ApiLoadingType.none:
        break;
    }

    if (dioJWT == '' || options.headers["Authorization"] == '$dioAuthHeader ') {
      final container = getGlobalProviderContainer();
      if (container != null) {
        final userDao = container.read(userDaoProvider);
        final user = await userDao.getLoggedInUser();
        dioJWT = user?.accessToken ?? '';
      }
      options.headers["Authorization"] = "$dioAuthHeader $dioJWT";
    }

    // remove Authorization header for login url
    if (options.uri.toString().contains(ApiConstants.to.loginUrl)) {
      options.headers.remove("Authorization");
    }

    // Log
    const List<Tag> tags = [Tag.API, Tag.REQUEST];
    final url = _parseUri(options.uri);

    if (isLogging && isDebug) {
      pLog.tags(tags).xd("┌ 🚀 ——→ $_endSeparator");
      pLog.tags(tags).xd('│ 🚀 [URL] - [${options.method}] $url');
      pLog.tags(tags).xd('│ 🚀 [HEADERS] - ${options.headers.toPrettyString(withBoxSeparator: false)}');
      final data = options.data;
      if (data is Map<String, dynamic>) {
        pLog.tags(tags).xd('│ 🚀 [BODY] - ${data.toPrettyString(withBoxSeparator: false)}');
      } else {
        pLog.tags(tags).xd('│ 🚀 [BODY] - $data');
      }
      pLog.tags(tags).xd('└ 🚀 ——→  $_endSeparator');
    }

    return super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final failed = response.statusCode != HttpStatus.ok;
    final emoji = failed ? '❌' : '✅';
    List<Tag> tags = [Tag.API, Tag.RESPONSE];

    if (isLogging && isDebug) {
      pLog.tags(tags).xd("┌ $emoji ←—— $_endSeparator");
      pLog
          .tags(tags)
          .xd(
            '│ $emoji [URL] - [${response.requestOptions.method}] ${_parseUri(response.requestOptions.uri)}',
          );
      pLog
          .tags(tags)
          .xd(
            '│ $emoji [HEADERS] - ${response.requestOptions.headers.toPrettyString(withBoxSeparator: false)}',
          );
      pLog.tags(tags).xd('│ $emoji [CODE] - ${response.statusCode}');
      final responseData = response.data;
      if (responseData is Map<String, dynamic>) {
        pLog.tags(tags).xd('│ $emoji [BODY] - ${responseData.toPrettyString(withBoxSeparator: false)}');
      } else {
        pLog.tags(tags).xd('│ $emoji [BODY] - $responseData');
      }
      pLog.tags(tags).xd('└ $emoji  ←—— $_endSeparator');
    }

    switch (loadingType) {
      case ApiLoadingType.global:
        decrementLoadingCountGlobal();
        break;
      case ApiLoadingType.local:
        decrementLoadingCountLocal();
        break;
      case ApiLoadingType.none:
        break;
    }
    return super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    switch (loadingType) {
      case ApiLoadingType.global:
        decrementLoadingCountGlobal();
        break;
      case ApiLoadingType.local:
        decrementLoadingCountLocal();
        break;
      case ApiLoadingType.none:
        break;
    }

    if (err.response?.statusCode == 401) {
      final dio = Dio();
      final container = getGlobalProviderContainer();
      if (container == null) {
        return;
      }
      final userDao = container.read(userDaoProvider);
      final user = await userDao.getLoggedInUser();
      final refreshToken = user?.refreshToken;

      final response = await dio.post(
        ApiConstants.to.refreshTokenUrl,
        data: {'refresh': refreshToken},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map<String, dynamic> && data.containsKey('access')) {
          dioJWT = data['access'];
          final refreshToken = data['refresh'];

          final userDao = container.read(userDaoProvider);
          final user = await userDao.getLoggedInUser();
          if (user != null) {
            await userDao.updateUserTokens(
              id: user.id,
              accessToken: dioJWT,
              refreshToken: refreshToken,
            );
          }

          final options = err.requestOptions;
          options.headers["Authorization"] = "$dioAuthHeader $dioJWT";

          final result = await dio.fetch(options);
          return handler.resolve(result);
        } else {
          logout();
        }
      }
    }

    if (isLogging && isDebug) {
      const List<Tag> tags = [Tag.API, Tag.ERROR];
      pLog.tags(tags).xe("┌ ❌ ←—— $_endSeparator");
      pLog
          .tags(tags)
          .xe(
            '│ ❌ [URL] - [${err.requestOptions.method}] ${_parseUri(err.requestOptions.uri)}',
          );
      pLog
          .tags(tags)
          .xe('│ ❌ [HEADERS] - ${err.requestOptions.headers.toPrettyString(withBoxSeparator: false)}');
      pLog.tags(tags).xe('│ ❌ [ERROR] - ${err.error}');

      if (err.response != null) {
        pLog.tags(tags).xe('│ ❌ [STATUS] - ${err.response?.statusCode}');
        final responseData = err.response?.data;
        if (responseData is Map<String, dynamic>) {
          pLog.tags(tags).xe('│ ❌ [BODY] - ${responseData.toPrettyString(withBoxSeparator: false)}');
        } else {
          pLog.tags(tags).xe('│ ❌ [BODY] - $responseData');
        }
      } 
      pLog.tags(tags).xe('└ ❌$_endSeparator');
    }

    String errorMessage = StringKey.alertServerError.value;
    if (err.response?.data != null) {
      final responseData = err.response!.data;
      if (responseData is Map<String, dynamic> &&
          responseData.containsKey('code')) {
        errorMessage = responseData['code'].toString();
      }
    }

    return handler.resolve(
      Response(
        requestOptions: err.requestOptions,
        data: {'s': false, 'code': errorMessage},
        statusCode: err.response?.statusCode ?? 500,
      ),
    );
  }

  String get _endSeparator {
    return '——————————————————————————————————————————————————————————————————————';
  }

  String _parseUri(Uri? uri) {
    if (uri == null) {
      return 'NULL';
    }
    final path = uri.path.isEmpty ? '/' : uri.path;
    final queryPart =
        uri.query.isNotEmpty ? '?${uri.query}' : '';
    return path + queryPart;
  }
}


class ApiConstants {
  static final ApiConstants to = ApiConstants._();
  ApiConstants._();

  String signupUrl = '${BASE_URL}/api/signup/';
  String loginUrl = '${BASE_URL}/api/login/';
  String refreshTokenUrl = '${BASE_URL}/api/token/refresh/';
}

String get BASE_URL {
  // return apiUrl;
  // Android 에뮬레이터/기기: localhost는 기기 자신을 가리킴 → 호스트 PC는 10.0.2.2
  if (Platform.isAndroid) {
    return "http://10.0.2.2:8000";
  }
  return "http://localhost:8000";
  // return "http://pi-test.tgclab.com";
}

enum StringKey {
  alertServerError('alert_server_error_msg'),
  ok('ok'),
  error('error');

  final String value;
  const StringKey(this.value);
}
