part of let_log;

class SharedPrefsWidget extends StatefulWidget {
  final SharedPreferences? sheredPrefs;

  const SharedPrefsWidget({super.key, this.sheredPrefs});

  @override
  State<SharedPrefsWidget> createState() => _SharedPrefsWidgetState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(
      DiagnosticsProperty<SharedPreferences?>('sharedPrefs', sheredPrefs),
    );
  }
}

class _SharedPrefsWidgetState extends State<SharedPrefsWidget> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  List<MapEntry<String, Object?>> _entries = [];
  String _keyword = "";

  @override
  void initState() {
    super.initState();
    _refreshEntries();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _refreshEntries() {
    final prefs = widget.sheredPrefs;
    if (prefs == null) return;

    final entries =
        prefs
            .getKeys()
            .map((key) => MapEntry<String, Object?>(key, prefs.get(key)))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    setState(() => _entries = entries);
  }

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    final filteredEntries = _entries
        .where((entry) {
          if (_keyword.isEmpty) return true;

          final normalizedKeyword = _keyword.toLowerCase();
          return entry.key.toLowerCase().contains(normalizedKeyword) ||
              entry.value.toString().toLowerCase().contains(normalizedKeyword);
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: t.surface,
      body: Column(
        children: [
          _buildToolbar(t),
          Expanded(
            child: filteredEntries.isEmpty
                ? const _EmptyState(
                    'Nenhuma preferência corresponde ao filtro.',
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ListView.separated(
                      controller: _scrollController,
                      padding: const EdgeInsets.fromLTRB(10, 8, 18, 24),
                      itemCount: filteredEntries.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) =>
                          _buildEntry(filteredEntries[index], t),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(_LetLogTheme t) {
    return Container(
      color: t.card,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 40,
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: t.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: t.field,
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: t.border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: t.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: t.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  hintText: "Search shared prefs",
                  hintStyle: TextStyle(color: t.textMuted),
                  prefixIcon: Icon(Icons.search, size: 20, color: t.textMuted),
                ),
                onChanged: (value) => setState(() => _keyword = value),
              ),
            ),
          ),
          IconButton(
            tooltip: "Refresh",
            icon: const Icon(Icons.refresh),
            onPressed: _refreshEntries,
          ),
          IconButton(
            tooltip: "Clear search",
            icon: const Icon(Icons.close),
            onPressed: () {
              setState(() {
                _keyword = "";
                _searchController.clear();
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEntry(MapEntry<String, Object?> entry, _LetLogTheme t) {
    final value = entry.value?.toString() ?? 'null';
    final typeName = entry.value == null
        ? 'null'
        : entry.value.runtimeType.toString();
    return _CopyTarget(
      copyText: '${entry.key}: $value',
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: t.card,
          border: Border.all(color: t.border),
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Flexible(
                  child: Text(
                    entry.key,
                    style: TextStyle(
                      color: t.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _Pill(text: typeName, fg: t.info.fg, bg: t.info.bg),
              ],
            ),
            const SizedBox(height: 7),
            SelectableText(
              value,
              maxLines: 12,
              style: TextStyle(
                color: t.mono,
                fontSize: 12.5,
                height: 1.25,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
