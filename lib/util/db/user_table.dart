import 'package:drift/drift.dart';

/// User 테이블 (테이블당 한 파일)
class Users extends Table {
  IntColumn get id => integer()();
  TextColumn get accessToken => text().nullable()();
  TextColumn get refreshToken => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}
