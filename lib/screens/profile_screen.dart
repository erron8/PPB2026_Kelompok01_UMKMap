import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/constants.dart';

class MockVoucher {
  final String title;
  final String subtitle;
  final int cost;
  final int minTier; // 1 = Bronze, 2 = Silver, 3 = Gold, 4 = Platinum, 5 = Super User
  final String tierName;

  const MockVoucher({
    required this.title,
    required this.subtitle,
    required this.cost,
    required this.minTier,
    required this.tierName,
  });
}

const _vouchers = [
  MockVoucher(
    title: 'Diskon 20% Kopi Senja',
    subtitle: 'Tukarkan dengan 100 Poin',
    cost: 100,
    minTier: 2,
    tierName: 'Silver',
  ),
  MockVoucher(
    title: 'Potongan Rp10.000 Hijab Store',
    subtitle: 'Tukarkan dengan 150 Poin',
    cost: 150,
    minTier: 2,
    tierName: 'Silver',
  ),
  MockVoucher(
    title: 'Diskon 30% Bengkel Lancar',
    subtitle: 'Tukarkan dengan 200 Poin',
    cost: 200,
    minTier: 3,
    tierName: 'Gold',
  ),
  MockVoucher(
    title: 'Gratis 1 Paket Kerajinan Bambu',
    subtitle: 'Tukarkan dengan 300 Poin',
    cost: 300,
    minTier: 4,
    tierName: 'Platinum',
  ),
  MockVoucher(
    title: 'Voucher Homestay Desa Wisata',
    subtitle: 'Tukarkan dengan 400 Poin',
    cost: 400,
    minTier: 4,
    tierName: 'Platinum',
  ),
];

class MockHistory {
  final String title;
  final String subtitle;
  final int points;
  final bool isPositive;

  const MockHistory({
    required this.title,
    required this.subtitle,
    required this.points,
    required this.isPositive,
  });
}

