import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({Key? key}) : super(key: key);

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  User? _user;

  @override
  void initState() {
    _getAuth();
    super.initState();
  }

  Future<void> _getAuth() async {
    setState(() {
      _user = Supabase.instance.client.auth.currentUser;
    });
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      setState(() {
        _user = data.session?.user;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Example'),
      ),
      body: _user == null ? const _LoginForm() : const _ProfileForm(),
    );
  }
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({Key? key}) : super(key: key);

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
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
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              TextFormField(
                keyboardType: TextInputType.emailAddress,
                controller: _emailController,
                decoration: const InputDecoration(label: Text('Email')),
              ),
              const SizedBox(height: 16),
              TextFormField(
                obscureText: true,
                controller: _passwordController,
                decoration: const InputDecoration(label: Text('Password')),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _loading = true;
                  });
                  try {
                    final email = _emailController.text;
                    final password = _passwordController.text;
                    await Supabase.instance.client.auth.signInWithPassword(
                      email: email,
                      password: password,
                    );
                  } catch (e) {
                    print(e);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Login failed'),
                      backgroundColor: Colors.red,
                    ));
                    setState(() {
                      _loading = false;
                    });
                  }
                },
                child: const Text('Login'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () async {
                  setState(() {
                    _loading = true;
                  });
                  try {
                    final email = _emailController.text;
                    final password = _passwordController.text;
                    final authResponse =
                        await Supabase.instance.client.auth.signUp(
                      email: email,
                      password: password,
                    );

                    if (authResponse.user != null) {
                      // Llamar a la función RPC después del registro exitoso
                      await Supabase.instance.client
                          .rpc('insert_user_uuid', params: {
                        'user_uuid': authResponse.user!.id,
                      });
                    }
                  } catch (e) {
                    print('Error en signup: $e'); // Para debug
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Signup failed: $e'),
                      backgroundColor: Colors.red,
                    ));
                    setState(() {
                      _loading = false;
                    });
                  }
                },
                child: const Text('Signup'),
              ),
            ],
          );
  }
}

class _ProfileForm extends StatefulWidget {
  const _ProfileForm({Key? key}) : super(key: key);

  @override
  State<_ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<_ProfileForm> {
  var _loading = true;
  final _usernameController = TextEditingController();
  final _websiteController = TextEditingController();

  @override
  void initState() {
    _loadProfile();
    super.initState();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _websiteController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final data = (await Supabase.instance.client
          .from('profiles')
          .select()
          .match({'id': userId}).maybeSingle());
      if (data != null) {
        setState(() {
          _usernameController.text = data['username'];
          _websiteController.text = data['website'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Error occurred while getting profile'),
        backgroundColor: Colors.red,
      ));
    }
    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  label: Text('Username'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _websiteController,
                decoration: const InputDecoration(
                  label: Text('Website'),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                  onPressed: () async {
                    try {
                      setState(() {
                        _loading = true;
                      });
                      final userId =
                          Supabase.instance.client.auth.currentUser!.id;
                      final username = _usernameController.text;
                      final website = _websiteController.text;
                      await Supabase.instance.client.from('profiles').upsert({
                        'id': userId,
                        'username': username,
                        'website': website,
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text('Saved profile'),
                        ));
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Error saving profile'),
                        backgroundColor: Colors.red,
                      ));
                    }
                    setState(() {
                      _loading = false;
                    });
                  },
                  child: const Text('Save')),
              const SizedBox(height: 16),
              TextButton(
                  onPressed: () => Supabase.instance.client.auth.signOut(),
                  child: const Text('Sign Out')),
            ],
          );
  }
}
