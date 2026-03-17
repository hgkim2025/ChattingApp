/// 서버 Room 모델과 1:1 대응 (GET 목록 / POST 생성 응답)
class RoomResponse {
  final int id;
  final String name;
  final String type;
  final String createdAt;

  RoomResponse({
    required this.id,
    required this.name,
    required this.type,
    required this.createdAt,
  });

  factory RoomResponse.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int ? idRaw : (int.tryParse(idRaw?.toString() ?? '') ?? 0);
    return RoomResponse(
      id: id,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'group',
      createdAt: json['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'created_at': createdAt,
    };
  }
}
