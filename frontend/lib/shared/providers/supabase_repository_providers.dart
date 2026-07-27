import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:charity_app/features/subscribers/data/supabase_subscribers_repository.dart';
import 'package:charity_app/features/families/data/supabase_families_repository.dart';
import 'package:charity_app/features/aid/data/supabase_aid_repository.dart';
import 'package:charity_app/features/help_requests/data/supabase_help_requests_repository.dart';
import 'package:charity_app/features/works/data/supabase_works_repository.dart';
import 'package:charity_app/features/competitions/data/supabase_competitions_repository.dart';
import 'package:charity_app/features/donations/data/supabase_donations_repository.dart';
import 'package:charity_app/features/logs/data/supabase_logs_repository.dart';
import 'package:charity_app/shared/models/subscriber_model.dart';
import 'package:charity_app/shared/models/family_model.dart';
import 'package:charity_app/shared/models/aid_model.dart';
import 'package:charity_app/shared/models/work_post_model.dart';
import 'package:charity_app/shared/models/log_model.dart';
import 'package:charity_app/features/help_requests/domain/entities/help_request.dart';
import 'package:charity_app/features/competitions/domain/competition_models.dart';
import 'package:charity_app/features/donations/presentation/providers/donations_provider.dart';

// ════════════════════════════════════════════════════════════════════════════
//  مزوّدات المستودعات المدعومة بـ Supabase (بديلة عن الـ mock).
//  المستودعات نفسها async، لذا تستهلكها الواجهة عبر FutureProvider + AsyncValue.when.
// ════════════════════════════════════════════════════════════════════════════

// ── singletons للمستودعات ────────────────────────────────────────────────────
final supabaseSubscribersRepositoryProvider =
    Provider<SupabaseSubscribersRepository>((ref) => SupabaseSubscribersRepository());

final supabaseFamiliesRepositoryProvider =
    Provider<SupabaseFamiliesRepository>((ref) => SupabaseFamiliesRepository());

final supabaseAidRepositoryProvider =
    Provider<SupabaseAidRepository>((ref) => SupabaseAidRepository());

// ── مزوّدات بيانات جاهزة للواجهة ──────────────────────────────────────────────
// استهلكها هكذا داخل build():
//   final async = ref.watch(subscribersListProvider);
//   return async.when(data: (list) => ..., loading: () => ..., error: (e,_) => ...);
// وبعد أي إضافة/تعديل: ref.invalidate(subscribersListProvider);

final subscribersListProvider = FutureProvider<List<SubscriberModel>>(
    (ref) => ref.watch(supabaseSubscribersRepositoryProvider).getAll());

final overdueSubscribersProvider = FutureProvider<List<SubscriberModel>>(
    (ref) => ref.watch(supabaseSubscribersRepositoryProvider).getOverdueSubscribers());

final familiesListProvider = FutureProvider<List<FamilyModel>>(
    (ref) => ref.watch(supabaseFamiliesRepositoryProvider).getAll());

final aidListProvider = FutureProvider<List<AidModel>>(
    (ref) => ref.watch(supabaseAidRepositoryProvider).getAll());

// ════════════════════════════════════════════════════════════════════════════
//  مستودعات إضافية: طلبات المساعدة · الأعمال · المسابقات · التبرعات · السجلّ.
// ════════════════════════════════════════════════════════════════════════════

// ── singletons للمستودعات ────────────────────────────────────────────────────
final supabaseHelpRequestsRepositoryProvider =
    Provider<SupabaseHelpRequestsRepository>((ref) => SupabaseHelpRequestsRepository());

final supabaseWorksRepositoryProvider =
    Provider<SupabaseWorksRepository>((ref) => SupabaseWorksRepository());

final supabaseCompetitionsRepositoryProvider =
    Provider<SupabaseCompetitionsRepository>((ref) => SupabaseCompetitionsRepository());

final supabaseDonationsRepositoryProvider =
    Provider<SupabaseDonationsRepository>((ref) => SupabaseDonationsRepository());

final supabaseLogsRepositoryProvider =
    Provider<SupabaseLogsRepository>((ref) => SupabaseLogsRepository());

// ── مزوّدات بيانات جاهزة للواجهة ──────────────────────────────────────────────
final helpRequestsListProvider = FutureProvider<List<HelpRequest>>(
    (ref) => ref.watch(supabaseHelpRequestsRepositoryProvider).getAll());

final workPostsListProvider = FutureProvider<List<WorkPost>>(
    (ref) => ref.watch(supabaseWorksRepositoryProvider).getAll());

final competitionsListProvider = FutureProvider<List<Competition>>(
    (ref) => ref.watch(supabaseCompetitionsRepositoryProvider).getCompetitions());

final prizesListProvider = FutureProvider<List<Prize>>(
    (ref) => ref.watch(supabaseCompetitionsRepositoryProvider).getPrizes());

final leaderboardProvider = FutureProvider<List<Participant>>(
    (ref) => ref.watch(supabaseCompetitionsRepositoryProvider).getLeaderboard());

final donationsListProvider = FutureProvider<List<TransferRecord>>(
    (ref) => ref.watch(supabaseDonationsRepositoryProvider).getAll());

final logsListProvider = FutureProvider<List<LogModel>>(
    (ref) => ref.watch(supabaseLogsRepositoryProvider).getAll());
