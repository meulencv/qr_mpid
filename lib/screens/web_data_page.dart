import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_mpid/screens/autodiag.dart'; // Importar la página de autodiagnóstico
import 'package:qr_mpid/screens/medical_guide_page.dart'; // Importar la página de guía médica

class WebDataPage extends StatefulWidget {
  const WebDataPage({Key? key}) : super(key: key);

  @override
  State<WebDataPage> createState() => _WebDataPageState();
}

class _WebDataPageState extends State<WebDataPage> {
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
    // Calcular edad
    final birthDate = DateTime.parse(_patientData!['birth_date']);
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información Personal',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        
        _buildInfoRow('Nombre', _patientData!['name']),
        _buildInfoRow('Apellidos', _patientData!['surname']),
        _buildInfoRow('Sexo', _patientData!['sex']),
        _buildInfoRow('Fecha de nacimiento', 
          '${birthDate.day}/${birthDate.month}/${birthDate.year} ($age años)'),
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
        if (_patientData!['other_epi_type'] != null)
          _buildInfoRow('Otro tipo de EPI', _patientData!['other_epi_type']),
        _buildInfoRow('Causas seleccionadas', 
          (_patientData!['selected_causes'] as List).join(', ')),
        if (_patientData!['other_cause'] != null)
          _buildInfoRow('Otra causa', _patientData!['other_cause']),
        _buildInfoRow('Tratamiento', _patientData!['treatment']),
        _buildInfoRow('Estado de inmunosupresión', 
          _patientData!['immunosuppression'] ? 'Sí' : 'No'),
        if (_patientData!['has_comorbidities'])
          _buildInfoRow('Comorbilidades', _patientData!['comorbidities'] ?? '')
        else
          _buildInfoRow('Tiene comorbilidades', 'No'),
        if (_patientData!['drug_allergies'] != null)
          _buildInfoRow('Alergias a medicamentos', _patientData!['drug_allergies']),
        const SizedBox(height: 30),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton(
              onPressed: _onAutodiagnosticoPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Autodiagnóstico'),
            ),
            ElevatedButton(
              onPressed: _onGuiaMedicaPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
              child: const Text('Guía Médica'),
            ),
          ],
        ),
      ],
    );
  }

  void _onAutodiagnosticoPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RespiratoryTestApp()),
    );
  }

  void _onGuiaMedicaPressed() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MedicalGuidePage()),
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
