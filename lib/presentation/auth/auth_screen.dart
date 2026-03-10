import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../home/home_screen.dart';
import 'complete_profile_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();

  bool _isLoading = false;
  bool _showOtpField = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty || !phone.startsWith('+218')) {
      _showError('الرجاء إدخال رقم الهاتف مع مفتاح الدولة (مثال: +2189...)');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithOtp(phone: phone);

      if (mounted) {
        setState(() {
          _showOtpField = true;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إرسال رمز التحقق إلى هاتفك 📱'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on AuthException catch (e) {
      _showError(e.message);
      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      _showError('حدث خطأ غير متوقع: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final phone = _phoneController.text.trim();
    final otp = _otpController.text.trim();

    if (otp.length != 6) {
      _showError('الرجاء إدخال رمز التحقق المكون من 6 أرقام');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client.auth.verifyOTP(
        phone: phone,
        token: otp,
        type: OtpType.sms,
      );

      if (response.user != null && mounted) {
        // Check if the user exists in the profiles table
        final profileData = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', response.user!.id)
            .maybeSingle();

        if (!mounted) return;

        if (profileData == null) {
          // New User
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => const CompleteProfileScreen(),
            ),
          );
        } else {
          // Existing User
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      _showError(e.message);
    } catch (e) {
      _showError('حدث خطأ أثناء التحقق: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Deep Black background
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo or Graphic
              Image.asset(
                'assets/images/logo.png',
                height: 100,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.local_pizza,
                    size: 80,
                    color: AppTheme.primaryColor,
                  );
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Pizza Lamia 🍕',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _showOtpField
                    ? 'أدخل رمز التحقق (OTP)'
                    : 'تسجيل الدخول و إنشاء حساب',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 48),

              if (!_showOtpField) ...[
                // Phone Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _phoneController,
                    style: const TextStyle(color: Colors.white),
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    decoration: const InputDecoration(
                      hintText: '+218XXXXXXXXX',
                      hintStyle: TextStyle(color: Colors.grey),
                      prefixIcon: Icon(Icons.phone_android, color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _sendOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'دخول / تسجيل',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // OTP Field
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: TextField(
                    controller: _otpController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 8,
                    ),
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    decoration: const InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        color: Colors.grey,
                        letterSpacing: 8,
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryColor,
                    ),
                  )
                else
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _verifyOtp,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: const Text(
                        'تحقق من الرمز',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showOtpField = false;
                      _otpController.clear();
                    });
                  },
                  child: const Text(
                    'تعديل رقم الهاتف',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
