part of let_log;

@visibleForTesting
String debugBuildCurl(LoggerNet n) => _buildCurl(n);

@visibleForTesting
Map<String, String> debugParseHeaders(String? raw) => _parseHeaders(raw);

@visibleForTesting
String debugPrettyJson(String raw) => _prettyJson(raw);

@visibleForTesting
String debugExportSession({
  required List<LoggerNet> nets,
  required List<LoggerLog> logs,
}) => _exportSession(nets: nets, logs: logs);

@visibleForTesting
String debugBuildRequestJson(LoggerNet n) => _buildRequestJson(n);

@visibleForTesting
String? debugEncodeData(Object? data) => _encodeData(data);

@visibleForTesting
Object? debugParsePrefValue(Object? original, bool boolValue, String text) =>
    _parsePrefValue(original, boolValue, text);
