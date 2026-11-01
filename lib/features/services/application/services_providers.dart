import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../data/services_repository.dart';

part 'services_providers.g.dart';

@Riverpod(keepAlive: true)
ServicesRepository servicesRepository(Ref ref) => Env.hasSupabase
    ? SupabaseServicesRepository(Supabase.instance.client)
    : DemoServicesRepository();

@riverpod
Future<List<ServicePartner>> servicePartners(Ref ref) =>
    ref.watch(servicesRepositoryProvider).partners();
