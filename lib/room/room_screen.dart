import 'package:chattingapp/util/api/api_notifier.dart';
import 'package:chattingapp/util/api/model/room_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RoomScreen extends ConsumerStatefulWidget {
  const RoomScreen({super.key});

  @override
  ConsumerState<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends ConsumerState<RoomScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiNotifier.notifier).getRooms();
    });
  }

  void _showCreateRoomDialog() {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('채팅방 만들기'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '방 이름',
            hintText: '방 이름 입력',
          ),
          autofocus: true,
          onSubmitted: (value) => _submitCreateRoom(context, value, nameController),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => _submitCreateRoom(
              context,
              nameController.text.trim(),
              nameController,
            ),
            child: const Text('만들기'),
          ),
        ],
      ),
    ).then((_) {
      // 다이얼로그가 완전히 사라진 뒤에 dispose (애니메이션 중 TextField가 controller를 쓰지 않도록)
      Future.delayed(const Duration(milliseconds: 300), nameController.dispose);
    });
  }

  void _submitCreateRoom(
    BuildContext context,
    String name,
    TextEditingController nameController,
  ) {
    if (name.isEmpty) return;
    Navigator.of(context).pop();
    // pop 직후 상태 갱신 시 빌드 스코프 오류 방지: 한 프레임 뒤에 createRoom 호출
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiNotifier.notifier).createRoom(name);
    });
  }

  @override
  Widget build(BuildContext context) {
    final apiState = ref.watch(apiNotifier);
    final rooms = apiState.rooms ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅방'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(apiNotifier.notifier).getRooms(),
            tooltip: '새로고침',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(apiNotifier.notifier).logout(),
            tooltip: '로그아웃',
          ),
        ],
      ),
      body: rooms.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    '참여한 채팅방이 없어요',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '우측 아래 + 버튼으로 방을 만들어 보세요',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(apiNotifier.notifier).getRooms(),
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  return _RoomListTile(room: room);
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateRoomDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _RoomListTile extends StatelessWidget {
  final RoomResponse room;

  const _RoomListTile({required this.room});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        child: Text(room.name.isNotEmpty ? room.name[0].toUpperCase() : '?'),
      ),
      title: Text(room.name),
      subtitle: Text(
        '${room.type} · ${room.createdAt.isNotEmpty ? room.createdAt : ""}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: 채팅방 상세/채팅 화면으로 이동
      },
    );
  }
}
