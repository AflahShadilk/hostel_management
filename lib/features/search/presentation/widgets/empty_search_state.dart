import 'package:flutter/material.dart';

import '../../../../core/widgets/app_empty_state.dart';

class EmptySearchState extends StatelessWidget {
  const EmptySearchState({super.key});

  @override
  Widget build(BuildContext context) => const AppEmptyState(
        icon: Icons.manage_search_outlined,
        title: 'Start a search',
        message: 'Enter a term and choose a filter to prepare your search.',
      );
}
