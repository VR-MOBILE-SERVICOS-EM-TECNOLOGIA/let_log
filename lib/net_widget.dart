part of let_log;

class NetWidget extends StatefulWidget {
  const NetWidget({super.key});

  @override
  State<NetWidget> createState() => _NetWidgetState();
}

class _NetWidgetState extends State<NetWidget>
    with _LiveListController<NetWidget> {
  final List<String> _selectTypes = [LoggerNet.all];
  String _statusClass = 'Tudo'; // Tudo / 2xx / 3xx / 4xx / 5xx

  @override
  void initState() {
    super.initState();
    attachLiveList(LoggerNet.length, () => LoggerNet.list.length);
  }

  @override
  void dispose() {
    detachLiveList();
    super.dispose();
  }

  // ── Step 2: Filters ──────────────────────────────────────────────────────

  bool _matchesStatusClass(int status) {
    switch (_statusClass) {
      case '2xx':
        return status >= 200 && status < 300;
      case '3xx':
        return status >= 300 && status < 400;
      case '4xx':
        return status >= 400 && status < 500;
      case '5xx':
        return status >= 500;
      default:
        return true;
    }
  }

  bool _matchesSearch(LoggerNet n) {
    if (keyword.isEmpty) return true;
    final k = keyword.toLowerCase();
    bool inUrl() => '${n.api} ${n.type}'.toLowerCase().contains(k);
    bool inHead() =>
        '${n.reqHeaders} ${n.resHeaders}'.toLowerCase().contains(k);
    bool inBody() => '${n.req} ${n.res}'.toLowerCase().contains(k);
    switch (searchScope) {
      case 'URL':
        return inUrl();
      case 'Headers':
        return inHead();
      case 'Body':
        return inBody();
      default:
        return inUrl() || inHead() || inBody();
    }
  }

  // Chronological order; the ListView renders with `reverse: true` so the
  // newest request appears at the top while keeping the scroll position stable.
  List<LoggerNet> _filteredLogs() {
    return LoggerNet.list
        .where((n) {
          final type =
              _selectTypes.contains(LoggerNet.all) ||
              _selectTypes.contains(n.type);
          return type && _matchesStatusClass(n.status) && _matchesSearch(n);
        })
        .toList(growable: false);
  }

  // ── Step 3: build ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    return Scaffold(
      backgroundColor: t.surface,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValueListenableBuilder<int>(
            valueListenable: LoggerNet.typeLength,
            builder: (context, _, __) => searchActive
                ? buildSearchToolbar(
                    scopes: const ['Tudo', 'URL', 'Headers', 'Body'],
                    shown: _filteredLogs().length,
                    total: LoggerNet.list.length,
                  )
                : _buildTools(t),
          ),
          Expanded(
            child: Stack(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: LoggerNet.length,
                  builder: (context, _, __) {
                    final logs = _filteredLogs();
                    if (logs.isEmpty) {
                      return _EmptyState(
                        keyword.isEmpty
                            ? 'Nenhuma requisição capturada ainda.'
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
                  newItemsLabel: '$newItemsCount nova(s) requisição(ões)',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 4: Toolbar ──────────────────────────────────────────────────────

  Widget _buildTools(_LetLogTheme t) {
    final methodChips = LoggerNet.types.map((type) {
      final sel = _selectTypes.contains(type);
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: FilterChip(
          label: Text(type),
          selected: sel,
          visualDensity: VisualDensity.compact,
          selectedColor: t.accentWeak,
          onSelected: (v) => _toggleType(type, v),
        ),
      );
    }).toList();

    const statusOptions = ['Tudo', '2xx', '3xx', '4xx', '5xx'];
    final errors = LoggerNet.list.where((n) => n.isError).length;
    final slow = LoggerNet.list.where((n) => n.spend >= 1000).length;

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
                  child: Row(
                    children: [
                      ...methodChips,
                      Container(
                        width: 1,
                        height: 22,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        color: t.border,
                      ),
                      ...statusOptions.map(
                        (s) => Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: ChoiceChip(
                            label: Text(s),
                            selected: _statusClass == s,
                            visualDensity: VisualDensity.compact,
                            selectedColor: t.accentWeak,
                            onSelected: (_) => setState(() => _statusClass = s),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Exportar sessão',
                icon: const Icon(Icons.ios_share),
                color: t.textMuted,
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: _exportSession(
                        nets: _filteredLogs(),
                        logs: LoggerLog.list,
                      ),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Sessão copiada para a área de transferência.',
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                tooltip: 'Limpar requisições',
                icon: const Icon(Icons.delete_outline),
                color: t.textMuted,
                onPressed: LoggerNet.clear,
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
                  '${LoggerNet.list.length} requests',
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
                const SizedBox(width: 14),
                Text(
                  '$slow lentos',
                  style: TextStyle(
                    color: t.textMuted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Step 5: Item card + rich detail ─────────────────────────────────────

  Widget _buildItem(LoggerNet item, _LetLogTheme t) {
    final sc = _statusColors(item, t);
    return _CopyTarget(
      copyText: _buildRequestJson(item),
      onTap: () => setState(() => item.showDetail = !item.showDetail),
      child: Container(
        decoration: BoxDecoration(
          color: item.isError ? t.err.bg : t.card,
          border: Border.all(
            color: item.isError ? t.err.fg.withValues(alpha: 0.4) : t.border,
          ),
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 9,
                  height: 9,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: sc.fg,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 7,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _Pill(
                            text: '${item.status}',
                            fg: sc.fg,
                            bg: sc.bg,
                            onTap: () => setState(
                              () => _statusClass = _classOf(item.status),
                            ),
                          ),
                          _Pill(
                            text: (item.type ?? 'HTTP').toUpperCase(),
                            fg: t.info.fg,
                            bg: t.info.bg,
                            onTap: () => _toggleType(item.type ?? '', true),
                          ),
                          _MetaText(_formatTimestamp(item.start)),
                          _MetaText(
                            '${item.spend}ms${item.spend >= 1000 ? ' 🐢' : ''}',
                          ),
                          _MetaText(
                            '${_formatBytes(item.getReqSize())}/${_formatBytes(item.getResSize())}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        item.api ?? '',
                        style: TextStyle(
                          color: t.textPrimary,
                          fontSize: 13.5,
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  item.showDetail ? Icons.expand_less : Icons.expand_more,
                  size: 22,
                  color: t.textMuted,
                ),
              ],
            ),
            if (item.errorMessage.isNotEmpty && !item.showDetail) ...[
              const SizedBox(height: 9),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: t.err.bg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: t.err.fg.withValues(alpha: 0.3)),
                ),
                child: Text(
                  item.errorMessage,
                  style: TextStyle(
                    color: t.err.fg,
                    fontSize: 12.5,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            if (item.showDetail) _buildDetails(item, t),
          ],
        ),
      ),
    );
  }

  Widget _buildDetails(LoggerNet item, _LetLogTheme t) {
    return Padding(
      padding: const EdgeInsets.only(top: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: t.accent,
                  foregroundColor: t.onAccent,
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Clipboard.setData(
                    ClipboardData(text: _buildRequestJson(item)),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copiado.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.content_copy, size: 16),
                label: const Text('Copiar JSON'),
              ),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _buildCurl(item)));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('cURL copiado.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                icon: const Icon(Icons.terminal, size: 16),
                label: const Text('cURL'),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, size: 18, color: t.textMuted),
                color: t.card,
                tooltip: 'Outros formatos',
                onSelected: (v) {
                  final text = v == 'text'
                      ? item.toString()
                      : v == 'req'
                      ? _prettyJson(item.req ?? '')
                      : _prettyJson(item.res ?? '');
                  Clipboard.setData(ClipboardData(text: text));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Copiado.'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'text',
                    child: Text(
                      'Copiar como texto',
                      style: TextStyle(color: t.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'req',
                    child: Text(
                      'Copiar requisição (JSON)',
                      style: TextStyle(color: t.textPrimary),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'res',
                    child: Text(
                      'Copiar resposta (JSON)',
                      style: TextStyle(color: t.textPrimary),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          _Section(
            title: 'General',
            copyText: _buildRequestJson(item),
            child: _generalBlock(item, t),
          ),
          if (_has(item.reqHeaders))
            _Section(
              title: 'Request Headers',
              copyText: _prettyJson(item.reqHeaders!),
              child: _JsonView(item.reqHeaders!),
            ),
          if (_has(item.req))
            _Section(
              title: 'Request Body',
              copyText: _prettyJson(item.req!),
              child: _JsonView(item.req!),
            ),
          if (_has(item.resHeaders))
            _Section(
              title: 'Response Headers',
              copyText: _prettyJson(item.resHeaders!),
              child: _JsonView(item.resHeaders!),
            ),
          if (_has(item.res))
            _Section(
              title: 'Response Body',
              copyText: _prettyJson(item.res!),
              child: _JsonView(item.res!),
            ),
        ],
      ),
    );
  }

  bool _has(String? v) => v != null && v.trim().isNotEmpty && v != 'null';

  Widget _generalBlock(LoggerNet item, _LetLogTheme t) {
    final rows = <List<String>>[
      ['Método', (item.type ?? 'HTTP').toUpperCase()],
      ['URL', item.api ?? ''],
      ['Status', '${item.status}'],
      ['Duração', '${item.spend} ms'],
      [
        'Tamanho',
        '${_formatBytes(item.getReqSize())} req / ${_formatBytes(item.getResSize())} resp',
      ],
      ['Início', _formatTimestamp(item.start)],
    ];
    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 78,
                    child: Text(
                      r[0],
                      style: TextStyle(color: t.textMuted, fontSize: 12),
                    ),
                  ),
                  Expanded(
                    child: SelectableText(
                      r[1],
                      style: TextStyle(
                        color: t.textPrimary,
                        fontSize: 12.5,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  // ── Step 6: Color helpers + toggle ───────────────────────────────────────

  _StatusColors _statusColors(LoggerNet n, _LetLogTheme t) {
    if (n.isPending) return t.info;
    if (n.status >= 500 || n.status >= 400) return t.err;
    if (n.status >= 300 && n.status != 304) return t.warn;
    return t.ok;
  }

  String _classOf(int status) {
    if (status >= 200 && status < 300) return '2xx';
    if (status >= 300 && status < 400) return '3xx';
    if (status >= 400 && status < 500) return '4xx';
    if (status >= 500) return '5xx';
    return 'Tudo';
  }

  void _toggleType(String type, bool selected) {
    setState(() {
      if (type == LoggerNet.all) {
        _selectTypes
          ..clear()
          ..add(LoggerNet.all);
        return;
      }

      _selectTypes.remove(LoggerNet.all);
      selected ? _selectTypes.add(type) : _selectTypes.remove(type);
      if (_selectTypes.isEmpty) _selectTypes.add(LoggerNet.all);
    });
  }
}
