import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Profil',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Halo, ${user?.fullName ?? 'Pengguna'}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Chip(label: Text(user?.role ?? 'tamu')),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => context.go('/umkm'),
            icon: const Icon(Icons.list),
            label: const Text('Daftar UMKM'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/map'),
            icon: const Icon(Icons.map),
            label: const Text('Peta'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => context.go('/umkm-form'),
            icon: const Icon(Icons.add_business),
            label: const Text('Tambah UMKM'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person),
            label: const Text('Profil'),
          ),
        ],
      ),
    );
  }
}
