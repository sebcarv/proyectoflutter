import 'package:flutter/material.dart';
import 'package:bank_app/screens/account_view.dart';

class SecondScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      backgroundColor: Colors.blue,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1,
            shrinkWrap: true,
            children: [
              ElevatedButton(
                onPressed: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => AccountView()));
                },
                child: const Text("Transferencias"),
              ),
              ElevatedButton(
                onPressed: () => print("Créditos"),
                child: const Text("Créditos"),
              ),
              ElevatedButton(
                onPressed: () => print("Beneficios"),
                child: const Text("Beneficios"),
              ),
              ElevatedButton(
                onPressed: () => print("Pagos"),
                child: const Text("Pagos"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
