part of let_log;

String _buildCurl(LoggerNet n) {
  final method = (n.type == null || n.type!.isEmpty)
      ? 'GET'
      : n.type!.toUpperCase();
  final sb = StringBuffer("curl -X $method '${n.api ?? ''}'");
  final headers = _parseHeaders(n.reqHeaders);
  headers.forEach((k, v) {
    final safe = v.replaceAll("'", r"'\''");
    sb.write(" \\\n  -H '$k: $safe'");
  });
  if (n.req != null && n.req!.isNotEmpty && n.req != 'null') {
    final body = n.req!.replaceAll("'", r"'\''");
    sb.write(" \\\n  --data '$body'");
  }
  return sb.toString();
}

Map<String, String> _parseHeaders(String? raw) {
  final result = <String, String>{};
  if (raw == null || raw.isEmpty || raw == 'null') return result;
  try {
    final decoded = json.decode(raw);
    if (decoded is Map) {
      decoded.forEach((k, v) => result['$k'] = '$v');
      return result;
    }
  } catch (_) {
    // headers veio como toString de Map: {a: 1, b: 2}
  }
  final inner = raw.replaceAll(RegExp(r'^\{|\}$'), '');
  for (final pair in inner.split(',')) {
    final idx = pair.indexOf(':');
    if (idx > 0) {
      result[pair.substring(0, idx).trim()] = pair.substring(idx + 1).trim();
    }
  }
  return result;
}

String _exportSession({
  required List<LoggerNet> nets,
  required List<LoggerLog> logs,
}) {
  final sb = StringBuffer();
  sb.writeln('=== LetLog session export ===');
  sb.writeln('Logs: ${logs.length} | Requests: ${nets.length}');
  sb.writeln();
  sb.writeln('--- LOGS ---');
  for (final l in logs) {
    sb.writeln(l.toString());
    sb.writeln('---');
  }
  sb.writeln();
  sb.writeln('--- NETWORK ---');
  for (final n in nets) {
    sb.writeln(n.toString());
    sb.writeln('---');
  }
  return sb.toString();
}
