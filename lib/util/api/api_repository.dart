import 'package:chattingapp/util/api/dio_client.dart';
import 'package:chattingapp/util/api/model/login_response.dart';
import 'package:chattingapp/util/api/p_client.dart';
import 'package:chattingapp/util/log.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiRepository {
  Future<void> signup(String id, String password) async {
    final response = await PPost(
      url: ApiConstants.to.signupUrl,
      body: {'id': id, 'pw': password},
    ).execute();

    if (response.statusCode == 200) {
      return;
    } else {
      pLog.tag(Tag.API).e('Failed to signup');
    }
  }

  Future<LoginResponse?> login(String id, String password) async {
    final response = await PPost(
      loadingType: ApiLoadingType.none,
      url: ApiConstants.to.loginUrl,
      body: {'id': id, 'pw': password},
    ).execute();

    if (response.statusCode == 200) {
      return LoginResponse.fromJson(response.data);
    } else {
      pLog.tag(Tag.API).e('Failed to login');
      return null;
    }
  }
}

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository();
});
