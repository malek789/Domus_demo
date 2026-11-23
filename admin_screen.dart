part of '../main.dart';

extension _AdminScreen on _DomusHomeState {
  Widget _buildAdminConsole() {
    // Admin-only view for accounts, listings, listing reports, and user reports.
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: mint,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.shield_outlined, color: teal),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocalizedText(
                      'Espace sécurisé',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 3),
                    _LocalizedText(
                      'Gestion des comptes, annonces et signalements.',
                      style: TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _update(() => _section = 'main'),
            icon: const Icon(Icons.arrow_back, size: 18),
            label: const _LocalizedText('Mon profil'),
          ),
        ),
        Row(
          children: [
            const Expanded(
              child: _LocalizedText(
                'Administration',
                style: TextStyle(
                  color: ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              tooltip: _t('Actualiser'),
              onPressed: _loadAdminData,
              icon: const Icon(Icons.refresh),
            ),
            IconButton(
              tooltip: _t('Se déconnecter'),
              onPressed: _signOut,
              icon: const Icon(Icons.logout),
            ),
          ],
        ),
        _adminSectionHeader('Comptes', _adminUsers.length),
        ..._adminUsers.map((user) {
          final banned = user['bannedAt'] != null;
          return Card(
            color: Colors.white,
            child: ListTile(
              title: _LocalizedText(user['name'] as String? ?? ''),
              subtitle: _LocalizedText(user['email'] as String? ?? ''),
              trailing: banned
                  ? const Icon(Icons.block, color: danger)
                  : IconButton(
                      tooltip: _t('Bannir définitivement'),
                      onPressed: () => _banAdminUser(user),
                      icon: const Icon(
                        Icons.person_off_outlined,
                        color: danger,
                      ),
                    ),
              titleTextStyle: const TextStyle(
                color: ink,
                fontWeight: FontWeight.w700,
              ),
              subtitleTextStyle: const TextStyle(color: muted),
              leading: const Icon(Icons.person_outline, color: teal),
            ),
          );
        }),
        const SizedBox(height: 16),
        _adminSectionHeader('Annonces', _adminProperties.length),
        ..._adminProperties.map(
          (property) => Card(
            color: Colors.white,
            child: ListTile(
              onTap: () => _showAdminProperty(property),
              title: _LocalizedText(property['title'] as String? ?? ''),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LocalizedText(
                    '${property['city'] ?? ''} · ${_formatPrice(property)} · ${_t(property['status'] as String? ?? '')}',
                  ),
                  const _LocalizedText(
                    'Voir les détails',
                    style: TextStyle(color: teal, fontSize: 12),
                  ),
                ],
              ),
              trailing: IconButton(
                tooltip: _t('Supprimer'),
                onPressed: () => _deleteAdminProperty(property),
                icon: const Icon(Icons.delete_outline, color: danger),
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _adminSectionHeader('Signalements', _adminReports.length),
        if (_adminReports.isEmpty)
          const Card(
            color: Colors.white,
            child: ListTile(title: _LocalizedText('Aucun signalement.')),
          ),
        ..._adminReports.map((report) {
          final status = report['status'] as String? ?? 'pending';
          final matchingProperties = _adminProperties
              .where((item) => item['id'] == report['propertyId'])
              .toList();
          final reportedProperty = matchingProperties.isEmpty
              ? null
              : matchingProperties.first;
          return Card(
            color: Colors.white,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: () => _showAdminReport(report),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LocalizedText(
                      report['propertyTitle'] as String? ??
                          'Annonce supprimée (${report['propertyId']})',
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _LocalizedText(
                      '${report['reporterName'] ?? ''} · ${report['reporterEmail'] ?? ''}',
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    _LocalizedText(report['reason'] as String? ?? ''),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const _LocalizedText('Statut :'),
                        const SizedBox(width: 4),
                        _LocalizedText(status),
                      ],
                    ),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (status != 'resolved')
                          TextButton(
                            onPressed: () =>
                                _reviewAdminReport(report, 'resolved'),
                            child: const _LocalizedText('Résoudre'),
                          ),
                        if (status != 'rejected')
                          TextButton(
                            onPressed: () =>
                                _reviewAdminReport(report, 'rejected'),
                            child: const _LocalizedText('Ignorer'),
                          ),
                        if (reportedProperty != null)
                          TextButton.icon(
                            onPressed: () =>
                                _deleteAdminProperty(reportedProperty),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: danger,
                              size: 18,
                            ),
                            label: const _LocalizedText('Supprimer l’annonce'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 16),
        _adminSectionHeader(
          'Signalements utilisateurs',
          _adminUserReports.length,
        ),
        if (_adminUserReports.isEmpty)
          const Card(
            color: Colors.white,
            child: ListTile(
              title: _LocalizedText('Aucun signalement utilisateur.'),
            ),
          ),
        ..._adminUserReports.map((report) {
          final status = report['status'] as String? ?? 'pending';
          return Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LocalizedText(
                    report['reportedUserName'] as String? ??
                        'Utilisateur signalé',
                    style: const TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _LocalizedText(
                    '${report['reporterName'] ?? ''} · ${report['reportedUserEmail'] ?? ''}',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  _LocalizedText(report['reason'] as String? ?? ''),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const _LocalizedText('Statut :'),
                      const SizedBox(width: 4),
                      _LocalizedText(status),
                    ],
                  ),
                  Wrap(
                    spacing: 4,
                    children: [
                      if (status != 'resolved')
                        TextButton(
                          onPressed: () =>
                              _reviewAdminUserReport(report, 'resolved'),
                          child: const _LocalizedText('Résoudre'),
                        ),
                      if (status != 'rejected')
                        TextButton(
                          onPressed: () =>
                              _reviewAdminUserReport(report, 'rejected'),
                          child: const _LocalizedText('Ignorer'),
                        ),
                      if (report['reportedUserBannedAt'] == null)
                        TextButton.icon(
                          onPressed: () =>
                              _banAdminUser({'id': report['reportedUserId']}),
                          icon: const Icon(
                            Icons.person_off_outlined,
                            color: danger,
                            size: 18,
                          ),
                          label: const _LocalizedText('Bannir définitivement'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _adminSectionHeader(String label, int count) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        Expanded(
          child: _LocalizedText(
            label,
            style: const TextStyle(
              color: ink,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        CircleAvatar(
          radius: 13,
          backgroundColor: mint,
          child: Text(
            '$count',
            style: const TextStyle(
              color: teal,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
