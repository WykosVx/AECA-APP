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

  // Dimensiones fijas virtuales del diseño original (Coordenadas exactas)
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
      // Captura con pixelRatio 3.0 para que salga nítida en alta calidad
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
                  // Widget interactivo
                  GestureDetector(
                    onDoubleTap: _shareConstancia,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 15,
                            spreadRadius: 2,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      // FittedBox adapta el lienzo de 500x700 a cualquier pantalla
                      child: FittedBox(
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                        child: Screenshot(
                          controller: _screenshotController,
                          // MediaQuery ignora el tamaño de fuente configurado en el celular
                          child: MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                              textScaler: TextScaler.noScaling,
                            ),
                            child: SizedBox(
                              width: _canvasWidth,
                              height: _canvasHeight,
                              child: Stack(
                                children: [
                                  // Fondo de la plantilla que llena exactamente los 500x700
                                  Positioned.fill(
                                    child: Image.asset(
                                      'assets/constancia_plantilla.png',
                                      fit: BoxFit.fill,
                                      width: _canvasWidth,
                                      height: _canvasHeight,
                                    ),
                                  ),

                                  // NOMBRE (Con ancho máximo para que no desborde si es largo)
                                  Positioned(
                                    top: _canvasHeight * 0.45,
                                    left: 120,
                                    child: SizedBox(
                                      width: 175,
                                      child: Text(
                                        data['nombre']!.toUpperCase(),
                                        textAlign: TextAlign.left,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 6.5,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // CÉDULA
                                  Positioned(
                                    top: _canvasHeight * 0.45,
                                    left: 305,
                                    child: Text(
                                      data['cedula']!,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 7.0,
                                      ),
                                    ),
                                  ),

                                  // FECHA
                                  Positioned(
                                    top: _canvasHeight * 0.48,
                                    left: 115,
                                    child: Text(
                                      widget.fechaJornada,
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 7.0,
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