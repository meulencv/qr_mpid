import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  Future<void> _scanQR(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewExample()),
    );

    if (result != null && context.mounted) {
      // Mostrar diálogo para introducir contraseña
      final password = await _showPasswordDialog(context);
      if (password != null) {
        try {
          final response = await Supabase.instance.client.rpc(
            'verify_qr_access',
            params: {
              'qr_uuid': result,
              'password': password,
            },
          );

          if (context.mounted) {
            if (response != false) {
              // QR válido, navegar a la siguiente pantalla
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Acceso concedido')),
              );
              // Aquí puedes navegar a la pantalla de datos del paciente
              // Navigator.pushNamed(context, '/patient_data', arguments: response);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contraseña incorrecta')),
              );
            }
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${e.toString()}')),
            );
          }
        }
      }
    }
  }

  Future<String?> _showPasswordDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (context) {
        String password = '';
        return AlertDialog(
          title: const Text('Introduce la contraseña'),
          content: TextField(
            obscureText: true,
            onChanged: (value) => password = value,
            decoration: const InputDecoration(
              hintText: 'Contraseña',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, password),
              child: const Text('Verificar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Mi App',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Crear Cuenta'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/login'),
                        child: const Text('Iniciar Sesión'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => _scanQR(context),
                        child: const Icon(Icons.qr_code),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<QRViewExample> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  MobileScannerController controller = MobileScannerController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escanear QR')),
      body: MobileScanner(
        controller: controller,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            final String? code = barcodes.first.rawValue;
            if (code != null) {
              controller.dispose();
              Navigator.pop(context, code);
            }
          }
        },
      ),
    );
  }
}
