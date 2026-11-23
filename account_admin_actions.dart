part of '../main.dart';

extension _AccountAdminActions on _DomusHomeState {
  Future<void> _saveProfile() async {
    if (_token == null) return;
    try {
      final updated = await _request(
        '/profile',
        method: 'PATCH',
        session: _token,
        body: {
          'name': _profileName.text.trim(),
          'phone': _profilePhone.text.trim(),
        },
      );
      if (mounted) {
        _update(() => _user = updated);
        await Future.wait([_loadUserData(_token!), _loadProperties()]);
        _showNotice('Profil mis à jour.');
      }
    } catch (error) {
      if (mounted) {
        _showNotice(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<void> _loadAdminData([String? session]) async {
    // Admin collections are fetched concurrently and shown only after all succeed.
    final token = session ?? _token;
    if (token == null) return;
    try {
      final results = await Future.wait([
        _request('/admin/users', session: token),
        _request('/admin/properties', session: token),
        _request('/admin/reports', session: token),
        _request('/admin/user-reports', session: token),
      ]);
      if (!mounted) return;
      _update(() {
        _adminUsers = _mapList(results[0]['items']);
        _adminProperties = _mapList(results[1]['items']);
        _adminReports = _mapList(results[2]['items']);
        _adminUserReports = _mapList(results[3]['items']);
      });
    } catch (error) {
      if (mounted) {
        if (error is DomusApiException && error.statusCode == 403) {
          await _storage.delete(key: 'domus.token');
          _update(() {
            _token = null;
            _user = null;
          });
        }
        _showNotice(error.toString().replaceFirst('Exception: ', ''));
      }
    }
  }

  Future<bool> _confirmAdminAction(String title, String message) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: _LocalizedText(title),
          content: _LocalizedText(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const _LocalizedText('Annuler'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const _LocalizedText('Confirmer'),
            ),
          ],
        ),
      ) ==
      true;

  Future<void> _banAdminUser(Map<String, dynamic> user) async {
    if (!await _confirmAdminAction(
      'Bannir définitivement ?',
      'Ce compte ne pourra plus se connecter et ses annonces seront retirées.',
    )) {
      return;
    }
    try {
      await _request(
        '/admin/users/${user['id']}',
        method: 'DELETE',
        session: _token,
      );
      await _loadAdminData();
      _showNotice('Compte banni définitivement.');
    } catch (error) {
      _showNotice(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteAdminProperty(Map<String, dynamic> property) async {
    if (!await _confirmAdminAction(
      'Supprimer cette annonce ?',
      'Cette action est définitive.',
    )) {
      return;
    }
    try {
      await _request(
        '/admin/properties/${property['id']}',
        method: 'DELETE',
        session: _token,
      );
      await _loadAdminData();
      await _loadProperties();
      _showNotice('Annonce supprimée.');
    } catch (error) {
      _showNotice(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reviewAdminReport(
    Map<String, dynamic> report,
    String status,
  ) async {
    try {
      await _request(
        '/admin/reports/${report['id']}',
        method: 'PATCH',
        session: _token,
        body: {'status': status},
      );
      await _loadAdminData();
      if (mounted) {
        _showNotice(
          status == 'resolved' ? 'Signalement traité.' : 'Signalement ignoré.',
        );
      }
    } catch (error) {
      _showNotice(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _reviewAdminUserReport(
    Map<String, dynamic> report,
    String status,
  ) async {
    try {
      await _request(
        '/admin/user-reports/${report['id']}',
        method: 'PATCH',
        session: _token,
        body: {'status': status},
      );
      await _loadAdminData();
      if (mounted) {
        _showNotice(
          status == 'resolved' ? 'Signalement traité.' : 'Signalement ignoré.',
        );
      }
    } catch (error) {
      _showNotice(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _deleteMyProperty(Map<String, dynamic> property) async {
    final session = _token;
    if (session == null) return;
    if (!await _confirmAdminAction(
      'Supprimer mon annonce ?',
      'Cette action est définitive.',
    )) {
      return;
    }
    try {
      await _request(
        '/my/properties/${property['id']}',
        method: 'DELETE',
        session: session,
      );
      await Future.wait([_loadProperties(), _loadUserData(session)]);
      _showNotice('Annonce supprimée.');
    } catch (error) {
      _showNotice(error.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _confirmDeleteAccount() async {
    // Require explicit confirmation before the server permanently deletes the account.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const _LocalizedText('Supprimer votre compte ?'),
        content: const _LocalizedText(
          'Cette action supprime votre profil, vos annonces, favoris et conversations. Elle est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const _LocalizedText('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: danger),
            onPressed: () => Navigator.pop(context, true),
            child: const _LocalizedText('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || _token == null) return;
    _update(() => _busy = true);
    try {
      await _request('/account', method: 'DELETE', session: _token);
      await _storage.delete(key: 'domus.token');
      if (!mounted) return;
      _update(() {
        _token = null;
        _user = null;
        _favorites = [];
        _myProperties = [];
        _conversations = [];
        _notifications = [];
        _section = 'main';
        _tab = 0;
      });
      await _loadProperties();
      if (mounted) {
        _showNotice('Votre compte et vos données ont été supprimés.');
      }
    } catch (error) {
      if (mounted) {
        _showNotice(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }
}
