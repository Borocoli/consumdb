import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

import 'package:csv/csv.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ConsumDB',
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/produse': (context) => const ProdusePage(),
        '/produse/add': (context) => const AddProduse(),
        '/produse/produs': (context) => const ProdusPage(),
        '/lista': (context) => const ListaPage(),
        '/save': (context) => const ImportExportDB(),
      },
    );
  }
}

Widget PopUp(
    BuildContext context, String nume, var data, String func, String path,
    [Produs? args = null]) {
  bool change = false;
  var val;
  return AlertDialog(
    title: Text(nume),
    content: Text(data.toString()),
    actions: <Widget>[
      TextField(
        onChanged: (String text) {
          if (text.isNotEmpty) {
            if (data.runtimeType == 'int') {
              print(int.tryParse(text));
              if (int.tryParse(text) != null) {
                val = text;
              }
            } else {
              val = text;
            }
            change = true;
          }
        },
      ),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Inapoi'),
      ),
      TextButton(
        onPressed: () async {
          print(change);
          if (change) {
            if (func == 'lista') {
              await DbHelper.instance.updateLista(nume, int.tryParse(val)!);
            } else {
              if (data.runtimeType == int) {
                await DbHelper.instance
                    .changeProd(nume, func, int.tryParse(val)!);
              } else {
                await DbHelper.instance.changeProd(nume, func, val);
              }
            }
            print(args);
            if (args != null) {
              if (func == 'min') {
                args.minim = int.tryParse(val)!;
              } else if (func == 'tot') {
                args.total = int.tryParse(val)!;
              } else if (func == 'cump') {
                args.cumparat = int.tryParse(val)!;
              } else {
                args.prod_nume = val;
              }
            }
            print(path);
            Navigator.pushNamed(context, path, arguments: args);
            return;
          }
          return Navigator.pop(context);
        },
        child: const Text('Submit'),
      ),
    ],
  );
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ConsumDB'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Produse'),
            onTap: () {
              Navigator.pushNamed(context, '/produse');
            },
          ),
          ListTile(
            title: Text('Lista'),
            onTap: () {
              Navigator.pushNamed(context, '/lista');
            },
          ),
          ListTile(
            title: Text('Import/Export'),
            onTap: () {
              Navigator.pushNamed(context, '/save');
            },
          ),
        ],
      ),
    );
  }
}

Widget list_tile(int f, String data, [Color c = Colors.black]) {
  return Expanded(
    flex: f,
    child: Container(
      height: 30.0,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(),
          left: BorderSide(),
          right: BorderSide(),
          bottom: BorderSide(),
        ),
      ),
      child: Center(
        child: Text(
          data,
          style: TextStyle(
            color: c,
          ),
        ),
      ),
    ),
  );
}

class ProdusePage extends StatefulWidget {
  const ProdusePage({Key? key}) : super(key: key);

  @override
  _ProdusePageState createState() => _ProdusePageState();
}

