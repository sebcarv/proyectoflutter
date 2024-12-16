import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:bank_app/screens/second_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
      ),
      home: const MyHomePage(
        title: 'Banco',
        nameButton: 'Inicio',
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.nameButton});

  final String title;
  final String nameButton;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Future<void> createAccount() async {
    final db = FirebaseFirestore.instance;
    await db.collection("accounts").get().then((event) {
      if (event.docs.isEmpty) {
        final account = <String, dynamic>{
          "account": "00123456",
          "amount": 180000000
        };
        db.collection("accounts").add(account);
      }
      for (var doc in event.docs) {
        print("${doc.id} => ${doc.data()}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      backgroundColor: Color(0xFF42A5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'Inicio de la aplicación bancaria',
            ),
            const SizedBox(height: 20),
            ClipOval(
                child: Image.asset('assets/bank.jpg',
                    width: 200, height: 200, fit: BoxFit.cover)),
            const SizedBox(height: 20),
            ElevatedButton(
                onPressed: () {
                  createAccount();
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SecondScreen()));
                },
                child: Text(widget.nameButton))
          ],
        ),
      ),
    );
  }
}
