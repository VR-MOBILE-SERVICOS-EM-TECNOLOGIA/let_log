part of let_log;

class NetWidget extends StatefulWidget {
  const NetWidget({Key? key}) : super(key: key);

  @override
  _NetWidgetState createState() => _NetWidgetState();
}

class _NetWidgetState extends State<NetWidget> {
  bool _showSearch = false;
  String _keyword = "";
  TextEditingController? _textController;
  ScrollController? _scrollController;
  FocusNode? _focusNode;
  bool _goDown = true;

  @override
  void initState() {
    _textController = TextEditingController(text: _keyword);
    _scrollController = ScrollController();
    _focusNode = FocusNode();
    super.initState();
  }

  @override
  void dispose() {
    _textController!.dispose();
    _scrollController!.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ValueListenableBuilder<int>(
            valueListenable: LoggerNet.typeLength,
            builder: (context, value, child) {
              return _buildTools();
            },
          ),
          Expanded(
            child: ValueListenableBuilder<int>(
              valueListenable: LoggerNet.length,
              builder: (context, value, child) {
                List<LoggerNet> logs = LoggerNet.list;
                if (!_selectTypes.contains(LoggerNet.all)) {
                  logs = LoggerNet.list.where((test) {
                    return _selectTypes.contains(test.type) &&
                        test.contains(_keyword);
                  }).toList();
                } else if (_keyword.isNotEmpty) {
                  logs = LoggerNet.list.where((test) {
                    return test.contains(_keyword);
                  }).toList();
                }

                final len = logs.length;
                return ListView.separated(
                  itemBuilder: (context, index) {
                    final item = Logger.config.reverse
                        ? logs[len - index - 1]
                        : logs[index];
                    return _buildItem(item, context);
                  },
                  itemCount: len,
                  controller: _scrollController,
                  reverse: Logger.config.reverse,
                  separatorBuilder: (context, index) {
                    return const Divider(
                      height: 10,
                      thickness: 0.5,
                      color: Color(0xFFE0E0E0),
                    );
                  },
                );
              },
            ),
          ),
        ],
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

  Widget _buildItem(LoggerNet item, context) {
    final color = _getColor(item.status);
    return InkWell(
      onTap: () {
        item.showDetail = !item.showDetail;
        setState(() {});
      },
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "[${item.type}] ${item.api}",
                    style: const TextStyle(fontSize: 16),
                  ),
                  if (item.showDetail && item.reqHeaders != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Req Headers: ${item.reqHeaders ?? ""}",
                        maxLines: 100,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (item.showDetail)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Request: ${item.req ?? ""}",
                        maxLines: 100,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (item.showDetail && item.resHeaders != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Res Headers: ${item.resHeaders ?? ""}",
                        maxLines: 100,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  if (item.showDetail)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        "Response: ${item.res ?? ""}",
                        maxLines: 100,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${item.start!.hour}:${item.start!.minute}:${item.start!.second}:${item.start!.millisecond}",
                            style: const TextStyle(fontSize: 14),
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          child: Text(
                            "${item.spend} ms",
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.visible,
                            maxLines: 1,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "${item.getReqSize()}/${item.getResSize()}B",
                            style: const TextStyle(fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
            InkWell(
              onTap: () {
                final ClipboardData data = ClipboardData(text: item.toString());
                Clipboard.setData(data);
                showDialog(
                  context: context,
                  barrierDismissible: true,
                  builder: (context) {
                    return const Center(
                      child: Material(
                        color: Colors.transparent,
                        child: Text(
                          "copy success!",
                          style: TextStyle(color: Colors.white, fontSize: 30),
                        ),
                      ),
                    );
                  },
                );
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    item.status.toString(),
                    style: TextStyle(fontSize: 20, color: color),
                  ),
                  if (item.showDetail)
                    const Text(
                      "copy",
                      style: TextStyle(fontSize: 16, color: Colors.blue),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColor(int status) {
    if (status == 200 || status == 0) {
      return Colors.green;
    } else if (status < 200) {
      return Colors.blue;
    } else {
      return Colors.red;
    }
  }

  final List<String> _selectTypes = [LoggerNet.all];

  Widget _buildTools() {
    final List<ChoiceChip> arr = [];
    LoggerNet.types.forEach((f) {
      arr.add(
        ChoiceChip(
          label: Text(f, style: const TextStyle(fontSize: 14)),
          selectedColor: const Color(0xFFCBE2F6),
          selected: _selectTypes.contains(f),
          onSelected: (value) {
            _selectTypes.contains(f)
                ? _selectTypes.remove(f)
                : _selectTypes.add(f);
            setState(() {});
          },
        ),
      );
    });
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 5, 0, 5),
      child: AnimatedCrossFade(
        crossFadeState:
            _showSearch ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 300),
        firstChild: Row(
          children: [
            Expanded(
              child: Wrap(
                spacing: 5,
                children: arr,
              ),
            ),
            const IconButton(
              icon: Icon(Icons.clear),
              onPressed: LoggerNet.clear,
            ),
            IconButton(
              icon: _keyword.isEmpty
                  ? const Icon(Icons.search)
                  : const Icon(Icons.filter_1),
              onPressed: () {
                _showSearch = true;
                setState(() {});
                _focusNode!.requestFocus();
              },
            ),
          ],
        ),
        secondChild: Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 36,
                child: TextField(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.all(6),
                  ),
                  controller: _textController,
                  focusNode: _focusNode,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                _showSearch = false;
                _keyword = _textController!.text;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }
}