const _history = [
  MockHistory(
    title: 'Pendaftaran Warung Bakso',
    subtitle: 'UMKM berhasil diverifikasi',
    points: 20,
    isPositive: true,
  ),
  MockHistory(
    title: 'Verifikasi Bengkel Jaya',
    subtitle: 'Verifikasi disetujui',
    points: 10,
    isPositive: true,
  ),
  MockHistory(
    title: 'Penukaran Voucher Kopi Senja',
    subtitle: 'Voucher telah diklaim',
    points: 100,
    isPositive: false,
  ),
];

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int _activeTab = 0; // 0 = Voucher Saya, 1 = Riwayat Poin

  int _getMaxPoints(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze':
        return 100;
      case 'silver':
        return 200;
      case 'gold':
        return 300;
      case 'platinum':
        return 400;
      case 'super user':
        return 500;
      default:
        return 100;
    }
  }

  int _getTierInt(String tier) {
    switch (tier) {
      case 'Bronze':
        return 1;
      case 'Silver':
        return 2;
      case 'Gold':
        return 3;
      case 'Platinum':
        return 4;
      case 'Super User':
        return 5;
      default:
        return 1;
    }
  }

  void _claimVoucher(BuildContext context, MockVoucher voucher) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(AppRadii.radiusSheet)),
          ),
          title: const Text(
            'Voucher Diklaim',
            style: TextStyle(fontWeight: FontWeight.w800, color: Color(AppColors.primary)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.qr_code_2, size: 100, color: Color(AppColors.primary)),
              const SizedBox(height: 16),
              Text(
                'Tunjukkan kode ini ke kasir ${voucher.title.split(" ").last}:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Color(AppColors.textSubtle)),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(AppColors.primaryContainer),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'UMKMAP-CLAIM-9874',
                  style: TextStyle(
                    color: Color(AppColors.onPrimaryContainer),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user == null) return;

    final nameController = TextEditingController(text: user.fullName);
    final phoneController = TextEditingController(text: user.phone);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.radiusSheet)),
      ),
      builder: (context) {
        bool isSubmitting = false;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ubah Profil',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(AppColors.primary),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Color(AppColors.textPrimary)),
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    labelStyle: TextStyle(color: Color(AppColors.textSubtle)),
                    hintText: 'Masukkan nama lengkap',
                    hintStyle: TextStyle(color: Color(AppColors.textSubtle)),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Nama lengkap tidak boleh kosong';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: phoneController,
                  style: const TextStyle(color: Color(AppColors.textPrimary)),
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    labelStyle: TextStyle(color: Color(AppColors.textSubtle)),
                    hintText: 'Masukkan nomor telepon',
                    hintStyle: TextStyle(color: Color(AppColors.textSubtle)),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 24),
                StatefulBuilder(
                  builder: (context, setSubState) {
                    return SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(AppColors.primary),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(52),
                          shape: const StadiumBorder(),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setSubState(() => isSubmitting = true);
                                  final success = await context.read<AuthProvider>().updateProfile(
                                    fullName: nameController.text.trim(),
                                    phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                                  );
                                  if (success) {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Profil berhasil diperbarui'),
                                        ),
                                      );
                                    }
                                  } else {
                                    setSubState(() => isSubmitting = false);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(auth.errorMessage ?? 'Gagal memperbarui profil'),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        child: const Text('Simpan'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final roleLabel = _roleLabel(user?.role);

    final int currentPoints = user?.poin ?? 0;
    final String currentTier = user?.tier ?? 'Bronze';
    final int maxPoints = _getMaxPoints(currentTier);
    double progress = currentPoints / maxPoints;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      backgroundColor: const Color(AppColors.background),
      appBar: AppBar(
        title: const Text('Profil', style: TextStyle(color: Color(AppColors.textPrimary), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(AppColors.background),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(AppColors.textPrimary)),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: const BoxDecoration(
              color: Color(AppColors.secondary),
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 44,
                      color: Color(AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Pengguna',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(AppColors.onSecondary),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF4A5526),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _ProfileRoleChip(
                      roleLabel: roleLabel,
                      isAdmin: user?.isAdmin == true,
                    ),
                    _ProfileTierChip(tier: currentTier),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Card(
            color: Colors.white,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusCard)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Progres Poin',
                        style: TextStyle(
                          color: Color(AppColors.textPrimary),
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        '$currentPoints / $maxPoints Poin',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(AppColors.primary),
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: const Color(AppColors.primaryContainer),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Kumpulkan poin dengan memverifikasi data UMKM.',
                    style: TextStyle(
                      color: Color(AppColors.textSubtle),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(AppColors.primaryContainer),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 0),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? const Color(AppColors.primary) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Voucher Saya',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _activeTab == 0 ? Colors.white : const Color(AppColors.onPrimaryContainer),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 1),
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? const Color(AppColors.primary) : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        'Riwayat Poin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _activeTab == 1 ? Colors.white : const Color(AppColors.onPrimaryContainer),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_activeTab == 0)
            ..._vouchers.map((voucher) {
              final canClaim = currentPoints >= voucher.cost &&
                  _getTierInt(currentTier) >= voucher.minTier;
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(AppColors.primaryContainer),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer_outlined, color: Color(AppColors.primary), size: 22),
                  ),
                  title: Text(
                    voucher.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(AppColors.textPrimary)),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(voucher.subtitle, style: const TextStyle(color: Color(AppColors.textSubtle), fontSize: 12)),
                      const SizedBox(height: 2),
                      Text('Min. Tier: ${voucher.tierName}', style: const TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: canClaim ? const Color(AppColors.primary) : const Color(AppColors.fieldFill),
                      foregroundColor: canClaim ? Colors.white : const Color(AppColors.textSubtle),
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: canClaim ? () => _claimVoucher(context, voucher) : null,
                    child: const Text('Klaim', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              );
            })
          else
            ..._history.map((history) {
              return Card(
                color: Colors.white,
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: history.isPositive
                          ? const Color(0xFFE3F0DC)
                          : const Color(0xFFF7DFDD),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      history.isPositive
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: history.isPositive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    history.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(AppColors.textPrimary)),
                  ),
                  subtitle: Text(
                    history.subtitle,
                    style: const TextStyle(color: Color(AppColors.textSubtle), fontSize: 12),
                  ),
                  trailing: Text(
                    '${history.isPositive ? '+' : '-'}${history.points}',
                    style: TextStyle(
                      color: history.isPositive
                          ? const Color(0xFF2E7D32)
                          : const Color(0xFFC62828),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _UserInfoTile(
              name: user?.fullName ?? '-',
              roleLabel: roleLabel,
              email: user?.email,
              phone: user?.phone,
              onEdit: () => _showEditProfileSheet(context),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: const Color(AppColors.error),
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(String? role) {
    return switch (role) {
      'admin' => 'Admin',
      'pemilik' => 'Pemilik',
      final value? when value.isNotEmpty => value,
      _ => '-',
    };
  }
}

class _ProfileRoleChip extends StatelessWidget {
  const _ProfileRoleChip({required this.roleLabel, required this.isAdmin});

  final String roleLabel;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isAdmin ? Icons.admin_panel_settings_outlined : Icons.storefront_outlined,
              size: 16,
              color: const Color(AppColors.primary),
            ),
            const SizedBox(width: 6),
            Text(
              roleLabel,
              style: const TextStyle(
                color: Color(AppColors.primary),
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileTierChip extends StatelessWidget {
  const _ProfileTierChip({required this.tier});

  final String tier;

  @override
  Widget build(BuildContext context) {
    IconData getTierIcon(String t) {
      return switch (t.toLowerCase()) {
        'bronze' => Icons.star_border,
        'silver' => Icons.star_half,
        'gold' => Icons.star,
        'platinum' => Icons.workspace_premium,
        'super user' => Icons.auto_awesome,
        _ => Icons.star,
      };
    }

    Color getTierColor(String t) {
      return switch (t.toLowerCase()) {
        'bronze' => const Color(0xFFCD7F32), // Bronze
        'silver' => const Color(0xFF7A7F6C), // Silver/subtle olive
        'gold' => const Color(0xFFD9A62E), // Mustard/Gold
        'platinum' => const Color(0xFF3E7C6B), // Deep teal/Platinum
        'super user' => const Color(0xFFC4703A), // Terracotta/Super User
        _ => const Color(AppColors.primary),
      };
    }

    final tierColor = getTierColor(tier);

    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: Colors.white,
        shape: StadiumBorder(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              getTierIcon(tier),
              size: 16,
              color: tierColor,
            ),
            const SizedBox(width: 6),
            Text(
              tier,
              style: TextStyle(
                color: tierColor,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoTile extends StatelessWidget {
  const _UserInfoTile({
    required this.name,
    required this.roleLabel,
    required this.email,
    required this.phone,
    required this.onEdit,
  });

  final String name;
  final String roleLabel;
  final String? email;
  final String? phone;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadii.radiusCard)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: Color(AppColors.primaryContainer),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.badge_outlined,
                        color: Color(AppColors.primary),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Informasi Pengguna',
                      style: TextStyle(
                        color: Color(AppColors.textPrimary),
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: onEdit,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Ubah', style: TextStyle(color: Color(AppColors.primary), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _UserInfoRow(
              icon: Icons.person_outline,
              label: 'Nama Lengkap',
              value: name,
            ),
            const Divider(height: 1, color: Color(AppColors.hairline)),
            _UserInfoRow(
              icon: Icons.badge_outlined,
              label: 'Role',
              value: roleLabel,
            ),
            const Divider(height: 1, color: Color(AppColors.hairline)),
            _UserInfoRow(
              icon: Icons.mail_outline,
              label: 'Email',
              value: email,
            ),
            const Divider(height: 1, color: Color(AppColors.hairline)),
            _UserInfoRow(
              icon: Icons.phone_outlined,
              label: 'Nomor Telepon',
              value: phone,
            ),
          ],
        ),
      ),
    );
  }
}

class _UserInfoRow extends StatelessWidget {
  const _UserInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(AppColors.primaryContainer),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: const Color(AppColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(AppColors.textSubtle),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null || value!.isEmpty ? '-' : value!,
                  style: const TextStyle(
                    color: Color(AppColors.textPrimary),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
