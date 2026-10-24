import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';

import '../../../core/providers.dart';
import '../data/academy_repository.dart';
import '../domain/academy_models.dart';
import '../domain/academy_more.dart';

part 'academy_providers.g.dart';

@Riverpod(keepAlive: true)
AcademyRepository academyRepository(Ref ref) => Env.hasSupabase
    ? SupabaseAcademyRepository(Supabase.instance.client)
    : DemoAcademyRepository();

@riverpod
Future<List<Academy>> academyList(Ref ref) =>
    ref.watch(academyRepositoryProvider).academies();

@riverpod
Future<Academy> academy(Ref ref, String id) =>
    ref.watch(academyRepositoryProvider).academy(id);

@riverpod
Future<List<Student>> myStudents(Ref ref) async {
  final me = await ref.watch(currentUserIdProvider.future);
  if (me == null) return const [];
  return ref.watch(academyRepositoryProvider).myStudents();
}

@riverpod
Future<Student> student(Ref ref, String id) =>
    ref.watch(academyRepositoryProvider).student(id);

@riverpod
Future<List<LessonWeek>> studentLessons(Ref ref, String id) =>
    ref.watch(academyRepositoryProvider).lessons(id);

@riverpod
Future<List<Invoice>> studentInvoices(Ref ref, String id) =>
    ref.watch(academyRepositoryProvider).invoices(id);

@riverpod
Future<List<MakeupSlot>> makeupSlots(Ref ref, String studentId) =>
    ref.watch(academyRepositoryProvider).makeupSlots(studentId);

@riverpod
Future<List<MakeupSlot>> trialSlots(Ref ref, String academyId) =>
    ref.watch(academyRepositoryProvider).trialSlots(academyId);

@riverpod
Future<List<CoachAlert>> coachAlerts(Ref ref, String academyId) =>
    ref.watch(academyRepositoryProvider).alerts(academyId);

@riverpod
Future<List<EnrolRequest>> enrolRequests(Ref ref, String academyId) =>
    ref.watch(academyRepositoryProvider).requests(academyId);

@riverpod
Future<List<Student>> classRoster(Ref ref, String classId) =>
    ref.watch(academyRepositoryProvider).roster(classId);

/// The create-academy answers, kept across the five steps.
@Riverpod(keepAlive: true)
class AcademyDraftController extends _$AcademyDraftController {
  @override
  AcademyDraft build() => const AcademyDraft();

  void reset() => state = const AcademyDraft();
  void edit(AcademyDraft Function(AcademyDraft) change) =>
      state = change(state);

  Future<String> create() async {
    final id = await ref.read(academyRepositoryProvider).createAcademy(state);
    ref.invalidate(academyListProvider);
    return id;
  }
}

@riverpod
Future<List<MessageThread>> academyMessages(Ref ref, String academyId) =>
    ref.watch(academyRepositoryProvider).messages(academyId);

@riverpod
Future<CoachPay> coachPay(Ref ref) =>
    ref.watch(academyRepositoryProvider).coachPay();

@riverpod
Future<List<CurriculumWeek>> curriculum(Ref ref, String academyId, int level) =>
    ref.watch(academyRepositoryProvider).curriculum(academyId, level);

@riverpod
Future<List<ClassProgress>> curriculumClasses(
  Ref ref,
  String academyId,
  int level,
) => ref.watch(academyRepositoryProvider).curriculumClasses(academyId, level);

@riverpod
Future<List<Drill>> drillVideos(Ref ref) =>
    ref.watch(academyRepositoryProvider).drillVideos();

@riverpod
Future<List<(String, String)>> pendingInvites(Ref ref, String classId) =>
    ref.watch(academyRepositoryProvider).pendingInvites(classId);

@riverpod
Future<List<AttendanceLine>> attendance(Ref ref, String studentId) =>
    ref.watch(academyRepositoryProvider).attendance(studentId);

@riverpod
Future<List<CoverCoach>> coverCoaches(Ref ref, String classId) =>
    ref.watch(academyRepositoryProvider).coverCoaches(classId);