class _ProdusePageState extends State<ProdusePage> {
  var list = [];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Produse'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                list_tile(3, 'Nume'),
                list_tile(1, 'Minim'),
                list_tile(1, 'Total'),
              ],
            ),
          ),
          FutureBuilder<List<Produs>>(
              future: DbHelper.instance.getProduse(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Produs>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Nu exista produse'));
                }
                return Expanded(
                  flex: 8,
                  child: ListView(
                    shrinkWrap: true,
                    children: snapshot.data!.map((produs) {
                      var c = (produs.tot >= produs.min)
                          ? Colors.black
                          : Colors.red;
                      return ListTile(
                        title: Row(children: [
                          list_tile(3, produs.nume, c),
                          list_tile(1, produs.min.toString(), c),
                          list_tile(1, produs.tot.toString(), c),
                        ]),
                        onTap: () {
                          Navigator.pushNamed(context, '/produse/produs',
                              arguments: produs);
                        },
                      );
                    }).toList(),
                  ),
                );
              }),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/');
                  },
                  child: const Text('Inapoi'),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/produse/add');
                  },
                  child: const Text('Adauga'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddProduse extends StatefulWidget {
  const AddProduse({Key? key}) : super(key: key);

  @override
  AddProduseState createState() {
    return AddProduseState();
  }
}

class AddProduseState extends State<AddProduse> {
  final _prodKey = GlobalKey<FormState>();
  String nm = '';
  int min = 0;
  int tot = 0;
  int cump = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adauga produs'),
      ),
      body: Column(
        children: [
          Form(
            key: _prodKey,
            child: Column(
              children: [
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Nume produs',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Produsul are nevoie de un nume';
                    }
                    nm = value;
                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Minim produs',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      value = '0';
                    } else if (int.tryParse(value.toString()) == null) {
                      return 'Minimul trebuie sa fie un numar ';
                    }
                    min = int.tryParse(value.toString())!;
                    if (min < 0) {
                      min *= -1;
                    }

                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Total produs',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      value = '0';
                    } else if (int.tryParse(value.toString()) == null) {
                      return 'Totalul trebuie sa fie un numar';
                    }
                    tot = int.tryParse(value.toString())!;
                    if (tot < 0) {
                      tot *= -1;
                    }

                    return null;
                  },
                ),
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Cat de cumparat',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      value = '0';
                    } else if (int.tryParse(value.toString()) == null) {
                      return 'Trebuie sa fie un numar ';
                    }
                    cump = int.tryParse(value.toString())!;
                    if (cump < 0) {
                      cump *= -1;
                    }
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_prodKey.currentState!.validate()) {
                      var p = Produs(nume: nm, min: min, tot: tot, cump: cump);
                      await DbHelper.instance.addProdus(p);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/produse');
            },
            child: const Text('Inapoi'),
          ),
        ],
      ),
    );
  }
}

class ProdusPage extends StatefulWidget {
  const ProdusPage({Key? key}) : super(key: key);

  @override
  _ProdusPageState createState() => _ProdusPageState();
}

class _ProdusPageState extends State<ProdusPage> {
  final _fKey = GlobalKey<FormState>();
  var val;
  @override
  Widget build(BuildContext context) {
    WidgetsFlutterBinding.ensureInitialized();
    final args = ModalRoute.of(context)!.settings.arguments as Produs;
    return Scaffold(
      appBar: AppBar(
        title: Text(args.nume),
      ),
      body: Column(
        children: [
          Row(
            children: [
              list_tile(3, 'Nume'),
              list_tile(3, args.nume),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PopUp(context, args.nume, args.nume, 'nume',
                            '/produse/produs', args);
                      }),
                  child: Text('+'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              list_tile(3, 'Minim'),
              list_tile(3, args.min.toString()),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PopUp(context, args.nume, args.min, 'min',
                            '/produse/produs', args);
                      }),
                  child: Text('+'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              list_tile(3, 'Cump'),
              list_tile(3, args.cump.toString()),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PopUp(context, args.nume, args.cump, 'cump',
                            '/produse/produs', args);
                      }),
                  child: Text('+'),
                ),
              ),
            ],
          ),
          Row(
            children: [
              list_tile(3, 'Total'),
              list_tile(3, args.tot.toString()),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: () => showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return PopUp(context, args.nume, args.tot, 'tot',
                            '/produse/produs', args);
                      }),
                  child: Text('+'),
                ),
              ),
            ],
          ),
          Form(
            key: _fKey,
            child: Column(
              children: <Widget>[
                TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Modifica total',
                    ),
                    validator: (value) {
                      if (int.tryParse(value.toString()) == 0 ||
                          value == null ||
                          value.isEmpty) {
                        return "Trebuie sa fie un numar";
                      } else {
                        val = int.tryParse(value.toString());
                        return null;
                      }
                    }),
                ElevatedButton(
                  onPressed: () async {
                    if (_fKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Inregistrat")),
                      );
                      await DbHelper.instance.updateProd(args.nume, val);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
          Spacer(),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/produse');
            },
            child: const Text('Inapoi'),
          ),
        ],
      ),
    );
  }
}

class ListaPage extends StatefulWidget {
  const ListaPage({Key? key}) : super(key: key);

  @override
  _ListaPageState createState() => _ListaPageState();
}

