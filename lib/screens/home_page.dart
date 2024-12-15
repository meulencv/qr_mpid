import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Añadir si no está ya incluida
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  // Cambiar a StatefulWidget
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ConfettiController _confettiController;
  String? savedQrUuid;
  String? savedQrFullUrl; // Variable para guardar la URL completa

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _loadSavedQR();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
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
              _confettiController.play();
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: Colors.white,
          title: Text(
            'Introdueix la contrasenya',
            style: GoogleFonts.roboto(
              color: const Color(0xFF4B66A6),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            obscureText: true,
            onChanged: (value) => password = value,
            decoration: InputDecoration(
              hintText: 'Contrasenya',
              hintStyle: GoogleFonts.roboto(color: Colors.grey[600]),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF4B66A6)),
              ),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[600],
              ),
              child: Text(
                'Cancel·lar',
                style: GoogleFonts.roboto(),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, password),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4B66A6),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              child: Text(
                'Verificar',
                style: GoogleFonts.roboto(),
              ),
            ),
          ],
          actionsPadding: const EdgeInsets.all(16),
        );
      },
    );
  }

  Future<void> _launchURL(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return const Scaffold(body: SizedBox.shrink());
    }

    if (savedQrUuid != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF7F7F8),
        body: SafeArea(
          child: Stack(
            children: [
              // Botón de cerrar sesión en la esquina superior derecha
              Positioned(
                top: 16,
                right: 16,
                child: IconButton(
                  icon: const Icon(Icons.logout, color: Colors.black),
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('saved_qr_uuid');
                    setState(() {
                      savedQrUuid = null;
                    });
                  },
                ),
              ),
              // Contenido central (QR y UUID)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'QR-MPID',
                      style: GoogleFonts.roboto(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4B66A6),
                      ),
                    ),
                    const SizedBox(height: 32),
                    GestureDetector(
                      onTap: () => _launchURL(savedQrFullUrl!),
                      child: Container(
                        width: 250,
                        height: 250,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: savedQrFullUrl!,
                          version: QrVersions.auto,
                          size: 250.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'UUID: ${savedQrUuid}',
                        style: GoogleFonts.roboto(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Codi QR d\'identificació i seguiment assistencial',
                      style: GoogleFonts.roboto(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              // Confetti en la parte superior
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirectionality: BlastDirectionality.explosive,
                  particleDrag: 0.05,
                  emissionFrequency: 0.05,
                  numberOfParticles: 20,
                  gravity: 0.05,
                  shouldLoop: false,
                  colors: const [
                    Colors.blue,
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: SafeArea(
        child: Stack(
          children: [
            // Contenido principal centrado
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.1),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'QR-MPID',
                            style: GoogleFonts.roboto(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF4B66A6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Gestió de pacients',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () =>
                                Navigator.pushNamed(context, '/signup'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4B66A6),
                              foregroundColor: Colors.white,
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Crear Compte',
                              style: GoogleFonts.roboto(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 4,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      Navigator.pushNamed(context, '/login'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF4B66A6),
                                    minimumSize:
                                        const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                        color: Color(0xFF4B66A6),
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Text(
                                    'Iniciar Sessió',
                                    style: GoogleFonts.roboto(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 1,
                                child: ElevatedButton(
                                  onPressed: () => _scanQR(context),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF4B66A6),
                                    minimumSize: const Size(50, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: const BorderSide(
                                        color: Color(0xFF4B66A6),
                                        width: 1,
                                      ),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: const Icon(Icons.qr_code),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Logo en la parte inferior
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: Center(
                child: Image.asset(
                  'assets/bxm.png',
                  width: 200,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ],
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
