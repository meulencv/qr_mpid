import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_mpid/home_page.dart';
import 'package:qr_mpid/verification_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_page.dart';
import 'my_widget.dart';
import 'config_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://stwxwofcwvazwgjfunlc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0d3h3b2Zjd3ZhendnamZ1bmxjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQxMjA2MTIsImV4cCI6MjA0OTY5NjYxMn0.UGYj-cNX6Pk-Vy7xlxSGmyF7v7ns6HHYdtD3qE-DQjA',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<String?> _getUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('user_uuids')
          .select('role')
          .eq('user_uuid', user.id)
          .single();
      
      return response['role'] as String?;
    } catch (e) {
      debugPrint('Error al obtener el rol del usuario: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: kIsWeb ? const WebHomePage() : const HomePage(),
      routes: {
        // Solo registrar rutas si no estamos en web
        if (!kIsWeb) ... {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/verification': (context) => const VerificationPage(),
          '/config': (context) => const ConfigPage(),
          '/menu': (context) => const MenuPage(),
          '/profile': (context) => const MyWidget(),
        }
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

class WebHomePage extends StatefulWidget {
  const WebHomePage({Key? key}) : super(key: key);

  @override
  State<WebHomePage> createState() => _WebHomePageState();
}

class _WebHomePageState extends State<WebHomePage> {
  bool _loading = false;
  Map<String, dynamic>? _patientData;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatientData();
  }

  String? _getUIDFromUrl() {
    final uri = Uri.base;
    return uri.queryParameters['UID'];
  }

  Future<void> _loadPatientData() async {
    final uid = _getUIDFromUrl();
    if (uid == null) {
      setState(() => _error = 'No se proporcionó UID');
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await Supabase.instance.client
          .from('patient_data')
          .select()
          .eq('qr_uuid', uid)
          .single();
      
      setState(() {
        _patientData = response;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Error al cargar los datos del paciente');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos del Paciente'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
              : _patientData == null
                  ? const Center(child: Text('No se encontraron datos'))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 800),
                          child: Card(
                            elevation: 4,
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildHeader(),
                                  const Divider(height: 30),
                                  _buildPersonalInfo(),
                                  const SizedBox(height: 20),
                                  _buildMedicalInfo(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'HISTORIA CLÍNICA',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.deepPurple,
          ),
        ),
        Text(
          'Fecha de registro: ${DateTime.parse(_patientData!['created_at']).toLocal().toString().split('.')[0]}',
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildPersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Personal',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildInfoRow('Nombre', '${_patientData!['name']} ${_patientData!['surname']}'),
        _buildInfoRow('Tarjeta Sanitaria', _patientData!['health_card_number']),
      ],
    );
  }

  Widget _buildMedicalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Médica',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        _buildInfoRow('Tipo de EPI', _patientData!['epi_type']),
        _buildInfoRow('Causas de agudización', _patientData!['causes'] ?? 'No especificado'),
        _buildInfoRow('Tratamiento', _patientData!['treatment'] ?? 'No especificado'),
        _buildInfoRow('Estado de inmunosupresión', 
          _patientData!['immunosuppression'] ? 'Sí' : 'No'),
        _buildInfoRow('Comorbilidades', _patientData!['comorbidities'] ?? 'No especificado'),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 200,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  Future<String?> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_uuids')
          .select('role')
          .eq('user_uuid', userId)
          .maybeSingle();
      
      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Error obteniendo el rol: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final user = snapshot.data?.session?.user;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<String?>(
          future: _getUserRole(user.id),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Error al cargar el rol')),
              );
            }

            final role = roleSnapshot.data;
            if (role == 'config') {
              return const ConfigPage();
            }

            return kIsWeb ? const MenuPage() : const MyWidget();
          },
        );
      },
    );
  }
}
