part of let_log;

class DBWidget extends StatefulWidget {
  final Future<Database?>? dbFuture;
  
  const DBWidget({
    Key? key,
    this.dbFuture,
  }) : super(key: key);

  @override
  _DBWidgetState createState() => _DBWidgetState();
  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Future<Database?>>('dbFuture', dbFuture));
  }
}

class _DBWidgetState extends State<DBWidget> {
  TextEditingController? _textController;
  ScrollController? _scrollController;
  bool _goDown = true;
  Future<List<Map<String, dynamic>>?>? _tablesList;
  Database? _db;

  Future<void> getTablesList() async {
    _tablesList = null;
    _db = await widget.dbFuture;
    _tablesList = _db!.rawQuery("SELECT name FROM sqlite_master WHERE type='table';").whenComplete(() => setState(() {}));
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
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>?>(
        future: _tablesList,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done)
            return Column(
              children: [
                const Text(
                  'TABELAS',
                  textAlign: TextAlign.center,
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      return TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) {
                              final Future<List<Map<String, dynamic>>> tableRows = _db!.rawQuery("SELECT * FROM ${snapshot.data![index]['name']};").whenComplete(() => setState(() {}));
                              return _tabela(tableRows, snapshot.data![index]['name']);
                            }),
                          );
                        },
                        child: Text(
                          snapshot.data![index]['name'],
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          else
            return Container(
              alignment: Alignment.center,
              child: const CircularProgressIndicator()
            );
        }
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_goDown) {
            _scrollController!.animateTo(
              _scrollController!.position.maxScrollExtent * 2,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          } else {
            _scrollController!.animateTo(
              0,
              curve: Curves.easeOut,
              duration: const Duration(milliseconds: 300),
            );
          }
          _goDown = !_goDown;
          setState(() {});
        },
        mini: true,
        child: Icon(
          _goDown ? Icons.arrow_downward : Icons.arrow_upward,
        ),
      ),
    );
  }

  Widget _tabela(Future<List<Map<String, dynamic>>> tableRows, String tableName) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          tableName
        ),
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: tableRows,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.connectionState == ConnectionState.done && snapshot.data!.isNotEmpty)
            return PlutoGrid(
              columns: snapshot.data![0].keys.map<PlutoColumn>((e) => PlutoColumn(title: e,
                field: e,
                type: PlutoColumnType.text())).toList(),
              rows: snapshot.data!.map<PlutoRow>((row) => PlutoRow(
                cells: row.map<String, PlutoCell>((key, value) => MapEntry(key, PlutoCell(value: value)))
              )).toList(),
            );
          else if (snapshot.hasData && snapshot.connectionState == ConnectionState.done && snapshot.data!.isEmpty)
            return Container(
              alignment: Alignment.center,
              child: const Text(
                'Tabela vazia.',
              ),
            );
          else
            return const CircularProgressIndicator();
        }
      ),
    );
  }
}
