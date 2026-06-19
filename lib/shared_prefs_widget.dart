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
      onTap: () => _openEditor(entry, t),
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

  Future<void> _openEditor(
    MapEntry<String, Object?> entry,
    _LetLogTheme t,
  ) async {
    final prefs = widget.sheredPrefs;
    if (prefs == null) return;

    final changed = await showDialog<bool>(
      context: context,
      builder: (_) => _PrefEditDialog(
        prefs: prefs,
        entryKey: entry.key,
        value: entry.value,
        typeLabel: _typeOf(entry.value),
        theme: t,
      ),
    );

    if (changed == true) _refreshEntries();
  }
}

/// Parses the edited input into the typed value matching [original]. Returns
/// null only when a numeric field cannot be parsed (an invalid edit). Pure and
/// unit-testable in isolation from the widget tree.
Object? _parsePrefValue(Object? original, bool boolValue, String text) {
  if (original is bool) return boolValue;
  if (original is int) return int.tryParse(text.trim());
  if (original is double) return double.tryParse(text.trim());
  if (original is List) {
    return text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
  return text;
}

/// Persists [value] using the SharedPreferences setter matching its type.
void _writePrefValue(SharedPreferences prefs, String key, Object value) {
  if (value is bool) {
    prefs.setBool(key, value);
  } else if (value is int) {
    prefs.setInt(key, value);
  } else if (value is double) {
    prefs.setDouble(key, value);
  } else if (value is List<String>) {
    prefs.setStringList(key, value);
  } else {
    prefs.setString(key, value.toString());
  }
}

/// Self-contained editor dialog that owns its [TextEditingController] lifecycle,
/// so dismissing it (Cancel/Save/Delete) can never use a disposed controller.
class _PrefEditDialog extends StatefulWidget {
  final SharedPreferences prefs;
  final String entryKey;
  final Object? value;
  final String typeLabel;
  final _LetLogTheme theme;

  const _PrefEditDialog({
    required this.prefs,
    required this.entryKey,
    required this.value,
    required this.typeLabel,
    required this.theme,
  });

  @override
  State<_PrefEditDialog> createState() => _PrefEditDialogState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SharedPreferences>('prefs', prefs));
    properties.add(StringProperty('entryKey', entryKey));
    properties.add(DiagnosticsProperty<Object?>('value', value));
    properties.add(StringProperty('typeLabel', typeLabel));
    properties.add(DiagnosticsProperty<_LetLogTheme>('theme', theme));
  }
}

class _PrefEditDialogState extends State<_PrefEditDialog> {
  late final TextEditingController _controller;
  late bool _boolValue;
  String? _error;

  @override
  void initState() {
    super.initState();
    final v = widget.value;
    _controller = TextEditingController(
      text: v is List ? v.join('\n') : (v?.toString() ?? ''),
    );
    _boolValue = v is bool && v;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final parsed = _parsePrefValue(widget.value, _boolValue, _controller.text);
    if (parsed == null) {
      setState(() => _error = 'Valor inválido para o tipo.');
      return;
    }
    _writePrefValue(widget.prefs, widget.entryKey, parsed);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.theme;
    final value = widget.value;
    final Widget editor;
    if (value is bool) {
      editor = SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(
          _boolValue ? 'true' : 'false',
          style: TextStyle(color: t.textPrimary),
        ),
        value: _boolValue,
        activeThumbColor: t.accent,
        onChanged: (v) => setState(() => _boolValue = v),
      );
    } else {
      final isNumber = value is int || value is double;
      final isList = value is List;
      editor = TextField(
        controller: _controller,
        autofocus: true,
        maxLines: isList ? 6 : 1,
        keyboardType: isNumber
            ? const TextInputType.numberWithOptions(decimal: true, signed: true)
            : TextInputType.multiline,
        style: TextStyle(color: t.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          filled: true,
          fillColor: t.field,
          helperText: isList ? 'Um item por linha' : null,
          helperStyle: TextStyle(color: t.textMuted),
          errorText: _error,
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
        widget.entryKey,
        style: TextStyle(color: t.textPrimary, fontSize: 16),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Pill(text: widget.typeLabel, fg: t.info.fg, bg: t.info.bg),
          const SizedBox(height: 14),
          editor,
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            widget.prefs.remove(widget.entryKey);
            Navigator.pop(context, true);
          },
          child: Text('Excluir', style: TextStyle(color: t.err.fg)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancelar', style: TextStyle(color: t.textMuted)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: t.accent),
          onPressed: _save,
          child: Text('Salvar', style: TextStyle(color: t.onAccent)),
        ),
      ],
    );
  }
}
