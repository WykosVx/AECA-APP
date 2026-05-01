import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importante para guardar el tema
import 'firebase_options.dart'; 
import 'screens/home_screen.dart'; 
import 'screens/login_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
// Notificador global (Empieza en dark por defecto)
final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.dark);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 1. Inicializar Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 5));
    print("Firebase cargó bien");
  } catch (e) {
    print("Error de Firebase: $e");
  }

  // 2. CARGAR EL TEMA GUARDADO
  final prefs = await SharedPreferences.getInstance();
  final String? savedTheme = prefs.getString('themeMode');
  
  if (savedTheme == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (savedTheme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }
  
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
          
          // Tema Claro
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: Colors.white,
            appBarTheme: const AppBarTheme(backgroundColor: Colors.amber, foregroundColor: Colors.black),
          ),

          // Tema Oscuro
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.amber,
            scaffoldBackgroundColor: Colors.black,
            appBarTheme: AppBarTheme(backgroundColor: Colors.grey[900]),
          ),

          themeMode: currentMode,

          // 3. Lógica de inicio de sesión persistente
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(body: Center(child: CircularProgressIndicator()));
              }
              // Si tiene datos, va al Home, si no, al Login
              return snapshot.hasData ? const HomeScreen() : const LoginPage();
            },
          ),
        );
      },
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late Image logoAeca;
  late Image logoGoogle;

  @override
  void initState() {
    super.initState();
    // Cargamos las imágenes con gaplessPlayback activado
    logoAeca = Image.asset(
      'assets/logo_aeca.png', 
      height: 120, 
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
    logoGoogle = Image.asset(
      'assets/google_logo.png', 
      height: 22, 
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Forzamos la precarga en el cache de la GPU
    precacheImage(logoAeca.image, context);
    precacheImage(logoGoogle.image, context);
  }

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
Widget build(BuildContext context) {
  // Detectamos si el modo actual es oscuro para ajustar los colores de texto y botones
  final bool isDark = Theme.of(context).brightness == Brightness.dark;

  return Scaffold(
    // El fondo ahora cambia automáticamente según el tema
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RepaintBoundary(child: logoAeca), 
            
            const SizedBox(height: 20),
            Text(
              "AECA APP", 
              style: TextStyle(
                fontSize: 32, 
                fontWeight: FontWeight.bold, 
                // Si está en modo claro, el texto debe ser negro para que se vea
                color: isDark ? Colors.white : Colors.black, 
                letterSpacing: 1.2
              )
            ),
            Text(
              "Control de Acceso", 
              style: TextStyle(
                fontSize: 14, 
                color: isDark ? Colors.white54 : Colors.black54
              )
            ),
            
            const SizedBox(height: 50),

            ElevatedButton(
              style: ElevatedButton.styleFrom(
                // Ajustamos el botón de Google para que se vea bien en ambos fondos
                backgroundColor: isDark ? const Color(0xFF131314) : Colors.grey[200],
                foregroundColor: isDark ? Colors.white : Colors.black87,
                minimumSize: const Size(double.infinity, 54),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                side: BorderSide(
                  color: isDark ? const Color(0xFF444746) : Colors.grey[400]!
                ),
                elevation: 0,
              ),
              onPressed: () => _signInWithGoogle(context),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 22,
                    height: 22,
                    child: RepaintBoundary(child: logoGoogle),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Continuar con Google',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}