class _ListaPageState extends State<ListaPage> {
  Map<String, bool?> checked = Map();
  Map<String, int> vals = Map();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lista'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 1,
            child: Row(
              children: [
                list_tile(4, 'Nume'),
                list_tile(1, 'Cantitate'),
                list_tile(1, 'Tick'),
              ],
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
              future: DbHelper.instance.getLista(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Lista e goala'));
                }
                final c = Colors.black;
                if (checked.isEmpty) {
                  checked = <String, bool?>{
                    for (var e in snapshot.data!) e['nume']: false
                  };
                  vals = <String, int>{
                    for (var e in snapshot.data!) e['nume']: e['cant']
                  };
                }
                return Expanded(
                  flex: 8,
                  child: ListView(
                    shrinkWrap: true,
                    children: snapshot.data!.map((produs) {
                      return ListTile(
                        title: Row(children: [
                          list_tile(4, produs['nume'], c),
                          list_tile(1, produs['cant'].toString(), c),
                          Checkbox(
                            value: checked[produs['nume']],
                            onChanged: (bool? value) {
                              setState(() {
                                checked[produs['nume']] = value;
                              });
                            },
                          ),
                        ]),
                        onTap: () => showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return PopUp(context, produs['nume'],
                                produs['cant'], 'lista', '/lista');
                          },
                        ),
                      );
                    }).toList(),
                  ),
                );
              }),
          Expanded(
            flex: 1,
            child: Row(
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/');
                  },
                  child: const Text('Inapoi'),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: () async {
                    for (String key in checked.keys) {
                      if (checked[key] == true) {
                        await DbHelper.instance.updateProd(key, vals[key]!);
                      }
                    }
                    Navigator.pushNamed(context, '/lista');
                  },
                  child: const Text('Submit'),
                ),
                Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ImportExportDB extends StatelessWidget {
  const ImportExportDB({Key? key}) : super(key: key);

  Future<bool> showAlertDialog(BuildContext context) async {
    bool mod = false;
    Widget ok = TextButton(
      child: Text("OK"),
      onPressed: () async {
        await DbHelper.instance.importCsv();
        mod = true;
        Navigator.of(context).pop();
      },
    );
    Widget cancel = TextButton(
      child: Text("Cancel"),
      onPressed: () {
        mod = false;
        Navigator.of(context).pop();
      },
    );

    AlertDialog alert = AlertDialog(
      title: Text("Alerta de Import"),
      content: Text("Urmeaza sa stergi baza de date si s-o refaci. Continua?"),
      actions: [
        ok,
        cancel,
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        });
    return mod;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Import/Export'),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text('Import'),
            onTap: () async {
              var mod = false;
              mod = await showAlertDialog(context);
              if (mod == true) {
                final snack = SnackBar(content: const Text('Done'));
                ScaffoldMessenger.of(context).showSnackBar(snack);
              }
            },
          ),
          ListTile(
            title: Text('Export'),
            onTap: () async {
              await DbHelper.instance.exportCsv();
              final snack = SnackBar(content: const Text('Done'));
              ScaffoldMessenger.of(context).showSnackBar(snack);
            },
          ),
        ],
      ),
    );
  }
}

class Produs {
  String nume;
  int min;
  int tot;
  int cump;

  Produs({
    required this.nume,
    required this.min,
    required this.tot,
    required this.cump,
  });

  set total(int x) {
    tot = x;
  }

  set minim(int x) {
    min = x;
  }

  set cumparat(int x) {
    cump = x;
  }

  set prod_nume(String n) {
    nume = n;
  }

  Map<String, dynamic> toMap() {
    return {
      'nume': nume,
      'min': min,
      'tot': tot,
      'cump': cump,
    };
  }

  factory Produs.fromMap(Map<String, dynamic> json) => new Produs(
        nume: json['nume'],
        min: json['min'],
        tot: json['tot'],
        cump: json['cump'],
      );

  List<String> toStrings() {
    List<String> tmp = [nume, min.toString(), tot.toString(), cump.toString()];
    return tmp;
  }
}

