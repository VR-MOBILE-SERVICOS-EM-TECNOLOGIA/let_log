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
    stateManager.removeListener(handleCurrentSelectionState);
    _scrollController!.dispose();
    super.dispose();
  }

  void handleCurrentSelectionState() {
    if (stateManager.hasFocus) {
      Clipboard.setData(ClipboardData(text: stateManager.currentCell!.value.toString()));
      showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text('Enviado para área de transferência!'),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Ok'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
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
          enableEditingMode: false,
        ),
      ],
      rows: _tablesList.map<PlutoRow>((row) => PlutoRow(
        cells: {
          'chave': PlutoCell(value: row.keys.first),
          'valor': PlutoCell(value: row.values.first),
        },
      )).toList(),
      onLoaded: (event) {
        stateManager = event.stateManager;
        stateManager.addListener(handleCurrentSelectionState);
      },
    );
  }
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<PlutoGridStateManager>('stateManager', stateManager));
  }
}
