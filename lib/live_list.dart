part of let_log;

mixin _LiveListController<T extends StatefulWidget> on State<T> {
  final ScrollController scrollController = ScrollController();
  final TextEditingController searchController = TextEditingController();
  final FocusNode searchFocus = FocusNode();

  bool searchActive = false;
  String keyword = '';
  String searchScope = 'Tudo';
  int newItemsCount = 0;

  /// Whether the list is pinned to the live edge (the top, where the newest
  /// items appear). When false there is older content below worth jumping to.
  bool atLiveEdge = true;

  ValueNotifier<int>? _source;
  int Function()? _currentLength;
  int _lastSeenLength = 0;

  void attachLiveList(ValueNotifier<int> source, int Function() currentLength) {
    _source = source;
    _currentLength = currentLength;
    _lastSeenLength = currentLength();
    scrollController.addListener(_handleScroll);
    source.addListener(_handleChange);
  }

  void detachLiveList() {
    _source?.removeListener(_handleChange);
    scrollController.removeListener(_handleScroll);
    scrollController.dispose();
    searchController.dispose();
    searchFocus.dispose();
  }

  void _handleScroll() {
    final tracking = _isTrackingLiveEdge;
    if (tracking == atLiveEdge && !(tracking && newItemsCount > 0)) return;
    setState(() {
      atLiveEdge = tracking;
      if (tracking) newItemsCount = 0;
    });
  }

  void _handleChange() {
    final current = _currentLength?.call() ?? 0;
    final delta = current - _lastSeenLength;
    _lastSeenLength = current;
    // delta == 0 happens on in-place updates (e.g. a network response landing
    // on an existing request); leave the unseen-items count untouched.
    if (delta == 0) return;
    if (delta < 0) {
      if (newItemsCount != 0) setState(() => newItemsCount = 0);
      return;
    }
    if (_isTrackingLiveEdge) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => scrollToLatest(jump: true),
      );
      return;
    }
    setState(() => newItemsCount += delta);
  }

  /// The lists render with `reverse: true` (newest items at the top), so the
  /// live edge sits at [maxScrollExtent]. Older history grows toward
  /// [minScrollExtent], which keeps the viewport stable while scrolled back.
  bool get _isTrackingLiveEdge {
    if (!scrollController.hasClients) return true;
    final p = scrollController.position;
    return p.maxScrollExtent - p.pixels <= _liveScrollTolerance;
  }

  void jumpToLatest() {
    setState(() => newItemsCount = 0);
    scrollToLatest();
  }

  void scrollToLatest({bool jump = false}) {
    if (!scrollController.hasClients) return;
    final target = scrollController.position.maxScrollExtent;
    if (jump) {
      scrollController.jumpTo(target);
    } else {
      scrollController.animateTo(
        target,
        curve: Curves.easeOutCubic,
        duration: const Duration(milliseconds: 260),
      );
    }
  }

  void openSearch() {
    setState(() => searchActive = true);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => searchFocus.requestFocus(),
    );
  }

  void closeSearch() {
    setState(() {
      searchActive = false;
      keyword = '';
      searchScope = 'Tudo';
      searchController.clear();
    });
    searchFocus.unfocus();
  }

  void setKeyword(String value) => setState(() => keyword = value);
  void setScope(String value) => setState(() => searchScope = value);
}

extension _LiveListUI<T extends StatefulWidget> on _LiveListController<T> {
  Widget buildSearchToolbar({
    required List<String> scopes,
    required int shown,
    required int total,
  }) {
    final t = _LetLogTheme.of(context);
    return Container(
      color: t.card,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, size: 18, color: t.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: searchController,
                    focusNode: searchFocus,
                    style: TextStyle(color: t.textPrimary, fontSize: 13),
                    decoration: InputDecoration(
                      isDense: true,
                      filled: true,
                      fillColor: t.field,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 9,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide(color: t.border),
                      ),
                      hintText: 'Buscar…',
                    ),
                    onChanged: setKeyword,
                  ),
                ),
              ),
              if (keyword.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    '$shown de $total',
                    style: TextStyle(
                      color: t.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Fechar busca',
                icon: const Icon(Icons.close),
                color: t.textMuted,
                onPressed: closeSearch,
              ),
            ],
          ),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: scopes.map((s) {
                final on =
                    (searchScope == s) || (searchScope.isEmpty && s == 'Tudo');
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(s),
                    selected: on,
                    visualDensity: VisualDensity.compact,
                    selectedColor: t.accentWeak,
                    onSelected: (_) => setScope(s),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// Single floating control to jump back to the newest items (the top).
  /// Shows whenever there is content above the viewport — labelled with the
  /// new-items count when there are unseen items, or a neutral hint otherwise.
  /// Sits above the system navigation bar via the bottom view padding.
  Widget buildLiveJumpButton({
    required String newItemsLabel,
    String idleLabel = 'Ir para os recentes',
  }) {
    if (atLiveEdge && newItemsCount == 0) return const SizedBox.shrink();
    final hasNew = newItemsCount > 0;
    return Positioned(
      left: 0,
      right: 0,
      bottom: 16 + MediaQuery.paddingOf(context).bottom,
      child: Center(
        child: FilledButton.tonalIcon(
          onPressed: jumpToLatest,
          icon: const Icon(Icons.arrow_upward, size: 16),
          label: Text(hasNew ? newItemsLabel : idleLabel),
        ),
      ),
    );
  }
}
