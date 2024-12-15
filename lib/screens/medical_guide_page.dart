import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // Añadir esta importación para ImageFilter
import 'package:supabase_flutter/supabase_flutter.dart'; // Añade esta importación
import 'package:google_fonts/google_fonts.dart'; // Añadir esta importación

class MedicalGuidePage extends StatelessWidget {
  const MedicalGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: Text(
          'Guia Mèdica (AI)',
          style: GoogleFonts.roboto(), // Aplicar fuente Roboto
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const ChatMessages(),
    );
  }
}

class ChatMessages extends StatefulWidget {
  const ChatMessages({Key? key}) : super(key: key);

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
  // Añadir controller para el chat
  final TextEditingController _chatController = TextEditingController();

  final Map<String, String> medicalData = {};
  final Map<String, bool> expandedItems = {};
  final List<String> chatMessages = []; // Añadimos lista de mensajes
  bool showForm = true; // Control de visibilidad del formulario
  final Map<String, bool> symptoms = {};
  String otherSymptoms = '';
  bool showSymptoms = false;
  bool dataSent = false; // Control para verificar si se han enviado los datos
  final List<Map<String, dynamic>> medicalTests =
      []; // Lista de pruebas médicas
  final Set<String> completedTests =
      {}; // Añadir esta línea para trackear pruebas completadas
  bool showDiagnosisForm = false;
  final TextEditingController _diagnosisController = TextEditingController();
  bool diagnosesShown = false; // Añadir esta variable
  bool diagnosisCompleted = false; // Añadir esta variable
  bool treatmentShown = false; // Añade esta variable de estado

  final String apiKey =
      'Br-FN7RQSitgDy47RrOCYujSvo5mtlBgtsJEg1CiDZnOun1hFWa'; // Reemplaza con tu API key de Straico

  final List<String> symptomsList = [
    'Tos persistent (seca)',
    'Dolor toràcic',
    'Congestió nasal',
    'Increment de la mucositat',
    'Xiulets',
    'Dificultat respiratòria',
    'Cianosi',
    'Altres',
  ];

  final List<MedicalCheckItem> checkItems = [
    MedicalCheckItem(
      title: 'Freqüència cardíaca',
      hint: 'Exemple: 80',
      key: 'frecuencia_cardiaca',
      unit: 'bpm',
    ),
    MedicalCheckItem(
      title: 'Freqüència respiratòria',
      hint: 'Exemple: 16',
      key: 'frecuencia_respiratoria',
      unit: 'rpm',
    ),
    MedicalCheckItem(
      title: 'Pressió arterial',
      hint: 'Exemple: 120/80',
      key: 'presion_arterial',
      unit: 'mmHg',
    ),
    MedicalCheckItem(
      title: 'Saturació d\'oxigen',
      hint: 'Exemple: 98',
      key: 'saturacion_oxigeno',
      unit: '%',
    ),
    MedicalCheckItem(
      title: 'Temperatura',
      hint: 'Exemple: 36.5',
      key: 'temperatura',
      unit: '°C',
    ),
  ];

  String _formatNumber(String value) {
    // Si es presión arterial, tratar especialmente
    if (value.contains('/')) {
      return value
          .split('/')
          .map((part) => _formatSingleNumber(part.trim()))
          .join('/');
    }
    return _formatSingleNumber(value);
  }

  String _formatSingleNumber(String value) {
    // Convertir punto a coma para decimales
    if (value.contains('.')) {
      value = value.replaceFirst('.', ',');
    }
    return value;
  }

