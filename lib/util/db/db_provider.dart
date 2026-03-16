import 'package:chattingapp/util/db/app_database.dart';
import 'package:chattingapp/util/db/user_dao.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appDBProvider = Provider<AppDatabase>((ref) => AppDatabase());

final userDaoProvider = Provider<UserDao>((ref) => UserDao(ref.read(appDBProvider)));
