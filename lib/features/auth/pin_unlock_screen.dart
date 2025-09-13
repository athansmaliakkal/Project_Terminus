import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinUnlockScreen extends StatefulWidget {
  const PinUnlockScreen({super.key});

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  String _enteredPin = '';
  String _statusMessage = 'Enter your 6-digit PIN';
  bool _hasError = false;

  void _onNumberPressed(int number) {
    if (_hasError) {
      setState(() {
        _statusMessage = 'Enter your 6-digit PIN';
        _hasError = false;
      });
    }

    if (_enteredPin.length < 6) {
      setState(() {
        _enteredPin += number.toString();
        if (_enteredPin.length == 6) {
          _verifyPin();
        }
      });
    }
  }

  void _onBackspacePressed() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        if (_hasError) {
          _statusMessage = 'Enter your 6-digit PIN';
          _hasError = false;
        }
      });
    }
  }


  Future<void> _verifyPin() async {
    const storage = FlutterSecureStorage();
    final storedHash = await storage.read(key: 'pinHash');

    final enteredHash = sha256.convert(utf8.encode(_enteredPin))
        .bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join('');

    if (storedHash == enteredHash) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      setState(() {
        _statusMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 22,
                      color: _hasError ? Colors.redAccent : Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  PinDisplay(pinLength: _enteredPin.length),
                ],
              ),
            ),
            PinKeypad(
              onNumberPressed: _onNumberPressed,
              onBackspacePressed: _onBackspacePressed,
            ),
          ],
        ),
      ),
    );
  }
}


class PinDisplay extends StatelessWidget {
  final int pinLength;
  const PinDisplay({super.key, required this.pinLength});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        6,
        (index) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: index < pinLength
                  ? Theme.of(context).colorScheme.primary
                  // ignore: deprecated_member_use
                  : Colors.white.withOpacity(0.2),
            ),
          );
        },
      ),
    );
  }
}

class PinKeypad extends StatelessWidget {
  final Function(int) onNumberPressed;
  final VoidCallback onBackspacePressed;

  const PinKeypad({
    super.key,
    required this.onNumberPressed,
    required this.onBackspacePressed,
  });

  Widget _numButton(int number) {
    return Expanded(
      child: TextButton(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.all(20),
          shape: const CircleBorder(),
        ),
        onPressed: () => onNumberPressed(number),
        child: Text(
          number.toString(),
          style: const TextStyle(
            fontSize: 28,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children:
                  List.generate(3, (index) => _numButton(1 + 3 * i + index)),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              const Expanded(child: SizedBox()),
              _numButton(0),
              Expanded(
                child: TextButton(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.all(20),
                    shape: const CircleBorder(),
                  ),
                  onPressed: onBackspacePressed,
                  child: const Icon(
                    Icons.backspace_outlined,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }
}

