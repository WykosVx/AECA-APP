import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';

class CedulaScreen extends StatefulWidget {
  final VoidCallback onComplete;
  const CedulaScreen({super.key, required this.onComplete});

  @override
  State<CedulaScreen> createState() => _CedulaScreenState();
}

class _CedulaScreenState extends State<CedulaScreen> {
  final _cedulaController = TextEditingController();
  final _nombreController = TextEditingController();
  bool _camposLlenos = false;

  @override
  void initState() {
    super.initState();
    _cedulaController.addListener(_validarInputs);
    _nombreController.addListener(_validarInputs);
  }

  void _validarInputs() {
    setState(() {
      _camposLlenos = _cedulaController.text.trim().isNotEmpty && 
                      _nombreController.text.trim().isNotEmpty;
    });
  }

  Future<void> _guardarDatos() async {
    // 1. Mostrar carga
    showDialog(
      context: context, 
      barrierDismissible: false, 
      builder: (_) => const Center(child: CircularProgressIndicator())
    );

    try {
      String cedula = _cedulaController.text.trim();
      String nombreIngresado = _nombreController.text.trim().toUpperCase();

      // 2. Consultar si la cédula existe en la colección 'Socios'
      DocumentSnapshot socioDoc = await FirebaseFirestore.instance
          .collection('Socios')
          .doc(cedula)
          .get();

      if (!socioDoc.exists) {
        Navigator.pop(context); // Quitar el indicador de carga
        _mostrarError("La cédula ingresada no se encuentra en el padrón.");
        return;
      }

      // 3. Validar coincidencia de nombre
      String nombreEnBD = (socioDoc.data() as Map<String, dynamic>)['nombre'];
      if (nombreEnBD.trim().toUpperCase() != nombreIngresado) {
        Navigator.pop(context);
        _mostrarError("El nombre no coincide con los registros del padrón.");
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      await FirebaseFirestore.instance.collection('UsuariosVinculados').doc(user?.email).set({
        'email': user?.email,
        'cedula': cedula,
        'nombre': nombreEnBD,
        'fechaVinculacion': FieldValue.serverTimestamp(),
      });

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_cedula', cedula);
      await prefs.setString('user_nombre_completo', nombreEnBD);
      await prefs.setBool('datos_completados', true);
      
      Navigator.pop(context); // Quitar el indicador de carga
      widget.onComplete();    // Redirigir al Home
      
    } catch (e) {
      Navigator.pop(context);
      _mostrarError("Error al validar: $e");
    }
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Registro de Datos")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              SizedBox(
                height: 200, 
                child: Lottie.asset(
                  'assets/animations/cedula-screen-animation.json', 
                  repeat: true,
                ),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),
              const Text("Validación de Identidad", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _nombreController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: "Nombre y Apellido", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _cedulaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Número de Cédula", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: _camposLlenos ? Colors.amber : Colors.grey),
                  onPressed: _camposLlenos ? _guardarDatos : null, 
                  child: const Text("GUARDAR Y VALIDAR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}