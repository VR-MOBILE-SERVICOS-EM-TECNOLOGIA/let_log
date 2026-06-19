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

  String _typeOf(Object? value) {
    if (value == null) return 'null';
    if (value is bool) return 'bool';
    if (value is int) return 'int';
    if (value is double) return 'double';
    if (value is List) return 'List';
    return 'String';
  }

  String _previewOf(Object? value) {
    if (value == null) return 'null';
    if (value is List) return value.join(', ');
    return value.toString();
  }

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    final filteredEntries = _entries
        .where((entry) {
          if (_keyword.isEmpty) return true;
          final normalizedKeyword = _keyword.toLowerCase();
          return entry.key.toLowerCase().contains(normalizedKeyword) ||
              _previewOf(entry.value).toLowerCase().contains(normalizedKeyword);
        })
        .toList(growable: false);

    return Scaffold(
      backgroundColor: t.surface,
      body: Column(
        children: [
          _buildToolbar(t, filteredEntries.length),
          _buildHeaderRow(t),
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
                      padding: const EdgeInsets.only(bottom: 24),
                      itemCount: filteredEntries.length,
                      separatorBuilder: (context, index) =>
                          Divider(height: 1, color: t.border),
                      itemBuilder: (context, index) =>
                          _buildRow(filteredEntries[index], t),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar(_LetLogTheme t, int shown) {
    return Container(
      color: t.card,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
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
                      hintText: 'Buscar preferências…',
                      hintStyle: TextStyle(color: t.textMuted),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: t.textMuted,
                      ),
                    ),
                    onChanged: (value) => setState(() => _keyword = value),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Atualizar',
                icon: const Icon(Icons.refresh),
                color: t.textMuted,
                onPressed: _refreshEntries,
              ),
              if (_keyword.isNotEmpty)
                IconButton(
                  tooltip: 'Limpar busca',
                  icon: const Icon(Icons.close),
                  color: t.textMuted,
                  onPressed: () {
                    setState(() {
                      _keyword = "";
                      _searchController.clear();
                    });
                  },
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 2),
            child: Text(
              '$shown ${shown == 1 ? 'preferência' : 'preferências'}',
              style: TextStyle(
                color: t.textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(_LetLogTheme t) {
    TextStyle head() => TextStyle(
      color: t.textMuted,
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.6,
    );
    return Container(
      color: t.surface,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Row(
        children: [
          Expanded(flex: 5, child: Text('CHAVE', style: head())),
          SizedBox(width: 58, child: Text('TIPO', style: head())),
          Expanded(flex: 6, child: Text('VALOR', style: head())),
          const SizedBox(width: 32),
        ],
      ),
    );
  }

  Widget _buildRow(MapEntry<String, Object?> entry, _LetLogTheme t) {
    final preview = _previewOf(entry.value);
    return _CopyTarget(
      copyText: '${entry.key}: $preview',
      onTap: () => _showEditDialog(entry, t),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                entry.key,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(
              width: 58,
              child: _Pill(
                text: _typeOf(entry.value),
                fg: t.info.fg,
                bg: t.info.bg,
              ),
            ),
            Expanded(
              flex: 6,
              child: Text(
                preview,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: t.mono,
                  fontSize: 12.5,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            Icon(Icons.edit_outlined, size: 16, color: t.textMuted),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    MapEntry<String, Object?> entry,
    _LetLogTheme t,
  ) async {
    final prefs = widget.sheredPrefs;
    if (prefs == null) return;

    final value = entry.value;
    final controller = TextEditingController(
      text: value is List ? value.join('\n') : (value?.toString() ?? ''),
    );
    bool boolValue = value is bool && value;
    String? error;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setLocal) {
            Widget editor;
            if (value is bool) {
              editor = SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  boolValue ? 'true' : 'false',
                  style: TextStyle(color: t.textPrimary),
                ),
                value: boolValue,
                activeThumbColor: t.accent,
                onChanged: (v) => setLocal(() => boolValue = v),
              );
            } else {
              final isNumber = value is int || value is double;
              final isList = value is List;
              editor = TextField(
                controller: controller,
                autofocus: true,
                maxLines: isList ? 6 : 1,
                keyboardType: isNumber
                    ? const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      )
                    : TextInputType.multiline,
                style: TextStyle(color: t.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: t.field,
                  helperText: isList ? 'Um item por linha' : null,
                  helperStyle: TextStyle(color: t.textMuted),
                  errorText: error,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: t.border),
                  ),
                ),
              );
            }

            return AlertDialog(
              backgroundColor: t.card,
              title: Text(
                entry.key,
                style: TextStyle(color: t.textPrimary, fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Pill(text: _typeOf(value), fg: t.info.fg, bg: t.info.bg),
                  const SizedBox(height: 14),
                  editor,
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    prefs.remove(entry.key);
                    Navigator.pop(dialogContext, true);
                  },
                  child: Text('Excluir', style: TextStyle(color: t.err.fg)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text('Cancelar', style: TextStyle(color: t.textMuted)),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: t.accent),
                  onPressed: () {
                    final ok = _persist(
                      prefs,
                      entry.key,
                      value,
                      boolValue,
                      controller.text,
                    );
                    if (ok) {
                      Navigator.pop(dialogContext, true);
                    } else {
                      setLocal(() => error = 'Valor inválido para o tipo.');
                    }
                  },
                  child: Text('Salvar', style: TextStyle(color: t.onAccent)),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();
    if (saved == true) _refreshEntries();
  }

  /// Writes the edited value back using the setter matching its current type.
  /// Returns false when the text cannot be parsed into that type.
  bool _persist(
    SharedPreferences prefs,
    String key,
    Object? original,
    bool boolValue,
    String text,
  ) {
    if (original is bool) {
      prefs.setBool(key, boolValue);
      return true;
    }
    if (original is int) {
      final parsed = int.tryParse(text.trim());
      if (parsed == null) return false;
      prefs.setInt(key, parsed);
      return true;
    }
    if (original is double) {
      final parsed = double.tryParse(text.trim());
      if (parsed == null) return false;
      prefs.setDouble(key, parsed);
      return true;
    }
    if (original is List) {
      final items = text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      prefs.setStringList(key, items);
      return true;
    }
    prefs.setString(key, text);
    return true;
  }
}
