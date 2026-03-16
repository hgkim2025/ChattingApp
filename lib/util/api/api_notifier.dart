import 'package:chattingapp/util/api/api_repository.dart';
import 'package:chattingapp/util/api/model/login_response.dart';
import 'package:chattingapp/util/db/db_provider.dart';
import 'package:chattingapp/util/db/user_dao.dart';
import 'package:chattingapp/util/log.dart';
import 'package:chattingapp/util/route/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiState {
  final LoginResponse? loginResponse;

  ApiState({
    this.loginResponse,
  });

  ApiState copyWith({
    LoginResponse? loginResponse,
  }) {
    return ApiState(
      loginResponse: loginResponse ?? this.loginResponse,
    );
  }
}



class ApiNotifier extends Notifier<ApiState> {

  ApiRepository get _apiRepository => ref.read(apiRepositoryProvider);
  UserDao get _userDao => ref.read(userDaoProvider);
  
  @override
  ApiState build() {
    return ApiState();
  }

  void signup(String id, String password) async {
    await _apiRepository.signup(id, password);
  }

  void login(String id, String password) async {
    final loginResponse = await _apiRepository.login(id, password);
    if (loginResponse == null) {
      return;
    }
    state = state.copyWith(loginResponse: loginResponse);
    await saveTokens(loginResponse);
  }


  Future<void> saveTokens(LoginResponse loginResponse) async {
    final userId = loginResponse.user.id;
    pLog.tag(Tag.LOGIN).d('✅ User ID: $userId');

    await _userDao.upsertUserTokens(
      id: userId,
      accessToken: loginResponse.tokens.access,
      refreshToken: loginResponse.tokens.refresh,
    );
  }

  Future<void> _removeTokens() async {
    // accessToken, refreshToken만 제거. id, isPremium, selectedSpaceId는 유지
    final userId = state.loginResponse?.user.id;
    if (userId != null) {
      await _userDao.updateUserTokens(
        id: userId,
        accessToken: null,
        refreshToken: null,
      );
    }
  }

  void logout() async {
    await _removeTokens();
    state = state.copyWith(loginResponse: null);

    final router = ref.read(routerProvider);
    router.go(AppRoute.login.path);
  }
}

final apiNotifier = NotifierProvider<ApiNotifier, ApiState>(() => ApiNotifier());