import 'package:chattingapp/util/api/dio_client.dart';
import 'package:chattingapp/util/api/model/login_response.dart';
import 'package:chattingapp/util/api/model/room_join_response.dart';
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

  /// GET /api/rooms/search/ — 채팅방 이름 부분 일치 검색 (쿼리 q 또는 name)
  Future<List<RoomResponse>> searchRooms(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      return [];
    }
    final response = await PGet(
      url: ApiConstants.to.roomSearchUrl,
      params: {'q': q},
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
      pLog.tag(Tag.API).e('Failed to search rooms');
    }
    return [];
  }

  /// POST /api/rooms/join/ — 채팅방 참여 (user_id는 토큰 유저와 일치해야 함)
  Future<RoomJoinResponse?> joinRoom({
    required int roomId,
    required int userId,
  }) async {
    final response = await PPost(
      url: ApiConstants.to.roomJoinUrl,
      body: {
        'room_id': roomId,
        'user_id': userId,
      },
    ).execute();

    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = response.data;
      if (body is Map<String, dynamic>) {
        final data = body['data'];
        if (data is Map<String, dynamic>) {
          try {
            return RoomJoinResponse.fromJson(data);
          } on FormatException {
            pLog.tag(Tag.API).e('Invalid join room response');
          }
        }
      }
    } else {
      pLog.tag(Tag.API).e('Failed to join room');
    }
    return null;
  }
}

final apiRepositoryProvider = Provider<ApiRepository>((ref) {
  return ApiRepository();
});
