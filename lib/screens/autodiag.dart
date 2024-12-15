import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_mpid/screens/web_data_page.dart'; // Import WebDataPage

// Custom color scheme
final customColors = {
  'primary': Color(0xFF4b66a6), // Dark blue
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
            backgroundColor: customColors['primary'],
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
      home: AutoDiagnosticScreen(),
    );
  }
}

class AutoDiagnosticScreen extends StatefulWidget {
  @override
  _AutoDiagnosticScreenState createState() => _AutoDiagnosticScreenState();
}

class _AutoDiagnosticScreenState extends State<AutoDiagnosticScreen> {
  final PageController _pageController = PageController();
  double fever = 37.0;
  bool? hasCough;
  bool? hasExpectoration;
  bool? hasBreathingDifficulty;
  bool? hasWheezing;
  bool? hasMuscleRetraction;
  bool? hasChestPain;
  bool? hasDisorientation;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void nextPage() {
    if (_pageController.page!.toInt() < 4) {
      _pageController.nextPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void previousPage() {
    if (_pageController.page!.toInt() > 0) {
      _pageController.previousPage(
        duration: Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Si estamos en la primera página, navegar a WebDataPage
        if (_pageController.page == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => WebDataPage()),
            (route) => false,
          );
          return false;
        }
        // Si no, permitir el pop normal y navegar a la página anterior
        previousPage();
        return false;
      },
      child: Scaffold(
        backgroundColor: Color(0xFFF5F5F7),
        body: PageView(
          controller: _pageController,
          physics: NeverScrollableScrollPhysics(),
          children: [
            FeverQuestionScreen(
              onNext: (value) {
                setState(() => fever = value);
                nextPage();
              },
              initialValue: fever, // Añadir valor inicial
            ),
            CoughQuestionScreen(
              onNext: (cough, expectoration) {
                setState(() {
                  hasCough = cough;
                  hasExpectoration = expectoration;
                });
                nextPage();
              },
              onBack: previousPage,
              initialCough: hasCough, // Añadir valores iniciales
              initialExpectoration: hasExpectoration,
            ),
            BreathingQuestionScreen(
              onNext: (breathing, wheezing, muscleRetraction) {
                setState(() {
                  hasBreathingDifficulty = breathing;
                  hasWheezing = wheezing;
                  hasMuscleRetraction = muscleRetraction;
                });
                nextPage();
              },
              onBack: previousPage,
              initialBreathing: hasBreathingDifficulty, // Añadir valores iniciales
              initialWheezing: hasWheezing,
              initialMuscleRetraction: hasMuscleRetraction,
            ),
            ChestPainQuestionScreen(
              onNext: (value) {
                setState(() => hasChestPain = value);
                nextPage();
              },
              onBack: previousPage,
              initialValue: hasChestPain, // Añadir valor inicial
            ),
            DisorientationQuestionScreen(
              onNext: (value) {
                setState(() => hasDisorientation = value);
                // Navegar a la pantalla de resultados
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ResultScreen(
                      fever: fever,
                      hasCough: hasCough ?? false,
                      hasExpectoration: hasExpectoration ?? false,
                      hasBreathingDifficulty: hasBreathingDifficulty ?? false,
                      hasWheezing: hasWheezing ?? false,
                      hasMuscleRetraction: hasMuscleRetraction ?? false,
                      hasChestPain: hasChestPain ?? false,
                      hasDisorientation: hasDisorientation ?? false,
                    ),
                  ),
                );
              },
              onBack: previousPage,
              initialValue: hasDisorientation, // Añadir valor inicial
            ),
          ],
        ),
      ),
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
  final bool isFirstQuestion;
  final VoidCallback? onBack;  // Añadir este parámetro

