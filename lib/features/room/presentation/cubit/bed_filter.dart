enum BedFilter {
  all,
  vacant,
  occupied,
  inactive;

  String get label {
    switch (this) {
      case BedFilter.all:
        return 'All';
      case BedFilter.vacant:
        return 'Vacant';
      case BedFilter.occupied:
        return 'Occupied';
      case BedFilter.inactive:
        return 'Inactive';
    }
  }
}
