import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
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
      setState(() => _error = 'No s\'ha proporcionat UID');
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
      setState(() => _error = 'Error en carregar les dades del pacient');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Dades del Pacient',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 18,
            color: Colors.white, // Aseguramos que el texto sea blanco
          ),
        ),
        backgroundColor: Color(0xFF304982), // Usamos el color primario en lugar de transparente
        foregroundColor: Colors.white, // Aseguramos que los iconos sean blancos
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF304982)),
            ))
          : _error != null
              ? _buildErrorState()
              : _patientData == null
                  ? _buildEmptyState()
                  : _buildMainContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
          SizedBox(height: 16),
          Text(_error!,
              style: GoogleFonts.inter(
                  color: Colors.red[300],
                  fontSize: 16,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off_outlined, size: 48, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text('No s\'han trobat dades',
              style: GoogleFonts.inter(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildMainContent() {
    final isSmallScreen = MediaQuery.of(context).size.width <= 600;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 16 : 24,
              vertical: isSmallScreen ? 12 : 20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Història Clínica',
                  style: GoogleFonts.inter(
                    fontSize: isSmallScreen ? 24 : 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF304982),
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Data de registre: ${DateTime.parse(_patientData!['created_at']).toLocal().toString().split('.')[0]}',
                  style: GoogleFonts.inter(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: _buildPatientCard(),
        ),
        SliverPadding(
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildInfoCards(),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientCard() {
    final isSmallScreen = MediaQuery.of(context).size.width <= 600;
    
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSmallScreen ? 16 : 24,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Color(0xFF304982).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _patientData!['name'][0].toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF304982),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_patientData!['name']} ${_patientData!['surname']}',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        _patientData!['health_card_number'],
                        style: GoogleFonts.inter(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: Colors.grey[100]),
          Padding(
            padding: EdgeInsets.all(16),
            child: isSmallScreen 
                ? Column(
                    children: [
                      _buildActionButton(
                        'Autodiagnòstic',
                        Icons.assignment_outlined,
                        Color(0xFF304982),
                        _onAutodiagnosticoPressed,
                      ),
                      SizedBox(height: 12),
                      _buildActionButton(
                        'Guia Mèdica',
                        Icons.menu_book_outlined,
                        Colors.white,
                        _onGuiaMedicaPressed,
                        textColor: Color(0xFF304982),
                        borderColor: Color(0xFF304982),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'Autodiagnòstic',
                          Icons.assignment_outlined,
                          Color(0xFF304982),
                          _onAutodiagnosticoPressed,
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Guia Mèdica',
                          Icons.menu_book_outlined,
                          Colors.white,
                          _onGuiaMedicaPressed,
                          textColor: Color(0xFF304982),
                          borderColor: Color(0xFF304982),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCards() {
    return Column(
      children: [
        _buildSectionCard(
          'Informació Personal',
          Icons.person_outline,
          [_buildPersonalInfoContent()],
        ),
        SizedBox(height: 16),
        _buildSectionCard(
          'Informació Mèdica',
          Icons.medical_services_outlined,
          [_buildMedicalInfoContent()],
        ),
      ],
    );
  }

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Color(0xFF304982).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Color(0xFF304982), size: 20),
                ),
                SizedBox(width: 12),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[100]!,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: Colors.black87,
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed, {
    Color? textColor,
    Color? borderColor,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: borderColor != null
              ? BoxDecoration(
                  border: Border.all(color: borderColor),
                  borderRadius: BorderRadius.circular(8),
                )
              : null,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icon,
                  color: textColor ?? Colors.white,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  text,
                  style: GoogleFonts.inter(
                    color: textColor ?? Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoContent() {
    final birthDate = DateTime.parse(_patientData!['birth_date']);
    final age = DateTime.now().difference(birthDate).inDays ~/ 365;

    return Column(
      children: [
        _buildInfoItem('Nom', _patientData!['name']),
        _buildInfoItem('Cognoms', _patientData!['surname']),
        _buildInfoItem('Sexe', _patientData!['sex']),
        _buildInfoItem('Data de naixement',
            '${birthDate.day}/${birthDate.month}/${birthDate.year} ($age anys)'),
        _buildInfoItem(
            'Targeta Sanitària', _patientData!['health_card_number']),
      ],
    );
  }

  Widget _buildMedicalInfoContent() {
    return Column(
      children: [
        _buildInfoItem('Tipus d\'EPI', _patientData!['epi_type']),
        if (_patientData!['other_epi_type'] != null)
          _buildInfoItem(
              'Altres tipus d\'EPI', _patientData!['other_epi_type']),
        _buildInfoItem('Causes seleccionades',
            (_patientData!['selected_causes'] as List).join(', ')),
        if (_patientData!['other_cause'] != null)
          _buildInfoItem('Altres causes', _patientData!['other_cause']),
        _buildInfoItem('Tractament', _patientData!['treatment']),
        _buildInfoItem('Estat d\'immunosupressió',
            _patientData!['immunosuppression'] ? 'Sí' : 'No'),
        if (_patientData!['has_comorbidities'])
          _buildInfoItem('Comorbiditats', _patientData!['comorbidities'] ?? ''),
        if (_patientData!['drug_allergies'] != null)
          _buildInfoItem(
              'Al·lèrgies a medicaments', _patientData!['drug_allergies']),
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
}