  BaseQuestionScreen({
    required this.title,
    required this.question,
    required this.content,
    this.button,
    required this.progress,
    this.isFirstQuestion = false,
    this.onBack,  // Añadir este parámetro
  });

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width <= 600;

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F7),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(
            Icons.home_outlined,
            color: Color(0xFF304982),
            size: 28,
          ),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (context) => MaterialApp(
                  theme: ThemeData(
                    primaryColor: Color(0xFF304982),
                    appBarTheme: AppBarTheme(
                      backgroundColor: Color(0xFF304982),
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                  ),
                  home: WebDataPage(),
                ),
              ),
              (route) => false,
            );
          },
        ),
      ),
      body: Column(
        children: [
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF304982)),
            minHeight: 2,
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 16 : 24,
                vertical: isSmallScreen ? 12 : 20,
              ),
              child: Column(
                children: [
                  Text(
                    'Autodiagnòstic',
                    style: GoogleFonts.inter(
                      fontSize: isSmallScreen ? 24 : 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF304982),
                      height: 1.2,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 24),
                  Container(
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
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(0xFF304982).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.help_outline_rounded,
                                  color: Color(0xFF304982),
                                  size: 20,
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  question,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Divider(
                            height: 1, thickness: 1, color: Colors.grey[100]),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: content,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  if (button != null) button!,
                  SizedBox(height: 16),
                  if (!isFirstQuestion)
                    OutlinedButton.icon(
                      onPressed: onBack,  // Usar onBack en lugar de Navigator.pop
                      icon: Icon(Icons.arrow_back, size: 18),
                      label: Text('Tornar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF304982),
                        side: BorderSide(color: Color(0xFF304982)),
                        padding:
                            EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

class FeverQuestionScreen extends StatefulWidget {
  final Function(double) onNext;
  final double? initialValue; // Añadir valor inicial

  FeverQuestionScreen({
    required this.onNext, 
    this.initialValue, // Añadir al constructor
  });

  @override
  _FeverQuestionScreenState createState() => _FeverQuestionScreenState();
}

class _FeverQuestionScreenState extends State<FeverQuestionScreen> {
  late double _fever;

  @override
  void initState() {
    super.initState();
    _fever = widget.initialValue ?? 37.0; // Usar valor inicial si existe
  }

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
          widget.onNext(_fever);
        },
        icon: Icon(Icons.arrow_forward, color: Colors.white),
        label: Text(
          'Següent',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF304982),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      isFirstQuestion: true,
    );
  }
}

class CoughQuestionScreen extends StatefulWidget {
  final Function(bool, bool) onNext;
  final VoidCallback onBack;
  final bool? initialCough;
  final bool? initialExpectoration;

  CoughQuestionScreen({
    required this.onNext,
    required this.onBack,
    this.initialCough,
    this.initialExpectoration,
  });

  @override
  _CoughQuestionScreenState createState() => _CoughQuestionScreenState();
}

class _CoughQuestionScreenState extends State<CoughQuestionScreen> {
  bool? hasCough;
  bool? hasExpectoration;

  @override
  void initState() {
    super.initState();
    hasCough = widget.initialCough;
    hasExpectoration = widget.initialExpectoration;
  }

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
                widget.onNext(hasCough!, hasExpectoration ?? false);
              },
        icon: Icon(Icons.arrow_forward, color: Colors.white),
        label: Text(
          'Següent',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF304982),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onBack: widget.onBack,  // Pasar la función onBack
    );
  }

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == value ? Color(0xFF304982) : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: groupValue == value
            ? Color(0xFF304982).withOpacity(0.05)
            : Colors.white,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: groupValue == value
                        ? Color(0xFF304982)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: groupValue == value
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF304982),
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight:
                      groupValue == value ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BreathingQuestionScreen extends StatefulWidget {
  final Function(bool, bool, bool) onNext;
  final VoidCallback onBack;
  final bool? initialBreathing;
  final bool? initialWheezing;
  final bool? initialMuscleRetraction;

  BreathingQuestionScreen({
    required this.onNext,
    required this.onBack,
    this.initialBreathing,
    this.initialWheezing,
    this.initialMuscleRetraction,
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
  void initState() {
    super.initState();
    hasBreathingDifficulty = widget.initialBreathing;
    hasWheezing = widget.initialWheezing;
    hasMuscleRetraction = widget.initialMuscleRetraction;
  }

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
                widget.onNext(hasBreathingDifficulty!, hasWheezing ?? false,
                    hasMuscleRetraction ?? false);
              },
        icon: Icon(Icons.arrow_forward, color: Colors.white),
        label: Text(
          'Següent',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF304982),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onBack: widget.onBack,  // Pasar la función onBack
    );
  }

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == value ? Color(0xFF304982) : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: groupValue == value
            ? Color(0xFF304982).withOpacity(0.05)
            : Colors.white,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: groupValue == value
                        ? Color(0xFF304982)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: groupValue == value
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF304982),
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight:
                      groupValue == value ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChestPainQuestionScreen extends StatefulWidget {
  final Function(bool) onNext;
  final VoidCallback onBack;
  final bool? initialValue;

  ChestPainQuestionScreen({
    required this.onNext,
    required this.onBack,
    this.initialValue,
  });

  @override
  _ChestPainQuestionScreenState createState() =>
      _ChestPainQuestionScreenState();
}

