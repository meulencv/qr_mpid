import 'package:flutter/material.dart';

class ConfigPage extends StatelessWidget {
  const ConfigPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Config Page'),
      ),
      body: const Center(
        child: Text('Configuration Settings'),
      ),
    );
  }
}