  Future<void> _sendToApi(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.straico.com/v0/prompt/completion'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'anthropic/claude-3.5-sonnet',
          'message': prompt,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final message =
            data['data']['completion']['choices'][0]['message']['content'];

        // Extraer el JSON de la respuesta usando expresión regular
        final jsonMatch = RegExp(r'\[.*\]', dotAll: true).firstMatch(message);
        if (jsonMatch != null) {
          final jsonString = jsonMatch.group(0);
          try {
            final List<dynamic> parsedTests = jsonDecode(jsonString!);
            setState(() {
              medicalTests.clear(); // Limpiar tests anteriores
              medicalTests.addAll(
                  parsedTests.map((test) => Map<String, dynamic>.from(test)));
              medicalTests.sort((a, b) => _priorityValue(b['prioritat'])
                  .compareTo(_priorityValue(a['prioritat'])));
              diagnosesShown =
                  true; // Marcar que los diagnósticos se han mostrado
            });
          } catch (e) {
            developer.log('Error parsing JSON: $e');
          }
        }
      }
    } catch (e) {
      developer.log('Error in API call: $e');
    }
  }

  int _priorityValue(String priority) {
    switch (priority) {
      case 'URGENT':
        return 4;
      case 'ALTA':
        return 3;
      case 'MITJANA':
        return 2;
      case 'BAIXA':
        return 1;
      default:
        return 0;
    }
  }

  void _sendTestResult(String testName, String result) {
    String resultMessage = 'Resultat de la prova $testName:\n$result';

    setState(() {
      chatMessages.add(resultMessage.trim());
      completedTests.add(testName);

      // Eliminar la prueba completada de la lista de pruebas pendientes
      medicalTests.removeWhere((test) => test['nom_prova'] == testName);

      // Verificar si todas las pruebas han sido completadas o eliminadas
      if (medicalTests.isEmpty) {
        showDiagnosisForm = true;
      }
    });
  }

  void _removeTest(String testName) {
    setState(() {
      medicalTests.removeWhere((test) => test['nom_prova'] == testName);
      // Verificar si ya no quedan pruebas después de eliminar
      if (medicalTests.isEmpty) {
        showDiagnosisForm =
            true; // Mostrar formulario de diagnóstico si no quedan pruebas
      }
    });
  }

  void _sendData() {
    String rawData = 'DADES MÈDIQUES RECOPILADES:\n\n';
    bool hasData = false;

    medicalData.forEach((key, value) {
      if (value.isNotEmpty) {
        final item = checkItems.firstWhere((item) => item.key == key);
        final formattedValue = _formatNumber(value);
        rawData += '${item.title}: $formattedValue ${item.unit}\n';
        hasData = true;
      }
    });

    if (!hasData) return; // No enviar si no hay datos

    developer.log(rawData);

    setState(() {
      chatMessages.add(rawData.trim()); // Añadir mensaje al chat
      showForm = false; // Ocultar el formulario
      showSymptoms = true; // Mostrar síntomas después de enviar datos vitales
    });
  }

  void _sendSymptoms() {
    String symptomsData = 'SÍMPTOMES DEL PACIENT:\n\n';
    bool hasSymptoms = false;

    symptoms.forEach((symptom, isChecked) {
      if (isChecked) {
        symptomsData += '- $symptom\n';
        hasSymptoms = true;
      }
    });

    if (symptoms['Altres'] == true && otherSymptoms.isNotEmpty) {
      symptomsData += '- Altres: $otherSymptoms\n';
      hasSymptoms = true;
    }

    if (!hasSymptoms) return;

    developer.log(symptomsData);

    setState(() {
      chatMessages.add(symptomsData.trim());
      showSymptoms = false;
      symptoms.clear();
      otherSymptoms = '';
      dataSent = true; // Marcar que se han enviado los datos
    });

    if (dataSent) {
      String rawData = 'DADES MÈDIQUES RECOPILADES:\n\n';
      medicalData.forEach((key, value) {
        if (value.isNotEmpty) {
          final item = checkItems.firstWhere((item) => item.key == key);
          final formattedValue = _formatNumber(value);
          rawData += '${item.title}: $formattedValue ${item.unit}\n';
        }
      });

      String prompt = '''
Segons les dades proporcionades anteriorment del pacient amb MPID i la informació de la següent taula, proporciona una recomanació de les proves mèdiques de la taula que cal fer en ordre de prioritat.

Adjunta també els objectius de fer cada prova.

Recorda:

1. Si a la taula hi ha més d'un símptoma que correspongui a una de les proves, aquesta prova tindrà més prioritat.
2. Si el símptoma és més greu, la prova també serà prioritària.

Aquesta és la taula amb les proves mèdiques disponibles:

| **Símptomes del pacient (TOTS ELS PACIENTS TENEN MPID)** | **Proves prioritàries** (si hi ha més d'un símptoma de la casella anterior aquesta prova és urgent) |
| --- | --- |
| - Dificultat per respirar ocasional (si hi ha sospita d'hipoxèmia lleu)
- Dificultat per respirar a l'hora de parlar
- Dificultat respiratòria significativa (increment o disminució del nombre de respiracions per minut)
- Saturació d'oxigen <92%
- Desorientació
- Signes d'hipoxèmia severa
- Cianosi (llavis blavosos o gemma de blavosa) | Gasometria arterial 
- Objectiu de la prova: Avaluar hipoxèmia i acidosi respiratòria/metabòlica.
- Prioritària en casos amb dispnea, saturació <92% o cianosi. |
| - Dificultat respiratòria significativa (increment o disminució del nombre de respiracions per minut)
- Saturació d'oxigen inestable
- Signes d'hipoxèmia | TACAR d'alta resolució per avaluar canvis pulmonars intersticials |
| - Si sospita de tromboembòlia pulmonar
- Dolor toràcic | Angio-TACAR |
| - Tos amb expectoració
- Dificultat per respirar a l'hora de parlar
- Dolor toràcic
- Saturació d'oxigen <92%
- Saturació d'oxigen inestable | Radiografia de tòrax per identificar possibles patrons intersticials o canvis pulmonars
- Eina inicial de diagnòstic visual.
- Identificar infiltrats, consolidacions, o progressió de fibrosi pulmonar. |
| - Febre (>38°C) | - Anàlisi de sang (PCR, bioquímica…)
- Hemocultius (descartar infeccions sistèmiques) |
| - Febre (>39°C) | Anàlisi de sang:
- H**emograma complet:** Detectar signes d'infecció, inflamació (leucocitosi) o anèmia.
- P**CR (Proteïna C Reactiva):** Identificar inflamació sistèmica o exacerbació aguda.
- B**ioquímica:** Nivells d'electròlits, funció renal i hepàtica.
- C**oagulació:** Útil per sospita de tromboembòlia pulmonar (TEP). 
Hemocultius (2 mostres):
- Identificar infeccions bacterianes sistèmiques en pacients febrils. 
Antigenúria (Pneumococ/Legionel·la):
- Diagnòstic d'infeccions bacterianes específiques en pacients amb febre i tos productiva.
PCR Virus Respiratoris (Influenza A/B):
- Confirmar infeccions virals en contextos epidèmics o febrils. |
| - Dificultat per respirar a l'hora de parlar
- Dificultat per respirar ocasional | Saturació d'oxigen amb pulsioxímetre:
- Monitoritzar la saturació d'oxigen de manera no invasiva.
- Indicador ràpid de la necessitat d'oxigenoteràpia. |
| - Cianosi (llavis blavosos o gemma de blavosa)
- hipoxèmia
- Saturació d'oxigen <92% | Pulsioximetria contínua
- Monitoritzar la saturació d'oxigen de manera no invasiva. |
| Tos amb expectoració | Anàlisi d'esput per descartar infeccions bacterianes o virals |
| hipoxèmia | Avaluar si el pacient necessita suport ventilatori |
| Saturació d'oxigen <92% | oxigenoteràpia com a mesura immediata si està compromesa |
| - Dolor toràcic
- Dispnea significativa o progressiva
- Signes d'insuficiència cardíaca dreta
- Hipoxèmia severa o persistent
- Palpitacions o arítmies sospitades
- Signes de tromboembòlia pulmonar (TEP)
- Sospita de miocarditis o pericarditis | ECG:
- Dolor toràcic: Per descartar causes cardíaques com isquèmia, infart agut de miocardi (IAM) o pericarditis.
- Dispnea significativa o progressiva: Per identificar alteracions cardíaques secundàries a insuficiència respiratòria o sobrecàrrega ventricular dreta.
- Signes d'insuficiència cardíaca dreta: Indicat en casos d'hipertensió pulmonar o cor pulmonale associat a la malaltia pulmonar intersticial.
- Hipoxèmia severa o persistent: Avaluar possibles arítmies per hipoxèmia o sobrecàrrega cardíaca aguda.
- Palpitacions o arítmies sospitades: Confirmar la presència d'alteracions del ritme cardíac, com fibril·lació auricular.
- Signes de tromboembòlia pulmonar (TEP): Avaluar patrons electrocardiogràfics associats, com desviació de l'eix dret o patró S1Q3T3.
- Sospita de miocarditis o pericarditis: Dolor toràcic de característiques específiques acompanyat de febre o inflamació. |
''';

      String formattedPrompt = '''
$rawData\n$symptomsData\n$prompt

Respon únicament en aquest format JSON:

[
  {
    "nom_prova": "",
    "rao_prova": "",
    "objectiu_prova": "",
    "prioritat": ""
  }
]

/* Les categories de prioritat disponibles son:
   - BAIXA
   - MITJANA
   - ALTA
   - URGENT
*/
''';

      _sendToApi(formattedPrompt);
    }
  }

  Future<void> _getDiagnosisSuggestion() async {
    String prompt = '''
Tenint en compte les dades del pacient amb MPID:
${chatMessages.join('\n')}

Proporciona un diagnòstic breu i concís basat en:
1. Els símptomes inicials
2. Les constants vitals
3. Els resultats de les proves realitzades

Resposta en català, màxim 3-4 línies.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.straico.com/v0/prompt/completion'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'anthropic/claude-3.5-sonnet',
          'message': prompt,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final suggestion =
            data['data']['completion']['choices'][0]['message']['content'];
        _diagnosisController.text = suggestion.trim();
      }
    } catch (e) {
      developer.log('Error getting diagnosis suggestion: $e');
    }
  }

  // Añade esta función para obtener los tratamientos de Supabase
  Future<List<Map<String, dynamic>>> _getTreatments() async {
    try {
      final response =
          await Supabase.instance.client.from('tratamientos_clinicos').select();

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      developer.log('Error fetching treatments: $e');
      return [];
    }
  }

  // Modifica la función _sendDiagnosis para incluir la recomendación de tratamiento
  void _sendDiagnosis() async {
    if (_diagnosisController.text.isEmpty) return;

    setState(() {
      chatMessages.add('DIAGNÒSTIC FINAL:\n\n${_diagnosisController.text}');
      showDiagnosisForm = false;
      diagnosisCompleted = true;
    });

    // Obtener los tratamientos de Supabase
    final treatments = await _getTreatments();

    // Preparar el prompt para la IA con los tratamientos disponibles
    String treatmentsData = treatments
        .map((t) =>
            "Diagnòstic: ${t['diagnostic']}\nTractament: ${t['tractament']}")
        .join('\n\n');

    String prompt = '''
Basant-te en el següent diagnòstic del pacient amb MPID:
${_diagnosisController.text}

I tenint en compte l'històric de dades i proves:
${chatMessages.join('\n')}

Analitza la següent taula de tractaments disponibles i recomana el més adequat:
$treatmentsData

Proporciona:
1. El tractament més adequat
2. Justificació de l'elecció
3. Precaucions o consideracions especials
4. Seguiment recomanat

Resposta en català, format estructurat.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.straico.com/v0/prompt/completion'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'anthropic/claude-3.5-sonnet',
          'message': prompt,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final treatment =
            data['data']['completion']['choices'][0]['message']['content'];

        setState(() {
          chatMessages.add('RECOMANACIÓ DE TRACTAMENT:\n\n$treatment');
          treatmentShown = true;
        });
      }
    } catch (e) {
      developer.log('Error getting treatment recommendation: $e');
    }
  }

  // Añadir función para manejar los mensajes del chat
  Future<void> _handleChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    // Formatear los datos relevantes del paciente
    String patientContext = '';
    if (_patientData != null) {
      final birthDate = DateTime.parse(_patientData!['birth_date']);
      final age = DateTime.now().difference(birthDate).inDays ~/ 365;
      
      patientContext = '''
DADES RELLEVANTS DEL PACIENT:
- Edat: $age anys
- Sexe: ${_patientData!['sex']}
- Tipus d'EPI: ${_patientData!['epi_type']}
${_patientData!['other_epi_type'] != null ? '- Altres tipus d\'EPI: ${_patientData!['other_epi_type']}' : ''}
- Causes seleccionades: ${(_patientData!['selected_causes'] as List).join(', ')}
${_patientData!['other_cause'] != null ? '- Altres causes: ${_patientData!['other_cause']}' : ''}
- Tractament actual: ${_patientData!['treatment']}
- Immunosupressió: ${_patientData!['immunosuppression'] ? 'Sí' : 'No'}
${_patientData!['has_comorbidities'] ? '- Comorbiditats: ${_patientData!['comorbidities']}' : '- No presenta comorbiditats'}
${_patientData!['drug_allergies'] != null ? '- Al·lèrgies a medicaments: ${_patientData!['drug_allergies']}' : '- No presenta al·lèrgies medicamentoses'}
''';
    }

    setState(() {
      chatMessages.add('USUARI:\n\n$message');
    });

    final treatments = await _getTreatments();
    String treatmentsData = treatments.map((t) => '''
Diagnòstic: ${t['diagnostic']}
Tractament: ${t['tractament']}
Recomanacions: ${t['recomendaciones'] ?? 'No especificades'}
Gravetat: ${t['gravedad'] ?? 'No especificada'}
''').join('\n---\n');

    String prompt = '''
CONTEXT DEL PACIENT AMB MPID:
$patientContext

HISTÒRIC DE LA CONSULTA:
${chatMessages.join('\n')}

TRACTAMENTS DISPONIBLES:
$treatmentsData

CONSULTA ACTUAL:
$message

Proporciona una resposta en català tenint en compte:
1. L'edat i el sexe del pacient
2. El tipus específic d'EPI i les seves causes
3. El tractament actual i possibles interaccions
4. La presència d'immunosupressió
5. Les comorbiditats i al·lèrgies existents
6. L'historial de la consulta actual

Resposta màxima 3-4 línies, prioritzant la seguretat del pacient i les seves condicions específiques.
''';

    try {
      final response = await http.post(
        Uri.parse('https://api.straico.com/v0/prompt/completion'),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'anthropic/claude-3.5-sonnet',
          'message': prompt,
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final aiResponse =
            data['data']['completion']['choices'][0]['message']['content'];

        setState(() {
          chatMessages.add('ASSISTENT:\n\n${aiResponse.trim()}');
        });
      }
    } catch (e) {
      developer.log('Error in chat response: $e');
    }
  }

  Map<String, dynamic>? _patientData;

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
    if (uid == null) return;

    try {
      final response = await Supabase.instance.client
          .from('patient_data')
          .select()
          .eq('qr_uuid', uid)
          .single();

      setState(() => _patientData = response);
    } catch (e) {
      developer.log('Error loading patient data: $e');
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    _diagnosisController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Modificar la condición para mostrar el diagnóstico
    bool shouldShowDiagnosis = medicalTests.isEmpty &&
        !showDiagnosisForm &&
        diagnosesShown &&
        !diagnosisCompleted &&
        !treatmentShown; // Añadir esta condición

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...chatMessages.map((message) => UserMessage(text: message)),
              if (showForm)
                SystemMessage(
                  title: "Sistema d'Assistència Monitoritzada per IA",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selecciona i omple les dades disponibles:',
                        style: GoogleFonts.roboto(
                            fontSize: 16), // Aplicar fuente Roboto
                      ),
                      const SizedBox(height: 16),
                      ...checkItems.map((item) => MedicalChecklistItem(
                            item: item,
                            isExpanded: expandedItems[item.key] ?? false,
                            value: medicalData[item.key] ?? '',
                            onChanged: (expanded) {
                              setState(() {
                                expandedItems[item.key] = expanded;
                              });
                            },
                            onValueChanged: (value) {
                              setState(() {
                                medicalData[item.key] = value;
                              });
                            },
                          )),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sendData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                              0xFF4B66A6), // Color principal actualizado
                          minimumSize: const Size(double.infinity, 45),
                          foregroundColor: Colors.white, // Añadir esto
                        ),
                        child: const Text('Enviar dades'),
                      ),
                    ],
                  ),
                ),
              if (showSymptoms)
                SystemMessage(
                  title: 'Símptomes del pacient',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Selecciona els símptomes presents:',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ...symptomsList.map((symptom) => CheckboxListTile(
                            title: Text(symptom),
                            value: symptoms[symptom] ?? false,
                            onChanged: (bool? value) {
                              setState(() {
                                symptoms[symptom] = value ?? false;
                              });
                            },
                            activeColor: const Color(
                                0xFF4B66A6), // Color principal actualizado
                          )),
                      if (symptoms['Altres'] ?? false)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: 'Descriu altres símptomes...',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: const Color(
                                  0xFFE8E8E8), // Cambiado a un gris más oscuro
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              hintStyle: TextStyle(
                                  color: Colors.grey
                                      .shade600), // Añadido estilo para el hint
                            ),
                            onChanged: (value) => otherSymptoms = value,
                            maxLines: null,
                            style: TextStyle(
                                color: Colors.grey
                                    .shade800), // Añadido estilo para el texto
                          ),
                        ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _sendSymptoms,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                              0xFF4B66A6), // Color principal actualizado
                          minimumSize: const Size(double.infinity, 45),
                          foregroundColor: Colors.white, // Añadir esto
                        ),
                        child: const Text('Enviar símptomes'),
                      ),
                    ],
                  ),
                ),
              // Mostrar las pruebas pendientes
              ...medicalTests.map((test) => MedicalTestCard(
                    test: test,
                    onResultSubmit: _sendTestResult,
                    onRemove: _removeTest,
                  )),

              // Mostrar el botón de diagnóstico cuando no queden pruebas
              if (shouldShowDiagnosis)
                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: SystemMessage(
                    title: 'Diagnòstic',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Totes les proves s\'han completat o descartat. Vols procedir amb el diagnòstic?',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () =>
                              setState(() => showDiagnosisForm = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                                0xFF4B66A6), // Color principal actualizado
                            minimumSize: const Size(double.infinity, 45),
                            foregroundColor: Colors.white, // Añadir esto
                          ),
                          child: const Text('Introduir diagnòstic'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (showDiagnosisForm)
                SystemMessage(
                  title: 'Diagnòstic Final',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _diagnosisController,
                        decoration: InputDecoration(
                          hintText: 'Escriu el diagnòstic...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true, // Añadido
                          fillColor: const Color(0xFFE8E8E8), // Añadido
                          hintStyle: TextStyle(
                              color: Colors.grey
                                  .shade600), // Añadido estilo para el hint
                        ),
                        maxLines: null,
                        style: TextStyle(
                            color: Colors
                                .grey.shade800), // Añadido estilo para el texto
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _sendDiagnosis,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                    0xFF4B66A6), // Color principal actualizado
                                minimumSize: const Size(double.infinity, 45),
                                foregroundColor: Colors.white, // Añadir esto
                              ),
                              child: const Text('Enviar diagnòstic'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _getDiagnosisSuggestion,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              minimumSize: const Size(45, 45),
                            ),
                            child: const Icon(Icons.psychology,
                                color: Colors.black54),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (treatmentShown)
          const ChatInput(), // Mostrar ChatInput si treatmentShown es verdadero
      ],
    );
  }
}

