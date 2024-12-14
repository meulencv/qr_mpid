import 'package:flutter/material.dart';

// Custom color scheme
final customColors = {
  'primary': Color(0xFF2C3E50),
  'secondary': Color(0xFF3498DB),
  'background': Color(0xFFF5F6FA),
  'success': Color(0xFF2ECC71),
  'warning': Color(0xFFF1C40F),
  'danger': Color(0xFFE74C3C),
};

void main() {
  runApp(RespiratoryTestApp());
}

class RespiratoryTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Autodiagnosi Test',
      theme: ThemeData(
        primaryColor: customColors['primary'],
        scaffoldBackgroundColor: customColors['background'],
        appBarTheme: AppBarTheme(
          backgroundColor: customColors['primary'],
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: customColors['secondary'],
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
          ),
        ),
      ),
      home: FeverQuestionScreen(),
    );
  }
}

// Base question screen widget to reuse styling
class BaseQuestionScreen extends StatelessWidget {
  final String title;
  final String question;
  final Widget content;
  final Widget? button;
  final double progress;

  BaseQuestionScreen({
    required this.title,
    required this.question,
    required this.content,
    this.button,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor:
                AlwaysStoppedAnimation<Color>(customColors['secondary']!),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Card(
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.help_outline_rounded,
                                size: 48,
                                color: customColors['secondary'],
                              ),
                              SizedBox(height: 16),
                              Text(
                                question,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: customColors['primary'],
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 32),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withAlpha(25),
                                      spreadRadius: 2,
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: content,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      if (button != null) button!,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeverQuestionScreen extends StatefulWidget {
  @override
  _FeverQuestionScreenState createState() => _FeverQuestionScreenState();
}

class _FeverQuestionScreenState extends State<FeverQuestionScreen> {
  final _feverController = TextEditingController();

  @override
  void dispose() {
    _feverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Temperatura',
      question: 'Tens febre? Introdueix la temperatura (°C):',
      progress: 0.2,
      content: TextField(
        controller: _feverController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: 'Exemple: 38.5',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
      button: ElevatedButton.icon(
        onPressed: () {
          final fever = double.tryParse(_feverController.text);
          if (fever == null) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Error'),
                content: Text('Si us plau, introdueix un número vàlid.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            );
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoughQuestionScreen(fever: fever),
            ),
          );
        },
        icon: Icon(Icons.arrow_forward),
        label: Text('Següent'),
      ),
    );
  }
}

class CoughQuestionScreen extends StatefulWidget {
  final double fever;
  CoughQuestionScreen({required this.fever});

  @override
  _CoughQuestionScreenState createState() => _CoughQuestionScreenState();
}

class _CoughQuestionScreenState extends State<CoughQuestionScreen> {
  bool? hasCough;
  bool? hasExpectoration;

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Tos',
      question: 'Tens tos persistent?',
      progress: 0.4,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Sí',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: true,
              groupValue: hasCough,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasCough = value;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasCough == true,
          ),
          ListTile(
            title: Text(
              'No',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: false,
              groupValue: hasCough,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasCough = value;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasCough == false,
          ),
          if (hasCough == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'És amb expectoració?',
                  style: TextStyle(fontSize: 18),
                ),
                ListTile(
                  title: Text(
                    'Sí',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  leading: Radio<bool?>(
                    value: true,
                    groupValue: hasExpectoration,
                    activeColor: customColors['secondary'],
                    onChanged: (value) {
                      setState(() {
                        hasExpectoration = value;
                      });
                    },
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: Colors.white,
                  selectedTileColor: customColors['secondary']!.withAlpha(25),
                  selected: hasExpectoration == true,
                ),
                ListTile(
                  title: Text(
                    'No',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  leading: Radio<bool?>(
                    value: false,
                    groupValue: hasExpectoration,
                    activeColor: customColors['secondary'],
                    onChanged: (value) {
                      setState(() {
                        hasExpectoration = value;
                      });
                    },
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: Colors.white,
                  selectedTileColor: customColors['secondary']!.withAlpha(25),
                  selected: hasExpectoration == false,
                ),
              ],
            ),
        ],
      ),
      button: ElevatedButton.icon(
        onPressed: hasCough == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BreathingQuestionScreen(
                      fever: widget.fever,
                      hasCough: hasCough!,
                      hasExpectoration: hasExpectoration ?? false,
                    ),
                  ),
                );
              },
        icon: Icon(Icons.arrow_forward),
        label: Text('Següent'),
      ),
    );
  }
}