class _ChestPainQuestionScreenState extends State<ChestPainQuestionScreen> {
  bool? hasChestPain;

  @override
  void initState() {
    super.initState();
    hasChestPain = widget.initialValue;
  }

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
                widget.onNext(hasChestPain!);
              },
        icon: Icon(Icons.arrow_forward, color: Colors.white),
        label: Text(
          'Següent',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF304982),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onBack: widget.onBack,  // Pasar la función onBack
    );
  }

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == value ? Color(0xFF304982) : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: groupValue == value
            ? Color(0xFF304982).withOpacity(0.05)
            : Colors.white,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: groupValue == value
                        ? Color(0xFF304982)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: groupValue == value
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF304982),
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight:
                      groupValue == value ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DisorientationQuestionScreen extends StatefulWidget {
  final Function(bool) onNext;
  final VoidCallback onBack;
  final bool? initialValue;

  DisorientationQuestionScreen({
    required this.onNext,
    required this.onBack,
    this.initialValue,
  });

  @override
  _DisorientationQuestionScreenState createState() =>
      _DisorientationQuestionScreenState();
}

class _DisorientationQuestionScreenState
    extends State<DisorientationQuestionScreen> {
  bool? hasDisorientation;

  @override
  void initState() {
    super.initState();
    hasDisorientation = widget.initialValue;
  }

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
                widget.onNext(hasDisorientation!);
              },
        icon: Icon(Icons.check, color: Colors.white),
        label: Text(
          'Finalitzar',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF304982),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      onBack: widget.onBack,  // Pasar la función onBack
    );
  }

  Widget _buildRadioTile(String title, bool value, bool? groupValue,
      ValueChanged<bool?> onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: groupValue == value ? Color(0xFF304982) : Colors.grey[300]!,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: groupValue == value
            ? Color(0xFF304982).withOpacity(0.05)
            : Colors.white,
      ),
      child: InkWell(
        onTap: () => onChanged(value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: groupValue == value
                        ? Color(0xFF304982)
                        : Colors.grey[400]!,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: groupValue == value
                      ? Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFF304982),
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight:
                      groupValue == value ? FontWeight.w500 : FontWeight.w400,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
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
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: Colors.black87,
                    height: 1.6,
                  ),
                ),
                if (extraButton != null) ...[
                  SizedBox(height: 20),
                  Center(child: extraButton),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Color(0xFF304982).withOpacity(0.1),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color(0xFF304982).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.assignment_outlined,
                    color: Color(0xFF304982),
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Text(
                  'Resum de símptomes',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF304982),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                _buildSummaryRow('Temperatura', '${fever.toStringAsFixed(1)}°C'),
                _buildSummaryRow('Tos', hasCough ? 'Sí' : 'No'),
                if (hasCough)
                  _buildSummaryRow('Expectoració', hasExpectoration ? 'Sí' : 'No'),
                _buildSummaryRow(
                    'Dificultat respiratòria', hasBreathingDifficulty ? 'Sí' : 'No'),
                if (hasBreathingDifficulty) ...[
                  _buildSummaryRow('Xiulet al respirar', hasWheezing ? 'Sí' : 'No'),
                  _buildSummaryRow(
                      'Tiratge muscular', hasMuscleRetraction ? 'Sí' : 'No'),
                ],
                _buildSummaryRow('Dolor al pit', hasChestPain ? 'Sí' : 'No'),
                _buildSummaryRow('Desorientació', hasDisorientation ? 'Sí' : 'No'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Color(0xFF304982),
              fontWeight: FontWeight.w600,
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
      backgroundColor: Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF304982),
        title: Text(
          'Resultats',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildSummaryCard(),
                  SizedBox(height: 20),
                  _buildResultCard(
                    'Diagnòstic',
                    result,
                    resultColor,
                    resultIcon,
                    extraButton: result == 'Símptomes Greus'
                        ? Container(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                const url = 'tel:112';
                                if (await canLaunch(url)) {
                                  await launch(url);
                                }
                              },
                              icon: Icon(Icons.phone, color: Colors.white),
                              label: Text(
                                'Trucar a urgències (112)',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: resultColor,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: 20),
                  _buildResultCard(
                    'Accions recomanades',
                    actions,
                    Color(0xFF304982),
                    Icons.medical_services_outlined,
                  ),
                  SizedBox(height: 32),
                  Container(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                              builder: (context) => AutoDiagnosticScreen()),
                          (route) => false,
                        );
                      },
                      icon: Icon(Icons.refresh, color: Colors.white),
                      label: Text(
                        'Realitzar nou diagnòstic',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF304982),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
