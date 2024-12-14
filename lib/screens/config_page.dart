import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart'; // Agregar esta dependencia
import 'package:crypto/crypto.dart'; // Agregar esta dependencia
import 'package:uuid/uuid.dart'; // Agregar esta importación
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _healthCardController = TextEditingController();
  final _epiController = TextEditingController();
  final _causasController = TextEditingController();
  final _tratamientoController = TextEditingController();
  final _comorbilidadesController = TextEditingController();
  bool _inmunosupresion = false;
  bool _loading = false;
  String? _qrUuid;
  String? _accessCode;

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _healthCardController.dispose();
    _epiController.dispose();
    _causasController.dispose();
    _tratamientoController.dispose();
    _comorbilidadesController.dispose();
    super.dispose();
  }

  String _generateAccessCode() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8); // Tomar los primeros 8 caracteres
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        _qrUuid = const Uuid().v4(); // Usar el Uuid importado correctamente
        _accessCode = _generateAccessCode();

        final response = await Supabase.instance.client
            .from('patient_data')
            .insert({
              'qr_uuid': _qrUuid, // Ahora es la clave primaria
              'user_id': userId,
              'name': _nameController.text,
              'surname': _surnameController.text,
              'health_card_number': _healthCardController.text,
              'access_code': _accessCode,
              'epi_type': _epiController.text,
              'causes': _causasController.text,
              'treatment': _tratamientoController.text,
              'immunosuppression': _inmunosupresion,
              'comorbidities': _comorbilidadesController.text,
            })
            .select()
            .single();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos guardados correctamente')),
          );
          _showQRDialog();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar: $e')),
          );
        }
      } finally {
        if (mounted) setState(() => _loading = false);
      }
    }
  }

  void _showQRDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Generado'),
        backgroundColor: Colors.white,
        content: Container(
          constraints: const BoxConstraints(
            maxWidth: 300,
            minHeight: 300,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey),
                ),
                child: QrImageView(
                  data: _qrUuid!,
                  version: QrVersions.auto,
                  size: 200.0,
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(height: 16),
              SelectableText(
                'Contraseña: $_accessCode',
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historia Clínica')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'DATOS PERSONALES DEL PACIENTE',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(
                        labelText: 'Apellidos',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _healthCardController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Tarjeta Sanitaria',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _epiController,
                      decoration: const InputDecoration(
                        labelText: 'Tipo de Enfermedad Pulmonar Intersticial',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _causasController,
                      decoration: const InputDecoration(
                        labelText: 'Causas potenciales de agudización',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tratamientoController,
                      decoration: const InputDecoration(
                        labelText: 'Tratamiento de base',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Estado de inmunosupresión'),
                      value: _inmunosupresion,
                      onChanged: (bool value) {
                        setState(() {
                          _inmunosupresion = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _comorbilidadesController,
                      decoration: const InputDecoration(
                        labelText: 'Comorbilidades',
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Guardar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
