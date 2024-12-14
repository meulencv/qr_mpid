import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class VerificationPage extends StatelessWidget {
  const VerificationPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF4b66a6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFF4b66a6)),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Color(0xFF4b66a6),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Esperant verificació de permisos',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'El teu compte està pendent d\'aprovació. Si us plau, inicia sessió més tard per verificar l\'estat.',
                      style: GoogleFonts.roboto(),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Iniciar Sessió', style: TextStyle(fontFamily: 'Roboto')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
