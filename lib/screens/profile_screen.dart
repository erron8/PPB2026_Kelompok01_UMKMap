import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(radius: 36, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 16),
          Text(
            user?.fullName ?? 'Pengguna',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(user?.email ?? '-', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Role'),
            subtitle: Text(user?.role ?? 'tamu'),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: auth.isLoading
                ? null
                : () async {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) context.go('/login');
                  },
            icon: const Icon(Icons.logout),
            label: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
