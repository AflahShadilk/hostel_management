enum ExpenseSort { newest, oldest, highestAmount, lowestAmount }

class ExpenseQuery {
  final String searchTerm;
  final DateTime? startDate;
  final DateTime? endDate;
  final ExpenseSort sort;

  const ExpenseQuery({
    this.searchTerm = '',
    this.startDate,
    this.endDate,
    this.sort = ExpenseSort.newest,
  });

  ExpenseQuery copyWith({
    String? searchTerm,
    DateTime? startDate,
    DateTime? endDate,
    bool clearStartDate = false,
    bool clearEndDate = false,
    ExpenseSort? sort,
  }) {
    return ExpenseQuery(
      searchTerm: searchTerm ?? this.searchTerm,
      startDate: clearStartDate ? null : startDate ?? this.startDate,
      endDate: clearEndDate ? null : endDate ?? this.endDate,
      sort: sort ?? this.sort,
    );
  }
}
