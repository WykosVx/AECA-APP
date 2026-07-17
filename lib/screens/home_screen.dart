import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';
import 'constancia_screen.dart';
import 'generador_qr_screen.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart'; 

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cerrar sesión?"),
        content: const Text("¿Estás seguro de que quieres salir de AECA APP?"),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear(); 
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  
  void _abrirEscanner(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: MobileScanner(
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            for (final barcode in barcodes) {
              if (barcode.rawValue != null) {
                Navigator.pop(context);
                _registrarAsistencia(barcode.rawValue!);
                break;
              }
            }
          },
        ),
      ),
    );
  }

  void _mostrarExitoAsistencia(BuildContext context) {
    try {
      final AudioPlayer player = AudioPlayer();
      player.play(AssetSource('sounds/success.mp3')); 
    } catch (e) {
      debugPrint("Error al reproducir sonido: $e");
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 3), () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
        });

        final bool isDark = Theme.of(context).brightness == Brightness.dark;

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.8) : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.05),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Tu animación de Lottie de Check de éxito
                    SizedBox(
                      height: 150,
                      child: Lottie.asset(
                        'assets/animations/Successful Check.json',
                        repeat: false,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text(
                      "Ya marcaste la asistencia de hoy",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _registrarAsistencia(String rawData) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final parts = rawData.split('|');
    if (parts.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR no válido"), backgroundColor: Colors.red));
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String nombreManual = prefs.getString('user_nombre_completo') ?? "Socio";
    final String cedulaManual = prefs.getString('user_cedula') ?? "Sin cédula";
    final jornadaId = parts[0];
    final int timestamp = int.tryParse(parts[1]) ?? 0;

    if (DateTime.now().millisecondsSinceEpoch - timestamp > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("QR expirado, intente de nuevo"), backgroundColor: Colors.red));
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_jornada_id', jornadaId);

      await FirebaseFirestore.instance.collection('Asistencias').add({
      'usuario': nombreManual, 
      'cedula': cedulaManual,  
      'email': user.email,
      'jornada': jornadaId,
      'fecha': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      _mostrarExitoAsistencia(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red));
    }
  }

  // --- 3. DISEÑO (UI) ---
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    List<String> admins = ["wilmaferreira22@gmail.com", "bosterwilliam23@gmail.com", "juansram@gmail.com"];
    bool esAdmin = admins.contains(user?.email);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Bienvenido,", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                      Text(user?.displayName ?? "Socio AECA",
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      Row(
                        children: [
                          Text(esAdmin ? "Administrador" : "Socio", style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 10),
                          GestureDetector(
                            onTap: () => _mostrarPanelTema(context),
                            child: const Icon(Icons.lightbulb_circle, color: Colors.amber, size: 28),
                          ),
                        ],
                      ),
                    ],
                  ),
                  PopupMenuButton<String>(
                    offset: const Offset(0, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    onSelected: (value) {
                      if (value == 'logout') _confirmarCerrarSesion(context);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'logout',
                        child: Row(
                          children: [
                            Icon(Icons.logout, color: Colors.red, size: 20),
                            SizedBox(width: 10),
                            Text("Cerrar Sesión", style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.amber,
                          backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                          child: user?.photoURL == null ? const Icon(Icons.person, color: Colors.white) : null,
                        ),
                        IgnorePointer(
                          child: SizedBox(
                            width: 100, 
                            height: 100,
                            child: Lottie.asset(
                              'assets/animations/circle-avataranimation.json',
                              repeat: true,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250, 
              child: Lottie.asset(
                'assets/animations/qr-animation.json', 
                repeat: true,
                animate: true,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Toca abajo para escanear", 
              style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)
            ),
            const Spacer(), 
          ],
        ),
      ),
      
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min, 
        children: [
          if (esAdmin)
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 10.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    width: double.infinity,
                    height: 55,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: Colors.redAccent.withOpacity(0.35),
                        width: 1.5,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.redAccent.withOpacity(0.20),
                          Colors.redAccent.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: InkWell(
                      onTap: () => Navigator.push(
                        context, 
                        MaterialPageRoute(builder: (_) => const GeneradorQrScreen())
                      ),
                      borderRadius: BorderRadius.circular(25),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.qr_code_2, color: Colors.white),
                          SizedBox(width: 10),
                          Text(
                            "GENERAR QR JORNADA",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            selectedItemColor: Colors.amber,
            unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
            onTap: (index) {
              setState(() => _selectedIndex = index);
              if (index == 0) Navigator.push(context, MaterialPageRoute(builder: (c) => const HistorialPage()));
              if (index == 1) _abrirEscanner(context);
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Historial'),
              BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner, size: 35), label: 'Escanear'),
              BottomNavigationBarItem(icon: Icon(Icons.campaign), label: 'Noticias'),
            ],
          ),
        ],
      ),
    );
  }

  void _mostrarPanelTema(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Configuración de Tema", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.wb_sunny, color: Colors.orange),
              title: const Text("Modo Claro"),
              onTap: () => _actualizarTema(ThemeMode.light),
            ),
            ListTile(
              leading: const Icon(Icons.dark_mode, color: Colors.blueGrey),
              title: const Text("Modo Oscuro"),
              onTap: () => _actualizarTema(ThemeMode.dark),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _actualizarTema(ThemeMode modo) async {
    themeNotifier.value = modo;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeMode', modo == ThemeMode.light ? 'light' : 'dark');
    if (mounted) Navigator.pop(context);
  }
}

class HistorialPage extends StatelessWidget {
  const HistorialPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mi Historial"),
        backgroundColor: isDark ? Colors.black : Colors.amber,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('Asistencias')
            .where('email', isEqualTo: user?.email)
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          var docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("No tienes asistencias."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              DateTime fecha = data['fecha'] != null ? (data['fecha'] as Timestamp).toDate() : DateTime.now();
              String nombreJornada = data['jornada'] ?? "Jornada";
              String fechaStr = DateFormat('dd/MM/yyyy').format(fecha);

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                color: isDark ? Colors.grey[900] : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(nombreJornada),
                  subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(fecha)),
                  trailing: IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: Colors.amber),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ConstanciaPreviewScreen(
                            nombreJornada: nombreJornada,
                            fechaJornada: fechaStr,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
