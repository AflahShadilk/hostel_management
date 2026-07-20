import 'package:flutter/material.dart';

import '../../../../core/widgets/app_loading_indicator.dart';

class SearchLoading extends StatelessWidget {
  const SearchLoading({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: AppLoadingIndicator(message: 'Preparing search'),
      );
}
