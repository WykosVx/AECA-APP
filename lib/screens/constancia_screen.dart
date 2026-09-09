import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class ConstanciaPreviewScreen extends StatefulWidget {
  final String nombreJornada;
  final String fechaJornada;

  const ConstanciaPreviewScreen({
    super.key,
    required this.nombreJornada,
    required this.fechaJornada,
  });

  @override
  State<ConstanciaPreviewScreen> createState() => _ConstanciaPreviewScreenState();
}

class _ConstanciaPreviewScreenState extends State<ConstanciaPreviewScreen> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _compartiendo = false;

  // Dimensiones fijas del lienzo
  static const double _canvasWidth = 500.0;
  static const double _canvasHeight = 700.0;

  Future<Map<String, String>> _getData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nombre': prefs.getString('user_nombre_completo') ?? "USUARIO",
      'cedula': prefs.getString('user_cedula') ?? "0000000"
    };
  }

  Future<void> _shareConstancia() async {
    if (_compartiendo) return;
    setState(() => _compartiendo = true);

    try {
      final image = await _screenshotController.capture(pixelRatio: 3.0);
      if (image != null) {
        final dir = await getTemporaryDirectory();
        final file = await File('${dir.path}/constancia.png').create();
        await file.writeAsBytes(image);
        await Share.shareXFiles(
          [XFile(file.path)],
          text: "Mi constancia de asistencia a ${widget.nombreJornada}.",
        );
      }
    } catch (e) {
      debugPrint("Error al compartir constancia: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al generar constancia: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _compartiendo = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Vista previa de Constancia"),
        actions: [
          IconButton(
            tooltip: "Compartir",
            icon: _compartiendo
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                  )
                : const Icon(Icons.share),
            onPressed: _compartiendo ? null : _shareConstancia,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, String>>(
        future: _getData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data!;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onDoubleTap: _shareConstancia,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: Screenshot(
                          controller: _screenshotController,
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.noScaling,
                            ),
                            child: Container(
                              color: Colors.white,
                              width: _canvasWidth,
                              height: _canvasHeight,
                              child: Stack(
                                children: [
                                  // Plantilla centrada
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/constancia_plantilla.png',
                                      fit: BoxFit.contain,
                                      alignment: Alignment.center,
                                    ),
                                  ),

                                // ==========================================
// 1. NOMBRE: Sobre los puntos de "el/la Prof."
// ==========================================
Positioned(
  top: _canvasHeight * 0.434,
  left: 151, // Desplazado para no tocar "Prof."
  child: SizedBox(
    width: 170,
    child: Text(
      data['nombre']!.toUpperCase(),
      textAlign: TextAlign.left,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 7,
      ),
    ),
  ),
),

// ==========================================
// 2. CÉDULA: Sobre los puntos de "con C.I. Nº"
// ==========================================
Positioned(
  top: _canvasHeight * 0.434,
  left: 384, // Desplazado para no tocar "Nº"
  child: Text(
    data['cedula']!,
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 7,
    ),
  ),
),

// ==========================================
// 3. FECHA: Espacio en blanco después de "fecha"
// ==========================================
Positioned(
  top: _canvasHeight * 0.471, // Nivelado al renglón de la fecha
  left: 142, // Separado de la palabra "fecha"
  child: Text(
    widget.fechaJornada,
    style: const TextStyle(
      color: Colors.black,
      fontWeight: FontWeight.bold,
      fontSize: 7,
    ), 

                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  const Text(
                    "Toca dos veces sobre la imagen o el botón de arriba para compartir.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}