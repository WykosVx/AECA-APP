import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:screenshot/screenshot.dart';
import 'package:path_provider/path_provider.dart';

class ConstanciaPreviewScreen extends StatelessWidget {
  final String nombreJornada;
  final String fechaJornada;
  final ScreenshotController _screenshotController = ScreenshotController();

  ConstanciaPreviewScreen({super.key, required this.nombreJornada, required this.fechaJornada});

  Future<Map<String, String>> _getData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nombre': prefs.getString('user_nombre_completo') ?? "USUARIO",
      'cedula': prefs.getString('user_cedula') ?? "0000000"
    };
  }

  Future<void> _shareConstancia() async {
    final image = await _screenshotController.capture(pixelRatio: 2.0);
    if (image != null) {
      final dir = await getTemporaryDirectory();
      final file = await File('${dir.path}/constancia.png').create();
      await file.writeAsBytes(image);
      await Share.shareXFiles([XFile(file.path)], text: "Mi constancia de asistencia.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Doble toque para compartir")),
      body: FutureBuilder<Map<String, String>>(
        future: _getData(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!;
          double h = 700;

          return Center(
            child: SingleChildScrollView(
              child: GestureDetector(
                onDoubleTap: _shareConstancia, 
                child: Screenshot(
                  controller: _screenshotController,
                  child: SizedBox(
                    width: 500,
                    height: h,
                    child: Stack(
                      children: [
                       Positioned.fill(
                       child: Image.asset(
                       'assets/constancia_plantilla.png', 
                        fit: BoxFit.contain, 
                      ),
                     ),
                        // NOMBRE
                        Positioned(
                          top: h * 0.45, left: 120, 
                          child: Text(data['nombre']!.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 6)),
                        ),
                        // CÉDULA
                        Positioned(
                          top: h * 0.45, left: 305,
                          child: Text(data['cedula']!, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 7)),
                        ),
                        // FECHA
                        Positioned(
                          top: h * 0.48, left: 115,
                          child: Text(fechaJornada, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 7)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}