import 'package:chattingapp/util/api/dio_client.dart';
import 'package:chattingapp/util/api/model/login_response.dart';
import 'package:chattingapp/util/api/model/room_response.dart';
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
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return LoginResponse.fromJson(data);
        }
      }
      return null;
    } else {
      pLog.tag(Tag.API).e('Failed to login');
      return null;
    }
  }

  Future<List<RoomResponse>> getRooms() async {
    final response = await PGet(
      url: ApiConstants.to.roomUrl,
    ).execute();

    if (response.statusCode == 200) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is List) {
          return data
              .whereType<Map<String, dynamic>>()
              .map((e) => RoomResponse.fromJson(e))
              .toList();
        }
      }
    } else {
      pLog.tag(Tag.API).e('Failed to get rooms');
    }
    return [];
  }

  /// POST /api/rooms/ — 채팅방 생성 (생성한 유저는 자동으로 멤버)
  Future<RoomResponse?> createRoom(String name) async {
    final response = await PPost(
      url: ApiConstants.to.roomUrl,
      body: {'name': name},
    ).execute();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          return RoomResponse.fromJson(data);
        }
      }
    } else {
      pLog.tag(Tag.API).e('Failed to create room');
    }
    return null;
  }
}

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository();
});
