import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MisAsistencias extends StatelessWidget {
  const MisAsistencias({super.key});

  @override
  Widget build(BuildContext context) {
    final String? userEmail = FirebaseAuth.instance.currentUser?.email;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("MIS ASISTENCIAS"),
        backgroundColor: Colors.amber,
        foregroundColor: Colors.black,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
       
        stream: FirebaseFirestore.instance
            .collection('Asistencias')
            .where('email', isEqualTo: userEmail) 
            .orderBy('fecha', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text("Error: ${snapshot.error}", 
              style: const TextStyle(color: Colors.red)),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.amber));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("No tienes asistencias registradas.", 
              style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

              return Card(
                color: Colors.grey[900],
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: const Icon(Icons.verified, color: Colors.amber),
                 
                  title: Text(
                    data['reunion'] ?? "Reunión AECA",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  
                  subtitle: Text(
                    "Fecha: ${data['fecha']}",
                    style: const TextStyle(color: Colors.amberAccent),
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