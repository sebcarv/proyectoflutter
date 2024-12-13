import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:bank_app/screens/account_view.dart';

class TransactionScreen extends StatefulWidget {
  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  double amount = 0;

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
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AccountView(),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateAccountBalance('00123456', amount);
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => AccountView()));
            },
            child: const Text(
              'Actualizar saldo',
              style: TextStyle(color: Color.fromARGB(255, 255, 0, 0)),
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

        if (data["submit"] == false) {
          amount += data["amount"] ?? 0.0;
        }

        transactions.add(Transaction(
          receiver: data['receiver'],
          amount: data['amount'] ?? 0.0,
          sender: data['sender'],
          date: (data['date'] as Timestamp).toDate(),
          submit: data['submit'],
        ));
      }

      return transactions;
    });
  }

  Future<void> updateAccountBalance(String accountNumber, double amount) async {
    try {
      final accountQuery = await FirebaseFirestore.instance
          .collection('accounts')
          .where('account', isEqualTo: accountNumber)
          .get();

      if (accountQuery.docs.isNotEmpty) {
        final accountDoc = accountQuery.docs.first;
        final currentBalance = accountDoc.data()['amount'] ?? 0.0;

        double totalPendingAmount = 0;

        final transactionQuery = await FirebaseFirestore.instance
            .collection('transactions')
            .where('submit', isEqualTo: false)
            .get();

        for (var doc in transactionQuery.docs) {
          final data = doc.data();
          totalPendingAmount += data['amount'] ?? 0.0;

          await FirebaseFirestore.instance
              .collection('transactions')
              .doc(doc.id)
              .update({'submit': true});
        }

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(accountDoc.id)
            .update({
          'amount': currentBalance - totalPendingAmount,
        });

        print(
            'Saldo actualizado exitosamente. Total procesado: $totalPendingAmount');
      } else {
        print('Cuenta no encontrada.');
      }
    } catch (e) {
      print('Error al actualizar el saldo: $e');
    }
  }
}

class Transaction {
  final double amount;
  final String sender;
  final String receiver;
  final DateTime date;
  final bool submit;

  Transaction({
    required this.sender,
    required this.amount,
    required this.receiver,
    required this.date,
    required this.submit,
  });
}
