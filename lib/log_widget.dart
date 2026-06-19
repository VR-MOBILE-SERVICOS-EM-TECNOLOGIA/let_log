part of let_log;

class LogWidget extends StatefulWidget {
  const LogWidget({super.key});

  @override
  State<LogWidget> createState() => _LogWidgetState();
}

class _LogWidgetState extends State<LogWidget>
    with _LiveListController<LogWidget> {
  final List<_Type> _selectTypes = [
    _Type.log,
    _Type.debug,
    _Type.warn,
    _Type.error,
  ];

  @override
  void initState() {
    super.initState();
    attachLiveList(LoggerLog.length, () => LoggerLog.list.length);
  }

  @override
  void dispose() {
    detachLiveList();
    super.dispose();
  }

  bool _matchesSearch(LoggerLog l) {
    if (keyword.isEmpty) return true;
    final k = keyword.toLowerCase();
    bool inMsg() => '${l.message} ${l.origin}'.toLowerCase().contains(k);
    bool inDet() => (l.detail ?? '').toLowerCase().contains(k);
    switch (searchScope) {
      case 'Mensagem':
        return inMsg();
      case 'Detalhe':
        return inDet();
      default:
        return inMsg() || inDet();
    }
  }

  // Chronological order; the ListView renders with `reverse: true` so the
  // newest log appears at the top while keeping the scroll position stable.
  List<LoggerLog> _filteredLogs() => LoggerLog.list
      .where((l) => _selectTypes.contains(l.type) && _matchesSearch(l))
      .toList(growable: false);

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    return Scaffold(
      backgroundColor: t.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (searchActive)
            buildSearchToolbar(
              scopes: const ['Tudo', 'Mensagem', 'Detalhe'],
              shown: _filteredLogs().length,
              total: LoggerLog.list.length,
            )
          else
            _buildTools(t),
          Expanded(
            child: Stack(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: LoggerLog.length,
                  builder: (context, _, __) {
                    final logs = _filteredLogs();
                    if (logs.isEmpty) {
                      return _EmptyState(
                        keyword.isEmpty
                            ? 'Nenhum log capturado ainda.'
                            : 'Nenhum resultado para "$keyword".',
                      );
                    }
                    return Scrollbar(
                      controller: scrollController,
                      thumbVisibility: true,
                      child: ListView.separated(
                        controller: scrollController,
                        reverse: true,
                        padding: const EdgeInsets.fromLTRB(10, 8, 14, 88),
                        itemCount: logs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 9),
                        itemBuilder: (context, i) => _buildItem(logs[i], t),
                      ),
                    );
                  },
                ),
                buildLiveJumpButton(
                  newItemsLabel: '$newItemsCount novo(s) log(s)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTools(_LetLogTheme t) {
    final chips = _Type.values.map((type) {
      final sel = _selectTypes.contains(type);
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(_getTabName(type.index)),
          selected: sel,
          visualDensity: VisualDensity.compact,
          selectedColor: t.accentWeak,
          onSelected: (v) => setState(
            () => v ? _selectTypes.add(type) : _selectTypes.remove(type),
          ),
        ),
      );
    }).toList();
    final errors = LoggerLog.list.where((l) => l.type == _Type.error).length;

    return Container(
      color: t.card,
      padding: const EdgeInsets.fromLTRB(10, 8, 6, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: chips),
                ),
              ),
              IconButton(
                tooltip: 'Limpar logs',
                icon: const Icon(Icons.delete_outline),
                color: t.textMuted,
                onPressed: LoggerLog.clear,
              ),
              IconButton(
                tooltip: 'Buscar',
                icon: const Icon(Icons.search),
                color: t.textMuted,
                onPressed: openSearch,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 2, top: 2),
            child: Row(
              children: [
                Text(
                  '${LoggerLog.list.length} logs',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '$errors erros',
                  style: TextStyle(
                    color: t.err.fg,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(LoggerLog item, _LetLogTheme t) {
    final sc = _statusColorsForLog(item.type, t);
    final isError = item.type == _Type.error;
    return _CopyTarget(
      copyText: item.toString(),
      onTap: () => setState(() => item.showDetail = !item.showDetail),
      child: Container(
        decoration: BoxDecoration(
          color: isError ? t.err.bg : t.card,
          border: Border.all(
            color: isError ? t.err.fg.withValues(alpha: 0.4) : t.border,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 7,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                _Pill(text: item.label, fg: sc.fg, bg: sc.bg),
                _MetaText(_formatTimestamp(item.start)),
                _MetaText(item.origin),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.displayMessage,
              style: TextStyle(
                color: sc.fg,
                fontSize: 14,
                height: 1.3,
                fontWeight: isError ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            if (item.showDetail &&
                item.detail != null &&
                item.detail!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              _Section(
                title: 'Stack trace / detalhe',
                copyText: item.detail!,
                child: SelectableText(
                  item.detail!,
                  style: TextStyle(
                    color: t.mono,
                    fontSize: 12.5,
                    height: 1.4,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  _StatusColors _statusColorsForLog(_Type? type, _LetLogTheme t) {
    switch (type) {
      case _Type.debug:
        return t.info;
      case _Type.warn:
        return t.warn;
      case _Type.error:
        return t.err;
      default:
        return _StatusColors(t.textPrimary, t.accentWeak);
    }
  }
}
