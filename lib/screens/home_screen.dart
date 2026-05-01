import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 1;

  @override
  void initState() {
    super.initState();
    _verificarAcceso();
  }

  // --- 1. LÓGICA DE SEGURIDAD ---
  Future<void> _verificarAcceso() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios_autorizados')
        .doc(user.email)
        .get();

    if (!doc.exists) {
      if (!mounted) return;
      await FirebaseAuth.instance.signOut();
    }
  }

  // --- NUEVA FUNCIÓN: CERRAR SESIÓN ---
  void _confirmarCerrarSesion(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("¿Cerrar sesión?"),
        content: const Text("¿Estás seguro de que quieres salir de AECA APP?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await FirebaseAuth.instance.signOut();
            },
            child: const Text("CERRAR SESIÓN", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // --- 2. LÓGICA DEL ESCÁNER ---
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

  Future<void> _registrarAsistencia(String jornadaId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('Asistencias').add({
        'usuario': user.displayName ?? "Socio",
        'email': user.email,
        'jornada': jornadaId,
        'fecha': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ Asistencia registrada"), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e"), backgroundColor: Colors.red),
      );
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
                  // BOTÓN DE PERFIL CON MENÚ DE CIERRE DE SESIÓN
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
                    child: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.amber,
                      backgroundImage: user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
                      child: user?.photoURL == null 
                          ? const Icon(Icons.person, color: Colors.white) 
                          : null,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Icon(Icons.qr_code_scanner, size: 120, color: Colors.amber),
            const SizedBox(height: 20),
            Text("Toca abajo para escanear", style: TextStyle(color: isDark ? Colors.white38 : Colors.black38)),
            const Spacer(),
            if (esAdmin)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.qr_code_2),
                  label: const Text("GENERAR QR JORNADA"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
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
    );
  }

  // --- 4. TEMA ---
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

// --- 5. PÁGINA DE HISTORIAL ---
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
              DateTime fecha = data['fecha'] != null 
                  ? (data['fecha'] as Timestamp).toDate() 
                  : DateTime.now();
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                color: isDark ? Colors.grey[900] : Colors.white,
                child: ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(data['jornada'] ?? "Jornada"),
                  subtitle: Text(DateFormat('dd/MM/yyyy - HH:mm').format(fecha)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}