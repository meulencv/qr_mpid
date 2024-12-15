import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import 'package:confetti/confetti.dart';

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
  final _birthDateController = TextEditingController();
  String? _selectedSex;

  bool _inmunosupresion = false;
  bool _hasComorbilidades = false;
  bool _loading = false;
  String? _qrUuid;
  String? _accessCode;
  String? _selectedEpi;
  bool _isOtherSelected = false;
  List<String> _selectedCausas = [];

  final ConfettiController _confettiController =
      ConfettiController(duration: const Duration(seconds: 3));

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

  final List<String> sexOptions = ['Home', 'Dona'];

  @override
  void initState() {
    super.initState();
  }

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
    _birthDateController.dispose();
    _confettiController.dispose();
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
        _qrUuid = 'https://technologiescv.com/wapp/qr-mpid?UID=$uuid';
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
              'other_epi_type':
                  _isOtherSelected ? _otherEpiController.text : null,
              'selected_causes': _selectedCausas,
              'other_cause': _otherCausaController.text,
              'treatment': _tratamientoController.text,
              'immunosuppression': _inmunosupresion,
              'has_comorbidities': _hasComorbilidades,
              'comorbidities': _comorbilidadesController.text,
              'drug_allergies': _alergiaController.text,
              'birth_date': _birthDateController.text,
              'sex': _selectedSex,
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nameController.clear();
    _surnameController.clear();
    _healthCardController.clear();
    _birthDateController.clear();
    _epiController.clear();
    _causasController.clear();
    _tratamientoController.clear();
    _comorbilidadesController.clear();
    _otherEpiController.clear();
    _otherCausaController.clear();
    _alergiaController.clear();
    setState(() {
      _selectedSex = null;
      _selectedEpi = null;
      _isOtherSelected = false;
      _selectedCausas = [];
      _inmunosupresion = false;
      _hasComorbilidades = false;
    });
  }

  void _showQRDialog() {
    _confettiController.play();
    showDialog(
      context: context,
      barrierDismissible: false, // Evita que se cierre al tocar fuera
      builder: (context) => Material(
        type: MaterialType.transparency,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              title: Text(
                'QR Generat',
                style: GoogleFonts.roboto(
                  color: const Color(0xFF4B66A6),
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.white,
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 200,
                      height: 200,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: QrImageView(
                        data: _qrUuid!,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SelectableText(
                      'Contrasenya: $_accessCode',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _confettiController.stop();
                    Navigator.of(context).pop();
                    _resetForm(); // Añadir esta línea
                  },
                  child: Text(
                    'Tancar',
                    style: GoogleFonts.roboto(
                      color: const Color(0xFF4B66A6),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirection: pi / 2,
                maxBlastForce: 5,
                minBlastForce: 1,
                emissionFrequency: 0.05,
                numberOfParticles: 50,
                gravity: 0.1,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String? _validator(String? value) {
    return value?.isEmpty ?? true ? 'Camp obligatori' : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        automaticallyImplyLeading:
            false, // Añadir esta línea para quitar la flecha
        title: Center(
          child: Text(
            'Història Clínica',
            style: GoogleFonts.roboto(
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DADES PERSONALS DEL PACIENT',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4B66A6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nom',
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _surnameController,
                      label: 'Cognoms',
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _healthCardController,
                      label: 'Número de Targeta Sanitària',
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Camp obligatori';
                        if (value!.length != 14)
                          return 'Ha de tenir 14 caràcters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _birthDateController,
                      label: 'Data de naixement',
                      readOnly: true,
                      onTap: () => _selectDate(context),
                      suffixIcon: const Icon(Icons.calendar_today),
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    _buildDropdown(
                      value: _selectedSex,
                      items: sexOptions,
                      label: 'Sexe',
                      onChanged: (String? newValue) {
                        setState(() => _selectedSex = newValue);
                      },
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'INFORMACIÓ MÈDICA',
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4B66A6),
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildDropdown(
                      value: _selectedEpi,
                      items: tiposEpidGenerales,
                      label: 'Tipus de Malaltia Pulmonar Intersticial',
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedEpi = newValue;
                          _isOtherSelected = newValue == "altres:";
                        });
                      },
                    ),
                    if (_isOtherSelected) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _otherEpiController,
                        label: 'Especifiqui altre tipus de MPID',
                        validator: _validator,
                      ),
                    ],
                    const SizedBox(height: 24),
                    Text(
                      'Causes potencials d\'agudització',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4B66A6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCheckboxList(),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _otherCausaController,
                      label: 'Especifiqui altres causes',
                      validator: _validator,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _tratamientoController,
                      label: 'Tractament de base',
                      validator: _validator,
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    _buildSwitchTile(
                      title: 'Estat d\'immunosupressió',
                      value: _inmunosupresion,
                      onChanged: (value) {
                        setState(() => _inmunosupresion = value);
                      },
                    ),
                    _buildSwitchTile(
                      title: 'Té comorbiditats?',
                      value: _hasComorbilidades,
                      onChanged: (value) {
                        setState(() {
                          _hasComorbilidades = value;
                          if (!value) _comorbilidadesController.clear();
                        });
                      },
                    ),
                    if (_hasComorbilidades) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _comorbilidadesController,
                        label: 'Especifiqui les comorbiditats',
                        validator: _validator,
                        maxLines: 3,
                      ),
                    ],
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _alergiaController,
                      label: 'Al·lèrgies a fàrmacs',
                      validator: _validator,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4B66A6),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        'Desar',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      readOnly: readOnly,
      onTap: onTap,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF4B66A6)),
        ),
        suffixIcon: suffixIcon,
      ),
      style: GoogleFonts.roboto(),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String label,
    required void Function(String?) onChanged,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(
        canvasColor: Colors.white,
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.roboto(color: Colors.grey[700]),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF4B66A6)),
          ),
        ),
        items: items.map((String item) {
          return DropdownMenuItem(
            value: item,
            child: Text(
              item,
              style: GoogleFonts.roboto(
                color: Colors.black87,
                fontSize: 14,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          );
        }).toList(),
        onChanged: onChanged,
        style: GoogleFonts.roboto(
          color: Colors.black87,
          fontSize: 14,
        ),
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4B66A6)),
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildCheckboxList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: opcionesCausas.map((String causa) {
          return CheckboxListTile(
            title: Text(causa, style: GoogleFonts.roboto()),
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
            activeColor: const Color(0xFF4B66A6),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required void Function(bool) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: SwitchListTile(
        title: Text(title, style: GoogleFonts.roboto()),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF4B66A6),
      ),
    );
  }
}
