import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:url_launcher/url_launcher.dart';

// Custom color scheme
final customColors = {
  'primary': Color(0xFF003366), // Dark blue
  'secondary': Color(0xFF0099CC), // Light blue
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
          titleTextStyle: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: customColors['secondary'],
            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            textStyle: TextStyle(
              fontFamily: 'Montserrat',
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        textTheme: TextTheme(
          bodyLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            color: customColors['primary'],
          ),
          bodyMedium: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 14,
            color: customColors['primary'],
          ),
          titleLarge: TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: customColors['primary'],
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
                                  fontFamily: 'Montserrat',
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
  double _fever = 37.0;

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Temperatura',
      question: 'Tens febre? Introdueix la temperatura (°C):',
      progress: 0.2,
      content: Column(
        children: [
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 32.0,
              onSelectedItemChanged: (index) {
                setState(() {
                  _fever = 35.0 + index * 0.1;
                });
              },
              children: List<Widget>.generate(71, (index) {
                return Center(
                  child: Text(
                    (35.0 + index * 0.1).toStringAsFixed(1),
                    style: TextStyle(fontSize: 24),
                  ),
                );
              }),
            ),
          ),
          Text(
            '${_fever.toStringAsFixed(1)}°C',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      button: ElevatedButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CoughQuestionScreen(fever: _fever),
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
          _buildRadioTile('Sí', true, hasCough, (value) {
            setState(() {
              hasCough = value;
            });
          }),
          _buildRadioTile('No', false, hasCough, (value) {
            setState(() {
              hasCough = value;
            });
          }),
          if (hasCough == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'És amb expectoració?',
                  style: TextStyle(fontSize: 18),
                ),
                _buildRadioTile('Sí', true, hasExpectoration, (value) {
                  setState(() {
                    hasExpectoration = value;
                  });
                }),
                _buildRadioTile('No', false, hasExpectoration, (value) {
                  setState(() {
                    hasExpectoration = value;
                  });
                }),
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

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      leading: Radio<bool?>(
        value: value,
        groupValue: groupValue,
        activeColor: customColors['secondary'],
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.white,
      selectedTileColor: customColors['secondary']!.withAlpha(25),
      selected: groupValue == value,
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
  bool? hasMuscleRetraction;

  @override
  Widget build(BuildContext context) {
    return BaseQuestionScreen(
      title: 'Respiració',
      question: 'Experimentes dificultat per respirar?',
      progress: 0.6,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRadioTile('Sí', true, hasBreathingDifficulty, (value) {
            setState(() {
              hasBreathingDifficulty = value;
              if (value == false) {
                hasWheezing = null;
                hasMuscleRetraction = null;
              }
            });
          }),
          _buildRadioTile('No', false, hasBreathingDifficulty, (value) {
            setState(() {
              hasBreathingDifficulty = value;
              hasWheezing = null;
              hasMuscleRetraction = null;
            });
          }),
          if (hasBreathingDifficulty == true)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 16),
                Text(
                  'Sents un xiulet al respirar?',
                  style: TextStyle(fontSize: 18),
                ),
                _buildRadioTile('Sí', true, hasWheezing, (value) {
                  setState(() {
                    hasWheezing = value;
                  });
                }),
                _buildRadioTile('No', false, hasWheezing, (value) {
                  setState(() {
                    hasWheezing = value;
                  });
                }),
                SizedBox(height: 16),
                Text(
                  'Sents tiratge muscular al respirar?',
                  style: TextStyle(fontSize: 18),
                ),
                _buildRadioTile('Sí', true, hasMuscleRetraction, (value) {
                  setState(() {
                    hasMuscleRetraction = value;
                  });
                }),
                _buildRadioTile('No', false, hasMuscleRetraction, (value) {
                  setState(() {
                    hasMuscleRetraction = value;
                  });
                }),
              ],
            ),
        ],
      ),
      button: ElevatedButton.icon(
        onPressed: hasBreathingDifficulty == null ||
                (hasBreathingDifficulty == true &&
                    (hasWheezing == null || hasMuscleRetraction == null))
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
                      hasMuscleRetraction: hasMuscleRetraction ?? false,
                    ),
                  ),
                );
              },
        icon: Icon(Icons.arrow_forward),
        label: Text('Següent'),
      ),
    );
  }

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      leading: Radio<bool?>(
        value: value,
        groupValue: groupValue,
        activeColor: customColors['secondary'],
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.white,
      selectedTileColor: customColors['secondary']!.withAlpha(25),
      selected: groupValue == value,
    );
  }
}

