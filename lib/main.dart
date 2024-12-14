import 'package:flutter/foundation.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:qr_mpid/home_page.dart';
import 'package:qr_mpid/verification_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'menu_page.dart';
import 'my_widget.dart';
import 'config_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://stwxwofcwvazwgjfunlc.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN0d3h3b2Zjd3ZhendnamZ1bmxjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQxMjA2MTIsImV4cCI6MjA0OTY5NjYxMn0.UGYj-cNX6Pk-Vy7xlxSGmyF7v7ns6HHYdtD3qE-DQjA',
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  Future<String?> _getUserRole() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return null;

      final response = await Supabase.instance.client
          .from('user_uuids')
          .select('role')
          .eq('user_uuid', user.id)
          .single();
      
      return response['role'] as String?;
    } catch (e) {
      debugPrint('Error al obtener el rol del usuario: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: kIsWeb ? const WebHomePage() : const HomePage(),
      routes: {
        // Solo registrar rutas si no estamos en web
        if (!kIsWeb) ... {
          '/login': (context) => const LoginPage(),
          '/signup': (context) => const SignupPage(),
          '/verification': (context) => const VerificationPage(),
          '/config': (context) => const ConfigPage(),
          '/menu': (context) => const MenuPage(),
          '/profile': (context) => const MyWidget(),
        }
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}

class WebHomePage extends StatelessWidget {
  const WebHomePage({Key? key}) : super(key: key);

  String? _getUIDFromUrl() {
    final uri = Uri.base;
    return uri.queryParameters['UID'];
  }

  @override
  Widget build(BuildContext context) {
    final uid = _getUIDFromUrl();
    
    return Scaffold(
      body: Center(
        child: uid != null 
          ? Text('UID: $uid', style: const TextStyle(fontSize: 24))
          : const Text('No UID provided', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

class _AuthWrapper extends StatelessWidget {
  Future<String?> _getUserRole(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('user_uuids')
          .select('role')
          .eq('user_uuid', userId)
          .maybeSingle();
      
      return response?['role'] as String?;
    } catch (e) {
      debugPrint('Error obteniendo el rol: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const LoginPage();
        }

        final user = snapshot.data?.session?.user;
        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<String?>(
          future: _getUserRole(user.id),
          builder: (context, roleSnapshot) {
            if (roleSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (roleSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text('Error al cargar el rol')),
              );
            }

            final role = roleSnapshot.data;
            if (role == 'config') {
              return const ConfigPage();
            }

            return kIsWeb ? const MenuPage() : const MyWidget();
          },
        );
      },
    );
  }
}
