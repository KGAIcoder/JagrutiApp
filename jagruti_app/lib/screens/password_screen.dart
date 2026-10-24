import 'package:flutter/material.dart';

import 'home_page.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});

  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  static const Color _bg = Color(0xFFFFF4E6);
  static const Color _text = Color(0xFF2B160F);
  static const Color _muted = Color(0xFF7A5A47);

  final List<TextEditingController> _pinControllers =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(4, (_) => FocusNode());
  final String _correctPassword = "1008";

  String get _enteredPin => _pinControllers.map((controller) => controller.text).join();

  @override
  void dispose() {
    for (final controller in _pinControllers) {
      controller.dispose();
    }
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    super.dispose();
  }

  void _checkPassword() {
    if (_enteredPin == _correctPassword) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else {
      for (final controller in _pinControllers) {
        controller.clear();
      }
      _focusNodes.first.requestFocus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect PIN. Try again.")),
      );
    }
  }

  void _onPinChanged(int index, String value) {
    if (value.isNotEmpty && index < _focusNodes.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
    if (_enteredPin.length == 4) {
      _checkPassword();
    }
  }

  Widget _pinBox(int index) {
    return Container(
      width: 68,
      height: 84,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEFDCC8)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22A57A3A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFF9F0), Color(0xFFFFEBCF)],
        ),
      ),
      child: Center(
        child: TextField(
          controller: _pinControllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: _text),
          maxLength: 1,
          obscureText: true,
          obscuringCharacter: '•',
          decoration: const InputDecoration(
            border: InputBorder.none,
            counterText: '',
            contentPadding: EdgeInsets.only(bottom: 2),
          ),
          onChanged: (value) => _onPinChanged(index, value),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 190,
                height: 190,
                decoration: BoxDecoration(
                  color: const Color(0xFF5E0F2C),
                  borderRadius: BorderRadius.circular(36),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x331A0A05),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Image.asset('assets/Jagruti.png', fit: BoxFit.contain),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Enter 4-Digit Password',
                style: TextStyle(
                  color: _text,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '○ ○ ○ ○',
                style: TextStyle(color: _muted, fontSize: 20, letterSpacing: 6),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _pinBox(0),
                  const SizedBox(width: 12),
                  _pinBox(1),
                  const SizedBox(width: 12),
                  _pinBox(2),
                  const SizedBox(width: 12),
                  _pinBox(3),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 280,
                height: 62,
                child: ElevatedButton(
                onPressed: _checkPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB88A43),
                    foregroundColor: Colors.white,
                    elevation: 8,
                    shadowColor: const Color(0x55251408),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(31)),
                  ),
                  child: const Text(
                    'Unlock',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