class ChestPainQuestionScreen extends StatefulWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  final bool hasBreathingDifficulty;
  final bool hasWheezing;
  final bool hasMuscleRetraction;

  ChestPainQuestionScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
    required this.hasBreathingDifficulty,
    required this.hasWheezing,
    required this.hasMuscleRetraction,
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
          _buildRadioTile('Sí', true, hasChestPain, (value) {
            setState(() {
              hasChestPain = value;
            });
          }),
          _buildRadioTile('No', false, hasChestPain, (value) {
            setState(() {
              hasChestPain = value;
            });
          }),
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
                      hasMuscleRetraction: widget.hasMuscleRetraction,
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

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      leading: Radio<bool?>(
        value: value,
        groupValue: groupValue,
        activeColor: customColors['secondary'],
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.white,
      selectedTileColor: customColors['secondary']!.withAlpha(25),
      selected: groupValue == value,
    );
  }
}

class DisorientationQuestionScreen extends StatefulWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  final bool hasBreathingDifficulty;
  final bool hasWheezing;
  final bool hasMuscleRetraction;
  final bool hasChestPain;

  DisorientationQuestionScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
    required this.hasBreathingDifficulty,
    required this.hasWheezing,
    required this.hasMuscleRetraction,
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
          _buildRadioTile('Sí', true, hasDisorientation, (value) {
            setState(() {
              hasDisorientation = value;
            });
          }),
          _buildRadioTile('No', false, hasDisorientation, (value) {
            setState(() {
              hasDisorientation = value;
            });
          }),
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
                      hasMuscleRetraction: widget.hasMuscleRetraction,
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

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return ListTile(
      title: Text(
        title,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
      ),
      leading: Radio<bool?>(
        value: value,
        groupValue: groupValue,
        activeColor: customColors['secondary'],
        onChanged: onChanged,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      tileColor: Colors.white,
      selectedTileColor: customColors['secondary']!.withAlpha(25),
      selected: groupValue == value,
    );
  }
}

class ResultScreen extends StatelessWidget {
  final double fever;
  final bool hasCough;
  final bool hasExpectoration;
  final bool hasBreathingDifficulty;
  final bool hasWheezing;
  final bool hasMuscleRetraction;
  final bool hasChestPain;
  final bool hasDisorientation;

  ResultScreen({
    required this.fever,
    required this.hasCough,
    required this.hasExpectoration,
    required this.hasBreathingDifficulty,
    required this.hasWheezing,
    required this.hasMuscleRetraction,
    required this.hasChestPain,
    required this.hasDisorientation,
  });

  Widget _buildResultCard(
      String title, String content, Color color, IconData icon,
      {Widget? extraButton}) {
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
            Row(
              children: [
                Icon(icon, color: color, size: 30),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              content,
              style: TextStyle(fontSize: 16),
            ),
            if (extraButton != null) ...[
              SizedBox(height: 16),
              extraButton,
            ],
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
            if (hasBreathingDifficulty)
              _buildSummaryItem(
                  'Tiratge muscular:', hasMuscleRetraction ? 'Sí' : 'No'),
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
    String actions;
    Color resultColor;
    IconData resultIcon;

    if (fever >= 39 ||
        hasDisorientation ||
        hasChestPain && hasBreathingDifficulty ||
        (hasBreathingDifficulty && (hasWheezing || hasMuscleRetraction))) {
      result = 'Símptomes Greus';
      actions = '- EMERGÈNCIA MÈDICA\n'
          '- Trucar ambulància\n'
          '- Anar a urgències';
      resultColor = customColors['danger']!;
      resultIcon = Icons.error;
    } else if (fever >= 38.5 && hasCough && hasExpectoration && hasChestPain) {
      result = 'Símptomes Moderats';
      actions = '- Contactar metge mateix dia\n'
          '- Possible consulta presencial\n'
          '- Proves diagnòstiques bàsiques';
      resultColor = customColors['warning']!;
      resultIcon = Icons.warning;
    } else {
      result = 'Símptomes Lleus';
      actions = '- Repòs\n'
          '- Hidratació\n'
          '- Consultar al seu metge en 24-48 hores';
      resultColor = customColors['success']!;
      resultIcon = Icons.check_circle;
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
              resultColor,
              resultIcon,
              extraButton: result == 'Símptomes Greus'
                  ? ElevatedButton.icon(
                      onPressed: () async {
                        const url = 'tel:112';
                        if (await canLaunch(url)) {
                          await launch(url);
                        } else {
                          throw 'Could not launch $url';
                        }
                      },
                      icon: Icon(Icons.phone),
                      label: Text('Trucar a urgències (112)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors['danger'],
                      ),
                    )
                  : null,
            ),
            SizedBox(height: 24),
            _buildResultCard(
              'Accions',
              actions,
              customColors['primary']!,
              Icons.info,
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
