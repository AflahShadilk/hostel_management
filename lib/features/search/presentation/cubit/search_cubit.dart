import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/search_filter.dart';
import '../../domain/repositories/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(this._searchRepository) : super(const SearchInitial());

  final SearchRepository _searchRepository;
  Timer? _debounce;
  int _requestVersion = 0;

  void updateQuery(String query) {
    _scheduleSearch(query: query, filter: state.selectedFilter);
  }

  void selectFilter(SearchFilter filter) {
    _scheduleSearch(query: state.query, filter: filter);
  }

  void clearQuery() {
    _scheduleSearch(query: '', filter: state.selectedFilter);
  }

  void _scheduleSearch({required String query, required SearchFilter filter}) {
    _debounce?.cancel();
    final normalizedQuery = query.trim();
    if (normalizedQuery.isEmpty && filter == SearchFilter.all) {
      _requestVersion++;
      emit(const SearchInitial());
      return;
    }

    final requestVersion = ++_requestVersion;
    emit(SearchLoading(query: normalizedQuery, selectedFilter: filter));
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await _searchRepository.search(
          query: normalizedQuery,
          filter: filter,
        );
        if (isClosed || requestVersion != _requestVersion) return;
        if (results.isEmpty) {
          emit(SearchEmpty(query: normalizedQuery, selectedFilter: filter));
          return;
        }
        emit(
          SearchReady(
            results: results,
            query: normalizedQuery,
            selectedFilter: filter,
          ),
        );
      } catch (error) {
        if (isClosed || requestVersion != _requestVersion) return;
        emit(
          SearchError(
            'Unable to search: $error',
            query: normalizedQuery,
            selectedFilter: filter,
          ),
        );
      }
    });
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
