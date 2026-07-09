import 'package:flutter/material.dart';

class UmkmDetailScreen extends StatelessWidget {
  const UmkmDetailScreen({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail UMKM')),
      body: Center(child: Text('Detail UMKM: $id')),
    );
  }
}
