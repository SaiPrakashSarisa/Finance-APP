import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/security/mpin_service.dart';

enum MpinMode { setup, verify }

/// Purpose: Modern 4-Digit MPIN Security Screen (Setup & Verification)
/// Author: Antigravity AI

class MpinScreen extends StatefulWidget {
  final MpinMode mode;
  final VoidCallback? onSuccess;

  const MpinScreen({
    super.key,
    this.mode = MpinMode.verify,
    this.onSuccess,
  });

  @override
  State<MpinScreen> createState() => _MpinScreenState();
}

class _MpinScreenState extends State<MpinScreen> {
  String _enteredPin = '';
  String _firstPin = ''; // For setup mode confirmation
  bool _isConfirming = false;
  String? _errorMessage;
  bool _isLoading = false;

  void _onKeyPress(String val) {
    if (_enteredPin.length < 4) {
      setState(() {
        _enteredPin += val;
        _errorMessage = null;
      });

      if (_enteredPin.length == 4) {
        _handlePinComplete();
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  Future<void> _handlePinComplete() async {
    setState(() => _isLoading = true);

    try {
      if (widget.mode == MpinMode.setup) {
        if (!_isConfirming) {
          // Move to confirm stage
          setState(() {
            _firstPin = _enteredPin;
            _enteredPin = '';
            _isConfirming = true;
            _isLoading = false;
          });
        } else {
          // Compare initial pin and confirm pin
          if (_enteredPin == _firstPin) {
            await MpinService.setMpin(_enteredPin);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('4-Digit MPIN set successfully!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
              if (widget.onSuccess != null) {
                widget.onSuccess!();
              } else {
                context.go('/home');
              }
            }
          } else {
            setState(() {
              _errorMessage = 'Pins do not match. Try again.';
              _enteredPin = '';
              _firstPin = '';
              _isConfirming = false;
              _isLoading = false;
            });
          }
        }
      } else {
        // Verification Mode
        final result = await MpinService.verifyMpin(_enteredPin);
        if (result.success) {
          if (mounted) {
            if (widget.onSuccess != null) {
              widget.onSuccess!();
            } else {
              context.go('/home');
            }
          }
        } else {
          setState(() {
            _errorMessage = result.errorMessage ?? 'Incorrect MPIN';
            _enteredPin = '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _enteredPin = '';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == MpinMode.setup
        ? (_isConfirming ? 'Confirm 4-Digit MPIN' : 'Create 4-Digit MPIN')
        : 'Enter 4-Digit MPIN';

    final subtitle = widget.mode == MpinMode.setup
        ? (_isConfirming ? 'Re-enter your 4-digit PIN' : 'Set a quick PIN to unlock your app')
        : 'Unlock your Finance App session';

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Sleek Dark Slate
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 32),
              // Security Shield Icon
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4), width: 2),
                ),
                child: const Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFF818CF8),
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // PIN Indicator Dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    width: isFilled ? 20 : 16,
                    height: isFilled ? 20 : 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isFilled ? const Color(0xFF6366F1) : Colors.transparent,
                      border: Border.all(
                        color: _errorMessage != null
                            ? const Color(0xFFEF4444)
                            : (isFilled ? const Color(0xFF6366F1) : const Color(0xFF475569)),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(
                    color: Color(0xFFEF4444),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),

              const Spacer(),

              // Numeric Keypad
              if (!_isLoading) ...[
                _buildKeypadRow(['1', '2', '3']),
                const SizedBox(height: 16),
                _buildKeypadRow(['4', '5', '6']),
                const SizedBox(height: 16),
                _buildKeypadRow(['7', '8', '9']),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    const SizedBox(width: 72), // Empty placeholder for symmetry
                    _buildKeypadButton('0'),
                    IconButton(
                      onPressed: _onBackspace,
                      icon: const Icon(Icons.backspace_outlined, color: Colors.white, size: 28),
                    ),
                  ],
                ),
              ] else
                const CircularProgressIndicator(color: Color(0xFF6366F1)),

              const Spacer(),

              // Alternative Login Option
              if (widget.mode == MpinMode.verify)
                TextButton(
                  onPressed: () {
                    context.go('/login');
                  },
                  child: const Text(
                    'Log in with Password',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> values) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: values.map((v) => _buildKeypadButton(v)).toList(),
    );
  }

  Widget _buildKeypadButton(String value) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onKeyPress(value),
        borderRadius: BorderRadius.circular(36),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF1E293B),
            border: Border.all(color: const Color(0xFF334155), width: 1),
          ),
          child: Center(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
