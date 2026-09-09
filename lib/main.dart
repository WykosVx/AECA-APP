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

    if (!mounted) return;
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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _iniciandoSesion = false;

  Future<void> _signInWithGoogle(BuildContext context) async {
    if (_iniciandoSesion) return; // Evita clics repetidos

    setState(() => _iniciandoSesion = true);

    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    try {
      // 1. Limpieza preventiva por si quedó una sesión corrupta en ese dispositivo
      await googleSignIn.signOut();

      // 2. Abrir selector de cuenta
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // El usuario canceló o cerró la ventana de Google
        if (mounted) setState(() => _iniciandoSesion = false);
        return;
      }

      // 3. Obtener credenciales de autenticación
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 4. Verificación anti "null, null": Comprobar si ambos tokens vinieron vacíos
      if (googleAuth.idToken == null && googleAuth.accessToken == null) {
        throw FirebaseAuthException(
          code: 'TOKEN_NULL',
          message: 'No se pudo obtener el token de acceso de Google. Revisa la conexión o actualiza Google Play Services.',
        );
      }

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 5. Autenticar en Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

    } on FirebaseAuthException catch (e) {
      debugPrint("Firebase Auth Error: ${e.code} - ${e.message}");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.code == 'account-exists-with-different-credential'
                  ? 'Esta cuenta ya está registrada con otro método.'
                  : (e.message ?? 'Error al iniciar sesión con Google.'),
            ),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } catch (e) {
      debugPrint("Error general Google Sign-In: $e");
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al conectar con Google: ${e.toString()}"),
            backgroundColor: Colors.red.shade800,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _iniciandoSesion = false);
      }
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
                
                // Botón con efecto Glassmorphism
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
                        onTap: _iniciandoSesion ? null : () => _signInWithGoogle(context),
                        borderRadius: BorderRadius.circular(12),
                        child: _iniciandoSesion
                            ? const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                ),
                              )
                            : Row(
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