class BreathingQuestionScreen extends StatefulWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  BreathingQuestionScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
  });

  @override
  _BreathingQuestionScreenState createState() =>
      _BreathingQuestionScreenState();
}

class _BreathingQuestionScreenState extends State<BreathingQuestionScreen> {
  bool? hasBreathingDifficulty;
  bool? hasWheezing;

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Respiració',
      question: 'Experimentes dificultat per respirar?',
      progress: 0.6,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Sí',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: true,
              groupValue: hasBreathingDifficulty,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasBreathingDifficulty = value;
                  if (value == false) {
                    hasWheezing = null;
                  }
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasBreathingDifficulty == true,
          ),
          ListTile(
            title: Text(
              'No',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: false,
              groupValue: hasBreathingDifficulty,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasBreathingDifficulty = value;
                  hasWheezing = null;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasBreathingDifficulty == false,
          ),
          if (hasBreathingDifficulty == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  'Sents un xiulet al respirar?',
                  style: TextStyle(fontSize: 18),
                ),
                ListTile(
                  title: Text(
                    'Sí',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  leading: Radio<bool?>(
                    value: true,
                    groupValue: hasWheezing,
                    activeColor: customColors['secondary'],
                    onChanged: (value) {
                      setState(() {
                        hasWheezing = value;
                      });
                    },
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: Colors.white,
                  selectedTileColor: customColors['secondary']!.withAlpha(25),
                  selected: hasWheezing == true,
                ),
                ListTile(
                  title: Text(
                    'No',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                  ),
                  leading: Radio<bool?>(
                    value: false,
                    groupValue: hasWheezing,
                    activeColor: customColors['secondary'],
                    onChanged: (value) {
                      setState(() {
                        hasWheezing = value;
                      });
                    },
                  ),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  tileColor: Colors.white,
                  selectedTileColor: customColors['secondary']!.withAlpha(25),
                  selected: hasWheezing == false,
                ),
              ],
            ),
        ],
      ),
      button: ElevatedButton.icon(
        onPressed: hasBreathingDifficulty == null ||
                (hasBreathingDifficulty == true && hasWheezing == null)
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChestPainQuestionScreen(
                      fever: widget.fever,
                      hasCough: widget.hasCough,
                      hasExpectoration: widget.hasExpectoration,
                      hasBreathingDifficulty: hasBreathingDifficulty!,
                      hasWheezing: hasWheezing ?? false,
                    ),
                  ),
                );
              },
        icon: Icon(Icons.arrow_forward),
        label: Text('Següent'),
      ),
    );
  }
}

class ChestPainQuestionScreen extends StatefulWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  final bool hasBreathingDifficulty;
  final bool hasWheezing;

  ChestPainQuestionScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
    required this.hasBreathingDifficulty,
    required this.hasWheezing,
  });

  @override
  _ChestPainQuestionScreenState createState() =>
      _ChestPainQuestionScreenState();
}

class _ChestPainQuestionScreenState extends State<ChestPainQuestionScreen> {
  bool? hasChestPain;

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Dolor al pit',
      question: 'Tens dolor al pit?',
      progress: 0.8,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Sí',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: true,
              groupValue: hasChestPain,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasChestPain = value;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasChestPain == true,
          ),
          ListTile(
            title: Text(
              'No',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: false,
              groupValue: hasChestPain,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasChestPain = value;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasChestPain == false,
          ),
        ],
      ),
      button: ElevatedButton.icon(
        onPressed: hasChestPain == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DisorientationQuestionScreen(
                      fever: widget.fever,
                      hasCough: widget.hasCough,
                      hasExpectoration: widget.hasExpectoration,
                      hasBreathingDifficulty: widget.hasBreathingDifficulty,
                      hasWheezing: widget.hasWheezing,
                      hasChestPain: hasChestPain!,
                    ),
                  ),
                );
              },
        icon: Icon(Icons.arrow_forward),
        label: Text('Següent'),
      ),
    );
  }
}

class DisorientationQuestionScreen extends StatefulWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  final bool hasBreathingDifficulty;
  final bool hasWheezing;
  final bool hasChestPain;

  DisorientationQuestionScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
    required this.hasBreathingDifficulty,
    required this.hasWheezing,
    required this.hasChestPain,
  });

  @override
  _DisorientationQuestionScreenState createState() =>
      _DisorientationQuestionScreenState();
}

