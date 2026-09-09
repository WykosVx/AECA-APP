import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:qr_flutter/qr_flutter.dart';

class GeneradorQrScreen extends StatefulWidget {
  const GeneradorQrScreen({super.key});

  @override
  State<GeneradorQrScreen> createState() => _GeneradorQrScreenState();
}

class _GeneradorQrScreenState extends State<GeneradorQrScreen>
    with SingleTickerProviderStateMixin {
  String _qrData = "";
  bool _cargando = true;
  String? _idJornada;
  Timer? _timerRotacion;

  // Tiempo de validez/rotación del QR en segundos (10s o 15s es lo recomendado)
  static const int _duracionSegundos = 10;
  
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: _duracionSegundos),
    );
    _iniciarGenerador();
  }

  void _iniciarGenerador() async {
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('Jornadas')
          .where('activa', isEqualTo: true)
          .limit(1)
          .get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        _idJornada = snapshot.docs.first.id;
        _generarNuevoQr();

        // Reinicia la barra de progreso
        _animController.forward(from: 0.0);

        // Timer periódico que refresca el QR
        _timerRotacion = Timer.periodic(
          const Duration(seconds: _duracionSegundos),
          (timer) {
            if (!mounted) return;
            _generarNuevoQr();
            _animController.forward(from: 0.0);
          },
        );
      } else {
        setState(() {
          _cargando = false;
          _qrData = "ERROR: No hay jornadas activas en este momento.";
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _qrData = "ERROR: ${e.toString()}";
      });
    }
  }

  void _generarNuevoQr() {
    if (_idJornada == null) return;
    final int timestamp = DateTime.now().millisecondsSinceEpoch;
    setState(() {
      _cargando = false;
      // Formato: idJornada|timestamp
      _qrData = "$_idJornada|$timestamp";
    });
  }

  @override
  void dispose() {
    _timerRotacion?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Generar QR de Asistencia"),
        centerTitle: true,
      ),
      body: Center(
        child: _cargando
            ? const CircularProgressIndicator()
            : _qrData.startsWith("ERROR")
                ? Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 48),
                        const SizedBox(height: 12),
                        Text(
                          _qrData,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red, fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() => _cargando = true);
                            _iniciarGenerador();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("Reintentar"),
                        )
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Escanea para registrar asistencia",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 20),

                        // Contenedor del QR
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: RepaintBoundary(
                            child: QrImageView(
                              key: ValueKey(_qrData),
                              data: _qrData,
                              version: QrVersions.auto,
                              size: 260.0,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // Barra de tiempo restante visual
                        SizedBox(
                          width: 260,
                          child: AnimatedBuilder(
                            animation: _animController,
                            builder: (context, child) {
                              final restante = (_duracionSegundos * (1.0 - _animController.value)).ceil();
                              return Column(
                                children: [
                                  LinearProgressIndicator(
                                    value: 1.0 - _animController.value,
                                    backgroundColor: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 8,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "El código se actualiza en $restante s",
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 20),
                        Text(
                          _qrData,
                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
      ),
    );
  }
}