import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeneradorQrScreen extends StatefulWidget {
  const GeneradorQrScreen({super.key});

  @override
  State<GeneradorQrScreen> createState() => _GeneradorQrScreenState();
}

class _GeneradorQrScreenState extends State<GeneradorQrScreen> {
  String _qrData = "";
  bool _cargando = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _iniciarGenerador();
  }

  void _iniciarGenerador() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Jornadas')
          .where('activa', isEqualTo: true)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        String idJornada = snapshot.docs.first.id;
        
        if (mounted) {
          setState(() {
            _qrData = "$idJornada|${DateTime.now().millisecondsSinceEpoch}";
            _cargando = false;
          });
        }

        _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
          if (!mounted) return;
          setState(() {
            _qrData = "$idJornada|${DateTime.now().millisecondsSinceEpoch}";
          });
        });
      } else {
        if (mounted) {
          setState(() {
            _cargando = false;
            _qrData = "ERROR: No hay jornadas activas";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargando = false;
          _qrData = "ERROR: ${e.toString()}";
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Generar QR de Asistencia")),
      body: Center(
        child: _cargando 
          ? const CircularProgressIndicator() 
          : _qrData.contains("ERROR") 
            ? Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(_qrData, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RepaintBoundary(
                    child: QrImageView(
                      key: ValueKey(_qrData), // Fuerza redibujado cada 5s
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 300.0,
                      backgroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text("El código cambia cada 5s"),
                  const SizedBox(height: 10),
                  Text(_qrData, style: const TextStyle(fontSize: 8, color: Colors.grey)),
                ],
              ),
      ),
    );
  }
}