import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar Sessió',
            style: TextStyle(fontFamily: 'Roboto')),
        backgroundColor: const Color(0xFF4b66a6),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration:
                        const InputDecoration(labelText: 'Correu electrònic'),
                    style: GoogleFonts.roboto(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Contrasenya'),
                    obscureText: true,
                    style: GoogleFonts.roboto(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handleLogin,
                      child: const Text('Iniciar Sessió',
                          style: TextStyle(fontFamily: 'Roboto')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4b66a6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _handleLogin() async {
    setState(() => _loading = true);
    try {
      final auth = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (auth.user != null) {
        final response = await Supabase.instance.client
            .from('user_uuids')
            .select('role')
            .eq('user_uuid', auth.user!.id)
            .single();

        if (mounted) {
          if (response['role'] == 'config') {
            Navigator.pushReplacementNamed(
                context, '/config'); // Cambiado de '/survey' a '/config'
          } else if (response['role'] != null) {
            Navigator.pushReplacementNamed(context, '/');
          } else {
            await Supabase.instance.client.auth.signOut();
            Navigator.pushReplacementNamed(context, '/verification');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error d\'inici de sessió: $e',
                style: GoogleFonts.roboto()), // Mejorado el mensaje de error
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
