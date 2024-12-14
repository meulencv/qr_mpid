import 'package:flutter/material.dart';
import '../my_widget.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MENU'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_android),
            onPressed: () {
              // Simular recarga como si estuviera en un móvil
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyWidget()),
              );
            },
          ),
        ],
      ),
      body: const Center(
        child: Text('MENU'),
      ),
    );
  }
}
