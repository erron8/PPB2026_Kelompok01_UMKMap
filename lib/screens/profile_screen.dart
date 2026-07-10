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
        final theme = Theme.of(context);
        return AlertDialog(
          title: const Text('Voucher Diklaim', style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.qr_code_2, size: 100, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                'Tunjukkan kode ini ke kasir ${voucher.title.split(" ").last}:',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'UMKMAP-CLAIM-9874',
                  style: TextStyle(
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
              child: const Text('Tutup'),
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
        final theme = Theme.of(context);
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
                Text(
                  'Ubah Profil',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    hintText: 'Masukkan nama lengkap',
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
                  decoration: const InputDecoration(
                    labelText: 'Nomor Telepon',
                    hintText: 'Masukkan nomor telepon',
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
    final theme = Theme.of(context);
    final roleLabel = _roleLabel(user?.role);

    final int currentPoints = user?.poin ?? 0;
    final String currentTier = user?.tier ?? 'Bronze';
    final int maxPoints = _getMaxPoints(currentTier);
    double progress = currentPoints / maxPoints;
    if (progress > 1.0) progress = 1.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        child: Column(
          children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary,
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(AppRadii.radiusSheet),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: Color(AppColors.surface),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    size: 44,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user?.fullName ?? 'Pengguna',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.onSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '-',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: const Color(0xFF4A5526),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
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
          const SizedBox(height: 24),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progres Poin',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '$currentPoints / $maxPoints Poin',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Tier saat ini: $currentTier',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: const Color(AppColors.textSubtle),
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
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(AppRadii.radiusPill),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 0),
                    borderRadius: BorderRadius.circular(AppRadii.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.radiusPill),
                      ),
                      child: Text(
                        'Voucher Saya',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _activeTab == 0 ? Colors.white : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () => setState(() => _activeTab = 1),
                    borderRadius: BorderRadius.circular(AppRadii.radiusPill),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? theme.colorScheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadii.radiusPill),
                      ),
                      child: Text(
                        'Riwayat Poin',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _activeTab == 1 ? Colors.white : theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
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
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.local_offer_outlined, color: theme.colorScheme.primary, size: 22),
                  ),
                  title: Text(
                    voucher.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(voucher.subtitle, style: const TextStyle(color: Color(AppColors.textSubtle), fontSize: 12)),
                      Text('Min. Tier: ${voucher.tierName}', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 11)),
                    ],
                  ),
                  trailing: FilledButton(
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: const StadiumBorder(),
                    ),
                    onPressed: canClaim ? () => _claimVoucher(context, voucher) : null,
                    child: const Text('Klaim', style: TextStyle(fontSize: 12)),
                  ),
                ),
              );
            })
          else
            ..._history.map((history) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: history.isPositive
                          ? const Color(AppColors.statusVerifiedFill)
                          : const Color(AppColors.statusRejectedFill),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      history.isPositive
                          ? Icons.add_circle_outline
                          : Icons.remove_circle_outline,
                      color: history.isPositive
                          ? const Color(AppColors.statusVerifiedText)
                          : const Color(AppColors.statusRejectedText),
                      size: 22,
                    ),
                  ),
                  title: Text(
                    history.title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  subtitle: Text(
                    history.subtitle,
                    style: const TextStyle(color: Color(AppColors.textSubtle), fontSize: 12),
                  ),
                  trailing: Text(
                    '${history.isPositive ? '+' : '-'}${history.points}',
                    style: TextStyle(
                      color: history.isPositive
                          ? const Color(AppColors.statusVerifiedText)
                          : const Color(AppColors.statusRejectedText),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),
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
                minimumSize: const Size.fromHeight(48),
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
                shape: const StadiumBorder(),
              ),
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AuthProvider>().logout();
                      if (context.mounted) context.go('/login');
                    },
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
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
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: Color(AppColors.surface),
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
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              roleLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
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
    final theme = Theme.of(context);

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

    return DecoratedBox(
      decoration: const ShapeDecoration(
        color: Color(AppColors.surface),
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
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              tier,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
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
    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.badge_outlined,
                        color: theme.colorScheme.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Informasi Pengguna',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
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
                  child: const Text('Ubah'),
                ),
              ],
            ),
            const SizedBox(height: 12),
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
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(AppColors.textSubtle),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == null || value!.isEmpty ? '-' : value!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
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
