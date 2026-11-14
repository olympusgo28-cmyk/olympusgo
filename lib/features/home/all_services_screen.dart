import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/widgets/og_kit.dart';
import 'application/home_services.dart';
import 'service_widgets.dart';

/// Every service on one page: Your favourites, then More services.
class AllServicesScreen extends ConsumerWidget {
  const AllServicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final services = ref.watch(homeServicesControllerProvider);
    final more = services.moreList;
    return KitScaffold(
      header: const KitHeader(title: 'All services'),
      children: [
        KitSection(
          'Your favourites',
          trailing: KitLink(
            'Edit',
            minHeight: 32,
            onPressed: () => context.push(Routes.editFavourites),
          ),
        ),
        FavouriteGrid(services: services.favouriteList),
        const SizedBox(height: 4),
        const KitSection('More services'),
        Column(
          children: [
            for (var row = 0; row < more.length; row += 4) ...[
              if (row > 0) const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = row; i < row + 4; i++)
                    Expanded(
                      child: i < more.length
                          ? Center(child: ServiceCircle(service: more[i]))
                          : const SizedBox.shrink(),
                    ),
                ],
              ),
            ],
          ],
        ),
      ],
    );
  }
}
