part of let_log;

/// Notificador global do modo de tema da devtool (system/light/dark).
final ValueNotifier<ThemeMode> letLogThemeMode = ValueNotifier<ThemeMode>(
  ThemeMode.system,
);

Color _lighten(Color c, [double amount = 0.28]) {
  final hsl = HSLColor.fromColor(c);
  return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
}

class _StatusColors {
  final Color fg;
  final Color bg;
  const _StatusColors(this.fg, this.bg);
}

class _LetLogTheme {
  final Color chrome;
  final Color surface;
  final Color card;
  final Color border;
  final Color textPrimary;
  final Color textMuted;
  final Color mono;
  final Color field;
  final Color accent;
  final Color accentWeak;
  final Color onAccent;
  final _StatusColors ok;
  final _StatusColors warn;
  final _StatusColors err;
  final _StatusColors info;

  const _LetLogTheme({
    required this.chrome,
    required this.surface,
    required this.card,
    required this.border,
    required this.textPrimary,
    required this.textMuted,
    required this.mono,
    required this.field,
    required this.accent,
    required this.accentWeak,
    required this.onAccent,
    required this.ok,
    required this.warn,
    required this.err,
    required this.info,
  });

  factory _LetLogTheme.resolve(Brightness brightness, Color accent) {
    if (brightness == Brightness.dark) {
      final a = _lighten(accent, 0.30);
      return _LetLogTheme(
        chrome: const Color(0xFF202124),
        surface: const Color(0xFF161719),
        card: const Color(0xFF232427),
        border: const Color(0xFF34363B),
        textPrimary: const Color(0xFFE6E7E9),
        textMuted: const Color(0xFF9AA0A6),
        mono: const Color(0xFFC9CDD3),
        field: const Color(0xFF2A2B2F),
        accent: a,
        accentWeak: a.withValues(alpha: 0.16),
        onAccent: const Color(0xFF1A1416),
        ok: _StatusColors(
          const Color(0xFF5BCB7A),
          const Color(0xFF5BCB7A).withValues(alpha: 0.16),
        ),
        warn: _StatusColors(
          const Color(0xFFE0A24B),
          const Color(0xFFE0A24B).withValues(alpha: 0.16),
        ),
        err: _StatusColors(
          const Color(0xFFF28B82),
          const Color(0xFFF28B82).withValues(alpha: 0.14),
        ),
        info: _StatusColors(
          const Color(0xFF6BA4F0),
          const Color(0xFF6BA4F0).withValues(alpha: 0.16),
        ),
      );
    }
    return _LetLogTheme(
      chrome: const Color(0xFFF2F2F4),
      surface: const Color(0xFFF7F7F8),
      card: const Color(0xFFFFFFFF),
      border: const Color(0xFFE2E4E8),
      textPrimary: const Color(0xFF1F2023),
      textMuted: const Color(0xFF61656B),
      mono: const Color(0xFF3A3D42),
      field: const Color(0xFFFFFFFF),
      accent: accent,
      accentWeak: accent.withValues(alpha: 0.10),
      onAccent: const Color(0xFFFFFFFF),
      ok: _StatusColors(
        const Color(0xFF1E8E3E),
        const Color(0xFF1E8E3E).withValues(alpha: 0.12),
      ),
      warn: _StatusColors(
        const Color(0xFFB06000),
        const Color(0xFFB06000).withValues(alpha: 0.12),
      ),
      err: _StatusColors(
        const Color(0xFFD93025),
        const Color(0xFFD93025).withValues(alpha: 0.10),
      ),
      info: _StatusColors(
        const Color(0xFF1967D2),
        const Color(0xFF1967D2).withValues(alpha: 0.12),
      ),
    );
  }

  static _LetLogTheme of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<_LetLogScope>();
    assert(
      scope != null,
      '_LetLogScope ausente: envolva com _LetLogScope no Logger.',
    );
    return scope!.theme;
  }
}

class _LetLogScope extends InheritedWidget {
  final _LetLogTheme theme;
  const _LetLogScope({required this.theme, required super.child});

  @override
  bool updateShouldNotify(_LetLogScope oldWidget) => oldWidget.theme != theme;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<_LetLogTheme>('theme', theme));
  }
}
