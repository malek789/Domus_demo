part of '../main.dart';

extension _ProfileScreen on _DomusHomeState {
  Widget _buildProfile() {
    // Profile subpages reuse the same tab for personal listings, favorites, and settings.
    if (_user?['role'] == 'admin') return _buildAdminConsole();
    if (_section == 'favorites' && _user != null) {
      return _subPage(
        'Mes favoris',
        _favorites.isEmpty
            ? [
                _emptyState(
                  'Pas encore de favoris',
                  'Touchez le cœur d’une annonce pour la retrouver ici.',
                ),
              ]
            : _favorites.map(_propertyCard).toList(),
      );
    }
    if (_section == 'listings') {
      return _subPage(
        'Mes annonces',
        _myProperties.isEmpty
            ? [
                _emptyState(
                  'Aucune annonce publiée',
                  'Votre prochaine annonce n’attend que vous.',
                ),
              ]
            : _myProperties
                  .map(
                    (property) => Column(
                      children: [
                        _propertyCard(property),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _editProperty(property),
                                child: const _LocalizedText('Modifier'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _changeStatus(property),
                                child: _LocalizedText(
                                  property['status'] == 'paused'
                                      ? 'Remettre en ligne'
                                      : 'Mettre en pause',
                                ),
                              ),
                            ),
                          ],
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () => _deleteMyProperty(property),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: danger,
                            ),
                            label: const _LocalizedText(
                              'Supprimer',
                              style: TextStyle(color: danger),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .toList(),
      );
    }
    if (_section == 'notifications') {
      return _subPage(
        'Notifications',
        _notifications.isEmpty
            ? [
                _emptyState(
                  'Tout est à jour',
                  'Les nouveaux messages et annonces apparaîtront ici.',
                ),
              ]
            : _notifications
                  .map(
                    (item) => Card(
                      color: Colors.white,
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: mint,
                          child: Icon(Icons.notifications_none, color: teal),
                        ),
                        title: _LocalizedText(
                          item['title'] as String? ?? 'Notification',
                          style: const TextStyle(
                            color: ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: _LocalizedText(item['body'] as String? ?? ''),
                      ),
                    ),
                  )
                  .toList(),
      );
    }
    if (_section == 'privacy') {
      return _subPage('Confidentialité', [
        _privacyItem(
          'Données collectées',
          'Nom, adresse e-mail et téléphone facultatif du compte; annonces, photos, ville et emplacement précis fournis par leur propriétaire.',
        ),
        _privacyItem(
          'Activité du compte',
          'Favoris, conversations et messages sont enregistrés pour fournir les fonctions de l’application.',
        ),
        _privacyItem(
          'Utilisation des données',
          'Les données servent à publier et rechercher des biens, afficher les cartes et permettre aux acheteurs et propriétaires de communiquer.',
        ),
        _privacyItem(
          'Partage et services',
          'Les annonces et les emplacements choisis sont visibles par les utilisateurs. Les données nécessaires sont échangées avec le serveur Domus; les cartes chargent les tuiles OpenFreeMap.',
        ),
        _privacyItem(
          'Notifications locales',
          'Les préférences et alertes locales sont gérées sur cet appareil. Elles ne sont pas envoyées à Firebase ou à un service push.',
        ),
        _privacyItem(
          'Conservation et suppression',
          'Les données restent dans le compte jusqu’à suppression. La suppression du compte efface le profil, les annonces et les données associées selon le fonctionnement du service.',
        ),
        _privacyItem(
          'Vos choix',
          'Vous pouvez modifier votre profil, désactiver les notifications dans les réglages de l’appareil ou supprimer votre compte depuis le profil.',
        ),
        _privacyItem(
          'Contact',
          'Pour toute question relative à la confidentialité, contactez le support Domus.',
        ),
      ]);
    }
    if (_section == 'settings') {
      return _subPage(_t('Paramètres'), [
        SwitchListTile(
          value: _localNotificationsEnabled,
          onChanged: _localNotificationsBusy ? null : _setLocalNotifications,
          activeTrackColor: teal,
          title: _LocalizedText(
            _t('Notifications locales'),
            style: const TextStyle(color: ink),
          ),
          subtitle: _LocalizedText(
            _t('Alertes locales sur cet appareil uniquement'),
            style: TextStyle(color: muted),
          ),
        ),
        SwitchListTile(
          value: _notificationsEnabled,
          onChanged: (value) => _update(() => _notificationsEnabled = value),
          activeTrackColor: teal,
          title: _LocalizedText(
            _t('Notifications dans l’application'),
            style: TextStyle(color: ink),
          ),
          subtitle: _LocalizedText(
            _t('Messages et annonces sauvegardées'),
            style: TextStyle(color: muted),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LocalizedText(_t('Langue'), style: const TextStyle(color: ink)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final (code, label) in [
                    ('fr', 'Français'),
                    ('en', 'English'),
                    ('ar', 'العربية'),
                  ])
                    ChoiceChip(
                      label: _LocalizedText(label),
                      selected: _language == code,
                      onSelected: (_) => _setLanguage(code),
                      selectedColor: mint,
                      side: BorderSide(
                        color: _language == code ? teal : border,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        ListTile(
          title: _LocalizedText(_t('Confidentialité')),
          onTap: () => _update(() => _section = 'privacy'),
        ),
      ]);
    }
    return ListView(
      key: const ValueKey('profile-list'),
      padding: const EdgeInsets.all(20),
      children: [
        const _LocalizedText(
          'VOTRE ESPACE',
          style: TextStyle(
            color: teal,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        const _LocalizedText(
          'Mon profil',
          style: TextStyle(
            color: ink,
            fontSize: 27,
            fontWeight: FontWeight.w700,
          ),
        ),
        if (_user == null) ...[
          Card(
            color: mint,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _LocalizedText(
                    'Bienvenue chez Domus',
                    style: TextStyle(
                      color: ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 5),
                  _LocalizedText(
                    'Un compte pour contacter les propriétaires et garder vos biens favoris.',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ),
          _authCard(),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                _menuRow(
                  'Paramètres',
                  () => _update(() => _section = 'settings'),
                ),
              ],
            ),
          ),
        ] else ...[
          Card(
            color: Colors.white,
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: mint,
                foregroundColor: teal,
                child: _LocalizedText(
                  (_user?['name'] as String? ?? 'D').characters.first
                      .toUpperCase(),
                ),
              ),
              title: _LocalizedText(
                _user?['name'] as String? ?? '',
                style: const TextStyle(color: ink, fontWeight: FontWeight.w700),
              ),
              subtitle: _LocalizedText(_user?['email'] as String? ?? ''),
            ),
          ),
          Card(
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _LocalizedText(
                      'Modifier le profil',
                      style: TextStyle(color: ink, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _textField('Nom complet', _profileName),
                  _textField(
                    'Téléphone',
                    _profilePhone,
                    keyboard: TextInputType.phone,
                  ),
                  const SizedBox(height: 10),
                  _secondaryButton('Enregistrer', _saveProfile),
                ],
              ),
            ),
          ),
          Card(
            color: Colors.white,
            child: Column(
              children: [
                _menuRow(
                  'Mes annonces',
                  () => _update(() => _section = 'listings'),
                ),
                _menuRow(
                  'Mes favoris',
                  () => _update(() => _section = 'favorites'),
                ),
                _menuRow(
                  'Notifications',
                  () => _update(() => _section = 'notifications'),
                ),
                _menuRow(
                  'Paramètres',
                  () => _update(() => _section = 'settings'),
                ),
                _menuRow('Centre d’aide', _openSupportEmail),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _secondaryButton('Se déconnecter', _signOut),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _busy ? null : _confirmDeleteAccount,
            child: const _LocalizedText(
              'Supprimer mon compte',
              style: TextStyle(color: danger),
            ),
          ),
        ],
      ],
    );
  }
}
