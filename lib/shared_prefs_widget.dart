part of let_log;

class SharedPrefsWidget extends StatefulWidget {
  final SharedPreferences? sheredPrefs;
  
  const SharedPrefsWidget({
    Key? key,
    this.sheredPrefs,
  }) : super(key: key);

  @override
  _SharedPrefsWidgetState createState() => _SharedPrefsWidgetState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<SharedPreferences?>('sharedPrefs', sheredPrefs));
  }
}

class _SharedPrefsWidgetState extends State<SharedPrefsWidget> {
  ScrollController? _scrollController;
  List<Map<String, dynamic>> _tablesList = [];
  SharedPreferences? _db;
  late PlutoGridStateManager stateManager;

  void getTablesList() {
    _tablesList = [];
    _db = widget.sheredPrefs;
    _tablesList = _db!.getKeys().map<Map<String, dynamic>>((e) => {e: _db!.get(e)}).toList();
  }

  @override
  void initState() {
    getTablesList();
    _scrollController = ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    _scrollController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlutoGrid(
      columns: [
        PlutoColumn(
          title: 'Chave',
          field: 'chave',
          type: PlutoColumnType.text(),
          enableEditingMode: false,
        ),
        PlutoColumn(
          title: 'Valor',
          field: 'valor',
          type: PlutoColumnType.text(),
          enableAutoEditing: true,
        ),
      ],
      rows: _tablesList.map<PlutoRow>((row) => PlutoRow(
        cells: {
          'chave': PlutoCell(value: row.keys.first),
          'valor': PlutoCell(value: row.values.first),
        },
      )).toList(),
    );
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PlutoGridStateManager>('stateManager', stateManager));
  }
}
