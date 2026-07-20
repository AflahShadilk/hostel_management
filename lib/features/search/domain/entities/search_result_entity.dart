import 'package:equatable/equatable.dart';

enum SearchResultType { tenant, room, rent, expense }

class SearchResultEntity extends Equatable {
  const SearchResultEntity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
  });

  final int id;
  final SearchResultType type;
  final String title;
  final String subtitle;

  @override
  List<Object?> get props => [id, type, title, subtitle];
}
