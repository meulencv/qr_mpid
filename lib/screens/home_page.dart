import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Añadir si no está ya incluida
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts

class HomePage extends StatefulWidget {
  // Cambiar a StatefulWidget
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? savedQrUuid;
  String? savedQrFullUrl; // Variable para guardar la URL completa

  @override
  void initState() {
    super.initState();
    _loadSavedQR();
  }

  Future<void> _loadSavedQR() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedQrUuid = prefs.getString('saved_qr_uuid');
      savedQrFullUrl =
          prefs.getString('saved_qr_full_url'); // Cargar URL completa
    });
  }

  String? _extractUuidFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final uid = uri.queryParameters['UID'];
      return uid;
    } catch (e) {
      return null;
    }
  }

  Future<void> _scanQR(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const QRViewExample()),
    );

    if (result != null && context.mounted) {
      print('URL escanejada: $result'); // Imprimir URL completa
      final qrUuid = _extractUuidFromUrl(result);
      print('UUID extret: $qrUuid'); // Imprimir UUID extraído

      if (qrUuid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR invàlid: no s\'ha trobat UUID')),
        );
        return;
      }

      // Validar formato UUID
      final uuidRegExp = RegExp(
        r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        caseSensitive: false,
      );

      if (!uuidRegExp.hasMatch(qrUuid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR invàlid: UUID mal format')),
        );
        return;
      }

      final password = await _showPasswordDialog(context);
      if (password != null) {
        try {
          final response = await Supabase.instance.client.rpc(
            'verify_qr_access',
            params: {
              'qr_uuid': qrUuid
                  .toLowerCase(), // Asegurar que el UUID esté en minúsculas
              'password': password,
            },
          );

          if (context.mounted) {
            if (response != false) {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setString('saved_qr_uuid', qrUuid);
              await prefs.setString(
                  'saved_qr_full_url', result); // Guardar URL completa
              setState(() {
                savedQrUuid = qrUuid;
                savedQrFullUrl = result; // Actualizar URL completa en el estado
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Accés concedit')),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contrasenya incorrecta')),
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
          title: const Text('Introdueix la contrasenya'),
          content: TextField(
            obscureText: true,
            onChanged: (value) => password = value,
            decoration: const InputDecoration(
              hintText: 'Contrasenya',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel·lar'),
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
    // Si es web, mostrar página en blanco
    if (kIsWeb) {
      return const Scaffold(body: SizedBox.shrink());
    }

    // El resto del código existente para móvil
    if (savedQrUuid != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('QR Guardat',
              style: TextStyle(color: Color(0xFF4b66a6))),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('saved_qr_uuid');
                setState(() {
                  savedQrUuid = null;
                });
              },
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: QrImageView(
                  data: savedQrFullUrl!, // Usar la URL completa original
                  version: QrVersions.auto,
                  size: 250.0,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'URL: $savedQrFullUrl', // Mostrar la URL completa
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'La Meva App',
                style: GoogleFonts.roboto(
                  // Use Google Fonts
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4b66a6),
                ),
              ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/signup'),
                  child: const Text('Crear Compte'),
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
                        child: const Text('Iniciar Sessió'),
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
      appBar: AppBar(title: const Text('Escanejar QR')),
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
