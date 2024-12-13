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
  bool isLoading = true; // Indicador de carga
  Future<void> getAccount() async {
    final db = FirebaseFirestore.instance;

    try {
      // Obtener datos de Firestore
      final querySnapshot = await db.collection("accounts").get();
      for (var doc in querySnapshot.docs) {
        final data = doc
            .data(); // Asegúrate de que sea un mapa// Verificar la estructura de los datos
        if (data["account"] == "00123456") {
          setState(() {
            userAccount = data["account"];
            balance =
                data["amount"].toDouble(); // Convertir a double si es necesario
          });
          break; // Termina el loop si encuentras el documento
        }
      }
    } catch (e) {
      print("Error al obtener datos: $e");
    } finally {
      // Actualizar el estado después de obtener los datos
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    getAccount(); // Llamar a la función al iniciar el widget
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
            // Mostrar cuenta y saldo
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

            // Formulario
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

  // Método para guardar la transacción en Firestore
  Future<void> createTransaction(
      String emisor, String receptor, double amount) async {
    final db = FirebaseFirestore.instance;

    // Crear el objeto de la transacción
    final transaction = {
      "sender": emisor,
      "receiver": receptor,
      "amount": amount,
      "date": FieldValue.serverTimestamp(),
    };

    try {
      // Guardar en la colección "transactions" en Firestore
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
        // Suponemos que el atributo 'account' es único y tomamos el primer resultado
        final accountDoc = accountQuery.docs.first;
        final currentBalance = accountDoc.data()['amount'] ?? 0.0;

        // Actualizar el saldo restando el monto calculado
        await FirebaseFirestore.instance
            .collection('accounts')
            .doc(accountDoc.id) // ID del documento que contiene la cuenta
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
          // Campo: Cuenta de destino
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

          // Campo: Monto
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

          // Botón de transferencia
          ElevatedButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final account = _accountController.text;
                final amount = double.parse(_amountController.text);

                // Crear la transacción
                await createTransaction("00123456", account, amount);

                // Mostrar mensaje de éxito
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
