part of let_log;

/// Stores data as JSON when it is structured (Map/List); keeps Strings as-is;
/// falls back to toString for anything non-encodable.
String? _encodeData(Object? data) {
  if (data == null) return null;
  if (data is String) return data;
  try {
    return json.encode(data);
  } catch (_) {
    return data.toString();
  }
}

/// Full request as a pretty-printed JSON object. Bodies/headers that are
/// valid JSON are embedded as real nested JSON (not escaped strings).
String _buildRequestJson(LoggerNet n) {
  Object? decode(String? s) {
    if (s == null || s.trim().isEmpty || s == 'null') return null;
    try {
      return json.decode(s);
    } catch (_) {
      return s;
    }
  }

  final map = <String, Object?>{
    'url': n.api,
    'method': (n.type ?? 'HTTP').toUpperCase(),
    'status': n.status,
    'startedAt': n.start?.toIso8601String(),
    'durationMs': n.spend,
    'requestHeaders': decode(n.reqHeaders),
    'requestBody': decode(n.req),
    'responseHeaders': decode(n.resHeaders),
    'responseBody': decode(n.res),
  };
  return const JsonEncoder.withIndent('  ').convert(map);
}

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