class DbHelper {
  DbHelper._privateConstructor();
  static final DbHelper instance = DbHelper._privateConstructor();
  static Database? _database;
  Future<Database> get database async => _database ??= await _initDatabase();
  Future<Database> _initDatabase() async {
    Directory dir = await getApplicationDocumentsDirectory();
    String path = join(dir.path, 'consum.db');
    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: _onUpdate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE produs (nume TEXT PRIMARY KEY, min INT, tot INT, cump INT)''',
    );
    await db
        .execute(''' CREATE TABLE lista (nume TEXT PRIMARY KEY, cant INT) ''');
  }

  Future _onUpdate(Database db, int ov, int nv) async {
    if (ov < 2) {
      await db.execute('ALTER TABLE produs ADD cump INT');
      await db.execute('UPDATE produs SET cump=0');
    }
    if (ov < 3) {
      await db.execute(
          ''' CREATE TABLE lista (nume TEXT PRIMARY KEY, cant INT) ''');
    }
  }

  Future _onDestroy(Database db) async {
    await db.execute('DROP TABLE produs');
    await db.execute('DROP TABLE lista');
  }

  Future<List<Produs>> getProduse() async {
    Database db = await instance.database;
    var produse = await db.query('produs', orderBy: 'nume');
    List<Produs> prodlist = produse.isNotEmpty
        ? produse.map((c) => Produs.fromMap(c)).toList()
        : [];
    return prodlist;
  }

  Future<List<Map<String, dynamic>>> getLista() async {
    Database db = await instance.database;
    var produse = await db.query('lista', orderBy: 'nume');
    return produse;
  }

  Future<int> checkProdus(Produs prod) async {
    Database db = await instance.database;
    int val = 0;
    if (prod.min > prod.tot) {
      if (prod.cump == 0)
        val = prod.min - prod.tot;
      else
        val = prod.cump;
      return await db.insert(
        'lista',
        {'nume': prod.nume, 'cant': val},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await db.execute('DELETE FROM lista WHERE nume = ?', [prod.nume]);
    }
    return 0;
  }

  Future<int> addProdus(Produs prod) async {
    Database db = await instance.database;
    checkProdus(prod);
    return await db.insert(
      'produs',
      prod.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> updateProd(String nume, int add) async {
    Database db = await instance.database;

    var produse =
        await db.rawQuery('SELECT * FROM produs WHERE nume = ?', [nume]);
    List<Produs> prodlist = produse.isNotEmpty
        ? produse.map((c) => Produs.fromMap(c)).toList()
        : [];
    prodlist[0].total = prodlist[0].tot + add;
    await db.rawUpdate('''UPDATE produs SET tot = ? WHERE nume = ?''',
        [prodlist[0].tot, nume]);
    checkProdus(prodlist[0]);
  }

  Future<void> changeProd(String nume, String charact, var val) async {
    Database db = await instance.database;
    await db.update('produs', {charact: val},
        where: 'nume = ?', whereArgs: [nume]);
    var produse =
        await db.rawQuery('SELECT * FROM produs WHERE nume = ?', [nume]);
    List<Produs> prodlist = produse.isNotEmpty
        ? produse.map((c) => Produs.fromMap(c)).toList()
        : [];
    checkProdus(prodlist[0]);
  }

  Future<void> updateLista(String nume, int add) async {
    Database db = await instance.database;
    await db
        .rawUpdate('''UPDATE lista SET cant = ? WHERE nume = ?''', [add, nume]);
  }

  exportCsv() async {
    String dir = (await getExternalStorageDirectory())!.path + "/DBconsum.csv";
    String file = "$dir";
    File f = new File(file);
    Database db = await instance.database;
    var produse = await db.rawQuery('Select * FROM produs');
    List<List<String>> list = List.empty(growable: true);
    for (var i in produse) {
      List<String> tmp = [
        i["nume"].toString(),
        i["min"].toString(),
        i["tot"].toString(),
        i["cump"].toString(),
      ];
      list.add(tmp);
    }
    String csv = const ListToCsvConverter().convert(list);
    f.writeAsString(csv);
  }

  importCsv() async {
    String dir = (await getExternalStorageDirectory())!.path + "/DBconsum.csv";
    String file = "$dir";
    File f = new File(file);
    final produse = f.readAsLinesSync()!.map((line) {
      final parts = line.split(',');
      return Produs(
          nume: parts[0],
          min: int.tryParse(parts[1])!,
          tot: int.tryParse(parts[2])!,
          cump: int.tryParse(parts[3])!);
    }).toList();
    print(produse);
    Database db = await instance.database;
    _onDestroy(db);
    _onCreate(db, 3);
    for (Produs prod in produse) {
      addProdus(prod);
      checkProdus(prod);
    }
    //String csv = const ListToCsvConverter().convert(list);
    //f.writeAsString(csv);
  }
}
