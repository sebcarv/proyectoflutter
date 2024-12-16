import 'package:bank_app/screens/transaction_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AccountView extends StatefulWidget {
  const AccountView({super.key});

  @override
  _AccountViewState createState() => _AccountViewState();
}

class _AccountViewState extends State<AccountView> {
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
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Cuenta del Usuario"),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Cuenta del Usuario"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Colors.blue,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            const SizedBox(height: 24),
            const Text(
              "Transferencia",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TransferForm(),
          ],
        ),
      ),
    );
  }
}

class TransferForm extends StatefulWidget {
  @override
  _TransferFormState createState() => _TransferFormState();
}

class _TransferFormState extends State<TransferForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _accountController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  double amountTransaction = 0;

  Future<void> createTransaction(
      String emisor, String receptor, double amount) async {
    final db = FirebaseFirestore.instance;

    final transaction = {
      "sender": emisor,
      "receiver": receptor,
      "amount": amount,
      "date": FieldValue.serverTimestamp(),
    };

    try {
      amountTransaction = amount;
      await db.collection("transactions").add(transaction);
      print("Transacción guardada exitosamente en Firestore.");
    } catch (e) {
      print("Error al guardar la transacción: $e");
    }
  }

  Future<void> updateAmount(String account, double balance) async {
    try {
      final accountQuery = await FirebaseFirestore.instance
          .collection('accounts')
          .where('account', isEqualTo: account)
          .get();
      if (accountQuery.docs.isNotEmpty) {
        final accountDoc = accountQuery.docs.first;
        final currentBalance = accountDoc.data()['amount'] ?? 0.0;

        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(accountDoc.id)
            .update({
          'amount': currentBalance - balance,
        });

        print('Saldo actualizado exitosamente. Total procesado: $balance');
      } else {
        print('Cuenta no encontrada.');
      }
    } catch (e) {
      print(e);
    } finally {
      Navigator.push(context,
          MaterialPageRoute(builder: (context) => TransactionScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          TextFormField(
            controller: _accountController,
            decoration: InputDecoration(
              labelText: "Cuenta de Destino",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Por favor, ingrese una cuenta válida";
              }
              return null;
            },
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: "Monto",
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return "Por favor, ingrese un monto";
              }
              if (double.tryParse(value) == null) {
                return "Por favor, ingrese un monto válido";
              }
              return null;
            },
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final account = _accountController.text;
                final amount = double.parse(_amountController.text);

                await createTransaction("00123456", account, amount);

                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text("Transferencia Exitosa"),
                    content: Text(
                        "Se han transferido \$${amount.toStringAsFixed(2)} a la cuenta $account."),
                    actions: [
                      TextButton(
                        onPressed: () {
                          updateAmount("00123456", amount);
                        },
                        child: Text("Cerrar"),
                      ),
                    ],
                  ),
                );
              }
            },
            child: Text("Transferir"),
          ),
        ],
      ),
    );
  }
}
