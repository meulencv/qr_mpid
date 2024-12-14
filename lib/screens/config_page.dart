import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Historia Clínica',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const ConfigPage(),
    );
  }
}

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
  final _otherEpiController = TextEditingController();
  final _otherCausaController = TextEditingController();
  final _alergiaController = TextEditingController();

  bool _inmunosupresion = false;
  bool _hasComorbilidades = false;
  bool _loading = false;
  String? _qrUuid;
  String? _accessCode;
  String? _selectedEpi;
  bool _isOtherSelected = false;
  List<String> _selectedCausas = [];

  final List<String> tiposEpidGenerales = [
    "MPID de causa coneguda (exposició ambiental, fàrmacs, malalties sistèmiques)",
    "MPID idiopàtica",
    "MPID secundària a altres condicions (infeccions, insuficiència cardíaca, neoplàsies)",
    "MPID genètica o hereditària",
    "altres:"
  ];

  final List<String> opcionesCausas = [
    "Cap",
    "Infeccions",
    "Insuficiència cardíaca esquerra",
    "Tromboembolisme pulmonar",
    "Fàrmacs",
    "Transfusió sang",
    "Inhalació aguda tòxics pulmonars",
    "Reflux Gastroesofàgic",
    "Causes d'abdomen agut",
    "Intervencions quirúrgiques en les setmanes prèvies",
    "Procediments invasius en les setmanes prèvies",
    "Pneumotòrax",
    "Contusió pulmonar",
    "Exacerbació aguda de la malaltia pulmonar intersticial de base"
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _healthCardController.dispose();
    _epiController.dispose();
    _causasController.dispose();
    _tratamientoController.dispose();
    _comorbilidadesController.dispose();
    _otherEpiController.dispose();
    _otherCausaController.dispose();
    _alergiaController.dispose();
    super.dispose();
  }

  String _generateAccessCode() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    final hash = sha256.convert(bytes);
    return hash.toString().substring(0, 8);
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _loading = true);
      try {
        final userId = Supabase.instance.client.auth.currentUser!.id;
        final uuid = const Uuid().v4();
        _qrUuid = 'https://technologiescv.com/wapp/qr?UID=$uuid';
        _accessCode = _generateAccessCode();

        final response = await Supabase.instance.client
            .from('patient_data')
            .insert({
              'qr_uuid': uuid, // Guardamos solo el UUID en la base de datos
              'user_id': userId,
              'name': _nameController.text,
              'surname': _surnameController.text,
              'health_card_number': _healthCardController.text,
              'access_code': _accessCode,
              'epi_type': _selectedEpi,
              'other_epi_type': _isOtherSelected ? _otherEpiController.text : null,
              'selected_causes': _selectedCausas,
              'other_cause': _otherCausaController.text,
              'treatment': _tratamientoController.text,
              'immunosuppression': _inmunosupresion,
              'has_comorbidities': _hasComorbilidades,
              'comorbidities': _comorbilidadesController.text,
              'drug_allergies': _alergiaController.text,
            })
            .select()
            .single();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Dades desades correctament')),
          );
          _showQRDialog();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error en desar: $e')),
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
        title: const Text('QR Generat'),
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
                  data: _qrUuid!, // Ahora contendrá la URL completa
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
            child: const Text('Tancar'),
          ),
        ],
      ),
    );
  }

  String? _validator(String? value) {
    return value?.isEmpty ?? true ? 'Camp obligatori' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Història Clínica')),
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
                      'DADES PERSONALS DEL PACIENT',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nom',
                      ),
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _surnameController,
                      decoration: const InputDecoration(
                        labelText: 'Cognoms',
                      ),
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _healthCardController,
                      decoration: const InputDecoration(
                        labelText: 'Número de Targeta Sanitària',
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Camp obligatori';
                        if (value!.length != 14) return 'Ha de tenir 14 caràcters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Tipus de Malaltia Pulmonar Intersticial',
                      ),
                      value: _selectedEpi,
                      items: tiposEpidGenerales.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedEpi = newValue;
                          _isOtherSelected = newValue == "altres:";
                        });
                      },
                      validator: (value) =>
                          value == null ? 'Seleccioni un tipus de MPID' : null,
                    ),

                    if (_isOtherSelected)
                      TextFormField(
                        controller: _otherEpiController,
                        decoration: const InputDecoration(
                          labelText: 'Especifiqui altre tipus de MPID',
                        ),
                        validator: _validator,
                      ),

                    const SizedBox(height: 16),
                    const Text(
                      'Causes potencials d\'agudització',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),

                    Column(
                      children: opcionesCausas.map((String causa) {
                        return CheckboxListTile(
                          title: Text(causa),
                          value: _selectedCausas.contains(causa),
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedCausas.add(causa);
                              } else {
                                _selectedCausas.remove(causa);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _otherCausaController,
                      decoration: const InputDecoration(
                        labelText: 'Especifiqui altres causes',
                      ),
                      validator: _validator,
                    ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _tratamientoController,
                      decoration: const InputDecoration(
                        labelText: 'Tractament de base',
                      ),
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Estat d\'immunosupressió'),
                      value: _inmunosupresion,
                      onChanged: (bool value) {
                        setState(() {
                          _inmunosupresion = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Té comorbiditats?'),
                      value: _hasComorbilidades,
                      onChanged: (bool value) {
                        setState(() {
                          _hasComorbilidades = value;
                          if (!value) {
                            _comorbilidadesController.clear();
                          }
                        });
                      },
                    ),

                    if (_hasComorbilidades)
                      TextFormField(
                        controller: _comorbilidadesController,
                        decoration: const InputDecoration(
                          labelText: 'Especifiqui les comorbiditats',
                        ),
                        validator: (value) {
                          if (_hasComorbilidades && (value?.isEmpty ?? true)) {
                            return 'Camp obligatori';
                          }
                          return null;
                        },
                      ),

                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _alergiaController,
                      decoration: const InputDecoration(
                        labelText: 'Al·lèrgies a fàrmacs',
                      ),
                      validator: _validator,
                    ),

                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        child: const Text('Desar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
