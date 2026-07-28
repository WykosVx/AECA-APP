import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http; 

class NoticiasPage extends StatefulWidget {
  const NoticiasPage({super.key});

  @override
  State<NoticiasPage> createState() => _NoticiasPageState();
}

class _NoticiasPageState extends State<NoticiasPage> {
  final PageController _pageController = PageController(viewportFraction: 0.88);

  // Consulta el clima en tiempo real usando las coordenadas de Caacupé
  Future<Map<String, dynamic>> _obtenerClimaCaacupe() async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=-25.3857&longitude=-57.1422&current_weather=true'
    );
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['current_weather'];
    } else {
      throw Exception('No se pudo cargar el clima');
    }
  }

  // Abre una ventana flotante estilo vidrio para leer avisos/jornadas muy largas
  void _mostrarDetalleAviso({
    required BuildContext context,
    required String titulo,
    required String contenido,
    required String fecha,
    required String tipo,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Colors.black.withOpacity(0.85) : Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: tipo == "AVISO" ? Colors.blueAccent.withOpacity(0.15) : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            tipo,
                            style: TextStyle(
                              color: tipo == "AVISO" ? Colors.blueAccent : Colors.green,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (fecha.isNotEmpty)
                          Text(
                            fecha,
                            style: const TextStyle(color: Colors.grey, fontSize: 11),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      titulo,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.4, 
                      ),
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          contenido,
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white70 : Colors.black54,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "CERRAR",
                          style: TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
                        ),
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

  Map<String, dynamic> _interpretarClima(int code) {
    if (code == 0) {
      return {'desc': 'Despejado', 'icon': Icons.wb_sunny_rounded, 'color': Colors.orangeAccent};
    } else if (code >= 1 && code <= 3) {
      return {'desc': 'Parcialmente Nublado', 'icon': Icons.wb_cloudy_rounded, 'color': Colors.blueGrey};
    } else if (code == 45 || code == 48) {
      return {'desc': 'Niebla', 'icon': Icons.blur_on_rounded, 'color': Colors.grey};
    } else if (code >= 51 && code <= 55) {
      return {'desc': 'Llovizna', 'icon': Icons.grain_rounded, 'color': Colors.lightBlue};
    } else if (code >= 61 && code <= 65) {
      return {'desc': 'Lluvia', 'icon': Icons.umbrella_rounded, 'color': Colors.blue};
    } else if (code >= 71 && code <= 75) {
      return {'desc': 'Nieve', 'icon': Icons.ac_unit_rounded, 'color': Colors.lightBlueAccent};
    } else if (code >= 95 && code <= 99) {
      return {'desc': 'Tormenta Eléctrica', 'icon': Icons.thunderstorm_rounded, 'color': Colors.purpleAccent};
    }
    return {'desc': 'General', 'icon': Icons.cloud_queue_rounded, 'color': Colors.grey};
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color backgroundColor = isDark ? Colors.black : const Color(0xFFF3F4F6);

    final Color glassBgColor = isDark 
        ? Colors.white.withOpacity(0.07) 
        : Colors.black.withOpacity(0.03);

    final Color glassBorderColor = isDark 
        ? Colors.white.withOpacity(0.18) 
        : Colors.black.withOpacity(0.08);

    final Color titleColor = isDark ? Colors.white : Colors.black87;
    final Color bodyColor = isDark ? Colors.white70 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text("Noticias y Comunicados"),
        backgroundColor: isDark ? Colors.black : Colors.amber,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // ==========================================
            // 1. SECCIÓN: CARRUSEL DE AVISOS GENERALES (COLECCIÓN 'AVISOS')
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Avisos de la Asociación",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Avisos') 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 180,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                var avisos = snapshot.data?.docs ?? [];

                if (avisos.isEmpty) {
                  return _tarjetaVaciaInfo(isDark, "No hay avisos generales vigentes.");
                }

                return SizedBox(
                  height: 180,
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: avisos.length,
                    itemBuilder: (context, index) {
                      var data = avisos[index].data() as Map<String, dynamic>;
                      String t = data['Titulo'] ?? "Aviso"; 
                      String desc = data['Asunto'] ?? ""; 
                      
                      Timestamp? fTimestamp = data['Fecha'] as Timestamp?;
                      String fStr = fTimestamp != null ? DateFormat('dd/MM').format(fTimestamp.toDate()) : "";

                      return Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(25),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: glassBgColor,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(color: glassBorderColor, width: 1.2),
                              ),
                              child: InkWell(
                                onTap: () => _mostrarDetalleAviso(
                                  context: context,
                                  titulo: t,
                                  contenido: desc,
                                  fecha: fStr,
                                  tipo: "AVISO",
                                ),
                                borderRadius: BorderRadius.circular(25),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          "AVISO",
                                          style: TextStyle(
                                            color: Colors.blueAccent, 
                                            fontSize: 11, 
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 0.5
                                          ),
                                        ),
                                        if (fStr.isNotEmpty) Text(fStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      t,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                                    ),
                                    const SizedBox(height: 6),
                                    Expanded(
                                      child: Text(
                                        desc,
                                        maxLines: 4,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 13, color: bodyColor, height: 1.3),
                                      ),
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
              },
            ),

            const SizedBox(height: 30),

            // ==========================================
            // 2. SECCIÓN: PRÓXIMAS JORNADAS (COLECCIÓN 'JORNADAS')
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Próximas Jornadas",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ),
            const SizedBox(height: 12),
            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('Jornadas') 
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var docs = snapshot.data?.docs ?? [];
                DateTime ahora = DateTime.now();

                // Filtramos localmente para quedarnos solo con las futuras y activas
                var proximas = docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  var fechaVal = data['Fecha'];
                  bool activa = data['activa'] ?? false; 

                  if (fechaVal == null || fechaVal is! Timestamp || !activa) return false;

                  DateTime fechaJornada = (fechaVal as Timestamp).toDate();
                  return fechaJornada.isAfter(ahora);
                }).toList();

                proximas.sort((a, b) {
                  Timestamp tA = (a.data() as Map<String, dynamic>)['Fecha'] as Timestamp;
                  Timestamp tB = (b.data() as Map<String, dynamic>)['Fecha'] as Timestamp;
                  return tA.compareTo(tB);
                });

                if (proximas.isEmpty) {
                  return _tarjetaVaciaInfo(isDark, "No hay jornadas planificadas por el momento.");
                }

                return ListView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: proximas.length,
                  itemBuilder: (context, index) {
                    var data = proximas[index].data() as Map<String, dynamic>;
                    String t = data['Titulo'] ?? "Jornada";
                    Timestamp timestamp = data['Fecha'] as Timestamp;
                    DateTime f = timestamp.toDate();
                    String fStr = DateFormat('dd/MM/yyyy - HH:mm').format(f);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14.0),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: glassBgColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.3), 
                                width: 1.2
                              ),
                            ),
                            child: InkWell(
                              // Pulsar la tarjeta de jornada para ver sus detalles completos
                              onTap: () => _mostrarDetalleAviso(
                                context: context,
                                titulo: t,
                                contenido: "Esta jornada se encuentra programada y activa en el sistema de AECA. Organiza tus tiempos y recuerda asistir puntualmente.",
                                fecha: fStr,
                                tipo: "JORNADA",
                              ),
                              borderRadius: BorderRadius.circular(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                        child: const Text(
                                          "JORNADA",
                                          style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      const Icon(Icons.event_available, color: Colors.green, size: 18),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    t,
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.access_time_rounded, color: Colors.grey, size: 14),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          fStr, 
                                          style: const TextStyle(fontSize: 13, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 30),

            // ==========================================
            // 3. SECCIÓN: EL CLIMA EN CAACUPÉ
            // ==========================================
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "Estado del Tiempo",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: titleColor),
              ),
            ),
            const SizedBox(height: 12),
            
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 30.0),
              child: FutureBuilder<Map<String, dynamic>>(
                future: _obtenerClimaCaacupe(),
                builder: (context, weatherSnapshot) {
                  if (weatherSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  
                  if (weatherSnapshot.hasError || !weatherSnapshot.hasData) {
                    return _tarjetaVaciaInfo(isDark, "No se pudo actualizar el clima.");
                  }

                  final weather = weatherSnapshot.data!;
                  double temp = (weather['temperature'] as num?)?.toDouble() ?? 0.0;
                  int weatherCode = weather['weathercode'] ?? 0;

                  final weatherInfo = _interpretarClima(weatherCode);

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: glassBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: glassBorderColor, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              weatherInfo['icon'],
                              size: 55,
                              color: weatherInfo['color'],
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Caacupé, Cordillera",
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: titleColor),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    weatherInfo['desc'],
                                    style: TextStyle(fontSize: 13, color: bodyColor),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "${temp.toStringAsFixed(1)}°C",
                              style: TextStyle(
                                  fontSize: 26, 
                                  fontWeight: FontWeight.bold, 
                                  color: titleColor
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaVaciaInfo(bool isDark, String mensaje) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
            width: 1.0
          ),
        ),
        child: Center(
          child: Text(
            mensaje,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
