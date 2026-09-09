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
  String? _idJornada;
  Timer? _timerSegundo;

  // Tiempo total de validez en segundos
  static const int _duracionTotal = 10;
  int _segundosRestantes = _duracionTotal;

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

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        _idJornada = snapshot.docs.first.id;
        _generarNuevoQr();

        // Timer que descuenta segundo a segundo de forma exacta
        _timerSegundo = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) return;

          setState(() {
            if (_segundosRestantes > 1) {
              _segundosRestantes--;
            } else {
              // Llega a cero -> Genera nuevo QR y reinicia contador a 10
              _segundosRestantes = _duracionTotal;
              _generarNuevoQr();
            }
          });
        });
      } else {
        setState(() {
          _cargando = false;
          _qrData = "ERROR: No hay jornadas activas";
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
      _qrData = "$_idJornada|$timestamp";
    });
  }

  @override
  void dispose() {
    _timerSegundo?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Progreso exacto de 1.0 (lleno) a 0.0 (vacío)
    final double progreso = _segundosRestantes / _duracionTotal;

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

                        // Contenedor del código QR
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

                        // Barra de progreso y contador sincronizado
                        SizedBox(
                          width: 260,
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: TweenAnimationBuilder<double>(
                                  duration: const Duration(milliseconds: 900),
                                  curve: Curves.linear,
                                  tween: Tween<double>(
                                    begin: progreso,
                                    end: progreso,
                                  ),
                                  builder: (context, value, _) => LinearProgressIndicator(
                                    value: value,
                                    backgroundColor: Colors.grey.shade200,
                                    color: value > 0.3 ? Colors.amber.shade700 : Colors.red,
                                    minHeight: 8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "El código se actualiza en $_segundosRestantes s",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _segundosRestantes <= 3 ? Colors.red : Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
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