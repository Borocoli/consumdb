import 'dart:async';
import 'dart:io';
import 'package:path/path.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';

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
      },
    );
  }
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
        ],
      ),
    );
  }
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
          Text('Test'),
          Row(
            children: [
              Text('Nume'),
              Spacer(),
              Text('Minim'),
              Spacer(),
              Text('Total'),
            ],
          ),
          FutureBuilder<List<Produs>>(
              future: DbHelper.instance.getProduse(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Produs>> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: Text('Nu exista produse'));
                }
                return ListView(
                  shrinkWrap: true,
                  children: snapshot.data!.map((produs) {
                    return Center(
                      child: ListTile(
                        title: Row(children: [
                          Text(produs.nume),
                          Spacer(),
                          Text(produs.min.toString()),
                          Spacer(),
                          Text(produs.tot.toString()),
                        ]),
                        onTap: () {
                          Navigator.pushNamed(context, '/produse/produs',
                              arguments: produs);
                        },
                      ),
                    );
                  }).toList(),
                );
              }),
          Spacer(),
          Row(
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/');
                },
                child: const Text('Inapoi'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/produse/add');
                },
                child: const Text('Adauga'),
              ),
            ],
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

  Future<String> insertProdus(Produs p) async {
    WidgetsFlutterBinding.ensureInitialized();
    final database = openDatabase(
      join(await getDatabasesPath(), 'consum2.db'),
      onCreate: (Database db, int version) async {
        await db.execute(
          '''CREATE TABLE produs (nume TEXT PRIMARY KEY, min INT, tot INT)''',
        );
      },
      version: 1,
    );
    final db = await database;
    await db.insert(
      'produs',
      p.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    return 'Done';
  }

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
                    return null;
                  },
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_prodKey.currentState!.validate()) {
                      var p = Produs(nume: nm, min: min, tot: tot);
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
          Text('Minim: ' + args.min.toString()),
          Text('Total: ' + args.tot.toString()),
          Form(
            child: Column(
              children: <Widget>[
                TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Modifica',
                    ),
                    validator: (value) {
                      if (int.tryParse(value.toString()) == 0 ||
                          value == null ||
                          value.isEmpty) {
                        return "Trebuie sa fie un numar";
                      } else {
                        val = int.tryParse(value.toString());
                        val = val + args.tot;
                        return null;
                      }
                    }),
                ElevatedButton(
                  onPressed: () async {
                    if (_fKey.currentState!.validate()) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("test")),
                      );
                      await DbHelper.instance.updateProd(args.nume, val);
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class Produs {
  final String nume;
  final int min;
  final int tot;

  const Produs({
    required this.nume,
    required this.min,
    required this.tot,
  });

  Map<String, dynamic> toMap() {
    return {
      'nume': nume,
      'min': min,
      'tot': tot,
    };
  }

  factory Produs.fromMap(Map<String, dynamic> json) => new Produs(
        nume: json['nume'],
        min: json['min'],
        tot: json['tot'],
      );
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
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute(
      '''CREATE TABLE produs (nume TEXT PRIMARY KEY, min INT, tot INT)''',
    );
  }

  Future<List<Produs>> getProduse() async {
    Database db = await instance.database;
    var produse = await db.query('produs', orderBy: 'nume');
    List<Produs> prodlist = produse.isNotEmpty
        ? produse.map((c) => Produs.fromMap(c)).toList()
        : [];
    return prodlist;
  }

  Future<int> addProdus(Produs prod) async {
    Database db = await instance.database;
    return await db.insert(
      'produs',
      prod.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> updateProd(String nume, int tot) async {
    Database db = await instance.database;
    return await db.rawUpdate('''
	UPDATE produs
	SET tot = ?
	WHERE nume = ?''', [tot, nume]);
  }
}
