import 'package:flutter/material.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback onGoogleSignIn;
  final Function(String email, String appPassword, String server, int port)
  onImapLogin;
  final bool isSigningIn;

  const SignInScreen({
    super.key,
    required this.onGoogleSignIn,
    required this.onImapLogin,
    this.isSigningIn = false,
  });

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController(text: 'imap.gmail.com');
  final _portController = TextEditingController(text: '993');
  bool _isImapLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void _handleImapConnect() {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final server = _serverController.text.trim();
    final portStr = _portController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        server.isEmpty ||
        portStr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final port = int.tryParse(portStr);
    if (port == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Port must be a valid number')),
      );
      return;
    }

    setState(() {
      _isImapLoading = true;
    });

    widget
        .onImapLogin(email, password, server, port)
        .then((_) {
          if (mounted) {
            setState(() {
              _isImapLoading = false;
            });
          }
        })
        .catchError((e) {
          if (mounted) {
            setState(() {
              _isImapLoading = false;
            });
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('IMAP Error: $e')));
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mail Organizer'), centerTitle: true),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome to Mail Organizer',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'Sign in to prioritize your emails, deadlines, and reminders.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                ElevatedButton.icon(
                  onPressed: widget.isSigningIn ? null : widget.onGoogleSignIn,
                  icon: const Icon(Icons.account_circle),
                  label: Text(
                    widget.isSigningIn
                        ? 'Signing in...'
                        : 'Sign in with Google',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Advanced Options',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Card(
                  child: ExpansionTile(
                    title: const Text('Manual Email Login (App Password)'),
                    subtitle: const Text('Use IMAP with Google App Password'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Google App Password',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Generate a 16-digit App Password from Google Account > Security > App passwords.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                hintText: 'your.email@gmail.com',
                                labelText: 'Email Address',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              enabled: !_isImapLoading,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _passwordController,
                              decoration: const InputDecoration(
                                hintText: '1234 5678 90ab cdef',
                                labelText: 'App Password',
                                border: OutlineInputBorder(),
                              ),
                              obscureText: true,
                              enabled: !_isImapLoading,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _serverController,
                              decoration: const InputDecoration(
                                labelText: 'IMAP Server',
                                border: OutlineInputBorder(),
                              ),
                              enabled: !_isImapLoading,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _portController,
                              decoration: const InputDecoration(
                                labelText: 'Port',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              enabled: !_isImapLoading,
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isImapLoading
                                    ? null
                                    : _handleImapConnect,
                                child: Text(
                                  _isImapLoading
                                      ? 'Connecting...'
                                      : 'Connect via IMAP',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
