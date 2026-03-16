import 'package:chattingapp/util/db/app_database.dart';
import 'package:drift/drift.dart' show Expression, Value;

/// User 테이블 접근용 Dao (DB 전용, API Repository와 구분)
class UserDao {
  UserDao(this._db);

  final AppDatabase _db;

  /// 로그인된 유저(accessToken, refreshToken이 non-null인 행) 조회
  Future<User?> getLoggedInUser() async {
    return (_db.select(_db.users)
          ..where((u) => Expression.and([
                u.accessToken.isNotNull(),
                u.refreshToken.isNotNull(),
              ])))
        .getSingleOrNull();
  }

  /// 토큰만 갱신 (기존 행이 있을 때만 사용: 토큰 리프레시, 로그아웃 시 null 처리)
  Future<void> updateUserTokens({
    required int id,
    String? accessToken,
    String? refreshToken,
  }) async {
    await (_db.update(_db.users)..where((u) => u.id.equals(id))).write(
      UsersCompanion(
        accessToken: Value(accessToken),
        refreshToken: Value(refreshToken),
      ),
    );
  }

  /// 로그인 시 토큰 저장: 행이 없으면 insert, 있으면 update
  Future<void> upsertUserTokens({
    required int id,
    String? accessToken,
    String? refreshToken,
  }) async {
    final existing =
        await (_db.select(_db.users)..where((u) => u.id.equals(id))).getSingleOrNull();

    if (existing != null) {
      await updateUserTokens(id: id, accessToken: accessToken, refreshToken: refreshToken);
    } else {
      if (accessToken != null && refreshToken != null) {
        await _db.into(_db.users).insert(
          UsersCompanion.insert(
            id: Value(id),
            accessToken: Value(accessToken),
            refreshToken: Value(refreshToken),
          ),
        );
      }
    }
  }
}
