import 'package:flutter/material.dart';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import 'dart:convert';

class MedicalGuidePage extends StatelessWidget {
  const MedicalGuidePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        title: const Text('Xat Mèdic'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: const Column(
        children: [
          Expanded(
            child: ChatMessages(),
          ),
          ChatInput(),
        ],
      ),
    );
  }
}

class ChatMessages extends StatefulWidget {
  const ChatMessages({Key? key}) : super(key: key);

  @override
  State<ChatMessages> createState() => _ChatMessagesState();
}

class _ChatMessagesState extends State<ChatMessages> {
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

  final String apiKey =
      'v2-wZX9sx0k1JffHejsM4WZnnymKxo7yYjc9eLaqVCzojf8qi7w'; // Reemplaza con tu API key de Straico

  final List<String> symptomsList = [
    'Tos persistente (seca)',
    'Dolor torácico',
    'Congestión nasal',
    'Incremento de la mucosidad',
    'Pitidos',
    'Dificultad respiratoria',
    'Cianosis',
    'Otros',
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
              diagnosesShown = true; // Marcar que los diagnósticos se han mostrado
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
        showDiagnosisForm = true; // Mostrar formulario de diagnóstico si no quedan pruebas
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

    if (symptoms['Otros'] == true && otherSymptoms.isNotEmpty) {
      symptomsData += '- Otros: $otherSymptoms\n';
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

  void _sendDiagnosis() {
    if (_diagnosisController.text.isEmpty) return;

    setState(() {
      chatMessages.add('DIAGNÒSTIC FINAL:\n\n${_diagnosisController.text}');
      showDiagnosisForm = false;
      diagnosisCompleted = true; // Marcar que el diagnóstico está completado
    });
  }

  @override
  Widget build(BuildContext context) {
    // Modificar la condición para mostrar el diagnóstico
    bool shouldShowDiagnosis = medicalTests.isEmpty && 
                             !showDiagnosisForm && 
                             diagnosesShown &&
                             !diagnosisCompleted; // Añadir esta condición

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...chatMessages.map((message) => UserMessage(text: message)),
        if (showForm)
          SystemMessage(
            title: "Sistema d'Assistència Monitoritzada per IA",
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecciona i omple les dades disponibles:',
                  style: TextStyle(fontSize: 16),
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
                    backgroundColor: const Color(0xFF007AFF),
                    minimumSize: const Size(double.infinity, 45),
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
                      activeColor: const Color(0xFF007AFF),
                    )),
                if (symptoms['Otros'] ?? false)
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
                        fillColor: const Color(0xFFF7F7F8),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      onChanged: (value) => otherSymptoms = value,
                      maxLines: null,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _sendSymptoms,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    minimumSize: const Size(double.infinity, 45),
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
                    onPressed: () => setState(() => showDiagnosisForm = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF007AFF),
                      minimumSize: const Size(double.infinity, 45),
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
                  ),
                  maxLines: null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sendDiagnosis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          minimumSize: const Size(double.infinity, 45),
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
                      child:
                          const Icon(Icons.psychology, color: Colors.black54),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  void dispose() {
    _diagnosisController.dispose();
    super.dispose();
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
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
                decoration: const InputDecoration(
                  labelText: 'Resultats de la prova',
                  border: OutlineInputBorder(),
                ),
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
          title: Text('${widget.item.title} (${widget.item.unit})'),
          value: widget.isExpanded,
          onChanged: (bool? value) => widget.onChanged(value ?? false),
          activeColor: const Color(0xFF007AFF),
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
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                suffixText: widget.item.unit,
              ),
              onChanged: widget.onValueChanged,
              controller: _controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            offset: const Offset(0, 2),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}

class UserMessage extends StatelessWidget {
  final String text;

  const UserMessage({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF007AFF),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.white,
          height: 1.5,
        ),
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  const ChatInput({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Escriu un missatge...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: const Color(0xFFF7F7F8),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: () {},
            color: const Color(0xFF007AFF),
          ),
        ],
      ),
    );
  }
}