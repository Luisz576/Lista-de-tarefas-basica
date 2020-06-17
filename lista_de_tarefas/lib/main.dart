import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

String _title = "Lista de tarefas";

void main(){
  runApp(
    MaterialApp(
      title: _title,
      home: new Home(),
    )
  );
}

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List _toDoList = [];
  Map<String, dynamic> _lastRemoved;
  int _lastRemovedPos;
  final _controllerAdd = new TextEditingController();

  @override
  void initState() {
    super.initState();
    _readData().then((data){ //Assim que pega os dados executa a funcao
      setState(() {
        _toDoList = json.decode(data);
        _toDoList.sort((a, b){
          if(a['ok'] && !b['ok']){
            return 1;
          }else if(!a['ok'] && b['ok']){
            return -1;
          }else{
            return 0;
          }
        });
      });
    });
  }

  void _addToDo(){
    setState(() {
      Map<String, dynamic> newToDo = new Map();
      newToDo['title'] = _controllerAdd.text;
      _controllerAdd.text = "";
      newToDo['ok'] = false;
      _toDoList.add(newToDo);
      _saveData();
    });
  }

  Future<Null> _refresh() async{
    await Future.delayed(Duration(seconds: 1));
    setState(() {
      _toDoList.sort((a, b){
        if(a['ok'] && !b['ok']){
          return 1;
        }else if(!a['ok'] && b['ok']){
          return -1;
        }else{
          return 0;
        }
      });
    });
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 25.0,
          ),
          textAlign: TextAlign.center,
        ),
        backgroundColor: Colors.lightBlue,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.only(left: 17.0, top: 1.0, right: 7.0, bottom: 1.0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _controllerAdd,
                    decoration: InputDecoration(
                        labelText: "Nova tarefa",
                        labelStyle: TextStyle(color: Colors.blueAccent)
                    ),
                  ),
                ),
                RaisedButton(
                  color: Colors.blueAccent,
                  child: Text("Add"),
                  textColor: Colors.white,
                  onPressed: _addToDo,
                )
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
                child: ListView.builder(
                  padding: EdgeInsets.only(top: 10.0),
                  itemCount: _toDoList.length,
                  itemBuilder: buildItem,
                ),
                onRefresh: _refresh
            ),
          ),
        ],
      ),
    );
  }

  Widget buildItem(BuildContext context, int index){
      return Dismissible(
        key: Key(DateTime.now().millisecondsSinceEpoch.toString()),
        background: Container(
          color: Colors.red,
          child: Align(
            child: Icon(
                Icons.delete,
                color: Colors.white
            ),
            alignment: Alignment(-0.9, 0.0),
          ),
        ),
        direction: DismissDirection.startToEnd,
        child: CheckboxListTile(
          title: Text(_toDoList[index]["title"]),
          value: _toDoList[index]["ok"],
          secondary: CircleAvatar(
            child: Icon(_toDoList[index]["ok"] ? Icons.check : Icons.error), //if(?) else(:),
          ),
          onChanged: (c){
            setState(() {
              _toDoList[index]['ok'] = c;
              _saveData();
            });
          },
        ),
        onDismissed: (direction){
          setState((){
            _lastRemoved = Map.from(_toDoList[index]);
            _lastRemovedPos = index;
            _toDoList.removeAt(index);
            _saveData();
            final snack = SnackBar(
              content: Text("Tarefa \"${_lastRemoved['title']}\" removida!"),
              action: SnackBarAction(
                  label: "Desfazer",
                  onPressed: () {
                    setState((){
                      _toDoList.insert(_lastRemovedPos, _lastRemoved);
                      _saveData();
                    });
                  }
              ),
              duration: Duration(seconds: 3),
            );
            Scaffold.of(context).removeCurrentSnackBar();
            Scaffold.of(context).showSnackBar(snack);
          });
        },
      );
  }

  Future<File> _getFile() async{
    final directory = await getApplicationDocumentsDirectory();
    return File("${directory.path}/data.json");
  }

  Future<File> _saveData() async{
    String data = json.encode(_toDoList);
    final file = await _getFile();
    return file.writeAsString(data);
  }

  Future<String> _readData() async{
    try{
      final file = await _getFile();
      return file.readAsString();
    }catch(e){
      return null;
    }
  }

}