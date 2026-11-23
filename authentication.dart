part of '../main.dart';

extension _Authentication on _DomusHomeState {
  Future<void> _loadUserData(String session) async {
    // Load independent account resources together, then notify about newly seen items.
    final results = await Future.wait([
      _request('/favorites', session: session),
      _request('/my/properties', session: session),
      _request('/conversations', session: session),
      _request('/notifications', session: session),
    ]);
    if (!mounted) return;
    _update(() {
      _favorites = _mapList(results[0]['items']);
      _myProperties = _mapList(results[1]['items']);
      _conversations = _mapList(results[2]['items']);
      _notifications = _mapList(results[3]['items']);
    });
    final notificationItems = _mapList(results[3]['items']);
    if (_hasLoadedNotifications) {
      for (final item in notificationItems) {
        if (!_knownNotificationIds.contains(item['id']) &&
            (item['read'] == false || item['read'] == 0)) {
          await _notifyLocally(
            item['title'] as String? ?? 'Domus',
            item['body'] as String? ?? '',
          );
        }
      }
    }
    _knownNotificationIds.addAll(notificationItems.map((item) => item['id']));
    _hasLoadedNotifications = true;
  }

  Future<void> _signIn() async {
    if (_registerMode) {
      final errors = <String, String>{};
      if (_authName.text.trim().length < 2) {
        errors['name'] = 'Saisissez un nom d’au moins 2 caractères.';
      }
      if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
          .hasMatch(_authEmail.text.trim())) {
        errors['email'] = 'Saisissez une adresse e-mail valide.';
      }
      if (_authPassword.text.length < 8 ||
          !RegExp(r'\d').hasMatch(_authPassword.text)) {
        errors['password'] = 'Utilisez au moins 8 caractères et un chiffre.';
      }
      if (!_acceptedTerms) {
        errors['terms'] = 'Veuillez accepter les conditions et la politique de confidentialité.';
      }
      _update(() {
        _authErrors
          ..clear()
          ..addAll(errors);
      });
      if (errors.isNotEmpty) return;
    }
    // Registration and login share a form but use different API endpoints and payloads.
    _update(() => _busy = true);
    try {
      final result = await _request(
        _registerMode ? '/auth/register' : '/auth/login',
        method: 'POST',
        body: _registerMode
            ? {
                'name': _authName.text.trim(),
                'email': _authEmail.text.trim(),
                'password': _authPassword.text,
                'acceptedTerms': _acceptedTerms,
              }
            : {'email': _authEmail.text.trim(), 'password': _authPassword.text},
      );
      final session = result['token'] as String?;
      final accountValue = result['user'];
      if (_registerMode && (session == null || accountValue is! Map)) {
        _authPassword.clear();
        if (!mounted) return;
        _update(() {
          _registerMode = false;
          _authFlow = 'verify';
        });
        _showNotice(
          'Si cette adresse peut être vérifiée, un courriel de confirmation a été envoyé. Consultez votre boîte de réception.',
        );
        return;
      }
      if (session == null || accountValue is! Map<String, dynamic>) {
        throw StateError('Connexion impossible pour le moment.');
      }
      final account = accountValue;
      await _storage.write(key: 'domus.token', value: session);
      if (!mounted) return;
      _update(() {
        _token = session;
        _user = account;
        _profileName.text = account['name'] as String? ?? '';
        _profilePhone.text = account['phone'] as String? ?? '';
        _authPassword.clear();
        _authErrors.clear();
      });
      if (account['role'] == 'admin') {
        await _loadAdminData(session);
      } else if (account['termsAcceptedAt'] != null) {
        await _loadUserData(session);
      }
      if (mounted) {
        _showNotice('Bienvenue chez vous !');
      }
    } catch (error) {
      if (error is DomusApiException && error.code == 'email_delivery_failed') {
        _authPassword.clear();
        _authToken.clear();
        if (!mounted) return;
        _update(() {
          _registerMode = false;
          _authFlow = 'verify';
        });
        _showNotice(error.message);
      } else if (error is DomusApiException &&
          error.code == 'email_verification_required') {
        _authPassword.clear();
        _authToken.clear();
        if (!mounted) return;
        _update(() {
          _registerMode = false;
          _authFlow = 'verify';
        });
        _showNotice(
          'Votre adresse e-mail n’est pas encore vérifiée. Saisissez le code reçu ou demandez un nouvel envoi.',
        );
      } else if (mounted) {
        if (_registerMode &&
            error is DomusApiException &&
            error.statusCode == 409) {
          _update(() => _authErrors['email'] = error.message);
        } else {
          _showNotice(error.toString().replaceFirst('Exception: ', ''));
        }
      }
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }

  Future<void> _verifyEmail() async {
    final code = _authToken.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _showNotice(
        'Saisissez les 6 chiffres du code de vérification reçu par e-mail.',
      );
      return;
    }
    final email = _authEmail.text.trim();
    if (email.isEmpty) {
      _showNotice('Saisissez votre adresse e-mail.');
      return;
    }
    _update(() => _busy = true);
    try {
      await _request(
        '/auth/verify-email',
        method: 'POST',
        body: {'email': email, 'token': code},
      );
      if (!mounted) return;
      _update(() {
        _authToken.clear();
        _authFlow = 'login';
      });
      _showNotice(
        'Adresse e-mail vérifiée. Vous pouvez maintenant vous connecter.',
      );
    } catch (_) {
      _showNotice(
        'Ce code de vérification est invalide ou expiré. Vérifiez-le.',
      );
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }

  Future<void> _resendVerificationEmail() async {
    final email = _authEmail.text.trim();
    if (email.isEmpty) {
      _showNotice('Saisissez votre adresse e-mail.');
      return;
    }
    _update(() => _busy = true);
    try {
      await _request(
        '/auth/resend-verification',
        method: 'POST',
        body: {'email': email},
      );
      if (mounted) {
        _showNotice(
          'Si un compte correspondant peut être vérifié, un courriel de confirmation a été envoyé.',
        );
      }
    } catch (error) {
      if (mounted) {
        _showNotice(error.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) _update(() => _busy = false);
    }
  }

  Future<void> _signOut() async {
    _messagePoll?.cancel();
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
    });
    _showNotice('Vous êtes déconnecté(e).');
  }
}
