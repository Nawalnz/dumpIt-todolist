import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:labexample/widgets/app_logo.dart';
import 'package:top_snackbar_flutter/top_snack_bar.dart';
import 'package:top_snackbar_flutter/custom_snack_bar.dart';

import '../providers/auth_provider.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = ref.read(authRepositoryProvider);
      
      // 1. Create User
      UserCredential userCredential = await auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. Send Verification Email
      await userCredential.user?.sendEmailVerification();

      // 3. Update Display Name (Optional)
      await userCredential.user?.updateDisplayName(_nameController.text.trim());

      if (!mounted) return;
      showTopSnackBar(
        Overlay.of(context),
        const CustomSnackBar.info(
          message: "Verification email sent! Check your inbox.",
        ),
      );

      // 4. Wait for 3 seconds as requested
      await Future.delayed(const Duration(seconds: 3));

      if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
      
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration Failed')),
      );
    } catch (e) { // ✅ Catch other unexpected errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const AppLogo(),
                      const SizedBox(height: 20), 
                      TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                      TextFormField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                      TextFormField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password'), obscureText: true),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(labelText: 'Confirm Password'),
                        obscureText: true,
                        validator: (val) => val != _passwordController.text ? 'Passwords do not match' : null,
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _register,
                        child: const Text('Register'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          // Navigates to the login route you defined in main.dart
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text(
                          "Already have an account? Login here",
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.w600,
                          ),
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

