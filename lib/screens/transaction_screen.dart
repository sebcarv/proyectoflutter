import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bank_app/screens/second_screen.dart';

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String userAccount = "";
  double balance = 0.0;
  bool isLoading = true;
  Future<void> getAccount() async {
    final db = FirebaseFirestore.instance;

    try {
      final querySnapshot = await db.collection("accounts").get();
      for (var doc in querySnapshot.docs) {
        final data = doc.data();
        if (data["account"] == "00123456") {
          setState(() {
            userAccount = data["account"];
            balance = data["amount"].toDouble();
          });
          break;
        }
      }
    } catch (e) {
      print("Error al obtener datos: $e");
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAccount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Movimientos'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Colors.blue,
      body: Column(
        children: [
          Text(
            "Cuenta: $userAccount",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text("Saldo: \$${balance.toStringAsFixed(2)}",
              style: const TextStyle(
                  fontSize: 18,
                  color: Colors.red,
                  fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder(
              stream: getTransactionsStream(),
              builder: (context, AsyncSnapshot<List<Transaction>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                      child: Text('No hay transacciones disponibles.'));
                }

                final transactions = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Cuenta: ${transaction.receiver}'),
                        subtitle: Text('Fecha: ${transaction.date}'),
                        trailing:
                            Text('\$${transaction.amount.toStringAsFixed(2)}'),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => SecondScreen()));
            },
            child: const Text(
              'Volver',
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Stream<List<Transaction>> getTransactionsStream() {
    return FirebaseFirestore.instance
        .collection('transactions')
        .snapshots()
        .asyncMap((snapshot) async {
      List<Transaction> transactions = [];
      for (var doc in snapshot.docs) {
        final data = doc.data();

        transactions.add(Transaction(
          receiver: data['receiver'],
          amount: data['amount'] ?? 0.0,
          sender: data['sender'],
          date: (data['date'] as Timestamp).toDate(),
        ));
      }

      return transactions;
    });
  }
}

class Transaction {
  final double amount;
  final String sender;
  final String receiver;
  final DateTime date;

  Transaction({
    required this.sender,
    required this.amount,
    required this.receiver,
    required this.date,
  });
}
