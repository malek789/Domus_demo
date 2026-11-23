part of '../main.dart';

extension _AdminDialogs on _DomusHomeState {
  Future<void> _showAdminProperty(Map<String, dynamic> property) async {
    final photos = _propertyPhotos(property);
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: _LocalizedText(property['title'] as String? ?? ''),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (photos.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      photos.first,
                      height: 190,
                      width: 360,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                const SizedBox(height: 10),
                _LocalizedText(
                  '${_formatPrice(property)} · ${_t(property['status'] as String? ?? '')}',
                  style: const TextStyle(
                    color: teal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                _LocalizedText(
                  '${property['city'] ?? ''}${(property['neighborhood'] as String? ?? '').isNotEmpty ? ' · ${property['neighborhood']}' : ''}',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 14),
                const _LocalizedText(
                  'Description',
                  style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                _LocalizedText(property['description'] as String? ?? ''),
                const SizedBox(height: 12),
                _LocalizedText(
                  '${property['ownerName'] ?? ''}',
                  style: const TextStyle(color: muted, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _stat('${property['surface'] ?? 0} m²', 'Surface'),
                    _stat('${property['bedrooms'] ?? 0}', 'Chambres'),
                  ],
                ),
                if (photos.length > 1) ...[
                  const SizedBox(height: 12),
                  _LocalizedText(
                    '${photos.length} ${_t('Photos')}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const _LocalizedText('Fermer'),
          ),
        ],
      ),
    );
  }

  Future<void> _showAdminReport(Map<String, dynamic> report) async {
    final propertyId = report['propertyId'];
    final property = _adminProperties.firstWhere(
      (item) => item['id'] == propertyId,
      orElse: () => <String, dynamic>{},
    );
    final propertyExists = property.isNotEmpty;
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(context).height * 0.8,
          ),
          child: SizedBox(
            width: 520,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LocalizedText(
                    report['propertyTitle'] as String? ??
                        'Annonce supprimée ($propertyId)',
                    style: const TextStyle(
                      color: ink,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (propertyExists &&
                              (property['imageUrl'] as String? ?? '')
                                  .isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                resolvePhotoUrl(property['imageUrl'] as String),
                                height: 170,
                                width: 360,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) =>
                                    const SizedBox.shrink(),
                              ),
                            ),
                          if (propertyExists) ...[
                            const SizedBox(height: 10),
                            _LocalizedText(
                              '${property['city'] ?? ''} · ${_formatPrice(property)}',
                              style: const TextStyle(
                                color: teal,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            _LocalizedText(
                              _t(property['status'] as String? ?? ''),
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            _LocalizedText(
                              property['description'] as String? ?? '',
                            ),
                            const SizedBox(height: 8),
                            _LocalizedText(
                              '${property['ownerName'] ?? ''}',
                              style: const TextStyle(
                                color: muted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _stat(
                                  '${property['surface'] ?? 0} m²',
                                  'Surface',
                                ),
                                _stat(
                                  '${property['bedrooms'] ?? 0}',
                                  'Chambres',
                                ),
                              ],
                            ),
                          ] else
                            const _LocalizedText(
                              'Cette annonce a déjà été supprimée. Les informations du signalement restent disponibles ci-dessous.',
                              style: TextStyle(color: muted),
                            ),
                          const Divider(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _LocalizedText(
                                'Signalement de',
                                style: TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              _LocalizedText(
                                '${report['reporterName'] ?? ''} (${report['reporterEmail'] ?? ''})',
                                style: const TextStyle(
                                  color: ink,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          _LocalizedText(report['reason'] as String? ?? ''),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const _LocalizedText('Fermer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