class _DisorientationQuestionScreenState
    extends State<DisorientationQuestionScreen> {
  bool? hasDisorientation;

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Desorientació',
      question: 'Tens desorientació severa?',
      progress: 1.0,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              'Sí',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: true,
              groupValue: hasDisorientation,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasDisorientation = value;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasDisorientation == true,
          ),
          ListTile(
            title: Text(
              'No',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            leading: Radio<bool?>(
              value: false,
              groupValue: hasDisorientation,
              activeColor: customColors['secondary'],
              onChanged: (value) {
                setState(() {
                  hasDisorientation = value;
                });
              },
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            tileColor: Colors.white,
            selectedTileColor: customColors['secondary']!.withAlpha(25),
            selected: hasDisorientation == false,
          ),
        ],
      ),
      button: ElevatedButton.icon(
        onPressed: hasDisorientation == null
            ? null
            : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      fever: widget.fever,
                      hasCough: widget.hasCough,
                      hasExpectoration: widget.hasExpectoration,
                      hasBreathingDifficulty: widget.hasBreathingDifficulty,
                      hasWheezing: widget.hasWheezing,
                      hasChestPain: widget.hasChestPain,
                      hasDisorientation: hasDisorientation!,
                    ),
                  ),
                );
              },
        icon: Icon(Icons.check),
        label: Text('Finalitzar'),
      ),
    );
  }
}

class ResultScreen extends StatelessWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  final bool hasBreathingDifficulty;
  final bool hasWheezing;
  final bool hasChestPain;
  final bool hasDisorientation;

  ResultScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
    required this.hasBreathingDifficulty,
    required this.hasWheezing,
    required this.hasChestPain,
    required this.hasDisorientation,
  });

  Widget _buildResultCard(String title, String content, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color, width: 2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resum de símptomes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: customColors['primary'],
              ),
            ),
            SizedBox(height: 16),
            _buildSummaryItem('Temperatura:', '${fever.toStringAsFixed(1)}°C'),
            _buildSummaryItem('Tos:', hasCough ? 'Sí' : 'No'),
            if (hasCough)
              _buildSummaryItem(
                  'Expectoració:', hasExpectoration ? 'Sí' : 'No'),
            _buildSummaryItem('Dificultat respiratòria:',
                hasBreathingDifficulty ? 'Sí' : 'No'),
            if (hasBreathingDifficulty)
              _buildSummaryItem(
                  'Xiulet al respirar:', hasWheezing ? 'Sí' : 'No'),
            _buildSummaryItem('Dolor al pit:', hasChestPain ? 'Sí' : 'No'),
            _buildSummaryItem(
                'Desorientació:', hasDisorientation ? 'Sí' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: customColors['primary'],
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String result;

    if (fever >= 39 ||
        hasDisorientation ||
        hasChestPain && hasBreathingDifficulty ||
        (hasBreathingDifficulty && hasWheezing)) {
      // Added wheezing condition
      result = 'Símptomes Greus\n\n'
          'Febre alta 39°C\n'
          'Dificultat respiratòria significativa\n'
          'Dolor toràcic intens\n'
          'Desorientació\n'
          'Xiulet al respirar\n\n'
          'Accions:\n'
          '- EMERGÈNCIA MÈDICA\n'
          '- Trucar ambulància\n'
          '- Anar a urgències';
    } else if (fever >= 38.5 && hasCough && hasExpectoration && hasChestPain) {
      result = 'Símptomes Moderats\n\n'
          'Febre 38.5°C\n'
          'Tos amb expectoració\n'
          'Dificultat respiratòria al parlar\n'
          'Dolor toràcic\n\n'
          'Accions:\n'
          '- Contactar metge mateix dia\n'
          '- Possible consulta presencial\n'
          '- Proves diagnòstiques bàsiques';
    } else {
      result = 'Símptomes Lleus\n\n'
          'Temperatura 38.5°C\n'
          'Tos sense expectoració\n'
          'Dificultat respiratòria ocasional\n\n'
          'Accions:\n'
          '- Repòs\n'
          '- Hidratació\n'
          '- Consultar al seu metge en 24-48 hores';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Resultats'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            _buildSummaryCard(),
            SizedBox(height: 24),
            _buildResultCard(
              'Diagnòstic',
              result,
              hasDisorientation
                  ? customColors['danger']!
                  : hasChestPain
                      ? customColors['warning']!
                      : customColors['success']!,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              icon: Icon(Icons.refresh),
              label: Text('Realitzar nou diagnòstic'),
            ),
          ],
        ),
      ),
    );
  }
}
