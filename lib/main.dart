import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/cubit/delivery_location_cubit.dart';
import 'presentation/splash/splash_screen.dart';
import 'presentation/cart/cubit/cart_cubit.dart';
import 'presentation/home/favorite/cubit/favorite_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: 'https://miewslafvehxtflrrexm.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1pZXdzbGFmdmVoeHRmbHJyZXhtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0NzQxMzIsImV4cCI6MjA4ODA1MDEzMn0.qMEyQOny1ERGpX3rVbe1Zyr5RYDsf7G3PHPwTZEF7FY',
    );

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
      ],
      child: MaterialApp(
        title: 'Pizza Lamia',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
