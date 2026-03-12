import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/cubit/delivery_location_cubit.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/cart/cubit/cart_cubit.dart';
import 'presentation/home/favorite/cubit/favorite_cubit.dart';
import 'presentation/notifications/cubit/notification_cubit.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> saveTokenToSupabase(String token) async {
  final user = Supabase.instance.client.auth.currentUser;
  
  if (user != null) {
    try {
      await Supabase.instance.client
          .from('user_tokens')
          .upsert({
            'user_id': user.id,
            'fcm_token': token,
          });
      debugPrint('🚀 FCM Token successfully linked to User: ${user.id}');
    } catch (e) {
      debugPrint('Error: $e');
    }
  } else {
    debugPrint('User not logged in, skipping FCM Token save.');
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Request notification permissions & print FCM token
    final messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);
    final fcmToken = await messaging.getToken();
    debugPrint('FCM Token: $fcmToken');

    // Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint(
        '🔥 NOTIFICATION RECEIVED IN APP: ${message.notification?.title}',
      );
      debugPrint('Data payload: ${message.data}');

      final currentContext = navigatorKey.currentContext;
      if (currentContext != null) {
        final title = message.notification?.title ?? 'إشعار جديد';
        final body = message.notification?.body ?? 'لديك رسالة جديدة';
        final isSuccess = title.contains('نجاح') || title.contains('تم');

        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(body),
              ],
            ),
            backgroundColor: isSuccess ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    await Supabase.initialize(
      url: 'https://miewslafvehxtflrrexm.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pZXdzbGFmdmVoeHRmbHJyZXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0NzQxMzIsImV4cCI6MjA4ODA1MDEzMn0.qMEyQOny1ERGpX3rVbe1Zyr5RYDsf7G3PHPwTZEF7FY',
    );

    if (fcmToken != null) {
      await saveTokenToSupabase(fcmToken);
    }

    // Listen to Supabase Auth state changes to save token when logging in
    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final AuthChangeEvent event = data.event;
      if (event == AuthChangeEvent.signedIn) {
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await saveTokenToSupabase(token);
        }
      }
    });

    runApp(const MyApp());
  } catch (e, stackTrace) {
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Center(
              child: Text(
                'Error Details:\n$e\n\nStack:\n$stackTrace',
                style: const TextStyle(color: Colors.red, fontSize: 14),
                textDirection: TextDirection.ltr,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => CartCubit()),
        BlocProvider(create: (context) => FavoriteCubit()),
        BlocProvider(create: (context) => DeliveryLocationCubit()),
        BlocProvider(create: (context) => NotificationCubit()),
      ],
      child: MaterialApp(
        navigatorKey: navigatorKey,
        title: 'Pizza Lamia',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
