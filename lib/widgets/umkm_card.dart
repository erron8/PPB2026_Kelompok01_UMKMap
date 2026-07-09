import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../models/umkm.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'status_chip.dart';

class UmkmCard extends StatelessWidget {
  const UmkmCard({super.key, required this.umkm, this.onTap});

  final Umkm umkm;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final category = umkm.kategoriNama ?? 'Kategori ${umkm.kategoriId}';
    final borderRadius = BorderRadius.circular(AppRadii.radiusCard);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(AppColors.textPrimary).withValues(alpha: 0.06),
            offset: const Offset(0, 1),
            blurRadius: 4,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _Photo(url: umkm.fotoUrl),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        umkm.namaUsaha,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: const Color(AppColors.textPrimary),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.place_outlined,
                            size: 14,
                            color: Color(AppColors.textSubtle),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${umkm.kecamatanNama}, ${umkm.kotaNama}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: const Color(AppColors.textSubtle),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          StatusChip(status: umkm.status, compact: true),
                          Text(
                            Formatters.date(umkm.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: const Color(AppColors.textFaint),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(AppColors.background),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chevron_right,
                    color: Color(AppColors.oliveGrey),
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Photo extends StatelessWidget {
  const _Photo({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final imageUrl = url;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.radiusThumb),
      child: SizedBox.square(
        dimension: 72,
        child: imageUrl == null || imageUrl.isEmpty
            ? ColoredBox(
                color: colorScheme.primaryContainer,
                child: Icon(
                  Icons.storefront,
                  color: colorScheme.primary,
                  size: 28,
                ),
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                placeholder: (context, _) => ColoredBox(
                  color: colorScheme.surfaceContainerHighest,
                  child: const Center(
                    child: SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                errorWidget: (context, _, _) => ColoredBox(
                  color: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
      ),
    );
  }
}
