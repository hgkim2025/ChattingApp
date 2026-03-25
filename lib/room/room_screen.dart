import 'dart:async';

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
  final _searchController = TextEditingController();
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiNotifier.notifier).getRooms();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchTextChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(apiNotifier.notifier).searchRooms(value);
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    _searchController.clear();
    setState(() {});
    ref.read(apiNotifier.notifier).searchRooms('');
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
          onSubmitted: (value) =>
              _submitCreateRoom(context, value, nameController),
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(apiNotifier.notifier).createRoom(name);
    });
  }

  Future<void> _onSearchResultTap(RoomResponse room) async {
    final ok = await ref.read(apiNotifier.notifier).joinRoomFromSearch(room.id);
    if (!mounted) return;
    _searchController.clear();
    setState(() {});
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('「${room.name}」에 참여했습니다')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('참여에 실패했습니다. 다시 시도해 주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiState = ref.watch(apiNotifier);
    final rooms = apiState.rooms ?? [];
    final searchResults = apiState.searchResults;
    final hasActiveSearch = apiState.lastSearchQuery.isNotEmpty;

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
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SearchBar(
              controller: _searchController,
              hintText: '채팅방 이름으로 검색',
              leading: const Icon(Icons.search),
              trailing: [
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
              ],
              onChanged: (value) {
                setState(() {});
                _onSearchTextChanged(value);
              },
              onSubmitted: (value) {
                _searchDebounce?.cancel();
                ref.read(apiNotifier.notifier).searchRooms(value);
              },
            ),
          ),
          if (hasActiveSearch) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                '검색 결과',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ),
            Expanded(
              flex: 2,
              child: searchResults.isEmpty
                  ? Center(
                      child: Text(
                        '「${apiState.lastSearchQuery}」에 맞는 채팅방이 없습니다',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: searchResults.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final room = searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              room.name.isNotEmpty
                                  ? room.name[0].toUpperCase()
                                  : '?',
                            ),
                          ),
                          title: Text(room.name),
                          subtitle: Text(
                            '${room.type} · 탭하여 참여',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          trailing: const Icon(Icons.group_add_outlined),
                          onTap: () => _onSearchResultTap(room),
                        );
                      },
                    ),
            ),
            const Divider(height: 1),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              '내 채팅방',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            flex: hasActiveSearch ? 3 : 1,
            child: rooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 56,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '참여한 채팅방이 없어요',
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '검색으로 참여하거나 + 로 방을 만들어 보세요',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.outline,
                                  ),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(apiNotifier.notifier).getRooms(),
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) {
                        final room = rooms[index];
                        return _RoomListTile(room: room);
                      },
                    ),
                  ),
          ),
        ],
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
        '${room.type}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        // TODO: 채팅방 상세/채팅 화면으로 이동
      },
    );
  }
}
