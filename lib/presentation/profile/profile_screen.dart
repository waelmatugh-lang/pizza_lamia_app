import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/services/location_service.dart';
import '../auth/auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  double? _latitude;
  double? _longitude;
  bool _isCapturingLocation = false;

  // --- تسجيل الخروج ---
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // --- زر GPS الذكي: يجلب الإحداثيات ويُحدّثها فوراً في Supabase ---
  Future<void> _updateLocation() async {
    setState(() => _isCapturingLocation = true);
    final position = await LocationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _isCapturingLocation = false);

    if (position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '⚠️ تعذّر الحصول على الموقع. تأكد من تفعيل GPS والصلاحيات.',
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // حفظ في الـ State أولاً
    setState(() {
      _latitude = position.latitude;
      _longitude = position.longitude;
    });

    // تحديث فوري في Supabase
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client
          .from('profiles')
          .update({
            'latitude': position.latitude,
            'longitude': position.longitude,
          })
          .eq('id', userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم تحديث موقعك في قاعدة البيانات بنجاح!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ خطأ في حفظ الموقع: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final email = user?.email ?? user?.phone ?? 'Guest User';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ملفي الشخصي', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Icon
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.5),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.person,
                    size: 80,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // User Email/Phone
              Text(
                email,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pizza Lover 🍕',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[400], fontSize: 16),
              ),

              const SizedBox(height: 40),

              // ======= زر GPS الذكي =======
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isCapturingLocation ? null : _updateLocation,
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
                        ? '✅ تم تحديث الموقع'
                        : '📍 تحديث موقعي',
                    style: TextStyle(
                      color: _latitude != null
                          ? Colors.green
                          : AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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

              // ===========================
              const SizedBox(height: 16),

              // Logout Button
              SizedBox(
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => _handleLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    'تسجيل الخروج',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
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
}