class MedicalTestCard extends StatefulWidget {
  final Map<String, dynamic> test;
  final Function(String, String) onResultSubmit;
  final Function(String) onRemove;

  const MedicalTestCard({
    Key? key,
    required this.test,
    required this.onResultSubmit,
    required this.onRemove,
  }) : super(key: key);

  @override
  _MedicalTestCardState createState() => _MedicalTestCardState();
}

class _MedicalTestCardState extends State<MedicalTestCard> {
  bool _isChecked = false;
  final TextEditingController _resultController = TextEditingController();

  Color _getPriorityColor() {
    switch (widget.test['prioritat']) {
      case 'URGENT':
        return Colors.red.shade100;
      case 'ALTA':
        return Colors.orange.shade100;
      case 'MITJANA':
        return Colors.yellow.shade100;
      case 'BAIXA':
        return Colors.green.shade100;
      default:
        return Colors.orange.shade100;
    }
  }

  Color _getPriorityBorderColor() {
    switch (widget.test['prioritat']) {
      case 'URGENT':
        return Colors.red;
      case 'ALTA':
        return Colors.orange;
      case 'MITJANA':
        return Colors.yellow.shade700;
      case 'BAIXA':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getPriorityColor(),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getPriorityBorderColor()),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.test['nom_prova'] ?? 'Prova sense nom',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ), // Aplicar fuente Roboto
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => widget.onRemove(widget.test['nom_prova']),
                    color: Colors.red,
                    tooltip: 'No es pot realitzar la prova',
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getPriorityBorderColor(),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.test['prioritat'] ?? 'SENSE PRIORITAT',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text('Raó: ${widget.test['rao_prova'] ?? 'No especificada'}'),
          const SizedBox(height: 8),
          Text(
              'Objectiu: ${widget.test['objectiu_prova'] ?? 'No especificat'}'),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text('Marcar com completada'),
            value: _isChecked,
            onChanged: (bool? value) {
              setState(() {
                _isChecked = value ?? false;
              });
            },
            activeColor: Colors.orange,
          ),
          if (_isChecked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextField(
                controller: _resultController,
                decoration: InputDecoration(
                  labelText: 'Resultats de la prova',
                  border: OutlineInputBorder(),
                  filled: true, // Añadido
                  fillColor: const Color(0xFFE8E8E8), // Añadido
                  labelStyle: TextStyle(color: Colors.grey.shade700), // Añadido
                ),
                style: TextStyle(color: Colors.grey.shade800), // Añadido
                maxLines: null,
              ),
            ),
          if (_isChecked)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: ElevatedButton(
                onPressed: () {
                  widget.onResultSubmit(
                      widget.test['nom_prova'], _resultController.text);
                },
                style: ElevatedButton.styleFrom(
                  // Añadir esto
                  backgroundColor:
                      const Color(0xFF4B66A6), // Color principal actualizado
                  foregroundColor: Colors.white,
                ), // Añadir esto
                child: const Text('Enviar resultats'),
              ),
            ),
        ],
      ),
    );
  }
}

