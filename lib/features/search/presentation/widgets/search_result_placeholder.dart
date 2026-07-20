import 'package:flutter/material.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/search_result_entity.dart';

class SearchResultPlaceholder extends StatelessWidget {
  const SearchResultPlaceholder({
    required this.results,
    super.key,
  });

  final List<SearchResultEntity> results;

  @override
  Widget build(BuildContext context) => ListView.separated(
        itemCount: results.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
        itemBuilder: (context, index) {
          final result = results[index];
          return Card(
            child: ListTile(
              leading: Icon(_iconFor(result.type)),
              title: Text(result.title),
              subtitle: Text(result.subtitle),
            ),
          );
        },
      );

  IconData _iconFor(SearchResultType type) => switch (type) {
        SearchResultType.tenant => Icons.person_outline,
        SearchResultType.room => Icons.meeting_room_outlined,
        SearchResultType.rent => Icons.payments_outlined,
        SearchResultType.expense => Icons.receipt_long_outlined,
      };
}
