import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import '../my_widget.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MENÚ', style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: const Color(0xFF4b66a6),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_android),
            onPressed: () {
              // Simular recarga como si estuviera en un mòbil
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const MyWidget()),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Text('MENÚ', style: GoogleFonts.roboto()),
      ),
    );
  }
}
