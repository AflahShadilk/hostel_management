import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/app_text_field.dart';
import '../cubit/search_cubit.dart';
import '../cubit/search_state.dart';

class SearchBar extends StatefulWidget {
  const SearchBar({super.key});

  @override
  State<SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<SearchBar> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: context.read<SearchCubit>().state.query);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<SearchCubit, SearchState>(
        listener: (context, state) {
          if (_controller.text != state.query) {
            _controller.value = TextEditingValue(
              text: state.query,
              selection: TextSelection.collapsed(offset: state.query.length),
            );
          }
        },
        child: AppTextField(
          controller: _controller,
          hint: 'Search tenants, rooms, phone numbers, and more',
          textInputAction: TextInputAction.search,
          prefixIcon: const Icon(Icons.search),
          suffixIcon: BlocBuilder<SearchCubit, SearchState>(
            buildWhen: (previous, current) => previous.query != current.query,
            builder: (context, state) => state.query.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear search',
                    onPressed: context.read<SearchCubit>().clearQuery,
                  ),
          ),
          onChanged: context.read<SearchCubit>().updateQuery,
        ),
      );
}