class MedicalCheckItem {
  final String title;
  final String hint;
  final String key;
  final String unit;

  MedicalCheckItem({
    required this.title,
    required this.hint,
    required this.key,
    required this.unit,
  });
}

class MedicalChecklistItem extends StatefulWidget {
  final MedicalCheckItem item;
  final bool isExpanded;
  final String value;
  final Function(bool) onChanged;
  final Function(String) onValueChanged;

  const MedicalChecklistItem({
    Key? key,
    required this.item,
    required this.isExpanded,
    required this.value,
    required this.onChanged,
    required this.onValueChanged,
  }) : super(key: key);

  @override
  _MedicalChecklistItemState createState() => _MedicalChecklistItemState();
}

class _MedicalChecklistItemState extends State<MedicalChecklistItem> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CheckboxListTile(
          title: Text(
            '${widget.item.title} (${widget.item.unit})',
            style: GoogleFonts.roboto(), // Aplicar fuente Roboto
          ),
          value: widget.isExpanded,
          onChanged: (bool? value) => widget.onChanged(value ?? false),
          activeColor: const Color(0xFF4B66A6), // Color principal actualizado
        ),
        if (widget.isExpanded)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: widget.item.hint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor:
                    const Color(0xFFE8E8E8), // Cambiado a un gris más oscuro
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixText: widget.item.unit,
                hintStyle: TextStyle(
                    color: Colors.grey.shade600), // Añadido estilo para el hint
              ),
              onChanged: widget.onValueChanged,
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: TextStyle(
                  color: Colors.grey.shade800), // Añadido estilo para el texto
            ),
          ),
      ],
    );
  }
}

