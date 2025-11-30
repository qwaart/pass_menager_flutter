import 'package:flutter/material.dart';
import '../services/pin_service.dart';
import 'home_screen.dart';

class PinScreen extends StatefulWidget {
  final bool isSetup; // true = creating PIN, false = entering PIN

  const PinScreen({Key? key, this.isSetup = false}) : super(key: key);

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  final PinService _pinService = PinService();
  String _pin = '';
  String _confirmPin = '';
  bool _isConfirming = false;
  String _errorMessage = '';

  void _onNumberPressed(String number) {
    setState(() {
      _errorMessage = '';
      
      if (widget.isSetup) {
        if (!_isConfirming) {
          if (_pin.length < 4) {
            _pin += number;
            if (_pin.length == 4) {
              // Transition to confirmation
              Future.delayed(const Duration(milliseconds: 300), () {
                setState(() {
                  _isConfirming = true;
                });
              });
            }
          }
        } else {
          if (_confirmPin.length < 4) {
            _confirmPin += number;
            if (_confirmPin.length == 4) {
              _verifySetup();
            }
          }
        }
      } else {
        if (_pin.length < 4) {
          _pin += number;
          if (_pin.length == 4) {
            _verifyPin();
          }
        }
      }
    });
  }

  void _onDeletePressed() {
    setState(() {
      _errorMessage = '';
      if (!_isConfirming) {
        if (_pin.isNotEmpty) {
          _pin = _pin.substring(0, _pin.length - 1);
        }
      } else {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        }
      }
    });
  }

  Future<void> _verifySetup() async {
    if (_pin == _confirmPin) {
      try {
        await _pinService.setPin(_pin);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'PIN save error';
          _pin = '';
          _confirmPin = '';
          _isConfirming = false;
        });
      }
    } else {
      setState(() {
        _errorMessage = 'PIN does not match!';
        _pin = '';
        _confirmPin = '';
        _isConfirming = false;
      });
    }
  }

  Future<void> _verifyPin() async {
    final isValid = await _pinService.verifyPin(_pin);
    if (isValid) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } else {
      setState(() {
        _errorMessage = 'Error PIN!';
        _pin = '';
      });
    }
  }

  Widget _buildPinDot(bool filled) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? Colors.deepPurple : Colors.transparent,
        border: Border.all(color: Colors.deepPurple, width: 2),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(50),
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.deepPurple, width: 2),
        ),
        child: Center(
          child: Text(
            number,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPin = _isConfirming ? _confirmPin : _pin;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 80,
                color: Colors.deepPurple,
              ),
              const SizedBox(height: 30),
              Text(
                widget.isSetup
                    ? (_isConfirming ? 'Confirm PIN' : 'Create PIN')
                    : 'Enter PIN',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                widget.isSetup
                    ? 'The PIN will be used for login.'
                    : 'Enter your 4-digit PIN',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),
              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => _buildPinDot(index < currentPin.length),
                ),
              ),
              if (_errorMessage.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  _errorMessage,
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
              ],
              const SizedBox(height: 60),
              // Number pad
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('1'),
                      _buildNumberButton('2'),
                      _buildNumberButton('3'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('4'),
                      _buildNumberButton('5'),
                      _buildNumberButton('6'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildNumberButton('7'),
                      _buildNumberButton('8'),
                      _buildNumberButton('9'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      const SizedBox(width: 70),
                      _buildNumberButton('0'),
                      InkWell(
                        onTap: _onDeletePressed,
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey[200],
                          ),
                          child: const Icon(
                            Icons.backspace_outlined,
                            color: Colors.deepPurple,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}