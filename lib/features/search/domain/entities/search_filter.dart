enum SearchFilter {
  all,
  tenant,
  room,
  rent,
  expense,
  pendingRent,
  occupied,
  vacant,
}

extension SearchFilterLabel on SearchFilter {
  String get label => switch (this) {
        SearchFilter.all => 'All',
        SearchFilter.tenant => 'Tenant',
        SearchFilter.room => 'Room',
        SearchFilter.rent => 'Rent',
        SearchFilter.expense => 'Expense',
        SearchFilter.pendingRent => 'Pending Rent',
        SearchFilter.occupied => 'Occupied',
        SearchFilter.vacant => 'Vacant',
      };
}
