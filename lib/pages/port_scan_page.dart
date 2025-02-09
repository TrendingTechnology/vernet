import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:network_tools/network_tools.dart';
import 'package:vernet/helper/port_desc_loader.dart';
import 'package:vernet/main.dart';
import 'package:vernet/models/port.dart';

class PortScanPage extends StatefulWidget {
  const PortScanPage({Key? key}) : super(key: key);

  @override
  _PortScanPageState createState() => _PortScanPageState();
}

class _PortScanPageState extends State<PortScanPage> {
  Set<OpenPort> _openPorts = {};
  Map<String, Port> _allPorts = {};
  TextEditingController _textEditingController = TextEditingController();
  StreamSubscription<OpenPort>? _streamSubscription;
  bool _completed = true;
  _startScanning() {
    setState(() {
      _completed = false;
      _openPorts.clear();
    });

    _streamSubscription = PortScanner.discover(_textEditingController.text,
            timeout: Duration(milliseconds: appSettings.socketTimeout))
        .listen((event) {
      if (event.isOpen) {
        setState(() {
          _openPorts.add(event);
        });
      }
    }, onDone: () {
      setState(() {
        _completed = true;
      });
    });
  }

  @override
  void initState() {
    super.initState();

    PortDescLoader("assets/ports_lists.json").load().then((value) {
      print("Fetched ports : ${value.length}");
      setState(() {
        _allPorts.addAll(value);
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _textEditingController.dispose();
    _streamSubscription?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Open Ports Scanner'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            //TODO: ip validation
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _textEditingController,
                        decoration: InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: 'Enter a domain or IP'),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 10.0),
                      child: ElevatedButton(
                        onPressed: _completed ? _startScanning : null,
                        child: Text(_completed ? 'Scan' : 'Scanning'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _openPorts.isEmpty
                ? Center(
                    child: Text('Open ports will appear here'),
                  )
                : ListView.builder(
                    itemCount: _openPorts.length,
                    itemBuilder: (context, index) {
                      OpenPort _openPort = _openPorts.toList()[index];
                      return Column(
                        children: [
                          ListTile(
                            dense: true,
                            contentPadding:
                                EdgeInsets.only(left: 10.0, right: 10.0),
                            leading: Text(
                              '${_openPort.port}',
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1!
                                  .copyWith(
                                      color: Theme.of(context).accentColor),
                            ),
                            title: _allPorts.isEmpty
                                ? SizedBox()
                                : Text(
                                    _allPorts[_openPort.port.toString()]!.desc),
                            subtitle: _allPorts.isEmpty
                                ? SizedBox()
                                : Row(
                                    children: [
                                      _allPorts[_openPort.port.toString()]!
                                              .isTCP
                                          ? Text('TCP   ')
                                          : SizedBox(),
                                      _allPorts[_openPort.port.toString()]!
                                              .isUDP
                                          ? Text('UDP   ')
                                          : SizedBox(),
                                      Text(_allPorts[_openPort.port.toString()]!
                                          .status),
                                    ],
                                  ),
                          ),
                          Divider(height: 4),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
