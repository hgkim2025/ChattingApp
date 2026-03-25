import 'package:chattingapp/util/api/model/room_response.dart';

/// POST /api/rooms/join/ 응답 — { room, already_member }
class RoomJoinResponse {
  final RoomResponse room;
  final bool alreadyMember;

  RoomJoinResponse({
    required this.room,
    required this.alreadyMember,
  });

  factory RoomJoinResponse.fromJson(Map<String, dynamic> json) {
    final roomRaw = json['room'];
    if (roomRaw is! Map<String, dynamic>) {
      throw FormatException('RoomJoinResponse.fromJson: room is missing or invalid');
    }
    final am = json['already_member'];
    final alreadyMember = am is bool
        ? am
        : am == 1 || am == 'true' || am == '1';
    return RoomJoinResponse(
      room: RoomResponse.fromJson(roomRaw),
      alreadyMember: alreadyMember,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'room': room.toJson(),
      'already_member': alreadyMember,
    };
  }
}
