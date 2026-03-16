import 'package:chattingapp/util/api/api_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _idController = TextEditingController(text: 'asukim');
  final _pwController = TextEditingController(text: '1234');

  @override
  void dispose() {
    _idController.dispose();
    _pwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              TextField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'ID',
                  hintText: '아이디 입력',
                ),
              ),
              TextField(
                controller: _pwController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: '비밀번호 입력',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final id = _idController.text.trim();
                  final pw = _pwController.text;
                  ref.read(apiNotifier.notifier).signup(id, pw);
                },
                child: const Text('Sign up'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  final id = _idController.text.trim();
                  final pw = _pwController.text;
                  ref.read(apiNotifier.notifier).login(id, pw);
                },
                child: const Text('Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
