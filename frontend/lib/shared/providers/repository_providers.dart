import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:charity_app/features/subscribers/data/mock_subscribers_repository.dart';
import 'package:charity_app/features/families/data/mock_families_repository.dart';
import 'package:charity_app/features/aid/data/mock_aid_repository.dart';
import 'package:charity_app/features/logs/data/mock_logs_repository.dart';

// ── Repository providers ──────────────────────────────────────────────────────
// Single, app-lifetime instances of the mock repositories. Reading them from a
// provider avoids re-instantiating a repository inside every widget build().
final subscribersRepositoryProvider =
    Provider<MockSubscribersRepository>((ref) => MockSubscribersRepository());

final familiesRepositoryProvider =
    Provider<MockFamiliesRepository>((ref) => MockFamiliesRepository());

final aidRepositoryProvider =
    Provider<MockAidRepository>((ref) => MockAidRepository());

final logsRepositoryProvider =
    Provider<MockLogsRepository>((ref) => MockLogsRepository());
