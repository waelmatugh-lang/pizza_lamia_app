import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../home/home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  bool _receiveNotifications = true;
  bool _isLoading = false;
  bool _isCapturingLocation = false;
  double? _latitude; // يُحفظ هنا عند الضغط على زر GPS
  double? _longitude;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final address = _addressController.text.trim();
    final email = _emailController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty || address.isEmpty) {
      _showError('الرجاء إدخال الاسم الأول، اللقب، والعنوان بالتفصيل.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('لا يوجد مستخدم مسجل حالياً. الرجاء تسجيل الدخول.');
      }

      await Supabase.instance.client.from('profiles').insert({
        'id': user.id,
        'first_name': firstName,
        'last_name': lastName,
        'address': address,
        'email': email.isNotEmpty ? email : null,
        'phone': user.phone,
        'accepts_notifications': _receiveNotifications,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        // GPS — يُرسل فقط إذا قام المستخدم بتحديد موقعه، وإلا null
        if (_latitude != null) 'latitude': _latitude,
        if (_longitude != null) 'longitude': _longitude,
      });

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('حدث خطأ أثناء حفظ البيانات: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// زر GPS — يجلب الإحداثيات ويحفظها في الـ State لترسل مع الـ Submit
  Future<void> _captureLocation() async {
    setState(() => _isCapturingLocation = true);
    final position = await LocationService.getCurrentLocation();
    if (mounted) setState(() => _isCapturingLocation = false);

    if (position != null) {
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديد موقعك بنجاح! سيُرسل مع بياناتك.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '⚠️ تعذّر الحصول على الموقع. تأكد من تفعيل GPS والصلاحيات.',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
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
      backgroundColor: Colors.black, // Dark background matching the app theme
      appBar: AppBar(
        title: const Text('إكمال البيانات الشخصية'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'مرحباً بك! 👋',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'الرجاء إكمال بياناتك لنتمكن من توصيل طلباتك بدقة.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 32),

              _buildTextField(
                'الاسم الأول',
                _firstNameController,
                Icons.person,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'اللقب',
                _lastNameController,
                Icons.person_outline,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'العنوان بالتفصيل (الحي، الشارع، أقرب معلم)',
                _addressController,
                Icons.location_on,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                'الإيميل (اختياري)',
                _emailController,
                Icons.email,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),

              Theme(
                data: Theme.of(
                  context,
                ).copyWith(unselectedWidgetColor: Colors.grey),
                child: CheckboxListTile(
                  title: const Text(
                    'أوافق على استلام الإشعارات للعروض وخصومات البيتزا 🍕',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  value: _receiveNotifications,
                  activeColor: AppTheme.primaryColor,
                  checkColor: Colors.white,
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  onChanged: (bool? value) {
                    if (value != null) {
                      setState(() => _receiveNotifications = value);
                    }
                  },
                ),
              ),

              const SizedBox(height: 16),

              // ======= زر GPS الدائم =======
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _isCapturingLocation ? null : _captureLocation,
                  icon: _isCapturingLocation
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryColor,
                          ),
                        )
                      : Icon(
                          _latitude != null
                              ? Icons
                                    .check_circle // ✅ تم التحديد
                              : Icons.gps_fixed, // لم يُحدَّد بعد
                          color: _latitude != null
                              ? Colors.green
                              : AppTheme.primaryColor,
                        ),
                  label: Text(
                    _isCapturingLocation
                        ? 'جارٍ التحديد...'
                        : _latitude != null
                        ? '✅ تم تحديد موقعك'
                        : '📍 حدد موقعي (اختياري)',
                    style: TextStyle(
                      color: _latitude != null
                          ? Colors.green
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _latitude != null
                          ? Colors.green
                          : AppTheme.primaryColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
              ),

              // =====================================
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
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'حفظ ومتابعة',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    String hintText,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: maxLines == 1
              ? Icon(icon, color: Colors.grey)
              : Padding(
                  padding: const EdgeInsets.only(
                    bottom: 40.0,
                  ), // Align icon to top for multiline
                  child: Icon(icon, color: Colors.grey),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }
}
