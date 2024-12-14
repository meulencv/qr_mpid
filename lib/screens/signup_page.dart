import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({Key? key}) : super(key: key);

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
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
      appBar: AppBar(title: const Text('Registrar-se')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration:
                      const InputDecoration(label: Text('Correu electrònic')),
                  style: GoogleFonts.roboto(),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  obscureText: true,
                  controller: _passwordController,
                  decoration: const InputDecoration(label: Text('Contrasenya')),
                  style: GoogleFonts.roboto(),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _handleSignup,
                  child: const Text('Crear Compte', style: TextStyle(fontFamily: 'Roboto')),
                ),
              ],
            ),
    );
  }

  Future<void> _handleSignup() async {
    setState(() => _loading = true);
    try {
      final auth = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (auth.user != null) {
        await Supabase.instance.client.rpc('insert_user_uuid', params: {
          'user_uuid': auth.user!.id,
        });

        if (mounted) {
          Navigator.pushReplacementNamed(context, '/verification');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('El registre ha fallat: $e', style: GoogleFonts.roboto()),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
