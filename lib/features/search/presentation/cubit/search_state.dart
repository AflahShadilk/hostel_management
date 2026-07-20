import 'package:equatable/equatable.dart';

import '../../domain/entities/search_filter.dart';
import '../../domain/entities/search_result_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.selectedFilter = SearchFilter.all,
  });

  final String query;
  final SearchFilter selectedFilter;
}

class SearchInitial extends SearchState {
  const SearchInitial();

  @override
  List<Object?> get props => const [];
}

class SearchLoading extends SearchState {
  const SearchLoading({super.query, super.selectedFilter});

  @override
  List<Object?> get props => [query, selectedFilter];
}

class SearchReady extends SearchState {
  const SearchReady({
    required this.results,
    super.query,
    super.selectedFilter,
  });

  final List<SearchResultEntity> results;

  @override
  List<Object?> get props => [results, query, selectedFilter];
}

class SearchEmpty extends SearchState {
  const SearchEmpty({super.query, super.selectedFilter});

  @override
  List<Object?> get props => [query, selectedFilter];
}

class SearchError extends SearchState {
  const SearchError(
    this.message, {
    super.query,
    super.selectedFilter,
  });

  final String message;

  @override
  List<Object?> get props => [message, query, selectedFilter];
}
