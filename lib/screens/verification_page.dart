import 'package:flutter/material.dart';

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
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700),
                ),
                child: const Column(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 48,
                      color: Color(0xFF4b66a6),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Esperant verificació de permisos',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'El teu compte està pendent d\'aprovació. Si us plau, inicia sessió més tard per verificar l\'estat.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('Iniciar Sessió'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
