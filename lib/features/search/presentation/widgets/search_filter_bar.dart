import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../domain/entities/search_filter.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';

class SearchFilterBar extends StatelessWidget {
  const SearchFilterBar({super.key});

  @override
  Widget build(BuildContext context) => BlocBuilder<SearchCubit, SearchState>(
        buildWhen: (previous, current) =>
            previous.selectedFilter != current.selectedFilter,
        builder: (context, state) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SearchFilter.values
                .map(
                  (filter) => Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: ChoiceChip(
                      label: Text(filter.label),
                      selected: state.selectedFilter == filter,
                      onSelected: (_) =>
                          context.read<SearchCubit>().selectFilter(filter),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      );
}
