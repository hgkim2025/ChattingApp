import 'package:chattingapp/util/api/api_repository.dart';
import 'package:chattingapp/util/api/model/login_response.dart';
import 'package:chattingapp/util/api/model/room_response.dart';
import 'package:chattingapp/util/db/db_provider.dart';
import 'package:chattingapp/util/db/user_dao.dart';
import 'package:chattingapp/util/log.dart';
import 'package:chattingapp/util/route/router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ApiState {
  final LoginResponse? loginResponse;
  final List<RoomResponse>? rooms;
  ApiState({
    this.loginResponse,
    this.rooms,
  });

  ApiState copyWith({
    LoginResponse? loginResponse,
    List<RoomResponse>? rooms,
  }) {
    return ApiState(
      loginResponse: loginResponse ?? this.loginResponse,
      rooms: rooms ?? this.rooms,
    );
  }
}



class ApiNotifier extends Notifier<ApiState> {

  ApiRepository get _apiRepository => ref.read(apiRepositoryProvider);
  UserDao get _userDao => ref.read(userDaoProvider);
  GoRouter get _router => ref.read(routerProvider);
  
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

    _router.go(AppRoute.room.path);
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
    final user = await _userDao.getLoggedInUser();
    if (user != null) {
      await _userDao.updateUserTokens(
        id: user.id,
        accessToken: null,
        refreshToken: null,
      );
    }
  }

  void logout() async {
    await _removeTokens();
    state = state.copyWith(loginResponse: null);

    _router.go(AppRoute.login.path);
  }

  Future<void> getRooms() async {
    final rooms = await _apiRepository.getRooms();
    state = state.copyWith(rooms: rooms);
  }

  Future<void> createRoom(String name) async {
    final room = await _apiRepository.createRoom(name);
    if (room == null) {
      return;
    }
    state = state.copyWith(rooms: [...(state.rooms ?? []), room]);
  }
}

final apiNotifier = NotifierProvider<ApiNotifier, ApiState>(() => ApiNotifier());