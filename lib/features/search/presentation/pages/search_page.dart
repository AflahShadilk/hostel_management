import 'package:flutter/material.dart' hide SearchBar;
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../domain/entities/search_filter.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart' as search_state;
import '../widgets/empty_search_state.dart';
import '../widgets/search_bar.dart';
import '../widgets/search_filter_bar.dart';
import '../widgets/search_loading.dart';
import '../widgets/search_result_placeholder.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Search')),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final horizontalPadding = constraints.maxWidth >= 1100
                  ? AppSpacing.xl
                  : constraints.maxWidth >= 700
                      ? AppSpacing.lg
                      : AppSpacing.md;

              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: AppSpacing.md,
                ),
                child: Column(
                  children: [
                    const SearchBar(),
                    const SizedBox(height: AppSpacing.md),
                    const SearchFilterBar(),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: BlocBuilder<SearchCubit, search_state.SearchState>(
                        builder: (context, state) {
                          if (state is search_state.SearchLoading) {
                            return const SearchLoading();
                          }
                          if (state is search_state.SearchError) {
                            return AppEmptyState(
                              icon: Icons.error_outline,
                              title: 'Search unavailable',
                              message: state.message,
                            );
                          }
                          if (state is search_state.SearchInitial ||
                              state.query.trim().isEmpty &&
                                  state.selectedFilter == SearchFilter.all) {
                            return const EmptySearchState();
                          }
                          if (state is search_state.SearchEmpty) {
                            return const AppEmptyState(
                              icon: Icons.search_off_outlined,
                              title: 'No results found',
                            );
                          }
                          if (state is search_state.SearchReady) {
                            return SearchResultPlaceholder(
                                results: state.results);
                          }
                          return SearchResultPlaceholder(
                            results: const [],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
}
