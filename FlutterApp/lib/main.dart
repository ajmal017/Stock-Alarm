import 'package:flutter/material.dart';
import 'models/alarm.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var init = true;
  String chosenSymbol;
  //var pairs = <String>['AAPL', 'GOOGL', 'IBM'];
  //List<Alarm> alarms = [Alarm("AAPL", 250.43), Alarm("GOOGL", 500.03)];
  List<Alarm> alarms = [];
  List<String> pairs = [];
  var user;

  @override
  void initState() {
    /*  final _firebaseMessaging = FirebaseMessaging();
    _firebaseMessaging.getToken().then((value) {
      print(value);
    }); */

    Firestore.instance.collection("Alarms").getDocuments().then((value) {
      value.documents.forEach((document) {
        var symbol = document.documentID;
        print(symbol);
        document.data.forEach((key, value) {
          String alarmId = key;
          String owner = value["Owner"];
          var level = value["Level"];
          setState(() {
            alarms.add(Alarm(symbol, level));
          });
        });
      });
    });

    super.initState();
  }

  void addAlarm(symbol, level) {
    var alarm = Alarm(symbol, level);

    Firestore.instance.collection("Alarms").document(symbol).setData({
      alarm.id: alarm.toJson(),
    });

    var userId = "notimplemented"; //TODO firebaseauth
    Firestore.instance.collection("Users").document(userId).setData({
      alarm.id: alarm.toJson(),
    });

/*
    Firestore.instance
        .collection('Alarms')
        .document("AUDUSD")
        .delete()
        .then((lol) {}); */
  }

  @override
  void didChangeDependencies() {
    if (init) {
      final _firebaseMessaging = FirebaseMessaging();
      _firebaseMessaging.configure(
        // ignore: missing_return
        onMessage: (Map<String, dynamic> message) {
          print('on message ${message}');
          showDialog(
              context: context,
              builder: (BuildContext ctx) {
                return AlertDialog(
                  title: Text("ALARM"),
                );
              });
        },
        // ignore: missing_return
        onResume: (Map<String, dynamic> message) {
          print('on resume $message');
        },
        // ignore: missing_return
        onLaunch: (Map<String, dynamic> message) {
          print('on launch $message');
        },
      );
      init = false;
    }
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    final appBar = AppBar(
      title: Text('Stock Alarm'),
    );
    final deviceHeight = MediaQuery.of(context).size.height -
        appBar.preferredSize.height -
        (2 * 16) -
        MediaQuery.of(context).padding.top;

    print(deviceHeight);
    print(MediaQuery.of(context).size.height);
    print(appBar.preferredSize.height);
    print(MediaQuery.of(context).padding.top);
    //console.log(deviceHeight);

    return Scaffold(
      appBar: appBar,
      body: Column(
        children: <Widget>[
          //Material example
          Container(
            //margin: EdgeInsets.all(15),
            padding: EdgeInsets.all(10),
            height: deviceHeight * 0.15,
            child: Row(
              children: <Widget>[
                Expanded(
                  child: LayoutBuilder(
                    builder:
                        (BuildContext context, BoxConstraints constraints) {
                      return DropdownButton(
                        hint: Container(
                          width: constraints.maxWidth - 24,
                          child: FittedBox(
                            child: Text("Choose a Stocksymbol"),
                            fit: BoxFit.fill,
                          ),
                        ),
                        value: chosenSymbol,
                        items: pairs.map((String value) {
                          return new DropdownMenuItem<String>(
                            value: value,
                            child: new Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            chosenSymbol = newValue;
                          });
                        },
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 16.0,
                ),
                Flexible(
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        filled: true,
                        hintText: 'Enter text',
                        labelText: 'Alarm Price'),
                    controller: new TextEditingController(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 16.0,
          ),
          Container(
            height: deviceHeight * 0.08,
            child: FlatButton(
              onPressed: () {
                addAlarm("AUDUSD", 104.3);
              },
              child: Text("Add Alarm"),
              color: Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(
            height: 16.0,
          ),
          Container(
            height: deviceHeight * 0.77,
            child: ListView.builder(
              itemCount: alarms.length,
              itemBuilder: (ctx, index) {
                return ListTile(
                  trailing: Text(
                    alarms[index].symbol,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  title: Text(alarms[index].level.toString() + "\$"),
                );
              },
            ),
          )
          //Alternate
        ],
      ),
    );
  }
}
