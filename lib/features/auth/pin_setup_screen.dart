import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  String _firstPin = '';
  String _secondPin = '';
  bool _isConfirming = false;
  String _statusMessage = 'Create a 6-digit PIN';

  Future<void> _finalizePinSetup() async {
    if (_firstPin != _secondPin) {
      setState(() {
        _statusMessage = 'PINs do not match. Please try again.';
        _firstPin = '';
        _secondPin = '';
        _isConfirming = false;
      });
      return;
    }

    final storage = const FlutterSecureStorage();
    final pinHash = sha256.convert(utf8.encode(_firstPin)).toString();

    await storage.write(key: 'pinHash', value: pinHash);
    await storage.write(key: 'isPinSet', value: 'true');

    if (mounted) {
      Navigator.pushReplacementNamed(context, '/unlock');
    }
  }

  void _onNumberPressed(int number) {
    setState(() {
      if (!_isConfirming) {
        if (_firstPin.length < 6) {
          _firstPin += number.toString();
        }
        if (_firstPin.length == 6) {
          _isConfirming = true;
          _statusMessage = 'Confirm your PIN';
        }
      } else {
        if (_secondPin.length < 6) {
          _secondPin += number.toString();
        }
        if (_secondPin.length == 6) {
          _finalizePinSetup();
        }
      }
    });
  }

  void _onBackspacePressed() {
    setState(() {
      if (_isConfirming) {
        if (_secondPin.isNotEmpty) {
          _secondPin = _secondPin.substring(0, _secondPin.length - 1);
        }
      } else {
        if (_firstPin.isNotEmpty) {
          _firstPin = _firstPin.substring(0, _firstPin.length - 1);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    String displayPin = _isConfirming ? _secondPin : _firstPin;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_statusMessage, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 40),
                  PinDisplay(pinLength: displayPin.length),
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
          style: const TextStyle(fontSize: 28, color: Colors.white),
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
              children: List.generate(3, (index) => _numButton(1 + 3 * i + index)),
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
                  child: const Icon(Icons.backspace_outlined, color: Colors.white),
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
