import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart'; 
import 'screens/home_screen.dart'; 
import 'screens/cedula_screen.dart'; 
import 'package:lottie/lottie.dart';

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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        
        // Si hay usuario, vamos a verificar si ya vinculó su cédula
        return const DataValidatorWrapper();
      },
    );
  }
}

// 2. Sub-wrapper para verificar datos guardados
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
    // Verificamos si existen los datos de la cédula y nombre
    setState(() {
      _registrado = prefs.containsKey('user_cedula') && prefs.containsKey('user_nombre_completo');
      _verificando = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_verificando) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    // Si no está registrado, enviamos a CedulaScreen y pasamos la función para re-verificar al completar
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
      body: Center(
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
            SizedBox(
              width: 260, 
              height: 50, 
              child: ElevatedButton(
                onPressed: () => _signInWithGoogle(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
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
                    const Text(
                      'Continuar con Google',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                     ),
                    ),
                  ],
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
    );
  }
}