class SystemMessage extends StatelessWidget {
  final String? title;
  final Widget child;

  const SystemMessage({
    Key? key,
    this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Material(
        elevation: 2,
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                border: Border.all(
                  color: Colors.grey.withOpacity(0.2),
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title != null) ...[
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF4B66A6).withOpacity(
                                0.1), // Color principal actualizado
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.medical_services_outlined,
                            color: Color(
                                0xFF4B66A6), // Color principal actualizado
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            title!,
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D2D2D),
                            ), // Aplicar fuente Roboto
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      height: 1,
                      color: Colors.grey.withOpacity(0.2),
                    ),
                    const SizedBox(height: 16),
                  ],
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UserMessage extends StatelessWidget {
  final String text;

  const UserMessage({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool isUserMessage = text.startsWith('USUARI:');
    bool isAssistantMessage = text.startsWith('ASSISTENT:');
    bool isSystemMessage = !isUserMessage && !isAssistantMessage;

    if (isSystemMessage) {
      return SystemMessage(
        child: Text(
          text,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      );
    }

    return SlideTransition(
      position: Tween<Offset>(
        begin: isUserMessage ? const Offset(1, 0) : const Offset(-1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: ModalRoute.of(context)!.animation!,
        curve: Curves.easeOutQuart,
      )),
      child: Align(
        alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isUserMessage
                  ? const Color(0xFF4B66A6) // Color principal actualizado
                  : const Color(
                      0xFF5B76B6), // Variación más clara del color principal
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUserMessage ? 20 : 5),
                bottomRight: Radius.circular(isUserMessage ? 5 : 20),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isUserMessage || isAssistantMessage)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      isUserMessage ? 'Tu' : 'Assistent',
                      style: GoogleFonts.roboto(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ), // Aplicar fuente Roboto
                    ),
                  ),
                Text(
                  text.replaceFirst(
                      isUserMessage ? 'USUARI:\n\n' : 'ASSISTENT:\n\n', ''),
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: Colors.white,
                    height: 1.5,
                  ), // Aplicar fuente Roboto
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final chatMessagesState =
        context.findAncestorStateOfType<_ChatMessagesState>();
    if (!chatMessagesState!.treatmentShown) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE8E8E8), // Cambiado a un gris más oscuro
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color: Colors.grey.shade400, // Borde un poco más oscuro
                ),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: chatMessagesState._chatController,
                      decoration: InputDecoration(
                        hintText: 'Escriu un missatge...',
                        border: InputBorder.none,
                        hintStyle: GoogleFonts.roboto(
                          color: Colors.grey.shade600,
                        ), // Aplicar fuente Roboto
                      ),
                      style: GoogleFonts.roboto(
                        color: Colors.grey.shade800,
                      ), // Aplicar fuente Roboto
                      maxLines: null,
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(25),
                      onTap: () {
                        final message = chatMessagesState._chatController.text;
                        if (message.isNotEmpty) {
                          chatMessagesState._handleChatMessage(message);
                          chatMessagesState._chatController.clear();
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        child: const Icon(
                          Icons.send_rounded,
                          color:
                              Color(0xFF4B66A6), // Color principal actualizado
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
