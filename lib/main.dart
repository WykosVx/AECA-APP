import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart'; 
import 'screens/home_screen.dart'; 
import 'screens/cedula_screen.dart'; 
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'notification_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Removemos el llamado directo de aquí para evitar el fallo silencioso
  } catch (e) {
    debugPrint("Error al inicializar Firebase: $e");
  }

  final prefs = await SharedPreferences.getInstance();
  final String? savedTheme = prefs.getString('themeMode');
  themeNotifier.value = savedTheme == 'light' 
      ? ThemeMode.light 
      : (savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.system);
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        final notificationService = NotificationService();
        await notificationService.inicializar();
      } catch (e) {
        debugPrint("Error al inicializar el servicio de notificaciones: $e");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, ThemeMode currentMode, __) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'AECA APP',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
          ),
          themeMode: currentMode,
          home: const AuthWrapper(), 
        );
      },
    );
  }
}

// 1. LÓGICA DE SESIÓN (AuthWrapper)
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData) return const LoginPage();
        
        return const DataValidatorWrapper();
      },
    );
  }
}

class DataValidatorWrapper extends StatefulWidget {
  const DataValidatorWrapper({super.key});
  @override
  State<DataValidatorWrapper> createState() => _DataValidatorWrapperState();
}

class _DataValidatorWrapperState extends State<DataValidatorWrapper> {
  bool _verificando = true;
  bool _registrado = false;

  @override
  void initState() {
    super.initState();
    _checkData();
  }

  Future<void> _checkData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      _registrado = prefs.containsKey('user_cedula') && prefs.containsKey('user_nombre_completo');
      _verificando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    if (!_registrado) return CedulaScreen(onComplete: _checkData);
    
    return const HomeScreen();
  }
}

// 3. LOGIN PAGE
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  Future<void> _signInWithGoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Lottie.asset(
              'assets/animations/notch-animation.json', 
              repeat: true,
              fit: BoxFit.fitWidth,
            ),
          ),
          
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                Image.asset(
                  'assets/logo_fondo.png', 
                  height: 120,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 50),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 260,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white.withOpacity(0.2)
                              : Colors.black.withOpacity(0.1),
                          width: 1.5,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: Theme.of(context).brightness == Brightness.dark
                              ? [
                                  Colors.white.withOpacity(0.12),
                                  Colors.white.withOpacity(0.03),
                                ]
                              : [
                                  Colors.black.withOpacity(0.05),
                                  Colors.black.withOpacity(0.01),
                                ],
                        ),
                      ),
                      child: InkWell(
                        onTap: () => _signInWithGoogle(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset(
                              'assets/google_logo.png',
                              height: 20,
                              width: 20,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Continuar con Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).brightness == Brightness.dark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Lottie.asset(
                    'assets/animations/people-animation.json', 
                    repeat: true,
                    fit: BoxFit.contain, 
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
