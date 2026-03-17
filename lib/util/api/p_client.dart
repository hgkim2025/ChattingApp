import 'dart:async';
import 'dart:io';

import 'package:chattingapp/util/api/dio_client.dart';
import 'package:chattingapp/util/api/loading_provider.dart';
import 'package:chattingapp/util/log.dart';
import 'package:chattingapp/util/route/router.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// TODO: - URL 등록 필요
const fileURL = '';
const jsonFileURL = '';
const jsonDirectoryURL = '';

typedef DataSetter<T> = FutureOr<void> Function(T data);

class PGet extends PClient {
  Map<String, dynamic> parameter;

  PGet({
    required String url,
    String errorTitle = 'error',
    Map<String, dynamic>? params,
    bool showErrorDialog = true,
    ApiLoadingType loadingType = ApiLoadingType.global,
  }) : parameter = params ?? {},
       super(
         url,
         errorTitle,
         showErrorDialog: showErrorDialog,
         loadingType: loadingType,
       );

  @override
  Future<dynamic> execute() async {
    dynamic result;
    try {
      String queryString = '';
      if (parameter.isNotEmpty) {
        queryString = '?${Uri(queryParameters: parameter).query}';
      }
      result = await DioClient.getClient(loadingType).get(url + queryString);
      await doResultCallback(result, errorTitle, url);
      return result;
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.GET).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PPost extends PClient {
  var body;

  PPost({
    required String url,
    required Map<String, dynamic> this.body,
    String errorTitle = 'error',
    bool showErrorDialog = true,
    ApiLoadingType loadingType = ApiLoadingType.global,
  }) : super(
         url,
         errorTitle,
         showErrorDialog: showErrorDialog,
         loadingType: loadingType,
       );

  @override
  Future<dynamic> execute() async {
    dynamic result;
    try {
      result = await DioClient.getClient(loadingType).post(url, data: body);
      await doResultCallback(result, errorTitle, url);
      return result;
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.POST).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PPostMultipart extends PClient {
  final dio.FormData formData;

  PPostMultipart({
    required String url,
    required this.formData,
    ApiLoadingType loadingType = ApiLoadingType.global,
    String errorTitle = 'error',
    bool showErrorDialog = true,
  }) : super(url, errorTitle, showErrorDialog: showErrorDialog);

  @override
  Future<dynamic> execute() async {
    dynamic result;
    try {
      result = await DioClient.getMultipartClient(
        loadingType,
      ).post(url, data: formData);
      await doResultCallback(result, errorTitle, url);
      return result;
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.POST).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PPut extends PClient {
  var data;

  PPut({
    required String url,
    required this.data,
    ApiLoadingType loadingType = ApiLoadingType.global,
    String errorTitle = 'error',
    bool showErrorDialog = true,
  }) : super(
         url,
         errorTitle,
         showErrorDialog: showErrorDialog,
         loadingType: loadingType,
       );

  @override
  Future<dynamic> execute() async {
    dynamic result;
    try {
      result = await DioClient.getClient(loadingType).put(url, data: data);
      await doResultCallback(result, errorTitle, url);
      return result;
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.PUT).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PDelete extends PClient {
  var request;

  PDelete({
    required String url,
    required Map<String, dynamic> this.request,
    String errorTitle = 'error',
    bool showErrorDialog = true,
    ApiLoadingType loadingType = ApiLoadingType.global,
  }) : super(
         url,
         errorTitle,
         showErrorDialog: showErrorDialog,
         loadingType: loadingType,
       );

  @override
  Future<dynamic> execute() async {
    dynamic result;
    try {
      result = await DioClient.getClient(
        loadingType,
      ).delete(url, data: request);
      await doResultCallback(result, errorTitle, url);
      return result;
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.DELETE).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

/// /////////////////////////////////////////////
/// File Upload / form data
/// /////////////////////////////////////////////
class PFileUploader extends PClient {
  String serverPathName;
  String filePath;
  String fileName;

  PFileUploader({
    required this.serverPathName,
    required this.filePath,
    required this.fileName,
    String errorTitle = 'error',
  }) : super(fileURL, errorTitle);

  @override
  Future<dynamic> execute() async {
    try {
      var formData = dio.FormData.fromMap({
        'path': serverPathName,
        'files': [
          await dio.MultipartFile.fromFile(filePath, filename: fileName),
        ],
      });

      var response = await DioClient.fileAuthClient.post(url, data: formData);
      await doResultCallback(response, 'file upload error', url);
      return response;
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FILE).tag(Tag.UPLOAD).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PFileUploadV2 extends PClientForm {
  PFileUploadV2({
    required String url,
    required dio.FormData formData,
    String errorTitle = 'error',
  }) : super(url, formData, errorTitle);

  @override
  Future<dynamic> execute() async {
    try {
      if (formData.files.isNotEmpty) {
        var response = await DioClient.aliFileClient.post(url, data: formData);
        await doResultCallback(response, 'file upload error', url);
        return response;
      } else {
        return null;
      }
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FILE).tag(Tag.UPLOAD).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PFilesUploader extends PClient {
  String serverPathName;
  List<File> files;

  PFilesUploader({
    required String url,
    required this.files,
    required this.serverPathName,
    String errorTitle = 'error',
  }) : super(url, errorTitle);

  @override
  Future<dynamic> execute() async {
    List<dio.MultipartFile> multiPartFiles = [];
    for (var file in files) {
      multiPartFiles.add(
        await dio.MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      );
    }

    try {
      var formData = dio.FormData.fromMap({
        'path': serverPathName,
        'files': multiPartFiles,
      });
      var response = await DioClient.fileAuthClient.post(
        fileURL,
        data: formData,
      );
      await doResultCallback(response, 'file upload error', url);
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FILE).tag(Tag.UPLOAD).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

/// /////////////////////////////////////////////
/// File/Directory 관련 JSON REQUEST
/// /////////////////////////////////////////////
class PFileDelete extends PClient {
  String filePath;

  PFileDelete({
    String? url,
    required this.filePath,
    String errorTitle = 'error',
  }) : super(url ?? jsonFileURL, errorTitle);

  @override
  Future<dynamic> execute() async {
    try {
      Map<String, dynamic> request = {"k": filePath};

      var response = await DioClient.fileAuthClient.delete(url, data: request);
      await doResultCallback(response, 'file upload error', url);
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FILE).tag(Tag.DELETE).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

///
/// ex 1) 이미지 파일 삭제
/// {
/// 	type: "file",
/// 	path: "timelapse/path/file.png"
/// }
///
/// ex 2) 디렉토리 삭제
/// {
/// 	type: "dir",
/// 	path: "timelapse/path"
/// }
class PFileDeleteV2 extends PClient {
  var request;

  PFileDeleteV2({
    required String url,
    required Map<String, dynamic> this.request,
    String errorTitle = 'error',
  }) : super(url, errorTitle);

  @override
  Future<dynamic> execute() async {
    try {
      var response = await DioClient.aliFileClient.delete(url, data: request);
      await doResultCallback(response, 'file upload error', url);
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FILE).tag(Tag.DELETE).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

class PDirDelete extends PClient {
  String? dirPath;

  PDirDelete({String? url, this.dirPath, String errorTitle = 'error'})
    : super(url ?? jsonDirectoryURL, errorTitle);

  @override
  Future<dynamic> execute() async {
    try {
      if (dirPath != null && dirPath!.isNotEmpty) {
        Map<String, dynamic> request = {"key": dirPath};
        var response = await DioClient.fileAuthClient.delete(
          url,
          data: request,
        );
        await doResultCallback(response, 'Directory delete error', url);
      }
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FILE).tag(Tag.DELETE).tag(Tag.FAIL).e('$e');
      rethrow;
    }
  }
}

abstract class PClient {
  @protected
  DataSetter<Map<String, dynamic>> _doSuccess = (v) {};

  @protected
  DataSetter<dynamic> _doPureResponse = (v) {};

  @protected
  bool useDoFailure = false;

  @protected
  Function _doFailure = (v) {};

  @protected
  Function _doFinal = () {};

  final String url;
  final String errorTitle;
  final bool showErrorDialog;
  final ApiLoadingType loadingType;

  PClient(
    this.url,
    this.errorTitle, {
    this.showErrorDialog = true,
    this.loadingType = ApiLoadingType.global,
  });

  PClient onSuccess(DataSetter doSuccess) {
    // TODO: - 상의해서 Send Analytics Event 언제 보내는지 결정 필요
    // if (!url.contains('tgclab.com')) {
    //   FrBsAnalytics.sendAnalyticsEvent('NOT_TGCLAB_API', {'url': url});
    // }

    _doSuccess = doSuccess;
    return this;
  }

  PClient onResponse(DataSetter onResponse) {
    _doPureResponse = onResponse;
    return this;
  }

  PClient onFailure(DataSetter doFailure) {
    useDoFailure = true;
    _doFailure = doFailure;
    return this;
  }

  PClient onFinal(Function doFinal) {
    _doFinal = doFinal;
    return this;
  }

  Future<void> doResultCallback(result, String errorTitle, String url) async {
    try {
      if (result.statusCode == HttpStatus.ok || result.statusCode == HttpStatus.created) {
        try {
          // await _doSuccess(result.data);
          return;
        } catch (e) {
          rethrow; // onSuccess 콜백의 예외를 상위로 전파
        }
      } else {
        if (!showErrorDialog) {
          return;
        }

        if (useDoFailure) {
          _doFailure(result.data);
        } else {
          // 에러 메시지 추출
          String errorMessage = "";
          dio.Response? response = null;

          if (result is dio.DioException) {
            response = result.response;
            pLog.tag(Tag.API).e('❌ [response] error - ${response?.statusCode}');
          }

          if (result is dio.Response) {
            response = result;
            pLog
                .tag(Tag.API)
                .e('❌ [response] response - ${response.statusCode}');
          }

          if (result.data.containsKey('code')) {
            errorMessage = result.data['code'].toString();
          } else {
            errorMessage = 'alert_server_error_msg';
          }

          pLog.tag(Tag.API).e('❌ [code] - ${result.data['code'].toString()}');

          // 전역 ProviderContainer를 통해 router의 navigatorKey 사용
          final container = getGlobalProviderContainer();
          if (container != null) {
            try {
              final router = container.read(routerProvider);
              // GoRouter의 routerDelegate를 통해 navigatorKey 접근
              final navigatorKey = router.routerDelegate.navigatorKey;
              final navigatorContext = navigatorKey.currentContext;
              if (navigatorContext != null) {
                showDialog(
                  context: navigatorContext,
                  barrierDismissible: true,
                  builder: (dialogContext) => AlertDialog(
                    title: Text(errorTitle),
                    content: Text(errorMessage),
                    actions: [
                      TextButton(
                        onPressed: () {
                          if (response?.statusCode == 401) {
                            logout();
                          }
                          dialogContext.pop();
                        },
                        child: Text('ok'),
                      ),
                    ],
                  ),
                );
              }
            } catch (e) {
              pLog.tag(Tag.API).e('다이얼로그 표시 실패: $e');
            }
          }
        }
      }
      await _doFinal();
    } catch (e) {
      pLog.tag(Tag.API).tag(Tag.FAIL).e('doResultCallback 실패: $e');
    }
  }

  Future<dynamic> execute();
}

abstract class PClientForm {
  @protected
  DataSetter<Map<String, dynamic>> _doSuccess = (v) {};

  @protected
  bool useDoFailure = false;

  @protected
  Function _doFailure = (v) {};

  @protected
  Function _doFinal = () {};

  final String url;
  final String errorTitle;
  final dio.FormData formData;

  PClientForm(this.url, this.formData, this.errorTitle);

  PClientForm onSuccess(DataSetter doSuccess) {
    _doSuccess = doSuccess;
    return this;
  }

  PClientForm onFailure(DataSetter doFailure) {
    useDoFailure = true;
    _doFailure = doFailure;
    return this;
  }

  PClientForm onFinal(Function doFinal) {
    _doFinal = doFinal;
    return this;
  }

  Future<void> doResultCallback(result, String errorTitle, String url) async {
    if (result.data['s'] as bool) {
      await _doSuccess(result.data);
    } else {
      if (useDoFailure) {
        _doFailure(result.data);
      } else {
        // FIXME ALERT여부는 확인 필요
        // Get.dialog(AlertDialog(
        //   title: Text(tr(errorTitle)),
        //   content: Text(
        //       result.data.containsKey('c') ? tr(result.data['c'].toString()) : result.data['m']),
        //   actions: [
        //     if (result.data.containsKey('c') && result.data['c'] == 100)
        //       TextButton(
        //           onPressed: () => OfflineService.to.goToOfflineScreen(),
        //           child: Text(tr('alert_network_error_offline'))),
        //     TextButton(
        //         onPressed: () {
        //           isLoading(false);
        //           Get.back();
        //         },
        //         child: Text(tr('ok')))
        //   ],
        // ));
      }
    }

    await _doFinal();
  }

  Future<dynamic> execute();
}
