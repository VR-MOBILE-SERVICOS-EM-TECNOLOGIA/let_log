part of let_log;

class _ErrorBadge extends StatelessWidget {
  final int count;
  const _ErrorBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.err.bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          color: t.err.fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('count', count));
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final Color fg;
  final Color bg;
  final VoidCallback? onTap;
  const _Pill({
    required this.text,
    required this.fg,
    required this.bg,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
    if (onTap == null) return pill;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: pill,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
    properties.add(ColorProperty('fg', fg));
    properties.add(ColorProperty('bg', bg));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }
}

class _MetaText extends StatelessWidget {
  final String text;
  const _MetaText(this.text);

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    return Text(
      text,
      style: TextStyle(
        color: t.textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('text', text));
  }
}

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState(this.message);

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: t.textMuted, fontSize: 13, height: 1.4),
        ),
      ),
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('message', message));
  }
}

class _CopyTarget extends StatelessWidget {
  final Widget child;
  final String copyText;
  final VoidCallback? onTap;
  const _CopyTarget({required this.child, required this.copyText, this.onTap});

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: copyText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copiado para a área de transferência.'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(13),
      onTap: onTap,
      onLongPress: () => _copy(context),
      child: child,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('copyText', copyText));
    properties.add(ObjectFlagProperty<VoidCallback?>.has('onTap', onTap));
  }
}

String _prettyJson(String raw) {
  try {
    final decoded = json.decode(raw);
    return const JsonEncoder.withIndent('  ').convert(decoded);
  } catch (_) {
    return raw;
  }
}

class _Section extends StatefulWidget {
  final String title;
  final String copyText;
  final Widget child;
  const _Section({
    required this.title,
    required this.copyText,
    required this.child,
  });

  @override
  State<_Section> createState() => _SectionState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('title', title));
    properties.add(StringProperty('copyText', copyText));
  }
}

class _SectionState extends State<_Section> {
  bool _open = true;

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        border: Border.all(color: t.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
              child: Row(
                children: [
                  Icon(
                    _open ? Icons.expand_more : Icons.chevron_right,
                    size: 18,
                    color: t.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        color: t.textMuted,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.copyText));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.title} copiado.'),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    },
                    child: Icon(
                      Icons.content_copy,
                      size: 15,
                      color: t.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_open)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(11, 0, 11, 11),
              child: widget.child,
            ),
        ],
      ),
    );
  }
}

class _JsonView extends StatefulWidget {
  final String raw;
  const _JsonView(this.raw);

  @override
  State<_JsonView> createState() => _JsonViewState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(StringProperty('raw', raw));
  }
}

class _JsonViewState extends State<_JsonView> {
  bool _rawMode = false;

  @override
  Widget build(BuildContext context) {
    final t = _LetLogTheme.of(context);
    final text = _rawMode ? widget.raw : _prettyJson(widget.raw);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: InkWell(
            onTap: () => setState(() => _rawMode = !_rawMode),
            child: Text(
              _rawMode ? 'ver formatado' : 'ver raw',
              style: TextStyle(
                color: t.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        SelectableText(
          text,
          style: TextStyle(
            color: t.mono,
            fontSize: 12.5,
            height: 1.4,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
