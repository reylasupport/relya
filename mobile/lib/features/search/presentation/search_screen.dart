import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design/concept/concept_kit.dart';
import '../../../core/design/components/empty_state.dart';
import '../../../core/design/tokens/app_spacing.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../navigation/routes.dart';
import '../../../shared/data/providers.dart';
import '../../../shared/domain/life_item.dart';

/// One search box over everything: documents, purchases, appointments,
/// subscriptions (spec section 26).
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<LifeItem> _results = const [];
  String _query = '';
  bool _searching = false;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    // Typing is not a query. Waiting a beat keeps the database and, later, the
    // bill, out of the user way.
    _debounce = Timer(const Duration(milliseconds: 250), () => _run(value));
  }

  Future<void> _run(String value) async {
    final query = value.trim();
    setState(() {
      _query = query;
      _searching = query.isNotEmpty;
    });
    if (query.isEmpty) {
      setState(() => _results = const []);
      return;
    }
    final results = await ref.read(lifeItemRepositoryProvider).search(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          onChanged: _onChanged,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: context.l10n.searchPlaceholder,
            filled: false,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
      body: _body(now),
    );
  }

  Widget _body(DateTime now) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.4));
    }
    if (_query.isEmpty) {
      return EmptyState(
        icon: Icons.search_rounded,
        title: context.l10n.searchEmptyTitle,
        message: context.l10n.searchEmptyMessage,
      );
    }
    if (_results.isEmpty) {
      return EmptyState(
        icon: Icons.search_off_rounded,
        title: context.l10n.searchNoResults(_query),
        message: context.l10n.searchEmptyMessage,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
      itemCount: _results.length,
      itemBuilder: (context, index) => context.kit.row(
        context,
        item: _results[index],
        now: now,
        onTap: () => context.push(Routes.item(_results[index].id)),
      ),
    );
  }
}
